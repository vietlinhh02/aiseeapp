# Connection Lifecycle Fix & Agent Greeting — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix WebSocket spam (8-10 parallel connections → 1), add LiveKit connect guard, keep Gemini session alive, and add agent greeting on every connect.

**Architecture:** Singleton `AiseeChatSocket` managed by `AuthShell`, passed to screens via constructor. LiveKit `connect()` gets a `Completer` guard. Agent Python code changes `user_away_timeout` to keep Gemini alive and starts with `wake_up=True` on first session.

**Tech Stack:** Flutter/Dart (client), Python/LiveKit Agents SDK (agent worker)

---

### Task 1: Add connection guard to AiseeChatSocket

**Files:**
- Modify: `lib/services/aisee_chat_socket.dart`

- [ ] **Step 1: Add `_connecting` guard and close-before-connect logic**

Replace the `connect` and `_doConnect` methods in `lib/services/aisee_chat_socket.dart`:

```dart
bool _connecting = false;

Future<void> connect(String accessToken) async {
  if (_connecting) return;
  _accessToken = accessToken;
  _disposed = false;
  _connecting = true;
  try {
    // Close existing socket before opening new one.
    final WebSocket? existing = _socket;
    if (existing != null) {
      _socket = null;
      _reconnectTimer?.cancel();
      _reconnectTimer = null;
      try {
        await existing.close();
      } catch (_) {}
    }
    _reconnectAttempts = 0;
    await _doConnect();
  } finally {
    _connecting = false;
  }
}
```

- [ ] **Step 2: Verify build succeeds**

Run: `cd /home/eddiesngu/Desktop/Dang/aiseeapp && flutter analyze lib/services/aisee_chat_socket.dart`
Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add lib/services/aisee_chat_socket.dart
git commit -m "fix(ws): add connection guard to AiseeChatSocket

Prevents duplicate WebSocket connections by tracking _connecting state
and closing existing socket before opening new one."
```

---

### Task 2: Move ChatSocket to AuthShell as singleton

**Files:**
- Modify: `lib/widgets/auth_shell.dart`
- Modify: `lib/screens/user_home_screen.dart`
- Modify: `lib/screens/family_home_screen.dart`

- [ ] **Step 1: Add ChatSocket to AuthShell**

In `lib/widgets/auth_shell.dart`, add import and field:

```dart
import '../services/aisee_chat_socket.dart';
```

Add field to `_AuthShellState`:

```dart
final AiseeChatSocket _chatSocket = AiseeChatSocket();
```

Add lifecycle observer to `_AuthShellState`:

```dart
@override
void initState() {
  super.initState();
  _aiseeAuth = widget.authService ?? AiseeAuthService();
  _ownsAuthService = widget.authService == null;
  WidgetsBinding.instance.addObserver(this);  // NEW
  unawaited(_bootstrap());
}
```

Make `_AuthShellState` implement `WidgetsBindingObserver`:

```dart
class _AuthShellState extends State<AuthShell> with WidgetsBindingObserver {
```

Add `didChangeAppLifecycleState`:

```dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (_aiseeProfile == null) return;
  if (state == AppLifecycleState.resumed) {
    _connectChatSocketIfNeeded();
  } else if (state == AppLifecycleState.paused) {
    _chatSocket.disconnect();
    _authLog('ChatSocket disconnected (app paused)');
  }
}

Future<void> _connectChatSocketIfNeeded() async {
  if (_chatSocket.isConnected) return;
  final AiseeAuthTokens? tokens = await _readStoredSession();
  if (tokens != null) {
    await _chatSocket.connect(tokens.accessToken);
    _authLog('ChatSocket connected');
  }
}
```

Connect socket in `_applySessionFromServer` (after tokens are saved):

After `await AiseeSessionStore.instance.write(resumed.tokens);` add:

```dart
unawaited(_chatSocket.connect(resumed.tokens.accessToken));
```

Connect socket in `_restoreStoredSession` (cache path), after `await AiseePushService.instance.initAndUploadToken(stored.accessToken);` add:

```dart
unawaited(_chatSocket.connect(stored.accessToken));
```

Disconnect socket on logout — in `_clearSessionAndRouteToLogin`, after the two `clear()` calls add:

```dart
unawaited(_chatSocket.disconnect());
```

Dispose socket:

```dart
@override
void dispose() {
  WidgetsBinding.instance.removeObserver(this);  // NEW
  _chatSocket.dispose();  // NEW
  unawaited(_authSub?.cancel());
  if (_ownsAuthService) {
    _aiseeAuth.close();
  }
  super.dispose();
}
```

- [ ] **Step 2: Pass chatSocket to UserHomeScreen and FamilyHomeScreen**

In `auth_shell.dart`, update `UserHomeScreen` constructor call in `_homeForRole`:

```dart
if (role == 'user') {
  return UserHomeScreen(
    googleUser: googleUser,
    aiseeProfile: aiseeProfile,
    aiseeLoading: aiseeLoading,
    aiseeError: aiseeError,
    onSignOut: _signOut,
    chatSocket: _chatSocket,
  );
}
return FamilyHomeScreen(
  googleUser: googleUser,
  aiseeProfile: aiseeProfile,
  aiseeLoading: aiseeLoading,
  aiseeError: aiseeError,
  onSignOut: _signOut,
  chatSocket: _chatSocket,
);
```

- [ ] **Step 3: Update UserHomeScreen to receive chatSocket**

In `lib/screens/user_home_screen.dart`:

Add parameter to widget:

```dart
const UserHomeScreen({
  super.key,
  this.googleUser,
  this.aiseeProfile,
  this.aiseeLoading = false,
  this.aiseeError,
  required this.onSignOut,
  required this.chatSocket,
});

