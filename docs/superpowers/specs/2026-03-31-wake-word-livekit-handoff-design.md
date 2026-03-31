# Wake Word and LiveKit Mic Handoff Design

## Summary

The assistant screen should keep the LiveKit room connected for low latency, but leave the
local microphone off while wake word detection listens in the background. When wake word is
detected, the app temporarily transfers microphone ownership from wake word detection to
LiveKit. After the agent finishes and the user stays silent for 20 seconds, the app turns the
LiveKit microphone off and restores wake word listening.

## Problem

The current implementation starts LiveKit, enables the microphone immediately, and then pauses
wake word detection. This makes the wake word integration effectively unusable on the assistant
screen because LiveKit permanently owns the microphone until disconnect.

## Goals

- Keep the LiveKit room warm to reduce activation latency.
- Allow wake word detection while the assistant is idle.
- Transfer microphone ownership cleanly between wake word and LiveKit.
- Return to wake word listening automatically after the conversation ends and 20 seconds of
  user silence pass.
- Avoid stuck states where both systems are off or both compete for the microphone.

## Non-Goals

- Running wake word detection and LiveKit microphone capture at the same time.
- Redesigning backend agent behavior beyond the minimum signaling needed to know when the agent
  has finished.
- Background always-on voice assistant outside the assistant screen.

## Current State

- `UserHomeScreen` connects LiveKit on screen startup.
- `AiseeLiveKitVoiceSession.connect()` enables the local microphone immediately after joining.
- `AiseeWakeWordService.startIfConfigured()` pauses itself when LiveKit already owns the mic.
- Wake word only resumes after LiveKit disconnects.

This creates a permanent conflict where the warm LiveKit session blocks wake word listening.

## Recommended Approach

Use a warm connected LiveKit room with explicit microphone toggling driven by a small assistant
audio state machine.

Why this approach:

- Lower latency than reconnecting LiveKit after each wake event.
- Smaller scope than adding a full cross-system signaling protocol first.
- Fits the existing code structure, which already keeps a long-lived `AiseeLiveKitVoiceSession`.

## Alternatives Considered

### 1. Cold-connect LiveKit after wake word

- Simpler ownership model.
- Higher latency because token fetch, room connect, and mic publish happen after wake detection.
- Rejected because responsiveness matters for the assistant experience.

### 2. Warm room with extra backend protocol

- Clearer server-client coordination for conversation lifecycle.
- More robust long term.
- Deferred for now because it expands scope to backend and agent protocol changes.

### 3. Infer conversation end only from audio activity

- Less backend dependency.
- Error-prone because silence does not always mean the agent is done.
- Rejected as the primary control path.

## Architecture

### Components

- `AiseeWakeWordService`
  - Owns wake word lifecycle.
  - Runs only while the assistant is idle.
  - Stops before LiveKit microphone activation.

- `AiseeLiveKitVoiceSession`
  - Keeps the LiveKit room connected.
  - Exposes microphone enable and disable operations without disconnecting the room.
  - Surfaces conversation lifecycle signals needed by the UI coordinator.

- Assistant audio coordinator
  - New coordination layer, likely inside `UserHomeScreen` first unless it becomes too large.
  - Owns the state machine, timer, and transitions between wake word and LiveKit mic states.

### State Machine

- `idle_listening_wake`
  - LiveKit room connected.
  - LiveKit local mic off.
  - Wake word listening on.

- `activating_live_session`
  - Wake word has been detected.
  - Wake word is stopping.
  - LiveKit mic is being enabled.

- `conversation_active`
  - LiveKit mic on.
  - Wake word off.
  - User and agent may exchange audio.

- `conversation_grace_period`
  - Agent has reported completion.
  - LiveKit mic remains on for up to 20 seconds.
  - Any new user or agent activity resets the timer and returns to `conversation_active`.

## Data Flow

### Startup

1. Enter assistant screen.
2. Connect LiveKit room.
3. Do not enable local microphone during room connect.
4. Start wake word listening after room connection succeeds.
5. Enter `idle_listening_wake`.

### Wake Activation

1. Wake word detects the configured phrase.
2. Ignore the event if not in `idle_listening_wake`.
3. Transition to `activating_live_session`.
4. Stop wake word listening.
5. Enable LiveKit local microphone.
6. Notify the agent session if needed that a user voice session has started.
7. Enter `conversation_active`.

