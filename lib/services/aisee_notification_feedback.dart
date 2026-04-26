import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AiseeNotificationFeedback {
  AiseeNotificationFeedback._();

  static final AiseeNotificationFeedback instance =
      AiseeNotificationFeedback._();

  Timer? _incomingCallTimer;

  void playMessageAlert() {
    if (kIsWeb) return;
    unawaited(_playAlert());
    unawaited(HapticFeedback.mediumImpact());
  }

  void startIncomingCallAlert() {
    if (kIsWeb || _incomingCallTimer != null) return;
    _ringIncomingCall();
    _incomingCallTimer = Timer.periodic(
      const Duration(milliseconds: 1800),
      (_) => _ringIncomingCall(),
    );
  }

  void stopIncomingCallAlert() {
    _incomingCallTimer?.cancel();
    _incomingCallTimer = null;
  }

  void _ringIncomingCall() {
    unawaited(_playAlert());
    unawaited(HapticFeedback.heavyImpact());
  }

  Future<void> _playAlert() async {
    try {
      await SystemSound.play(SystemSoundType.alert);
    } catch (e) {
      debugPrint('[AiSee:Feedback] alert sound failed: $e');
    }
  }
}
