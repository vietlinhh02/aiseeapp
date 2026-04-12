import 'package:flutter/foundation.dart';

import '../models/aisee_incoming_call.dart';

class AiseeIncomingCallController extends ChangeNotifier {
  AiseeIncomingCallController();

  static final AiseeIncomingCallController instance =
      AiseeIncomingCallController();

  AiseeIncomingCall? _currentCall;
  bool _appForeground = true;

  AiseeIncomingCall? get currentCall => _currentCall;

  bool get isAppForeground => _appForeground;

  bool get shouldShowOverlay => _appForeground && _currentCall != null;

  void setAppForeground(bool value) {
    if (_appForeground == value) {
      return;
    }
    _appForeground = value;
    notifyListeners();
  }

  void showIncomingCall(AiseeIncomingCall call) {
    _currentCall = call;
    notifyListeners();
  }

  void hideIncomingCall() {
    if (_currentCall == null) {
      return;
    }
    _currentCall = null;
    notifyListeners();
  }
}
