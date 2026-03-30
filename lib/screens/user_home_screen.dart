import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/aisee_api_models.dart';
import '../services/aisee_livekit_voice_session.dart';
import '../theme/style_tokens.dart';
import '../widgets/app_wordmark.dart';
import '../widgets/user_low_vision_bottom_nav.dart';
import 'user_assistant_tab.dart';
import 'user_personal_tab.dart';
import 'user_tools_tab.dart';

/// Home người dùng chính — 3 tab cố định + nav nổi pill, ưu tiên thị lực thấp / a11y.
class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({
    super.key,
    this.googleUser,
    this.aiseeProfile,
    this.aiseeLoading = false,
    this.aiseeError,
    required this.onSignOut,
  });

  final GoogleSignInAccount? googleUser;
  final AiseeUserProfile? aiseeProfile;
  final bool aiseeLoading;
  final String? aiseeError;
  final VoidCallback onSignOut;

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen>
    with SingleTickerProviderStateMixin {
  int _tabIndex = 0;
  late final AnimationController _tabFade;

  final AiseeLiveKitVoiceSession _liveKitVoice = AiseeLiveKitVoiceSession();
  bool _liveKitConnecting = true;
  String? _liveKitError;
  bool _liveKitConnected = false;

  String get _displayName {
    final String? googleName = widget.googleUser?.displayName?.trim();
    final String? profileName = widget.aiseeProfile?.displayName?.trim();
    if (googleName != null && googleName.isNotEmpty) return googleName;
    if (profileName != null && profileName.isNotEmpty) return profileName;
    return widget.aiseeProfile?.email ?? '—';
  }

  static const List<String> _tabNames = ['Tro ly', 'Cong cu', 'Ca nhan'];

  void _onTabChanged(int index) {
    if (index == _tabIndex) return;
    debugPrint('[AiSee:UI] Tab: ${_tabNames[_tabIndex]} -> ${_tabNames[index]}');
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
    debugPrint('[AiSee:UI] User: $_displayName');
    debugPrint('[AiSee:UI] aiseeLoading=${widget.aiseeLoading} aiseeError=${widget.aiseeError}');
    _liveKitVoice.onMusicUiChanged = _onMusicUiChanged;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_startLiveKitVoice());
    });
  }

  void _onMusicUiChanged() {
    if (!mounted) return;
    debugPrint('[AiSee:UI] Music UI changed: title=${_liveKitVoice.nowPlayingTitle ?? "(none)"}');
    setState(() {});
  }

  @override
  void dispose() {
    _tabFade.dispose();
    debugPrint('[AiSee:UI] UserHomeScreen dispose — ngat LiveKit');
    _liveKitVoice.onMusicUiChanged = null;
    unawaited(_liveKitVoice.disconnect());
    _liveKitVoice.disposeHttp();
    super.dispose();
  }

  Future<void> _startLiveKitVoice() async {
    if (!mounted) return;
    debugPrint('');
    debugPrint('====================================');
    debugPrint('[AiSee:UI] BAT DAU KET NOI LIVEKIT');
    debugPrint('====================================');
    setState(() {
      _liveKitConnecting = true;
      _liveKitError = null;
      _liveKitConnected = false;
    });
    debugPrint('[AiSee:UI] State: connecting=true connected=false error=null');
    try {
      await _liveKitVoice.connect(
        userName: _displayName,
        userId: widget.aiseeProfile?.id ?? '',
        hasFamilyLink: false,
      );
      if (!mounted) return;
      setState(() {
        _liveKitConnected = true;
        _liveKitConnecting = false;
        _liveKitError = null;
      });
      debugPrint('');
      debugPrint('====================================');
      debugPrint('[AiSee:UI] KET NOI THANH CONG!');
      debugPrint('[AiSee:UI] State: connecting=false connected=true error=null');
      debugPrint('====================================');
      debugPrint('');
    } catch (e, st) {
      debugPrint('LiveKit voice: $e\n$st');
      if (!mounted) return;
      final String msg = e is AiseeApiException
          ? e.message
          : 'Không kết nối được trợ lý giọng nói.';
      setState(() {
        _liveKitError = msg;
        _liveKitConnecting = false;
        _liveKitConnected = false;
      });
      debugPrint('');
      debugPrint('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
      debugPrint('[AiSee:UI] LOI KET NOI LIVEKIT');
      debugPrint('[AiSee:UI] Error: $msg');
      debugPrint('[AiSee:UI] State: connecting=false connected=false');
      debugPrint('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
      debugPrint('');
    }
  }

  Widget _buildAppBarTitle() {
    if (_tabIndex == 0) {
      return Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Xin chào, $_displayName',
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
          ),
          const AppWordmark(fontSize: 15),
        ],
      );
    }
    return const Align(
      alignment: Alignment.centerLeft,
      widthFactor: 1,
      child: AppWordmark(fontSize: 15),
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
                  liveKitConnecting: _liveKitConnecting,
                  liveKitError: _liveKitError,
                  liveKitConnected: _liveKitConnected,
                  nowPlayingTitle: _liveKitVoice.nowPlayingTitle,
                  assistantWaveEnergy: _liveKitVoice.assistantWaveEnergy,
                  agentState: _liveKitVoice.agentState,
                  localCameraPreviewTrack:
                      _liveKitVoice.localCameraPreviewTrack,
                  onRetryLiveKit: _startLiveKitVoice,
                ),
                const UserToolsTab(),
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
            ),
          ),
        ],
      ),
    );
  }
}
