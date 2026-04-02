# Connection Lifecycle Fix & Agent Greeting — Design Spec

**Date:** 2026-04-02
**Branch:** fix/calling-system
**Goal:** Fix WebSocket spam, reduce latency, add agent greeting on connect.

---

## Problem Summary

1. **WebSocket chat spam:** `AiseeChatSocket.connect()` lacks guards — called multiple times from `initState`, `resumed`, and fallback in `build()`. Results in 8-10 parallel connections.
2. **LiveKit connect overhead:** Always calls `disconnect()` before `connect()`, no guard against duplicate calls. Room connect takes ~2.5s.
3. **Gemini session dies after ~30s idle:** Re-init adds ~300ms + drops first response (`received server content but no active generation`).
4. **No agent greeting:** User opens app with no feedback that AI is ready.

---

## Design

### 1. Singleton ChatSocket

**What changes:**
- `AiseeChatSocket` becomes a singleton managed at `AuthShell` level.
- `connect()` closes existing socket before opening new one. Adds `_connecting` flag to prevent concurrent calls.
- Remove socket creation from `UserHomeScreen`, `FamilyHomeScreen`, `ChatDetailScreen`. All receive socket via constructor or inherited widget.
- `FamilyHomeScreen`: remove `_chatSocket ?? AiseeChatSocket()` fallback in `build()` — pass nullable socket, child widget handles null state.

**Guard logic in `connect()`:**
```
if (_connecting) return;
if (_socket != null) await disconnect();
_connecting = true;
try { ... } finally { _connecting = false; }
```

**Lifecycle:**
- `AuthShell` calls `connect()` when user authenticated.
- `AuthShell` calls `disconnect()` on logout.
- App pause/resume: `disconnect()` on pause, `connect()` on resume — single call site.

**Files changed:**
- `lib/services/aisee_chat_socket.dart` — add guard
- `lib/widgets/auth_shell.dart` — own and manage singleton socket
- `lib/screens/user_home_screen.dart` — receive socket, remove creation/lifecycle
- `lib/screens/family_home_screen.dart` — receive socket, remove creation/lifecycle, remove fallback
- `lib/screens/chat_detail_screen.dart` — remove own socket fallback, require parent socket
- `lib/screens/contacts_tab.dart` — pass-through only, no changes needed

### 2. LiveKit Connection Guard

**What changes:**
- `AiseeLiveKitVoiceSession.connect()`: skip `disconnect()` if no existing room. Add `Completer`-based guard against concurrent `connect()` calls.
- Only call `disconnect()` when `_room != null`.

**Guard logic:**
```
Completer<void>? _connectCompleter;

Future<void> connect(...) async {
  if (_connectCompleter != null) return _connectCompleter!.future;
  _connectCompleter = Completer<void>();
  try {
    if (_room != null) await disconnect();
    // ... actual connect
  } finally {
    _connectCompleter!.complete();
    _connectCompleter = null;
  }
}
```

**Files changed:**
- `lib/services/aisee_livekit_voice_session.dart` — add connect guard

### 3. Keep-alive Gemini Session

**What changes:**
- Agent (Python) keeps Gemini session alive while LiveKit room is connected.
- Remove the ~30s idle timeout that closes the Gemini session.
- Close Gemini session only when: participant disconnects OR room disconnects.
- This eliminates the `received server content but no active generation` warning.

**Files changed:**
- Agent-side Python code in Docker container (aiseebackend-agent)
- Specifically: the idle timeout / session close logic

### 4. Agent Greeting on Connect

**What changes:**
- When agent connects to room and Gemini session is ready, start session with `wake_up=True`.
- Agent uses user context (name, time of day, locale) to generate a greeting via Gemini TTS.
- Greeting happens every new LiveKit connection (not just first time per day).

**Flow:**
```
User opens app
  → LiveKit room.connect() (~2s)
  → Agent joins room
  → Agent publishes state: initializing
  → Gemini session starts with wake_up=True
  → Agent speaks greeting
  → Agent state → listening (ready for user input)
```

**Files changed:**
- Agent-side Python code: change initial `wake_up=False` to `wake_up=True` in the first Gemini session start after participant connects.

### 5. Timing Budget (after fix)

| Phase | Before | After |
|-------|--------|-------|
| WebSocket connections | 8-10 parallel | 1 |
| LiveKit room connect | ~2.5s (with needless disconnect) | ~2s (skip disconnect if clean) |
| Gemini session ready | 47-300ms (cold/warm) | 0ms (already alive) |
| User speaks → AI responds | ~1s + 300ms re-init | ~1s |
| Agent greeting | N/A | Speaks within ~1s of Gemini ready |

---

## Out of Scope

- Changing wake word delays (300ms, 600ms) — necessary for Android audio.
- Changing 20s grace period — working as designed.
- Pre-connecting LiveKit before auth — requires architectural change.
- Audio cue before greeting — decided against.

---

## Testing

- Verify only 1 WebSocket connection in server logs after app open + resume cycles.
- Verify agent speaks greeting on each new LiveKit connection.
- Verify user speech → AI response has no extra Gemini re-init delay.
- Verify no `received server content but no active generation` warning in agent logs.
- Verify existing wake word flow still works (300ms delay preserved).
