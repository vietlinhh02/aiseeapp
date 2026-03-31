# Wake Word and LiveKit Handoff Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Keep LiveKit connected on the assistant screen while leaving the local mic off by default, then hand mic ownership to LiveKit only after wake word detection and return it to wake word after the agent finishes plus 20 seconds of silence.

**Architecture:** Add a small assistant-audio coordinator centered in `UserHomeScreen`, keep `AiseeLiveKitVoiceSession` warm but decouple room connection from mic enable, and make `AiseeWakeWordService` restartable as an explicit idle-listening service. Use existing `AgentState` updates as the first conversation lifecycle signal, with a 20-second timer owned by the coordinator.

**Tech Stack:** Flutter, Dart, `livekit_client`, `flutter_wake_word`, `flutter_test`

---

## File Map

- Modify: `lib/services/aisee_livekit_voice_session.dart`
  - Stop auto-enabling the mic in `connect()`.
  - Add explicit mic enable and disable methods.
  - Keep emitting `agentState` so the UI coordinator can drive grace-period transitions.
- Modify: `lib/services/aisee_wake_word_service.dart`
  - Make listening state explicit and safe to restart after LiveKit releases the mic.
  - Expose a small query surface for debugging and tests.
- Modify: `lib/screens/user_home_screen.dart`
  - Add the assistant audio state machine, 20-second timer, wake-to-mic handoff, and lifecycle recovery.
- Create: `test/user_home_wake_handoff_test.dart`
  - Add focused coordinator-level tests using a small extracted controller or test seams introduced during implementation.

## Task 1: Add explicit LiveKit mic control

**Files:**
- Modify: `lib/services/aisee_livekit_voice_session.dart`
- Test: `test/user_home_wake_handoff_test.dart`

- [ ] **Step 1: Write the failing test for mic control semantics**

Create `test/user_home_wake_handoff_test.dart` with a small fake session contract test target that expresses the intended API. If extracting a controller later, this test will stay and use the real method names.

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('live session starts with mic disabled until explicitly enabled', () async {
    final _FakeVoiceSession session = _FakeVoiceSession();

    await session.connect();

    expect(session.connectCalled, isTrue);
    expect(session.micEnabled, isFalse);

    await session.enableAssistantMic();
    expect(session.micEnabled, isTrue);

    await session.disableAssistantMic();
    expect(session.micEnabled, isFalse);
  });
}

class _FakeVoiceSession {
  bool connectCalled = false;
  bool micEnabled = true;

  Future<void> connect() async {
    connectCalled = true;
    throw UnimplementedError();
  }

  Future<void> enableAssistantMic() async => throw UnimplementedError();
  Future<void> disableAssistantMic() async => throw UnimplementedError();
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/user_home_wake_handoff_test.dart`

Expected: FAIL with `UnimplementedError`.

- [ ] **Step 3: Add minimal LiveKit mic APIs and stop auto-enable in connect**

Update `lib/services/aisee_livekit_voice_session.dart`.

Remove the eager mic activation from `connect()`:

```dart
_log('Connect', 'Room connected. Mic remains OFF until wake handoff.');
await _configureAudioSession();
syncLocalCameraPreviewTrack();
_startWaveDecayTimer();
await AiseeVoiceAssistantForeground.ensureStartedAfterConnected();
```

Add explicit methods near `connect()` / `disconnect()`:

```dart
bool _assistantMicEnabled = false;

bool get isAssistantMicEnabled => _assistantMicEnabled;

Future<void> enableAssistantMic() async {
  final LocalParticipant? participant = _room?.localParticipant;
  if (participant == null) {
    throw AiseeApiException('LiveKit chưa sẵn sàng để bật micro.');
  }
  await participant.setMicrophoneEnabled(true);
  _assistantMicEnabled = true;
  _log('Connect', 'Assistant mic ON');
}

Future<void> disableAssistantMic() async {
  final LocalParticipant? participant = _room?.localParticipant;
  if (participant == null) {
    _assistantMicEnabled = false;
    return;
  }
  await participant.setMicrophoneEnabled(false);
  _assistantMicEnabled = false;
  _log('Connect', 'Assistant mic OFF');
}
```

Reset the flag in `disconnect()`:

```dart
_assistantMicEnabled = false;
```

- [ ] **Step 4: Update the test to a concrete fake and verify it passes**

Replace the fake methods in `test/user_home_wake_handoff_test.dart`:

```dart
class _FakeVoiceSession {
  bool connectCalled = false;
  bool micEnabled = true;

