import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/aisee_locale_controller.dart';
import '../generated/l10n/app_localizations.dart';
import '../models/aisee_api_models.dart';
import '../models/aisee_call_info.dart';
import '../models/aisee_family_member.dart';
import '../models/aisee_incoming_call.dart';
import '../models/agent_state.dart';
import '../services/aisee_chat_socket.dart';
import '../services/aisee_ai_assistant_controller.dart';
import '../services/aisee_ai_camera_streamer.dart';
import '../services/aisee_ai_microphone_input.dart';
import '../services/aisee_ai_session.dart';
import '../services/aisee_analytics_service.dart';
import '../services/aisee_assistant_call_launcher.dart';
import '../services/aisee_assistant_device_command_handler.dart';
import '../services/aisee_audio_uplink_gate.dart';
import '../services/assistant_audio_coordinator.dart';
import '../services/aisee_auth_service.dart';
import '../services/aisee_family_service.dart';
import '../services/aisee_notification_feedback.dart';
import '../services/aisee_pcm_audio_player.dart';
import '../services/aisee_push_service.dart';
import '../services/aisee_wake_word_service.dart';
import '../services/in_app_message_controller.dart';
import '../services/aisee_session_store.dart';
import '../theme/style_tokens.dart';
import '../utils/app_toast.dart';
import '../widgets/app_wordmark.dart';
import '../widgets/user_low_vision_bottom_nav.dart';
import 'call_screen.dart';
import 'user_assistant_tab.dart';
import 'user_personal_tab.dart';
import 'contacts_tab.dart';

