import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

class AiseeNotificationFeedback {
  AiseeNotificationFeedback._();

  static final AiseeNotificationFeedback instance =
      AiseeNotificationFeedback._();

  Timer? _incomingCallTimer;
  AudioPlayer? _incomingRingPlayer;
  bool _incomingActive = false;

  AudioPlayer? _ringbackPlayer;
  Timer? _ringbackHapticTimer;
  bool _ringbackActive = false;

  void playMessageAlert() {
    if (kIsWeb) return;
    unawaited(_playAlert());
    unawaited(HapticFeedback.mediumImpact());
  }

  void startIncomingCallAlert() {
    if (kIsWeb || _incomingActive) return;
    _incomingActive = true;
    unawaited(_startIncomingPlayer());
    _ringIncomingCall();
    _incomingCallTimer = Timer.periodic(
      const Duration(milliseconds: 2400),
      (_) => _ringIncomingCall(),
    );
  }

  void stopIncomingCallAlert() {
    if (!_incomingActive && _incomingCallTimer == null) return;
    _incomingActive = false;
    _incomingCallTimer?.cancel();
    _incomingCallTimer = null;
    final AudioPlayer? player = _incomingRingPlayer;
    _incomingRingPlayer = null;
    if (player != null) {
      unawaited(_disposePlayer(player));
    }
  }

  /// Phát ringback tone GSM (425Hz, 1s on/3s off, lặp lại) khi đang chờ
  /// đầu kia bắt máy ở cuộc gọi đi. Kèm haptic nhẹ mỗi pulse 4s.
  void startOutgoingCallRingback() {
    if (kIsWeb || _ringbackActive) return;
    _ringbackActive = true;
    unawaited(_startRingbackPlayer());
    unawaited(HapticFeedback.lightImpact());
    _ringbackHapticTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => unawaited(HapticFeedback.lightImpact()),
    );
  }

  void stopOutgoingCallRingback() {
    if (!_ringbackActive) return;
    _ringbackActive = false;
    _ringbackHapticTimer?.cancel();
    _ringbackHapticTimer = null;
    final AudioPlayer? player = _ringbackPlayer;
    _ringbackPlayer = null;
    if (player != null) {
      unawaited(_disposePlayer(player));
    }
  }

  /// Phản hồi khi cuộc gọi vừa được kết nối thành công.
  void playCallConnected() {
    if (kIsWeb) return;
    unawaited(HapticFeedback.mediumImpact());
  }

  Future<void> _startRingbackPlayer() async {
    try {
      final AudioPlayer player = AudioPlayer();
      _ringbackPlayer = player;
      await player.setAsset('assets/audio/ringback_gsm.wav');
      await player.setLoopMode(LoopMode.all);
      await player.setVolume(0.85);
      if (!_ringbackActive) {
        await _disposePlayer(player);
        return;
      }
      await player.play();
    } catch (e) {
      debugPrint('[AiSee:Feedback] ringback play failed: $e');
    }
  }

  Future<void> _disposePlayer(AudioPlayer player) async {
    try {
      await player.stop();
    } catch (_) {}
    try {
      await player.dispose();
    } catch (_) {}
  }

  Future<void> _startIncomingPlayer() async {
    try {
      final AudioPlayer player = AudioPlayer();
      _incomingRingPlayer = player;
      await player.setAsset('assets/audio/incoming_ring.wav');
      await player.setLoopMode(LoopMode.all);
      await player.setVolume(1.0);
      if (!_incomingActive) {
        await _disposePlayer(player);
        return;
      }
      await player.play();
    } catch (e) {
      debugPrint('[AiSee:Feedback] incoming ringtone failed: $e');
    }
  }

  void _ringIncomingCall() {
    // BRR-BRR pattern: 2 rung mạnh cách nhau ~150ms, kế tiếp pulse cách 2.4s.
    unawaited(HapticFeedback.heavyImpact());
    Future<void>.delayed(const Duration(milliseconds: 160), () {
      if (_incomingActive) {
        unawaited(HapticFeedback.heavyImpact());
      }
    });
  }

  Future<void> _playAlert() async {
    try {
      await SystemSound.play(SystemSoundType.alert);
    } catch (e) {
      debugPrint('[AiSee:Feedback] alert sound failed: $e');
    }
  }
}