  Future<void> connect() async {
    connectCalled = true;
    micEnabled = false;
  }

  Future<void> enableAssistantMic() async {
    micEnabled = true;
  }

  Future<void> disableAssistantMic() async {
    micEnabled = false;
  }
}
```

Run: `flutter test test/user_home_wake_handoff_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/services/aisee_livekit_voice_session.dart test/user_home_wake_handoff_test.dart
git commit -m "refactor: separate livekit connection from mic state"
```

## Task 2: Make wake word an explicit idle listener

**Files:**
- Modify: `lib/services/aisee_wake_word_service.dart`
- Test: `test/user_home_wake_handoff_test.dart`

- [ ] **Step 1: Write the failing test for wake restart behavior**

Append a test that documents the restartable contract.

```dart
test('wake word can stop for live session and resume later', () async {
  final _FakeWakeService wake = _FakeWakeService();

  await wake.startIdleListening();
  expect(wake.isListening, isTrue);

  await wake.stopForLiveSession();
  expect(wake.isListening, isFalse);

  await wake.startIdleListening();
  expect(wake.isListening, isTrue);
});

class _FakeWakeService {
  bool isListening = false;

  Future<void> startIdleListening() async => throw UnimplementedError();
  Future<void> stopForLiveSession() async => throw UnimplementedError();
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/user_home_wake_handoff_test.dart`

Expected: FAIL with `UnimplementedError`.

- [ ] **Step 3: Refine wake word service with explicit listening API**

Update `lib/services/aisee_wake_word_service.dart`.

Add explicit state:

```dart
bool _started = false;
bool _listening = false;

bool get isConfiguredAndStarted => _started;
bool get isListening => _listening;
```

Replace `pauseForExclusiveMic()` / `resumeAfterExclusiveMic()` usage with clearer names while keeping wrappers only if needed for compatibility inside the repo:

```dart
Future<void> startIdleListening() async {
  if (!_started) {
    await startIfConfigured(liveKitMicActive: false);
    return;
  }
  if (_listening) {
    return;
  }
  await _useModel.startListening();
  _pausedForLiveKit = false;
  _listening = true;
}

Future<void> stopForLiveSession() async {
  if (!_started || !_listening) {
    return;
  }
  await _useModel.stopListening();
  _pausedForLiveKit = true;
  _listening = false;
}
```

Set `_listening = true` after a successful initial start and `_listening = false` on stop/remove.

- [ ] **Step 4: Update the fake test seam and verify it passes**

Replace the fake methods:

```dart
class _FakeWakeService {
  bool isListening = false;

  Future<void> startIdleListening() async {
    isListening = true;
  }

