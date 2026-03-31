import 'package:flutter/widgets.dart';

enum ChatRecordingLifecycleAction { ignore, cancelRecording }

class ChatRecordingLifecyclePolicy {
  const ChatRecordingLifecyclePolicy();

  ChatRecordingLifecycleAction actionFor({
    required AppLifecycleState state,
    required bool isRecording,
  }) {
    if (!isRecording) {
      return ChatRecordingLifecycleAction.ignore;
    }
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        return ChatRecordingLifecycleAction.cancelRecording;
      case AppLifecycleState.resumed:
        return ChatRecordingLifecycleAction.ignore;
    }
  }
}
