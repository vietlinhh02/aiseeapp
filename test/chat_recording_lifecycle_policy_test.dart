import 'package:aiseeapp/services/chat_recording_lifecycle_policy.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const ChatRecordingLifecyclePolicy policy = ChatRecordingLifecyclePolicy();

  test('paused while recording cancels recording', () {
    expect(
      policy.actionFor(state: AppLifecycleState.paused, isRecording: true),
      ChatRecordingLifecycleAction.cancelRecording,
    );
  });

  test('resumed while recording does not cancel recording', () {
    expect(
      policy.actionFor(state: AppLifecycleState.resumed, isRecording: true),
      ChatRecordingLifecycleAction.ignore,
    );
  });

  test('paused while not recording does nothing', () {
    expect(
      policy.actionFor(state: AppLifecycleState.paused, isRecording: false),
      ChatRecordingLifecycleAction.ignore,
    );
  });
}
