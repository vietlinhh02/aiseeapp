import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:aiseeapp/theme/aisee_typography.dart';
import 'package:livekit_client/livekit_client.dart';

import '../config/app_env.dart';
import '../generated/l10n/app_localizations.dart';
import '../models/aisee_api_models.dart';
import '../models/aisee_call_info.dart';
import '../services/aisee_call_service.dart';
import '../services/aisee_notification_feedback.dart';
import '../services/aisee_session_store.dart';
import '../theme/style_tokens.dart';
import '../utils/app_toast.dart';

String aiseeCallJoinErrorMessage(Object error) {
  if (error case AiseeApiException(:final String message)) {
    return message;
  }
  return 'callJoinFailed'; // key — resolved by caller with l10n
}

bool aiseeShouldEnableSpeakerByDefault(String callType) {
  return callType == 'voice' || callType == 'video';
}

bool aiseeShouldRefreshLocalVideoUi({
  required bool isLocalParticipant,
  required TrackSource? source,
}) {
  return isLocalParticipant && source == TrackSource.camera;
}

enum _CallState { ringing, connected, ended }

typedef AiseeCallErrorCallback = void Function(String message);

class CallScreen extends StatefulWidget {
  const CallScreen({
    super.key,
    required this.callInfo,
    this.outgoingAnswerTimeout,
    this.onAnswered,
    this.onNoAnswer,
    this.onStartFailed,
    this.onCancelledWhileRinging,
  });

  final AiseeCallInfo callInfo;
  final Duration? outgoingAnswerTimeout;
  final VoidCallback? onAnswered;
  final VoidCallback? onNoAnswer;
  final AiseeCallErrorCallback? onStartFailed;
  final VoidCallback? onCancelledWhileRinging;

  /// Tránh mở trùng từ [AiseePushService.syncActiveAcceptedCall] + pending.
  static int openRouteCount = 0;

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  _CallState _state = _CallState.ringing;
  Room? _room;
  EventsListener<RoomEvent>? _roomListener;
  bool _micEnabled = true;
  bool _speakerEnabled = true;
  bool _cameraEnabled = true;
  bool _toggling = false; // Guard against rapid taps on buttons.
  final ValueNotifier<Duration> _duration = ValueNotifier<Duration>(
    Duration.zero,
  );
  Timer? _durationTimer;
  Timer? _answerTimeoutTimer;
  RemoteParticipant? _remoteParticipant;
  bool _answeredNotified = false;
  bool _ringingEndNotified = false;

  bool get _isVideo => widget.callInfo.callType == 'video';

  AppLocalizations get l10n => AppLocalizations.of(context);

  static String _formatDuration(Duration d) {
    final int min = d.inMinutes;
    final int sec = d.inSeconds % 60;
    return '${min.toString().padLeft(2, '0')}:'
        '${sec.toString().padLeft(2, '0')}';
  }

  String get _statusText {
    switch (_state) {
      case _CallState.ringing:
        return l10n.callDialing;
      case _CallState.connected:
        return _formatDuration(_duration.value);
      case _CallState.ended:
        return l10n.callEnded;
    }
  }

