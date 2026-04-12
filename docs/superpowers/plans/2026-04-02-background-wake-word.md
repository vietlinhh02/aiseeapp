# Background Wake Word Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Keep DaVoice wake word listening active when the app moves to the background on Android instead of shutting it down on `paused`.

**Architecture:** Preserve the existing LiveKit-connected idle-wake flow, but stop treating `AppLifecycleState.paused` as a full audio teardown. Keep assistant mic disabled on pause, leave wake listening alone, and make resume only re-enter idle wake if the wake service is not already listening.

**Tech Stack:** Flutter, Dart, `flutter_wake_word`, `flutter_test`

---

## File Map

- Modify: `lib/services/assistant_audio_coordinator.dart`
  - Split pause cleanup from wake teardown so backgrounding does not stop idle wake listening.
- Modify: `test/user_home_wake_handoff_test.dart`
  - Add coordinator tests for pause/resume background behavior.

### Task 1: Preserve wake listening on app pause

**Files:**
- Modify: `lib/services/assistant_audio_coordinator.dart`
- Test: `test/user_home_wake_handoff_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
test('app pause keeps wake listening active while disabling assistant mic', () async {
  final _FakeAudioOps ops = _FakeAudioOps();
  final AssistantAudioCoordinator coordinator = AssistantAudioCoordinator(
    startWakeListening: ops.startWakeListening,
    stopWakeListening: ops.stopWakeListening,
    enableAssistantMic: ops.enableAssistantMic,
    disableAssistantMic: ops.disableAssistantMic,
    switchToAssistantTab: () {},
  );

  await coordinator.onAppPaused();

  expect(ops.disableAssistantMicCalls, 1);
  expect(ops.stopWakeListeningCalls, 0);
  expect(coordinator.state, AssistantAudioState.idleListeningWake);
});
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/user_home_wake_handoff_test.dart`

Expected: FAIL because `onAppPaused()` still calls `stopWakeListening()`.

- [ ] **Step 3: Make pause cleanup preserve wake listening**

```dart
Future<void> onAppPaused() async {
  _cancelGraceTimer(reason: 'app-paused');
  await disableAssistantMic();
  _setState(AssistantAudioState.idleListeningWake, 'App paused; wake retained');
}
```

- [ ] **Step 4: Run the targeted test to verify it passes**

Run: `flutter test test/user_home_wake_handoff_test.dart`

Expected: PASS.

### Task 2: Avoid redundant wake restart on resume

**Files:**
- Modify: `lib/services/assistant_audio_coordinator.dart`
- Test: `test/user_home_wake_handoff_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
test('app resume does not restart wake listening when already idle', () async {
  final _FakeAudioOps ops = _FakeAudioOps();
  final AssistantAudioCoordinator coordinator = AssistantAudioCoordinator(
    startWakeListening: ops.startWakeListening,
    stopWakeListening: ops.stopWakeListening,
    enableAssistantMic: ops.enableAssistantMic,
    disableAssistantMic: ops.disableAssistantMic,
    switchToAssistantTab: () {},
  );

  await coordinator.onAppResumed(liveKitConnected: true);

  expect(ops.startWakeListeningCalls, 0);
});
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/user_home_wake_handoff_test.dart`

Expected: FAIL because `onAppResumed()` always re-enters idle wake mode.

- [ ] **Step 3: Make resume conditional**

```dart
Future<void> onAppResumed({required bool liveKitConnected}) async {
  if (!liveKitConnected) {
    _log('Resume skipped: LiveKit not connected');
    return;
  }
  if (_state == AssistantAudioState.idleListeningWake) {
    _log('Resume skipped: wake already active');
    return;
  }
  await enterIdleWakeMode(reason: 'app-resumed');
}
```

- [ ] **Step 4: Run the targeted test to verify it passes**

Run: `flutter test test/user_home_wake_handoff_test.dart`

Expected: PASS.