  Future<void> stopForLiveSession() async {
    isListening = false;
  }
}
```

Run: `flutter test test/user_home_wake_handoff_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/services/aisee_wake_word_service.dart test/user_home_wake_handoff_test.dart
git commit -m "refactor: add explicit wake idle listening controls"
```

## Task 3: Add assistant audio coordinator and 20-second grace timer

**Files:**
- Modify: `lib/screens/user_home_screen.dart`
- Modify: `lib/services/aisee_livekit_voice_session.dart`
- Modify: `lib/services/aisee_wake_word_service.dart`
- Modify: `lib/models/agent_state.dart`
- Test: `test/user_home_wake_handoff_test.dart`

- [ ] **Step 1: Write the failing state-machine tests**

Expand `test/user_home_wake_handoff_test.dart` with a small extracted controller model. If extraction is required for testability, create it during implementation, but keep this test content.

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('wake detection enables mic and stops wake listening', () async {
    final controller = _FakeAssistantAudioController();

    await controller.onWakeDetected();

    expect(controller.state, 'conversation_active');
    expect(controller.wakeListening, isFalse);
    expect(controller.liveMicEnabled, isTrue);
  });

  test('agent idle starts grace period and timeout returns to wake', () async {
    final controller = _FakeAssistantAudioController();

    await controller.onWakeDetected();
    controller.onAgentStateChanged('idle');
    await controller.expireGracePeriod();

    expect(controller.state, 'idle_listening_wake');
    expect(controller.wakeListening, isTrue);
    expect(controller.liveMicEnabled, isFalse);
  });

  test('new activity during grace period restores active conversation', () async {
    final controller = _FakeAssistantAudioController();

    await controller.onWakeDetected();
    controller.onAgentStateChanged('idle');
    controller.onAgentStateChanged('speaking');

    expect(controller.state, 'conversation_active');
    expect(controller.liveMicEnabled, isTrue);
  });
}

class _FakeAssistantAudioController {
  String state = 'idle_listening_wake';
  bool wakeListening = true;
  bool liveMicEnabled = false;

  Future<void> onWakeDetected() async => throw UnimplementedError();
  void onAgentStateChanged(String next) => throw UnimplementedError();
  Future<void> expireGracePeriod() async => throw UnimplementedError();
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/user_home_wake_handoff_test.dart`

Expected: FAIL with `UnimplementedError`.

- [ ] **Step 3: Add a focused coordinator in `UserHomeScreen`**

Add a small enum near `_UserHomeScreenState`:

```dart
enum _AssistantAudioState {
  idleListeningWake,
  activatingLiveSession,
  conversationActive,
  conversationGracePeriod,
}
```

Add fields to `_UserHomeScreenState`:

```dart
_AssistantAudioState _assistantAudioState =
    _AssistantAudioState.idleListeningWake;
Timer? _assistantGraceTimer;

void _cancelAssistantGraceTimer() {
  _assistantGraceTimer?.cancel();
  _assistantGraceTimer = null;
}
```

Add coordinator methods:

```dart
Future<void> _enterIdleWakeMode() async {
  _cancelAssistantGraceTimer();
  await _liveKitVoice.disableAssistantMic();
  await AiseeWakeWordService.instance.startIdleListening();
  _assistantAudioState = _AssistantAudioState.idleListeningWake;
}

Future<void> _activateLiveConversationFromWake() async {
  if (_assistantAudioState != _AssistantAudioState.idleListeningWake) {
    return;
  }
  _assistantAudioState = _AssistantAudioState.activatingLiveSession;
  await AiseeWakeWordService.instance.stopForLiveSession();
  await _liveKitVoice.enableAssistantMic();
  _assistantAudioState = _AssistantAudioState.conversationActive;
}

void _startAssistantGracePeriod() {
  _cancelAssistantGraceTimer();
  _assistantAudioState = _AssistantAudioState.conversationGracePeriod;
  _assistantGraceTimer = Timer(const Duration(seconds: 20), () {
    unawaited(_enterIdleWakeMode());
  });
}
```

Wire wake detection in `initState()`:

```dart
AiseeWakeWordService.instance.onWakePhrase = (_) {
  if (!mounted) {
    return;
  }
  _onTabChanged(0);
  unawaited(_activateLiveConversationFromWake());
};
```

After LiveKit connection succeeds, start idle wake mode instead of starting wake with
`liveKitMicActive: _liveKitConnected`.

```dart
await _enterIdleWakeMode();
```

- [ ] **Step 4: Drive grace-period transitions from `AgentState`**

Add a helper to `lib/models/agent_state.dart` so the coordinator can reason about end-of-turn
without string comparisons spread around the UI.

```dart
bool get keepsConversationOpen =>
    this == listening || this == thinking || this == speaking;

bool get startsGracePeriod => this == idle;
```

In `UserHomeScreen.build()` or another existing rebuild path, observe `_liveKitVoice.agentState`
once in `initState()`:

```dart
_liveKitVoice.agentState.addListener(_onAgentStateChanged);
```

Add the listener method:

```dart
void _onAgentStateChanged() {
  final AgentState next = _liveKitVoice.agentState.value;
  if (_assistantAudioState == _AssistantAudioState.conversationGracePeriod &&
      next.keepsConversationOpen) {
    _cancelAssistantGraceTimer();
    _assistantAudioState = _AssistantAudioState.conversationActive;
    return;
  }
  if (_assistantAudioState == _AssistantAudioState.conversationActive &&
      next.startsGracePeriod) {
    _startAssistantGracePeriod();
  }
}
```

Remove the old pause/resume LiveKit hooks from `initState()` and `dispose()` because the new
coordinator owns mic handoff.

- [ ] **Step 5: Make lifecycle recovery explicit**

Update `didChangeAppLifecycleState` in `lib/screens/user_home_screen.dart`.

```dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed) {
    _connectChatSocket();
    return;
  }
  if (state == AppLifecycleState.paused) {
    _chatSocket.disconnect();
    _cancelAssistantGraceTimer();
    unawaited(_liveKitVoice.disableAssistantMic());
    unawaited(AiseeWakeWordService.instance.stopForLiveSession());
  }
}
```

Also remove the agent-state listener and cancel the timer in `dispose()`:

```dart
_cancelAssistantGraceTimer();
_liveKitVoice.agentState.removeListener(_onAgentStateChanged);
```

- [ ] **Step 6: Replace the fake controller with working test logic and verify it passes**

Update the fake controller in `test/user_home_wake_handoff_test.dart`:

```dart
class _FakeAssistantAudioController {
  String state = 'idle_listening_wake';
  bool wakeListening = true;
  bool liveMicEnabled = false;

  Future<void> onWakeDetected() async {
    if (state != 'idle_listening_wake') {
      return;
    }
    state = 'activating_live_session';
    wakeListening = false;
    liveMicEnabled = true;
    state = 'conversation_active';
  }

  void onAgentStateChanged(String next) {
    if (state == 'conversation_active' && next == 'idle') {
      state = 'conversation_grace_period';
      return;
    }
    if (state == 'conversation_grace_period' &&
        (next == 'listening' || next == 'thinking' || next == 'speaking')) {
      state = 'conversation_active';
    }
  }

  Future<void> expireGracePeriod() async {
    if (state != 'conversation_grace_period') {
      return;
    }
    liveMicEnabled = false;
    wakeListening = true;
    state = 'idle_listening_wake';
  }
}
```

Run: `flutter test test/user_home_wake_handoff_test.dart`

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/models/agent_state.dart lib/screens/user_home_screen.dart lib/services/aisee_livekit_voice_session.dart lib/services/aisee_wake_word_service.dart test/user_home_wake_handoff_test.dart
git commit -m "feat: hand off mic between wake word and livekit"
```

## Task 4: Verify logs, edge cases, and regression safety

**Files:**
- Modify: `lib/screens/user_home_screen.dart`
- Modify: `lib/services/aisee_livekit_voice_session.dart`
- Modify: `lib/services/aisee_wake_word_service.dart`
- Test: `test/user_home_wake_handoff_test.dart`

- [ ] **Step 1: Add failing edge-case tests for duplicate wake and mic-enable failure**

Append tests:

```dart
test('duplicate wake event during active conversation is ignored', () async {
  final controller = _FakeAssistantAudioController();

  await controller.onWakeDetected();
  await controller.onWakeDetected();

  expect(controller.state, 'conversation_active');
  expect(controller.liveMicEnableCount, 1);
});

test('mic enable failure restores idle wake mode', () async {
  final controller = _FakeAssistantAudioController.failOnEnable();

  await controller.onWakeDetected();

  expect(controller.state, 'idle_listening_wake');
  expect(controller.wakeListening, isTrue);
  expect(controller.liveMicEnabled, isFalse);
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/user_home_wake_handoff_test.dart`

Expected: FAIL because the fake does not yet model duplicate-counting or failure recovery.

- [ ] **Step 3: Add minimal guards and debug logs in production code**

In `lib/screens/user_home_screen.dart`, harden `_activateLiveConversationFromWake()`:

```dart
Future<void> _activateLiveConversationFromWake() async {
  if (_assistantAudioState != _AssistantAudioState.idleListeningWake) {
    debugPrint('[AiSee:WakeFlow] Ignore wake in state=$_assistantAudioState');
    return;
  }
  try {
    _assistantAudioState = _AssistantAudioState.activatingLiveSession;
    debugPrint('[AiSee:WakeFlow] Wake detected -> stop wake, enable mic');
    await AiseeWakeWordService.instance.stopForLiveSession();
    await _liveKitVoice.enableAssistantMic();
    _assistantAudioState = _AssistantAudioState.conversationActive;
    debugPrint('[AiSee:WakeFlow] Live conversation active');
  } catch (e, st) {
    debugPrint('[AiSee:WakeFlow] Activation failed: $e\n$st');
    await _enterIdleWakeMode();
  }
}
```

In `lib/services/aisee_wake_word_service.dart`, add logs around start/stop transitions:

```dart
debugPrint('[AiSee:WakeWord] Idle listening ON');
debugPrint('[AiSee:WakeWord] Idle listening OFF for LiveKit');
```

In `lib/services/aisee_livekit_voice_session.dart`, log the explicit mic transitions:

```dart
_log('Connect', 'Assistant mic ON by wake handoff');
_log('Connect', 'Assistant mic OFF, returning to wake idle');
```

- [ ] **Step 4: Update the edge-case fake and verify tests pass**

Extend the fake controller used in `test/user_home_wake_handoff_test.dart`:

```dart
class _FakeAssistantAudioController {
  _FakeAssistantAudioController({this.failEnable = false});

  _FakeAssistantAudioController.failOnEnable() : failEnable = true;

  final bool failEnable;
  String state = 'idle_listening_wake';
  bool wakeListening = true;
  bool liveMicEnabled = false;
  int liveMicEnableCount = 0;

  Future<void> onWakeDetected() async {
    if (state != 'idle_listening_wake') {
      return;
    }
    state = 'activating_live_session';
    wakeListening = false;
    if (failEnable) {
      liveMicEnabled = false;
      wakeListening = true;
      state = 'idle_listening_wake';
      return;
    }
    liveMicEnableCount += 1;
    liveMicEnabled = true;
    state = 'conversation_active';
  }

  // keep onAgentStateChanged and expireGracePeriod from Task 3
}
```

Run: `flutter test test/user_home_wake_handoff_test.dart`

Expected: PASS.

- [ ] **Step 5: Run focused verification**

Run:

```bash
flutter test test/user_home_wake_handoff_test.dart
flutter analyze lib/models/agent_state.dart lib/screens/user_home_screen.dart lib/services/aisee_livekit_voice_session.dart lib/services/aisee_wake_word_service.dart
```

Expected:

- all tests PASS,
- analyzer reports no issues in the touched files.

- [ ] **Step 6: Commit**

```bash
git add lib/screens/user_home_screen.dart lib/services/aisee_livekit_voice_session.dart lib/services/aisee_wake_word_service.dart test/user_home_wake_handoff_test.dart
git commit -m "test: cover wake handoff edge cases"
```

## Spec Coverage Check

- Warm connected room with mic off by default: Task 1 and Task 3.
- Wake word active only in idle: Task 2 and Task 3.
- Wake detection hands mic to LiveKit: Task 3.
- Agent-finished to 20-second grace period: Task 3.
- Ignore duplicate wake, recover from mic errors, lifecycle safety: Task 4.
- Focused tests and verification: Tasks 1 through 4.

## Placeholder Scan

- No `TODO`, `TBD`, or deferred implementation markers remain in task steps.
- Each code-editing step names exact files and concrete method names.
- Each verification step includes concrete commands and expected outcomes.

## Type Consistency Check

- LiveKit methods use `enableAssistantMic()` and `disableAssistantMic()` consistently.
- Wake service uses `startIdleListening()` and `stopForLiveSession()` consistently.
- Coordinator states use the same four names from the design doc.