  @override
  void initState() {
    super.initState();
    CallScreen.openRouteCount++;
    // Render UI first (show "Đang gọi..."), then connect.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _connectToRoom();
    });
  }

  Future<void> _connectToRoom() async {
    final Room room = Room(
      roomOptions: const RoomOptions(
        adaptiveStream: true,
        dynacast: true,
        defaultAudioPublishOptions: AudioPublishOptions(dtx: true),
        defaultVideoPublishOptions: VideoPublishOptions(simulcast: true),
      ),
    );
    _room = room;

    final EventsListener<RoomEvent> listener = room.createListener();
    _roomListener = listener;

    listener
      ..on<ParticipantConnectedEvent>((ParticipantConnectedEvent e) {
        if (!mounted) return;
        _markAnswered(e.participant);
      })
      ..on<TrackSubscribedEvent>((TrackSubscribedEvent e) {
        if (!mounted) return;
        _markAnswered(e.participant);
      })
      ..on<LocalTrackPublishedEvent>((LocalTrackPublishedEvent e) {
        if (!mounted) return;
        if (!aiseeShouldRefreshLocalVideoUi(
          isLocalParticipant: true,
          source: e.publication.source,
        )) {
          return;
        }
        setState(() {
          _cameraEnabled = true;
        });
      })
      ..on<LocalTrackUnpublishedEvent>((LocalTrackUnpublishedEvent e) {
        if (!mounted) return;
        if (!aiseeShouldRefreshLocalVideoUi(
          isLocalParticipant: true,
          source: e.publication.source,
        )) {
          return;
        }
        setState(() {
          _cameraEnabled = false;
        });
      })
      ..on<TrackMutedEvent>((TrackMutedEvent e) {
        if (!mounted) return;
        if (!aiseeShouldRefreshLocalVideoUi(
          isLocalParticipant: e.participant is LocalParticipant,
          source: e.publication.source,
        )) {
          return;
        }
        setState(() {
          _cameraEnabled = false;
        });
      })
      ..on<TrackUnmutedEvent>((TrackUnmutedEvent e) {
        if (!mounted) return;
        if (!aiseeShouldRefreshLocalVideoUi(
          isLocalParticipant: e.participant is LocalParticipant,
          source: e.publication.source,
        )) {
          return;
        }
        setState(() {
          _cameraEnabled = true;
        });
      })
      ..on<ParticipantDisconnectedEvent>(
        (ParticipantDisconnectedEvent e) => _endCall(),
      )
      ..on<RoomDisconnectedEvent>((RoomDisconnectedEvent e) => _endCall());

    try {
      await room.connect(AppEnv.liveKitWsUrl, widget.callInfo.token);
      await FlutterCallkitIncoming.setCallConnected(widget.callInfo.roomName);
      await room.localParticipant?.setMicrophoneEnabled(true);
      if (_isVideo) {
        await room.localParticipant?.setCameraEnabled(true);
      }

      // Check if remote participant already connected
      if (room.remoteParticipants.isNotEmpty && mounted) {
        final RemoteParticipant first = room.remoteParticipants.values.first;
        _markAnswered(first);
      } else if (mounted && _state == _CallState.ringing) {
        // Outgoing: chưa ai nhấc máy → phát ringback tone + haptic nhẹ.
        AiseeNotificationFeedback.instance.startOutgoingCallRingback();
        _startAnswerTimeout();
      }

      if (aiseeShouldEnableSpeakerByDefault(widget.callInfo.callType)) {
        await room.setSpeakerOn(true);
      }
    } catch (e, st) {
      debugPrint('[AiSee:Call] connect error: $e\n$st');
      AiseeNotificationFeedback.instance.stopOutgoingCallRingback();
      _answerTimeoutTimer?.cancel();
      final String msg;
      if (e case AiseeApiException(:final String message)) {
        msg = message;
      } else {
        msg = l10n.callJoinFailed;
      }
      widget.onStartFailed?.call(msg);
      if (!mounted) return;
      await AppToast.show(msg, isError: true);
      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }

  void _markAnswered(RemoteParticipant participant) {
    final bool wasRinging = _state == _CallState.ringing;
    _answerTimeoutTimer?.cancel();
    if (wasRinging) {
      AiseeNotificationFeedback.instance.stopOutgoingCallRingback();
      AiseeNotificationFeedback.instance.playCallConnected();
    }
    if (!_answeredNotified) {
      _answeredNotified = true;
      widget.onAnswered?.call();
    }
    setState(() {
      _remoteParticipant = participant;
      _state = _CallState.connected;
    });
    _startDurationTimer();
  }

  void _startAnswerTimeout() {
    final Duration? timeout = widget.outgoingAnswerTimeout;
    if (timeout == null) {
      return;
    }
    _answerTimeoutTimer?.cancel();
    _answerTimeoutTimer = Timer(timeout, _handleNoAnswerTimeout);
  }

  void _handleNoAnswerTimeout() {
    if (!mounted || _state != _CallState.ringing) {
      return;
    }
    _ringingEndNotified = true;
    widget.onNoAnswer?.call();
    AiseeNotificationFeedback.instance.stopOutgoingCallRingback();
    setState(() => _state = _CallState.ended);
    _durationTimer?.cancel();
    unawaited(_cleanupRoom());
    Navigator.of(context).pop();
  }

  void _startDurationTimer() {
    if (_durationTimer != null) return;
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _duration.value += const Duration(seconds: 1);
    });
  }

  Future<void> _toggleMic() async {
    if (_toggling || _state == _CallState.ended) return;
    _toggling = true;
    try {
      final bool next = !_micEnabled;
      await _room?.localParticipant?.setMicrophoneEnabled(next);
      if (!mounted) return;
      setState(() => _micEnabled = next);
    } catch (e) {
      debugPrint('[AiSee:Call] toggleMic error: $e');
    } finally {
      _toggling = false;
    }
  }

  Future<void> _toggleSpeaker() async {
    if (_toggling || _state == _CallState.ended) return;
    _toggling = true;
    try {
      final bool next = !_speakerEnabled;
      await _room?.setSpeakerOn(next);
      if (!mounted) return;
      setState(() => _speakerEnabled = next);
    } catch (e) {
      debugPrint('[AiSee:Call] toggleSpeaker error: $e');
    } finally {
      _toggling = false;
    }
  }

  Future<void> _toggleCamera() async {
    if (_toggling || _state == _CallState.ended) return;
    _toggling = true;
    try {
      final bool next = !_cameraEnabled;
      await _room?.localParticipant?.setCameraEnabled(next);
      if (!mounted) return;
      setState(() => _cameraEnabled = next);
    } catch (e) {
      debugPrint('[AiSee:Call] toggleCamera error: $e');
    } finally {
      _toggling = false;
    }
  }

  Future<void> _endCall() async {
    if (_state == _CallState.ended) return;
    AiseeNotificationFeedback.instance.stopOutgoingCallRingback();
    _answerTimeoutTimer?.cancel();
    if (_state == _CallState.ringing && !_ringingEndNotified) {
      _ringingEndNotified = true;
      widget.onCancelledWhileRinging?.call();
    }
    setState(() => _state = _CallState.ended);
    _durationTimer?.cancel();

    // Fire-and-forget: backend cleanup + LiveKit disconnect run in background.
    unawaited(_cleanupRoom());

    // Pop immediately — no delay.
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _cleanupRoom() async {
    // Backend end-room (best-effort).
    final tokens = await AiseeSessionStore.instance.read();
    if (tokens != null) {
      try {
        await AiseeCallService().endRoom(
          tokens.accessToken,
          widget.callInfo.roomName,
        );
      } catch (_) {}
    }

    // LiveKit cleanup.
    await _roomListener?.dispose();
    _roomListener = null;
    try {
      await FlutterCallkitIncoming.endCall(widget.callInfo.roomName);
    } catch (_) {}
    try {
      await _room?.disconnect();
    } catch (_) {}
    try {
      await _room?.dispose();
    } catch (_) {}
    _room = null;
  }

  @override
  void dispose() {
    AiseeNotificationFeedback.instance.stopOutgoingCallRingback();
    _answerTimeoutTimer?.cancel();
    CallScreen.openRouteCount = (CallScreen.openRouteCount - 1).clamp(
      0,
      1 << 30,
    );
    _durationTimer?.cancel();
    _duration.dispose();
    _roomListener?.dispose();
    _room?.disconnect();
    _room?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isVideo ? Colors.black : StyleTokens.buttonPrimary,
      body: SafeArea(
        child: _isVideo ? _buildVideoLayout() : _buildVoiceLayout(),
      ),
    );
  }

  // --------------- Voice layout ---------------

  Widget _buildVoiceLayout() {
    return Column(
      children: <Widget>[
        const Spacer(),
        _buildContactAvatar(),
        const SizedBox(height: 16),
        _buildContactName(),
        const SizedBox(height: 8),
        _buildStatusLabel(),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.only(bottom: 48),
          child: _buildVoiceButtons(),
        ),
      ],
    );
  }

  Widget _buildContactAvatar() {
    return CircleAvatar(
      radius: 40,
      backgroundColor: const Color(0xFFE8E8E8),
      backgroundImage: NetworkImage(
        'https://api.dicebear.com/9.x/notionists/png'
        '?seed=${Uri.encodeComponent(widget.callInfo.contact.id)}'
        '&size=160&backgroundColor=e8e8e8',
      ),
      onBackgroundImageError: (Object e, StackTrace? st) {},
    );
  }

  Widget _buildContactName() {
    return Text(
      widget.callInfo.contact.label,
      style: aiseeTextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }

  Widget _buildStatusLabel() {
    return ValueListenableBuilder<Duration>(
      valueListenable: _duration,
      builder: (BuildContext context, Duration d, _) {
        final String text = _state == _CallState.ringing
            ? l10n.callDialing
            : _state == _CallState.ended
            ? l10n.callEnded
            : _formatDuration(d);
        return Text(
          text,
          style: aiseeTextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.white70,
          ),
        );
      },
    );
  }

  Widget _buildVoiceButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _buildCircleButton(
          onTap: _toggleMic,
          color: Colors.white,
          child: SvgPicture.asset(
            'assets/icons/nav/ic_voice.svg',
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(
              _micEnabled ? StyleTokens.buttonPrimary : const Color(0xFFFF3B30),
              BlendMode.srcIn,
            ),
          ),
          label: _micEnabled ? l10n.callMicOff : l10n.callMicOn,
        ),
        const SizedBox(width: 32),
        _buildCircleButton(
          onTap: _toggleSpeaker,
          color: Colors.white,
          child: SvgPicture.asset(
            _speakerEnabled
                ? 'assets/icons/nav/ic_volume_up.svg'
                : 'assets/icons/nav/ic_volume_off.svg',
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(
              _speakerEnabled
                  ? StyleTokens.buttonPrimary
                  : const Color(0xFFFF3B30),
              BlendMode.srcIn,
            ),
          ),
          label: _speakerEnabled ? l10n.callSpeakerOff : l10n.callSpeakerOn,
        ),
        const SizedBox(width: 32),
        _buildCircleButton(
          onTap: _endCall,
          color: const Color(0xFFFF3B30),
          child: SvgPicture.asset(
            'assets/icons/nav/ic_close.svg',
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
          label: l10n.callEnd,
        ),
      ],
    );
  }

  // --------------- Video layout ---------------

  Widget _buildVideoLayout() {
    return Stack(
      children: <Widget>[
        _buildRemoteVideo(),
        Positioned(top: 16, right: 16, child: _buildLocalVideoPreview()),
        Positioned(top: 16, left: 16, right: 136, child: _buildVideoOverlay()),
        Positioned(left: 0, right: 0, bottom: 48, child: _buildVideoButtons()),
      ],
    );
  }

  Widget _buildRemoteVideo() {
    final VideoTrack? track = _remoteVideoTrack();
    if (track == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _buildContactAvatar(),
            const SizedBox(height: 16),
            _buildContactName(),
            const SizedBox(height: 8),
            _buildStatusLabel(),
          ],
        ),
      );
    }
    return VideoTrackRenderer(track, fit: VideoViewFit.cover);
  }

  Widget _buildLocalVideoPreview() {
    final VideoTrack? track = _localVideoTrack();
    if (track == null) {
      return const SizedBox.shrink();
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 120,
        height: 160,
        child: VideoTrackRenderer(
          track,
          fit: VideoViewFit.cover,
          mirrorMode: VideoViewMirrorMode.mirror,
        ),
      ),
    );
  }

  Widget _buildVideoOverlay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Colors.black.withValues(alpha: 0.6),
            Colors.transparent,
          ],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            widget.callInfo.contact.label,
            style: aiseeTextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _statusText,
            style: aiseeTextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _buildCircleButton(
          onTap: _toggleMic,
          color: Colors.white,
          child: SvgPicture.asset(
            'assets/icons/nav/ic_voice.svg',
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(
              _micEnabled ? StyleTokens.buttonPrimary : const Color(0xFFFF3B30),
              BlendMode.srcIn,
            ),
          ),
          label: _micEnabled ? l10n.callMicOff : l10n.callMicOn,
        ),
        const SizedBox(width: 32),
        _buildCircleButton(
          onTap: _toggleCamera,
          color: Colors.white,
          child: SvgPicture.asset(
            'assets/icons/nav/ic_camera.svg',
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(
              _cameraEnabled
                  ? StyleTokens.buttonPrimary
                  : const Color(0xFFFF3B30),
              BlendMode.srcIn,
            ),
          ),
          label: _cameraEnabled ? l10n.callCameraOff : l10n.callCameraOn,
        ),
        const SizedBox(width: 32),
        _buildCircleButton(
          onTap: _toggleSpeaker,
          color: Colors.white,
          child: SvgPicture.asset(
            _speakerEnabled
                ? 'assets/icons/nav/ic_volume_up.svg'
                : 'assets/icons/nav/ic_volume_off.svg',
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(
              _speakerEnabled
                  ? StyleTokens.buttonPrimary
                  : const Color(0xFFFF3B30),
              BlendMode.srcIn,
            ),
          ),
          label: _speakerEnabled ? l10n.callSpeakerOff : l10n.callSpeakerOn,
        ),
        const SizedBox(width: 32),
        _buildCircleButton(
          onTap: _endCall,
          color: const Color(0xFFFF3B30),
          child: SvgPicture.asset(
            'assets/icons/nav/ic_close.svg',
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
          label: l10n.callEnd,
        ),
      ],
    );
  }

  // --------------- Shared helpers ---------------

  Widget _buildCircleButton({
    required VoidCallback onTap,
    required Color color,
    required Widget child,
    required String label,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: color,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(width: 60, height: 60, child: Center(child: child)),
        ),
      ),
    );
  }

  VideoTrack? _remoteVideoTrack() {
    final List<RemoteTrackPublication<RemoteVideoTrack>>? pubs =
        _remoteParticipant?.videoTrackPublications;
    if (pubs == null || pubs.isEmpty) return null;
    return pubs.first.track;
  }

  VideoTrack? _localVideoTrack() {
    final pubs = _room?.localParticipant?.videoTrackPublications;
    if (pubs == null || pubs.isEmpty) return null;
    return pubs.first.track;
  }
}