// ... existing fields ...
final AiseeChatSocket chatSocket;
```

In `_UserHomeScreenState`:

- **Remove** `final AiseeChatSocket _chatSocket = AiseeChatSocket();`
- Replace all `_chatSocket` references with `widget.chatSocket`
- **Remove** the `_connectChatSocket()` method entirely
- **Remove** `_connectChatSocket();` from `initState` (line 130)
- **Remove** the chat socket lines from `didChangeAppLifecycleState`:
  - Remove `_connectChatSocket();` from resumed branch
  - Remove `_chatSocket.disconnect();` and its debugPrint from paused branch
- **Remove** `_chatSocket.dispose();` from `dispose()`
- Update the `ContactsTab` reference: `chatSocket: widget.chatSocket,`

- [ ] **Step 4: Update FamilyHomeScreen to receive chatSocket**

In `lib/screens/family_home_screen.dart`:

Add parameter:

```dart
const FamilyHomeScreen({
  super.key,
  this.googleUser,
  this.aiseeProfile,
  this.aiseeLoading = false,
  this.aiseeError,
  required this.onSignOut,
  required this.chatSocket,
});

// ... existing fields ...
final AiseeChatSocket chatSocket;
```

In `_FamilyHomeScreenState`:

- **Remove** `AiseeChatSocket? _chatSocket;`
- **Remove** the `_initSocket()` method entirely
- **Remove** `_initSocket();` from `initState`
- **Remove** `_chatSocket?.dispose();` from `dispose()`
- Replace `_chatSocket ?? AiseeChatSocket()` on line 178 with `widget.chatSocket`

```dart
FamilyMessagesTab(
  currentUserId: profile.id,
  chatSocket: widget.chatSocket,
  familyRosterVersion: _familyRosterVersion,
  messagesTabActive: _tabIndex == 1,
),
```

- [ ] **Step 5: Remove import of aisee_chat_socket from FamilyHomeScreen**

In `lib/screens/family_home_screen.dart`, remove:

```dart
import '../services/aisee_chat_socket.dart';
```

Also remove:

```dart
import '../services/aisee_session_store.dart';
```

(Only used by `_initSocket` which is now removed.)

- [ ] **Step 6: Update ChatDetailScreen to require chatSocket**

In `lib/screens/chat_detail_screen.dart`:

Change `chatSocket` parameter from optional to required:

```dart
const ChatDetailScreen({
  super.key,
  required this.contact,
  required this.chatSocket,
  this.currentUserId,
});

final AiseeChatSocket chatSocket;
```

Remove `_ownSocket` field (line 79):

```dart
// DELETE: AiseeChatSocket? _ownSocket;
```

Simplify `_listenSocket()`:

```dart
void _listenSocket() {
  _socketSub = widget.chatSocket.onMessage.listen(_onNewMessage);
}
```

Remove own socket cleanup from `dispose()` — only cancel subscription:

```dart
// Keep: _socketSub?.cancel();
// DELETE: _ownSocket?.disconnect();
// DELETE: _ownSocket?.dispose();
```

Remove unused import of `AiseeSessionStore` if only used by socket fallback.

- [ ] **Step 7: Verify build succeeds**

Run: `cd /home/eddiesngu/Desktop/Dang/aiseeapp && flutter analyze lib/widgets/auth_shell.dart lib/screens/user_home_screen.dart lib/screens/family_home_screen.dart lib/screens/chat_detail_screen.dart`
Expected: No issues found.

- [ ] **Step 8: Commit**

```bash
git add lib/widgets/auth_shell.dart lib/screens/user_home_screen.dart lib/screens/family_home_screen.dart lib/screens/chat_detail_screen.dart
git commit -m "refactor(ws): singleton ChatSocket managed by AuthShell

