import 'package:flutter/foundation.dart';

import '../models/aisee_incoming_call.dart';
import 'aisee_notification_feedback.dart';

class AiseeIncomingCallController extends ChangeNotifier {
  AiseeIncomingCallController();

  static final AiseeIncomingCallController instance =
      AiseeIncomingCallController();

  AiseeIncomingCall? _currentCall;
  bool _appForeground = true;

  AiseeIncomingCall? get currentCall => _currentCall;

  bool get isAppForeground => _appForeground;

  bool get shouldShowOverlay => _appForeground && _currentCall != null;

  bool isShowingRoom(String roomName) {
    final String normalized = roomName.trim();
    return normalized.isNotEmpty && _currentCall?.roomName == normalized;
  }

  void setAppForeground(bool value) {
    if (_appForeground == value) {
      return;
    }
    _appForeground = value;
    if (shouldShowOverlay) {
      AiseeNotificationFeedback.instance.startIncomingCallAlert();
    } else {
      AiseeNotificationFeedback.instance.stopIncomingCallAlert();
    }
    notifyListeners();
  }

  void showIncomingCall(AiseeIncomingCall call) {
    _currentCall = call;
    if (shouldShowOverlay) {
      AiseeNotificationFeedback.instance.startIncomingCallAlert();
    }
    notifyListeners();
  }

  void hideIncomingCall() {
    if (_currentCall == null) {
      return;
    }
    _currentCall = null;
    AiseeNotificationFeedback.instance.stopIncomingCallAlert();
    notifyListeners();
  }

  void hideIncomingCallForRoom(String roomName) {
    if (!isShowingRoom(roomName)) {
      return;
    }
    hideIncomingCall();
  }

  @override
  void dispose() {
    AiseeNotificationFeedback.instance.stopIncomingCallAlert();
    super.dispose();
  }
}
