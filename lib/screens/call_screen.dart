import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:livekit_client/livekit_client.dart';

import '../config/app_env.dart';
import '../models/aisee_call_info.dart';
import '../services/aisee_call_service.dart';
import '../services/aisee_session_store.dart';
import '../theme/style_tokens.dart';

enum _CallState { ringing, connected, ended }

class CallScreen extends StatefulWidget {
  const CallScreen({super.key, required this.callInfo});

  final AiseeCallInfo callInfo;

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
  final ValueNotifier<Duration> _duration =
      ValueNotifier<Duration>(Duration.zero);
  Timer? _durationTimer;
  RemoteParticipant? _remoteParticipant;

  bool get _isVideo => widget.callInfo.callType == 'video';

  static String _formatDuration(Duration d) {
    final int min = d.inMinutes;
    final int sec = d.inSeconds % 60;
    return '${min.toString().padLeft(2, '0')}:'
        '${sec.toString().padLeft(2, '0')}';
  }

  String get _statusText {
    switch (_state) {
      case _CallState.ringing:
        return 'Đang gọi...';
      case _CallState.connected:
        return _formatDuration(_duration.value);
      case _CallState.ended:
        return 'Đã kết thúc';
    }
  }

  @override
  void initState() {
    super.initState();
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
        defaultAudioPublishOptions: AudioPublishOptions(
          dtx: true,
        ),
        defaultVideoPublishOptions: VideoPublishOptions(
          simulcast: true,
        ),
      ),
    );
    _room = room;

    final EventsListener<RoomEvent> listener = room.createListener();
    _roomListener = listener;

    listener
      ..on<ParticipantConnectedEvent>((ParticipantConnectedEvent e) {
        if (!mounted) return;
        setState(() {
          _remoteParticipant = e.participant;
          _state = _CallState.connected;
        });
        _startDurationTimer();
      })
      ..on<TrackSubscribedEvent>((TrackSubscribedEvent e) {
        if (!mounted) return;
        setState(() {
          _remoteParticipant = e.participant;
          if (_state == _CallState.ringing) {
            _state = _CallState.connected;
            _startDurationTimer();
          }
        });
      })
      ..on<ParticipantDisconnectedEvent>(
        (ParticipantDisconnectedEvent e) => _endCall(),
      )
      ..on<RoomDisconnectedEvent>(
        (RoomDisconnectedEvent e) => _endCall(),
      );

    try {
      await room.connect(AppEnv.liveKitWsUrl, widget.callInfo.token);
      await room.localParticipant?.setMicrophoneEnabled(true);
      if (_isVideo) {
        await room.localParticipant?.setCameraEnabled(true);
      }

      // Check if remote participant already connected
      if (room.remoteParticipants.isNotEmpty && mounted) {
        final RemoteParticipant first =
            room.remoteParticipants.values.first;
        setState(() {
          _remoteParticipant = first;
          _state = _CallState.connected;
        });
        _startDurationTimer();
      }

      // Enable speakerphone for voice calls by default
      if (!_isVideo) {
        await room.setSpeakerOn(true);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }

  void _startDurationTimer() {
    if (_durationTimer != null) return;
    _durationTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) return;
        _duration.value += const Duration(seconds: 1);
      },
    );
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
      await _room?.disconnect();
    } catch (_) {}
    try {
      await _room?.dispose();
    } catch (_) {}
    _room = null;
  }

  @override
  void dispose() {
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
      backgroundColor:
          _isVideo ? Colors.black : StyleTokens.buttonPrimary,
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
      style: GoogleFonts.plusJakartaSans(
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
            ? 'Đang gọi...'
            : _state == _CallState.ended
                ? 'Đã kết thúc'
                : _formatDuration(d);
        return Text(
          text,
          style: GoogleFonts.plusJakartaSans(
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
              _micEnabled
                  ? StyleTokens.buttonPrimary
                  : const Color(0xFFFF3B30),
              BlendMode.srcIn,
            ),
          ),
          label: _micEnabled ? 'Tắt mic' : 'Bật mic',
        ),
        const SizedBox(width: 32),
        _buildCircleButton(
          onTap: _toggleSpeaker,
          color: Colors.white,
          child: Icon(
            _speakerEnabled
                ? Icons.volume_up_rounded
                : Icons.volume_off_rounded,
            size: 24,
            color: _speakerEnabled
                ? StyleTokens.buttonPrimary
                : const Color(0xFFFF3B30),
          ),
          label: _speakerEnabled ? 'Tắt loa' : 'Bật loa',
        ),
        const SizedBox(width: 32),
        _buildCircleButton(
          onTap: _endCall,
          color: const Color(0xFFFF3B30),
          child: const Icon(
            Icons.call_end_rounded,
            size: 24,
            color: Colors.white,
          ),
          label: 'Kết thúc cuộc gọi',
        ),
      ],
    );
  }

  // --------------- Video layout ---------------

  Widget _buildVideoLayout() {
    return Stack(
      children: <Widget>[
        _buildRemoteVideo(),
        Positioned(
          top: 16,
          right: 16,
          child: _buildLocalVideoPreview(),
        ),
        Positioned(
          top: 16,
          left: 16,
          right: 136,
          child: _buildVideoOverlay(),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 48,
          child: _buildVideoButtons(),
        ),
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
    return VideoTrackRenderer(
      track,
      fit: VideoViewFit.cover,
    );
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
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
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
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _statusText,
            style: GoogleFonts.plusJakartaSans(
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
              _micEnabled
                  ? StyleTokens.buttonPrimary
                  : const Color(0xFFFF3B30),
              BlendMode.srcIn,
            ),
          ),
          label: _micEnabled ? 'Tắt mic' : 'Bật mic',
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
          label: _cameraEnabled ? 'Tắt camera' : 'Bật camera',
        ),
        const SizedBox(width: 32),
        _buildCircleButton(
          onTap: _endCall,
          color: const Color(0xFFFF3B30),
          child: const Icon(
            Icons.call_end_rounded,
            size: 24,
            color: Colors.white,
          ),
          label: 'Kết thúc cuộc gọi',
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
          child: SizedBox(
            width: 60,
            height: 60,
            child: Center(child: child),
          ),
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
    final pubs =
        _room?.localParticipant?.videoTrackPublications;
    if (pubs == null || pubs.isEmpty) return null;
    return pubs.first.track;
  }
}