Move socket lifecycle to AuthShell: connect on auth, disconnect on
pause/logout, pass to screens via constructor. Eliminates duplicate
socket creation in UserHomeScreen, FamilyHomeScreen, ChatDetailScreen."
```

---

### Task 3: Add Completer guard to LiveKit connect

**Files:**
- Modify: `lib/services/aisee_livekit_voice_session.dart`

- [ ] **Step 1: Add Completer guard**

At the top of the class, add field:

```dart
Completer<void>? _connectCompleter;
```

Wrap `connect()` method (starts at line 1014):

```dart
Future<void> connect({
  required String userName,
  required String userId,
  Future<bool>? resolveHasFamilyLink,
}) async {
  if (_connectCompleter != null) {
    _log('Connect', 'Already connecting, waiting...');
    return _connectCompleter!.future;
  }
  _connectCompleter = Completer<void>();
  try {
    await _connectInner(
      userName: userName,
      userId: userId,
      resolveHasFamilyLink: resolveHasFamilyLink,
    );
    _connectCompleter!.complete();
  } catch (e, st) {
    _connectCompleter!.completeError(e, st);
    rethrow;
  } finally {
    _connectCompleter = null;
  }
}

Future<void> _connectInner({
  required String userName,
  required String userId,
  Future<bool>? resolveHasFamilyLink,
}) async {
  _log('Connect', 'Bat dau ket noi LiveKit...');
  if (_room != null) {
    await disconnect();
  }
  // ... rest of existing connect() body from line 1023 onward ...
}
```

Move the entire body of `connect()` (from line 1023 `_log('Connect', 'Song song...')` through line 1121) into `_connectInner`.

- [ ] **Step 2: Verify build succeeds**

Run: `cd /home/eddiesngu/Desktop/Dang/aiseeapp && flutter analyze lib/services/aisee_livekit_voice_session.dart`
Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add lib/services/aisee_livekit_voice_session.dart
git commit -m "fix(livekit): add Completer guard to prevent duplicate connect

Skip disconnect() when no existing room. Guard concurrent connect()
calls with Completer so second caller awaits the first."
```

---

### Task 4: Keep Gemini session alive & enable greeting

**Files:**
- Modify: `/home/eddiesngu/Desktop/Dang/aiseebackend/agent_worker/main.py`

- [ ] **Step 1: Change user_away_timeout to disable idle close**

In `main.py` line 202, change:

```python
user_away_timeout=30,
```

to:

```python
user_away_timeout=0,
```

Setting to `0` disables the user-away timeout. The Gemini session stays alive until the room disconnects (handled by `_stop_session()` at line 321).

- [ ] **Step 2: Remove the user_state_changed handler that stops session on away**

Delete lines 205-208:

```python
# DELETE THESE LINES:
@active_session.on("user_state_changed")
def _on_user_state(ev):
    if ev.new_state == "away":
        asyncio.create_task(_stop_session())
```

- [ ] **Step 3: Change first session to wake_up=True for greeting**

In `main.py` lines 156-157, change:

```python
wake_up = not first_start
first_start = False
```

to:

```python
wake_up = True
```

Remove the `first_start = True` declaration at line 147. The `first_start` variable is no longer needed.

- [ ] **Step 4: Rebuild and restart agent container**

```bash
cd /home/eddiesngu/Desktop/Dang/aiseebackend && docker compose up -d --build agent
```

Expected: Container rebuilds and starts successfully. Logs should show `starting Gemini session (wake_up=True)` on first connect.

- [ ] **Step 5: Commit**

```bash
cd /home/eddiesngu/Desktop/Dang/aiseebackend
git add agent_worker/main.py
git commit -m "feat(agent): keep Gemini alive and greet on every connect

Disable user_away_timeout so session stays alive while room connected.
Always start with wake_up=True so agent greets user immediately."
```

---

### Task 5: Smoke test end-to-end

**Files:** No code changes — manual verification.

- [ ] **Step 1: Build and install Flutter app**

```bash
cd /home/eddiesngu/Desktop/Dang/aiseeapp && flutter build apk --debug && adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

- [ ] **Step 2: Verify single WebSocket connection**

Open app, navigate between tabs, pause/resume app 3 times. Check backend logs:

```bash
docker logs aiseebackend-api-1 --tail 100 2>&1 | grep "websocket"
```

Expected: Only **1 active WebSocket** at a time. Each resume creates exactly 1 new connection, previous one is closed.

- [ ] **Step 3: Verify agent greeting**

Open app → wait for LiveKit to connect → agent should speak a greeting within ~3s of app open.

Check agent logs:

```bash
docker logs aiseebackend-agent-1 --tail 50 2>&1 | grep -E "wake_up|Gemini session ready"
```

Expected: `starting Gemini session (wake_up=True)` and `Gemini session ready in Xms`.

- [ ] **Step 4: Verify no Gemini re-init on speech**

After agent greets, wait 60s (previously session would die at 30s), then speak.

Check agent logs:

```bash
docker logs aiseebackend-agent-1 --tail 50 2>&1
```

Expected: No `closing Gemini session` / `starting Gemini session` cycle during the 60s wait. Session stays alive. No `received server content but no active generation` warning.

- [ ] **Step 5: Verify LiveKit connect guard**

Rapidly toggle app pause/resume 5 times. Check for any duplicate connect warnings in Flutter debug console.

Expected: `[AiSee:Connect] Already connecting, waiting...` may appear. No crashes. Single room connection.