/// Home người dùng chính — 3 tab cố định + nav nổi pill, ưu tiên thị lực thấp / a11y.
class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({
    super.key,
    this.googleUser,
    this.aiseeProfile,
    this.aiseeLoading = false,
    this.aiseeError,
    required this.onSignOut,
    required this.chatSocket,
  });

  final GoogleSignInAccount? googleUser;
  final AiseeUserProfile? aiseeProfile;
  final bool aiseeLoading;
  final String? aiseeError;
  final VoidCallback onSignOut;
  final AiseeChatSocket chatSocket;

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  int _tabIndex = 0;
  late final AnimationController _tabFade;

  late final AiseeAiAssistantController _assistantController;
  late final AssistantAudioCoordinator _assistantAudioCoordinator;
  late final bool _wakeWordEnabled;
  bool _assistantConnecting = true;
  String? _assistantError;
  bool _assistantConnected = false;
  bool _showWakeReminder = false;

  String get _displayName {
    final String? googleName = widget.googleUser?.displayName?.trim();
    final String? profileName = widget.aiseeProfile?.displayName?.trim();
    if (googleName != null && googleName.isNotEmpty) return googleName;
    if (profileName != null && profileName.isNotEmpty) return profileName;
    return widget.aiseeProfile?.email ?? '—';
  }

  static const List<String> _tabNames = ['Tro ly', 'Lien lac', 'Ca nhan'];

  void _onTabChanged(int index) {
    if (index == _tabIndex) return;
    debugPrint(
      '[AiSee:UI] Tab: ${_tabNames[_tabIndex]} -> ${_tabNames[index]}',
    );
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);
    _tabFade.reverse().then((_) {
      if (!mounted) return;
      setState(() => _tabIndex = index);
      if (index == 2) {
        UserPersonalTab.tabKey.currentState?.refreshReminders();
      }
      _tabFade.forward();
    });
  }

  /// Ngay khi wake được chấp nhận (trước khi nhả DaVoice / bật mic) — tương tự chuông vào session của hello-wakeword.
  void _signalWakeAcknowledged() {
    _clearWakeReminder();
    HapticFeedback.lightImpact();
    SystemSound.play(SystemSoundType.click);
  }

  /// Sau wake word + mic trợ lý: rung + âm + thông báo trợ năng — user biết lúc được nói.
  void _signalAssistantReadyToUser() {
    if (!mounted) {
      return;
    }
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.alert);
    try {
      SemanticsService.sendAnnouncement(
        View.of(context),
        AppLocalizations.of(context).homeMicReadyAnnouncement,
        Directionality.of(context),
      );
    } catch (e, st) {
      debugPrint('[AiSee:UI] sendAnnouncement mic ready: $e\n$st');
    }
  }

  void _signalAssistantTimedOutToUser() {
    if (!mounted) {
      return;
    }
    AiseeNotificationFeedback.instance.playMessageAlert();
    try {
      SemanticsService.sendAnnouncement(
        View.of(context),
        AppLocalizations.of(context).homeWakeReminderAnnouncement,
        Directionality.of(context),
      );
    } catch (e, st) {
      debugPrint('[AiSee:UI] sendAnnouncement wake reminder: $e\n$st');
    }
  }

  void _clearWakeReminder() {
    if (!_showWakeReminder || !mounted) {
      return;
    }
    setState(() => _showWakeReminder = false);
  }

  void _handleReturnedToIdleWake(String reason) {
    if (reason != 'grace-expired' || !mounted) {
      return;
    }
    setState(() => _showWakeReminder = true);
    _signalAssistantTimedOutToUser();
  }

  @override
  void initState() {
    super.initState();
    _tabFade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      value: 1.0,
    );
    debugPrint('');
    debugPrint('[AiSee:UI] UserHomeScreen initState');
    unawaited(AiseeAnalyticsService.instance.trackScreen('user_home'));
    debugPrint('[AiSee:UI] User: $_displayName');
    debugPrint(
      '[AiSee:UI] aiseeLoading=${widget.aiseeLoading} aiseeError=${widget.aiseeError}',
    );
    WidgetsBinding.instance.addObserver(this);
    _wakeWordEnabled = AiseeWakeWordService.instance.isFeatureEnabledByConfig;
    debugPrint('[AiSee:UI] Wake word enabled=$_wakeWordEnabled');
    _assistantController = AiseeAiAssistantController(
      session: AiseeAiSessionClientAdapter(AiseeAiSession()),
      microphoneInput: AiseeAiRecordMicrophoneInput(),
      cameraStreamer: AiseeCameraPackageStreamer(
        onUnsafeContent: () async {
          if (!mounted) {
            return;
          }
          await AppToast.show(
            lookupAppLocalizations(
              AiseeLocaleController.instance.value,
            ).homeCameraBlockedNsfw,
            isError: true,
          );
        },
      ),
      audioPlayer: AiseeFlutterPcmAudioPlayer(),
      audioUplinkGate: AiseeAudioUplinkGate.echoOnly(),
      deviceCommandHandler: AiseeDefaultAssistantDeviceCommandHandler(
        onEnableCamera: (Map<String, dynamic> params) =>
            _assistantController.enableCamera(params),
        onDisableCamera: (Map<String, dynamic> params) =>
            _assistantController.disableCamera(params),
        onStartCall: (Map<String, dynamic> params) =>
            AiseeAssistantCallLauncher.instance.startCall(params),
        onAnswerIncomingCall: _handleAgentAnswerIncomingCall,
        onDeclineIncomingCall: _handleAgentDeclineIncomingCall,
      ),
      onMusicPlaybackStarted: () async {
        if (!_wakeWordEnabled) {
          return;
        }
        await _assistantAudioCoordinator.enterIdleWakeMode(
          reason: 'music-playback-started',
        );
      },
    );
    _assistantAudioCoordinator = AssistantAudioCoordinator(
      startWakeListening: AiseeWakeWordService.instance.startIdleListening,
      stopWakeListening: AiseeWakeWordService.instance.stopForLiveSession,
      enableAssistantMic: _assistantController.enableAssistantMic,
      disableAssistantMic: _assistantController.disableAssistantMic,
      switchToAssistantTab: () => _onTabChanged(0),
      gracePeriod: const Duration(seconds: 20),
      onWakeAcknowledged: _wakeWordEnabled ? _signalWakeAcknowledged : null,
      onMicReadyAfterWake: _wakeWordEnabled
          ? _signalAssistantReadyToUser
          : null,
      onReturnedToIdleWake: _wakeWordEnabled ? _handleReturnedToIdleWake : null,
      log: (String message) => debugPrint('[AiSee:WakeFlow] $message'),
    );
    _assistantController.nowPlayingTitle.addListener(_onMusicUiChanged);
    _assistantController.cameraPreview.addListener(_onCameraPreviewChanged);
    if (_wakeWordEnabled) {
      _assistantController.agentState.addListener(_onAgentStateChanged);
      AiseeWakeWordService.instance.onWakePhrase = (String phrase) {
        if (!mounted) {
          return;
        }
        unawaited(_assistantAudioCoordinator.onWakeDetected(phrase: phrase));
      };
    } else {
      AiseeWakeWordService.instance.onWakePhrase = null;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_startAssistantSession());
    });
    final AiseeCallInfo? pending = AiseePushService.instance
        .consumePendingCall();
    if (pending != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || CallScreen.openRouteCount > 0) return;
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute<void>(
            fullscreenDialog: true,
            builder: (_) => CallScreen(callInfo: pending),
          ),
        );
      });
    }
  }

  void _onMusicUiChanged() {
    if (!mounted) return;
    debugPrint(
      '[AiSee:UI] Music UI changed: title=${_assistantController.nowPlayingTitle.value ?? "(none)"}',
    );
    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_wakeWordEnabled) {
        unawaited(
          _assistantAudioCoordinator.onAppResumed(
            liveKitConnected: _assistantConnected,
          ),
        );
      }
    } else if (state == AppLifecycleState.paused) {
      if (_wakeWordEnabled) {
        unawaited(_assistantAudioCoordinator.onAppPaused());
      }
    }
  }

  @override
  void dispose() {
    if (_wakeWordEnabled) {
      _assistantAudioCoordinator.dispose();
      unawaited(AiseeWakeWordService.instance.stop());
    }
    WidgetsBinding.instance.removeObserver(this);
    _tabFade.dispose();
    debugPrint('[AiSee:UI] UserHomeScreen dispose — ngat AI assistant');
    if (_wakeWordEnabled) {
      _assistantController.agentState.removeListener(_onAgentStateChanged);
    }
    _assistantController.nowPlayingTitle.removeListener(_onMusicUiChanged);
    _assistantController.cameraPreview.removeListener(_onCameraPreviewChanged);
    unawaited(_assistantController.dispose());
    super.dispose();
  }

  void _onCameraPreviewChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  void _onAgentStateChanged() {
    if (!_wakeWordEnabled) {
      return;
    }
    final AgentState next = _assistantController.agentState.value;
    if (next.keepsConversationOpen) {
      _clearWakeReminder();
    }
    _assistantAudioCoordinator.onAgentStateChanged(next);
  }

  Future<Map<String, Object?>> _handleAgentAnswerIncomingCall(
    Map<String, dynamic> params,
  ) async {
    final String roomName = (params['room_name'] as String?) ?? '';
    final String token = (params['token'] as String?) ?? '';
    if (roomName.isEmpty || token.isEmpty) {
      return const <String, Object?>{
        'status': 'no_pending_call',
        'message': 'No incoming call is currently ringing.',
      };
    }
    final AiseeIncomingCall call =
        AiseeIncomingCall.fromPayload(<String, dynamic>{
          'room_name': roomName,
          'token': token,
          'caller_id': params['caller_id'] ?? '',
          'caller_name': params['caller_name'] ?? '',
          'caller_avatar_url': params['caller_avatar_url'],
          'call_type': params['call_type'] ?? 'voice',
        }, source: AiseeIncomingCallSource.callkit);
    await AiseePushService.instance.acceptIncomingCall(call);
    return <String, Object?>{
      'status': 'answered',
      'room_name': roomName,
      'caller_name': call.callerName,
      'call_type': call.callType,
    };
  }

  Future<Map<String, Object?>> _handleAgentDeclineIncomingCall(
    Map<String, dynamic> params,
  ) async {
    final String roomName = (params['room_name'] as String?) ?? '';
    if (roomName.isEmpty) {
      return const <String, Object?>{
        'status': 'no_pending_call',
        'message': 'No incoming call is currently ringing.',
      };
    }
    final AiseeIncomingCall call =
        AiseeIncomingCall.fromPayload(<String, dynamic>{
          'room_name': roomName,
          'caller_id': params['caller_id'] ?? '',
          'caller_name': params['caller_name'] ?? '',
          'call_type': params['call_type'] ?? 'voice',
        }, source: AiseeIncomingCallSource.callkit);
    await AiseePushService.instance.declineIncomingCall(call);
    return <String, Object?>{'status': 'declined', 'room_name': roomName};
  }

  Future<bool> _computeHasFamilyLink() async {
    final AiseeAuthTokens? tokens = await AiseeSessionStore.instance.read();
    if (tokens == null) {
      return false;
    }
    final AiseeFamilyService svc = AiseeFamilyService();
    try {
      final List<AiseeFamilyMember> family = await svc.fetchFamily(
        tokens.accessToken,
      );
      AiseeInAppMessageController.instance.rememberContacts(family);
      return family.isNotEmpty;
    } catch (_) {
      return false;
    } finally {
      svc.close();
    }
  }

  Future<void> _startAssistantSession() async {
    if (!mounted) return;
    debugPrint('');
    debugPrint('====================================');
    debugPrint('[AiSee:UI] BAT DAU KET NOI AI WS');
    debugPrint('====================================');
    setState(() {
      _assistantConnecting = true;
      _assistantError = null;
      _assistantConnected = false;
    });
    debugPrint('[AiSee:UI] State: connecting=true connected=false error=null');
    try {
      final Future<bool> familyLinkFuture = _computeHasFamilyLink();
      debugPrint(
        '[AiSee:UI] fetchFamily chay song song voi ket noi AI session',
      );
      final AiseeAuthTokens? tokens = await AiseeSessionStore.instance.read();
      if (tokens == null) {
        throw AiseeApiException(
          lookupAppLocalizations(
            AiseeLocaleController.instance.value,
          ).homeNoSession,
        );
      }
      try {
        await _assistantController.connect(tokens.accessToken);
      } on AiseeAiSessionException catch (error) {
        if (error.statusCode != 401) {
          rethrow;
        }
        final AiseeAuthService auth = AiseeAuthService();
        try {
          final AiseeAuthTokens rotated = await auth.refreshTokens(
            tokens.refreshToken,
          );
          await AiseeSessionStore.instance.write(rotated);
          await _assistantController.connect(rotated.accessToken);
        } finally {
          auth.close();
        }
      }
      if (!mounted) return;
      final bool hasLink = await familyLinkFuture;
      debugPrint('[AiSee:UI] hasFamilyLink=$hasLink');
      if (!mounted) return;
      setState(() {
        _assistantConnected = true;
        _assistantConnecting = false;
        _assistantError = null;
        _showWakeReminder = false;
      });
      unawaited(
        AiseeAnalyticsService.instance.trackOnce(
          AiseeAnalyticsEvent.firstAiSessionStarted,
          parameters: <String, Object?>{'has_family_link': hasLink},
        ),
      );
      debugPrint('');
      debugPrint('====================================');
      debugPrint('[AiSee:UI] KET NOI THANH CONG!');
      debugPrint(
        '[AiSee:UI] State: connecting=false connected=true error=null',
      );
      debugPrint('====================================');
      debugPrint('');
      if (_wakeWordEnabled) {
        await _assistantAudioCoordinator.enterIdleWakeMode(
          reason: 'ai-session-connected',
        );
      } else {
        await _assistantController.enableAssistantMic();
        debugPrint(
          '[AiSee:UI] Wake word disabled by env -> mic ON immediately',
        );
      }
    } catch (e, st) {
      debugPrint('AI websocket assistant: $e\n$st');
      unawaited(
        AiseeAnalyticsService.instance.trackAiSessionError(
          e,
          stackTrace: st,
          reason: 'ai_websocket_connect',
        ),
      );
      if (!mounted) return;
      final String msg = switch (e) {
        AiseeApiException error => error.message,
        AiseeAiSessionException error => error.message,
        _ => lookupAppLocalizations(
          AiseeLocaleController.instance.value,
        ).homeAssistantConnectFail,
      };
      setState(() {
        _assistantError = msg;
        _assistantConnecting = false;
        _assistantConnected = false;
        _showWakeReminder = false;
      });
      debugPrint('');
      debugPrint('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
      debugPrint('[AiSee:UI] LOI KET NOI AI WS');
      debugPrint('[AiSee:UI] Error: $msg');
      debugPrint('[AiSee:UI] State: connecting=false connected=false');
      debugPrint('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
      debugPrint('');
    }
  }

  Widget _buildAppBarTitle() {
    final AppLocalizations l = AppLocalizations.of(context);
    final List<String?> tabTitles = <String?>[
      null,
      l.homeTabContacts,
      l.homeTabPersonal,
    ];
    final String? tabTitle = tabTitles[_tabIndex];
    final String leftText = tabTitle ?? l.homeGreeting(_displayName);
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            leftText,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1,
              letterSpacing: -0.5,
              color: StyleTokens.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const AppWordmark(fontSize: 15),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: StyleTokens.background,
      extendBody: true,
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 20,
        toolbarHeight: 48,
        scrolledUnderElevation: 0,
        title: _buildAppBarTitle(),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 8,
              bottom: 112 + bottomInset,
            ),
            child: FadeTransition(
              opacity: _tabFade,
              child: IndexedStack(
                index: _tabIndex,
                children: [
                  UserAssistantTab(
                    aiseeLoading: widget.aiseeLoading,
                    aiseeError: widget.aiseeError,
                    assistantConnecting: _assistantConnecting,
                    assistantError: _assistantError,
                    assistantConnected: _assistantConnected,
                    nowPlayingTitle: _assistantController.nowPlayingTitle.value,
                    assistantWaveEnergy:
                        _assistantController.assistantWaveEnergy,
                    agentState: _assistantController.agentState,
                    showWakeReminder: _showWakeReminder,
                    assistantCameraPreview:
                        _assistantController.cameraPreview.value,
                    onRetryAssistant: _startAssistantSession,
                  ),
                  ContactsTab(
                    aiseeProfile: widget.aiseeProfile,
                    chatSocket: widget.chatSocket,
                  ),
                  UserPersonalTab(
                    key: UserPersonalTab.tabKey,
                    onSignOut: widget.onSignOut,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16 + bottomInset,
            child: UserLowVisionBottomNav(
              currentIndex: _tabIndex,
              onChanged: _onTabChanged,
              items: UserLowVisionBottomNav.defaultItems(
                AppLocalizations.of(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