### Conversation Progress

1. While the user or agent is still active, remain in `conversation_active`.
2. When the agent signals completion, transition to `conversation_grace_period`.
3. Start a 20-second inactivity timer.

### Grace Period

1. If the user speaks again or the agent emits more activity before the timer expires:
   - cancel the timer,
   - return to `conversation_active`.
2. If the timer reaches 20 seconds with no further activity:
   - disable LiveKit local microphone,
   - restart wake word listening,
   - return to `idle_listening_wake`.

## Conversation Lifecycle Signals

The design depends on one reliable indication that the agent has finished its turn. Preferred
signal sources, in order:

1. Existing agent state or RPC signal already available from LiveKit integration.
2. Participant attribute changes such as `lk.agent.state` if they map cleanly to a completed
   turn.
3. A small backend or agent protocol addition if existing signals are insufficient.

Pure audio-silence inference should only be a fallback, not the primary end-of-turn signal.

## Error Handling

- If wake word detection fires while the state is not `idle_listening_wake`, ignore it.
- If enabling the LiveKit microphone fails after wake detection:
  - log the failure,
  - restart wake word listening,
  - return to `idle_listening_wake`.
- If restarting wake word fails after a conversation:
  - keep LiveKit mic off,
  - expose a visible retry path or recover on next assistant screen resume.
- If LiveKit disconnects at any point:
  - cancel the grace timer,
  - turn off any assumption that the mic is active,
  - reconnect using existing screen behavior,
  - only restore wake word once the mic is confirmed off.
- If the app goes to background during `conversation_active` or `conversation_grace_period`:
  - cancel the timer,
  - disable LiveKit mic,
  - stop wake word unless background wake listening is explicitly supported.

## Platform Considerations

### Android

- `AudioRecord` ownership is exclusive enough that wake word and LiveKit should not attempt to
  capture simultaneously.
- Repeated microphone toggling should be verified against the foreground service setup already in
  use for LiveKit voice.

### iOS

- Audio session transitions must leave the app in a stable `playAndRecord` configuration.
- Repeated input activation and deactivation should be tested with speaker, wired headset, and
  Bluetooth routes.

## Required Research Before Implementation

1. Verify that a connected LiveKit room with local mic disabled still keeps the agent ready for a
   quick wake-to-talk transition.
2. Identify the best available event for `agent finished` from the current integration.
3. Measure how quickly `setMicrophoneEnabled(true)` becomes usable after being off.
4. Verify that repeated `true -> false -> true` mic transitions do not leak, stall, or leave the
   local participant in a bad published state.
5. Confirm whether any additional foreground-service or audio-session handling is needed during
   mic toggling.

## Testing Strategy

### Manual

1. Open assistant screen and confirm:
   - LiveKit room connects,
   - local mic stays off,
   - wake word listens.
2. Speak wake word and confirm:
   - wake word stops,
   - LiveKit mic turns on,
   - the agent receives user speech.
3. End the conversation and confirm:
   - a 20-second grace period starts after the agent finishes,
   - no new activity turns the mic off after 20 seconds,
   - wake word resumes.
4. Speak again during the 20-second grace period and confirm the timer resets.
5. Force LiveKit disconnect during a conversation and confirm the system returns to a safe idle
   state.
6. Background and foreground the app during each state and confirm there is no stuck microphone.

### Automated

- Unit-test the audio coordinator state machine and timer transitions.
- Mock wake detection, LiveKit mic enable and disable, and agent-finished signals.
- Cover duplicate wake events, mic-enable failures, disconnects, and background transitions.

## Open Decisions Already Resolved

- Product mode: keep LiveKit connected, but mic off by default.
- Grace timeout: 20 seconds after the agent reports completion and the user remains silent.
- Wake word is only active while the assistant is idle.

## Implementation Boundaries

The first implementation should stay minimal:

- avoid broad refactors,
- add only the coordinator logic and the LiveKit mic toggle changes required for this feature,
- reuse the current assistant screen and service structure where possible.

## Rollout Notes

- Ship behind existing assistant usage flow only; no new user-visible settings are required.
- Add focused debug logging around state transitions so microphone ownership issues can be traced
  in `flutter run` logs.
