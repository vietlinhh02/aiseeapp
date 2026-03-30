# Calling & Messaging Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add family calling (voice/video via LiveKit) and text messaging to AiSee, replacing tab 2.

**Architecture:** Three new services (AiseeFamilyService, AiseeChatService, AiseeChatSocket) + AiseeCallService for family calls. LiveKit used for media. WebSocket for real-time chat. FCM + CallKit for incoming calls. Tab 2 "Công cụ" replaced with "Liên lạc".

**Tech Stack:** Flutter, LiveKit, dart:io WebSocket, firebase_messaging, flutter_callkit_incoming, http package

---

## File Map

### New files — Models
- `lib/models/aisee_family_member.dart` — Family member data from GET /users/me/family
- `lib/models/aisee_message.dart` — Chat message data
- `lib/models/aisee_call_info.dart` — Call room info (roomName, token, callType, contact)

### New files — Services
- `lib/services/aisee_family_service.dart` — Family CRUD + push token upload
- `lib/services/aisee_chat_service.dart` — Messages REST API
- `lib/services/aisee_chat_socket.dart` — WebSocket real-time messages
- `lib/services/aisee_call_service.dart` — Create/end family call rooms

### New files — Screens
- `lib/screens/contacts_tab.dart` — Tab 2 replacement: family contacts + last message
- `lib/screens/chat_detail_screen.dart` — Conversation with a contact
- `lib/screens/call_screen.dart` — Active call UI (voice + video)

### Modified files
- `pubspec.yaml` — Add web_socket_channel, firebase_core, firebase_messaging, flutter_callkit_incoming
- `lib/widgets/user_low_vision_bottom_nav.dart` — Change tab 2 icon + label
- `lib/screens/user_home_screen.dart` — Replace UserToolsTab with ContactsTab, pass profile/tokens
- `lib/screens/user_personal_tab.dart` — Remove "Tin nhắn thoại chưa đọc" placeholder

### Deleted files
- `lib/screens/user_tools_tab.dart`

---

## Task 1: Models

**Files:**
- Create: `lib/models/aisee_family_member.dart`
- Create: `lib/models/aisee_message.dart`
- Create: `lib/models/aisee_call_info.dart`

- [ ] **Step 1: Create AiseeFamilyMember model**

```dart
// lib/models/aisee_family_member.dart
class AiseeFamilyMember {
  const AiseeFamilyMember({
    required this.id,
    required this.email,
    this.displayName,
    required this.role,
    this.avatarUrl,
  });

  final String id;
  final String email;
  final String? displayName;
  final String role;
  final String? avatarUrl;

  factory AiseeFamilyMember.fromJson(Map<String, dynamic> j) {
    return AiseeFamilyMember(
      id: j['id'] as String,
      email: j['email'] as String? ?? '',
      displayName: j['display_name'] as String?,
      role: j['role'] as String? ?? 'family',
      avatarUrl: j['avatar_url'] as String?,
    );
  }

  /// Display name with email fallback.
  String get label => displayName?.trim().isNotEmpty == true
      ? displayName!
      : email;
}
```

- [ ] **Step 2: Create AiseeMessage model**

```dart
// lib/models/aisee_message.dart
class AiseeMessage {
  const AiseeMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    this.contentText = '',
    this.voiceUrl,
    this.isRead = false,
    required this.createdAt,
  });

  final String id;
  final String senderId;
  final String receiverId;
  final String contentText;
  final String? voiceUrl;
  final bool isRead;
  final DateTime createdAt;

  factory AiseeMessage.fromJson(Map<String, dynamic> j) {
    return AiseeMessage(
      id: j['id'] as String,
      senderId: j['sender_id'] as String,
      receiverId: j['receiver_id'] as String,
      contentText: j['content_text'] as String? ?? '',
      voiceUrl: j['voice_url'] as String?,
      isRead: j['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(j['created_at'] as String),
    );
  }
}
```

- [ ] **Step 3: Create AiseeCallInfo model**

```dart
// lib/models/aisee_call_info.dart
import 'aisee_family_member.dart';

class AiseeCallInfo {
  const AiseeCallInfo({
    required this.roomName,
    required this.token,
    required this.callType,
    required this.contact,
  });

  final String roomName;
  final String token;
  final String callType; // "voice" | "video"
  final AiseeFamilyMember contact;
}
```

- [ ] **Step 4: Verify no analysis errors**

Run: `cd /home/eddiesngu/Desktop/Dang/aiseeapp && flutter analyze --no-fatal-infos 2>&1 | tail -5`

- [ ] **Step 5: Commit**

```bash
git add lib/models/aisee_family_member.dart lib/models/aisee_message.dart lib/models/aisee_call_info.dart
git commit -m "feat: add models for family member, message, and call info"
```

---

## Task 2: AiseeFamilyService

**Files:**
- Create: `lib/services/aisee_family_service.dart`

- [ ] **Step 1: Create AiseeFamilyService**

HTTP service with same pattern as `AiseeAuthService`: accepts `http.Client`, builds URIs from `AppEnv.apiBaseUrl`, parses errors with `AiseeApiException`.

Methods:
- `fetchFamily(String accessToken)` → `List<AiseeFamilyMember>` — GET /api/v1/users/me/family
- `createInvite(String accessToken, String relationship)` → `String` invite code — POST /api/v1/users/family-link
- `joinFamily(String accessToken, String inviteCode)` → void — POST /api/v1/users/join-family
- `deleteLink(String accessToken, String linkId)` → void — DELETE /api/v1/users/family-link/{linkId}
- `updateProfile(String accessToken, Map<String, dynamic> fields)` → void — PUT /api/v1/users/me

All methods add `Authorization: Bearer $accessToken` header. Parse errors from `{"error": "...", "message": "..."}` format.

- [ ] **Step 2: Verify no analysis errors**

Run: `flutter analyze --no-fatal-infos 2>&1 | tail -5`

- [ ] **Step 3: Commit**

```bash
git add lib/services/aisee_family_service.dart
git commit -m "feat: add AiseeFamilyService for family CRUD and profile update"
```

---

## Task 3: AiseeChatService

**Files:**
- Create: `lib/services/aisee_chat_service.dart`

- [ ] **Step 1: Create AiseeChatService**

HTTP service, same pattern as Task 2.

Methods:
- `fetchMessages(String accessToken, String contactId, {int limit = 50, String? before})` → `List<AiseeMessage>` — GET /api/v1/messages/{contactId}?limit=50&before={id}. Parse `{"messages": [...]}` response.
- `sendMessage(String accessToken, String receiverId, String text)` → `AiseeMessage` — POST /api/v1/messages/send with body `{"receiver_id": ..., "content_text": ..., "voice_url": ""}`.
- `markRead(String accessToken, String messageId)` → void — PUT /api/v1/messages/{id}/read.
- `fetchUnreadCount(String accessToken)` → `int` — GET /api/v1/messages/unread-count. Parse `{"count": N}`.

- [ ] **Step 2: Verify no analysis errors**

- [ ] **Step 3: Commit**

```bash
git add lib/services/aisee_chat_service.dart
git commit -m "feat: add AiseeChatService for messages REST API"
```

---

## Task 4: AiseeChatSocket

**Files:**
- Create: `lib/services/aisee_chat_socket.dart`

- [ ] **Step 1: Create AiseeChatSocket**

WebSocket client connecting to `ws(s)://<host>/api/v1/ws/chat?token=<jwt>`.

Key behaviors:
- Build WS URL: take `AppEnv.apiBaseUrl`, replace `http` → `ws` / `https` → `wss`, append `/api/v1/ws/chat?token=$accessToken`.
- `connect(String accessToken)` — open WebSocket, listen for messages.
- `Stream<AiseeMessage> get onMessage` — broadcast stream, parse `{"type": "new_message", "message": {...}}` JSON frames into `AiseeMessage`.
- Auto-reconnect on close/error with exponential backoff: 1s → 2s → 4s → 8s → 16s → 30s max. Reset backoff on successful connection.
- `disconnect()` — close WebSocket, cancel reconnect timer.
- Use `dart:io` `WebSocket` (not web_socket_channel — simpler for mobile-only app that already uses dart:io).

- [ ] **Step 2: Verify no analysis errors**

- [ ] **Step 3: Commit**

```bash
git add lib/services/aisee_chat_socket.dart
git commit -m "feat: add AiseeChatSocket with auto-reconnect"
```

---

## Task 5: AiseeCallService

**Files:**
- Create: `lib/services/aisee_call_service.dart`

- [ ] **Step 1: Create AiseeCallService**

HTTP service for family calling.

Methods:
- `createRoom(String accessToken, String calleeId, String callType)` → `({String roomName, String token})` — POST /api/v1/calls/create-room with `{"callee_id": ..., "call_type": "voice"|"video"}`. Parse response `{"room_name": ..., "token": ...}`.
- `endRoom(String accessToken, String roomName)` → void — POST /api/v1/calls/end-room with `{"room_name": ...}`.

- [ ] **Step 2: Verify no analysis errors**

- [ ] **Step 3: Commit**

```bash
git add lib/services/aisee_call_service.dart
git commit -m "feat: add AiseeCallService for family call room management"
```

---

## Task 6: Navigation restructure — delete UserToolsTab, update nav + home

**Files:**
- Delete: `lib/screens/user_tools_tab.dart`
- Modify: `lib/widgets/user_low_vision_bottom_nav.dart`
- Modify: `lib/screens/user_home_screen.dart`
- Modify: `lib/screens/user_personal_tab.dart`

- [ ] **Step 1: Delete user_tools_tab.dart**

Remove the file entirely.

- [ ] **Step 2: Update bottom nav — tab 2**

In `lib/widgets/user_low_vision_bottom_nav.dart`, change `_items[1]`:
- `iconAsset`: `'assets/icons/nav/ic_3user.svg'`
- `label`: `'Liên lạc'`
- `semanticsLabel`: `'Mục 2 trên 3: Liên lạc. Nhắn tin và gọi điện người thân.'`

- [ ] **Step 3: Update UserHomeScreen — replace tab 2 content**

In `lib/screens/user_home_screen.dart`:
- Remove import of `user_tools_tab.dart`
- Add import of `contacts_tab.dart` (will be created in Task 7)
- Change `_tabNames` index 1 from `'Cong cu'` to `'Lien lac'`
- Replace `const UserToolsTab()` in `IndexedStack` children with `ContactsTab(...)` — pass `aiseeProfile` so it can read the user ID and access token.

**Note:** ContactsTab doesn't exist yet, so this step will have a temporary compile error. Create a minimal placeholder `ContactsTab` widget (just a `Text('Liên lạc')` in a Center) to keep the app buildable. Task 7 will implement the real content.

- [ ] **Step 4: Remove message placeholder from UserPersonalTab**

In `lib/screens/user_personal_tab.dart`, remove:
```dart
const SizedBox(height: 16),
_InfoSection(
  iconAsset: 'assets/icons/nav/ic_voice.svg',
  title: 'Tin nhắn thoại chưa đọc',
  body: 'Không có tin mới từ người thân.',
),
```

- [ ] **Step 5: Verify build**

Run: `flutter analyze --no-fatal-infos 2>&1 | tail -5`

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "refactor: replace Công cụ tab with Liên lạc, remove tools tab"
```

---

## Task 7: ContactsTab screen

**Files:**
- Create (replace placeholder): `lib/screens/contacts_tab.dart`

- [ ] **Step 1: Implement ContactsTab**

A `StatefulWidget` that:
- On `initState`, loads family list via `AiseeFamilyService.fetchFamily()` and unread count via `AiseeChatService.fetchUnreadCount()`. Gets access token from `AiseeSessionStore.instance.read()`.
- Shows header "Liên lạc" (style: `StyleTokens.titleScreen().copyWith(fontSize: 18)`).
- Subtitle: "Nhắn tin và gọi điện người thân." (same style as other tabs).
- Below: `ListView` of contact rows.
- Each row: `Material` card with `surfaceCard` background, bo 12, padding 14. Contains:
  - Leading: `CircleAvatar` 44×44 with first letter of name, navy background.
  - Title: contact name (14 SemiBold).
  - Subtitle: last message preview (11 Regular muted) — initially just email since we haven't fetched messages per contact yet. Can show "Chạm để nhắn tin" placeholder.
  - Trailing: two `IconButton`s — phone (voice call) and video call icons using `ic_voice.svg` and `ic_camera.svg`. Size 20.
  - `onTap` → push `ChatDetailScreen` route.
- Empty state: "Chưa có người thân nào. Mời người thân qua mã mời." + invite button.
- Invite button: call `AiseeFamilyService.createInvite()`, show dialog with invite code.
- Error state: show error message + retry button.
- Loading state: `CircularProgressIndicator` centered.

Constructor accepts `AiseeUserProfile? aiseeProfile`.

- [ ] **Step 2: Verify no analysis errors**

- [ ] **Step 3: Commit**

```bash
git add lib/screens/contacts_tab.dart
git commit -m "feat: implement ContactsTab with family list and invite flow"
```

---

## Task 8: ChatDetailScreen

**Files:**
- Create: `lib/screens/chat_detail_screen.dart`

- [ ] **Step 1: Implement ChatDetailScreen**

A `StatefulWidget` receiving `AiseeFamilyMember contact` and `String currentUserId`.

Layout:
- **AppBar:** contact name centered. Two trailing icon buttons: voice call, video call (using SVG icons). Back button auto from Navigator.
- **Body:** Column with Expanded message list + input bar at bottom.
- **Message list:** `ListView.builder` with `reverse: true` (newest at bottom). Load initial messages via `AiseeChatService.fetchMessages()`. Infinite scroll: when scrolled near top, load older messages with `before` parameter (ID of oldest loaded message).
- **Message bubble:** Align left (received) or right (sent) based on `senderId == currentUserId`. Sent: navy background + white text. Received: white card + dark text. Border radius 16 with corner flatten on sender side. Show time below bubble (11px muted).
- **Input bar:** Row with `TextField` (flex) + send `IconButton`. TextField: white background, border `cardBorder`, bo 24, hint "Nhắn tin...". Send button: navy circle with white arrow icon (use `ic_arrow_right.svg` rotated or just `Icons.send` — actually use the SVG).
- **WebSocket:** On `initState`, connect `AiseeChatSocket` with token from `AiseeSessionStore`. Listen to `onMessage` stream, prepend new messages to list if they match this contact (senderId == contact.id). Also mark new incoming messages as read via `AiseeChatService.markRead()`.
- **Send:** Call `AiseeChatService.sendMessage()`, prepend result to list, clear TextField.
- **Lifecycle:** Connect socket on init, disconnect on dispose. Use `WidgetsBindingObserver` to pause/resume socket on app lifecycle.

- [ ] **Step 2: Wire navigation from ContactsTab**

In `contacts_tab.dart`, the `onTap` of each contact row should:
```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => ChatDetailScreen(
      contact: member,
      currentUserId: widget.aiseeProfile!.id,
    ),
  ),
);
```

- [ ] **Step 3: Verify no analysis errors**

- [ ] **Step 4: Commit**

```bash
git add lib/screens/chat_detail_screen.dart lib/screens/contacts_tab.dart
git commit -m "feat: implement ChatDetailScreen with real-time messaging"
```

---

## Task 9: CallScreen

**Files:**
- Create: `lib/screens/call_screen.dart`

- [ ] **Step 1: Implement CallScreen**

A `StatefulWidget` receiving `AiseeCallInfo callInfo`.

States: `ringing` → `connected` → `ended`.

Layout (voice mode):
- Full screen, navy background.
- Center: large CircleAvatar (80×80) with contact initial.
- Below avatar: contact name (20 SemiBold white).
- Below name: status text — "Đang gọi..." / duration timer "01:23" (14 Regular white).
- Bottom row: 3 circular buttons — mute mic, speaker toggle, end call (red). Size 56 each.

Layout (video mode):
- Full screen: remote video track fills screen (from LiveKit `RemoteParticipant`).
- Top-right corner: local video preview 120×160 bo 12 (from `LocalParticipant`).
- Bottom row: mute mic, flip camera, end call.
- Overlay contact name + duration at top.

LiveKit integration:
- Create `Room()`, connect with `callInfo.token` and `callInfo.url` (url from `AppEnv.liveKitWsUrl`).
- Enable mic. Enable camera if `callType == "video"`.
- Listen for `RemoteParticipant` join → set state to `connected`, start duration timer.
- Listen for room disconnect → set state to `ended`.
- End call: call `AiseeCallService.endRoom()`, disconnect room, pop navigator.

- [ ] **Step 2: Wire call buttons from ContactsTab and ChatDetailScreen**

In both screens, the call buttons should:
1. Call `AiseeCallService.createRoom()` with contact ID and call type.
2. Build `AiseeCallInfo` from response + contact.
3. Push `CallScreen` as full-screen route.

Extract shared helper function or just inline — it's only 5 lines.

- [ ] **Step 3: Verify no analysis errors**

- [ ] **Step 4: Commit**

```bash
git add lib/screens/call_screen.dart lib/screens/contacts_tab.dart lib/screens/chat_detail_screen.dart
git commit -m "feat: implement CallScreen with LiveKit voice and video"
```

---

## Task 10: FCM + CallKit integration (incoming calls)

**Files:**
- Modify: `pubspec.yaml` — add firebase_core, firebase_messaging, flutter_callkit_incoming
- Modify: `lib/main.dart` — initialize Firebase
- Create: `lib/services/aisee_push_service.dart` — FCM handler + CallKit bridge

- [ ] **Step 1: Add dependencies**

In `pubspec.yaml` dependencies section, add:
```yaml
  firebase_core: ^3.13.0
  firebase_messaging: ^15.2.6
  flutter_callkit_incoming: ^2.0.4+1
  web_socket_channel: ^3.0.2
```

Run: `flutter pub get`

**Note:** Firebase requires `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) to be configured. If these files don't exist yet, this task will set up the code but the user will need to add Firebase config files separately.

- [ ] **Step 2: Create AiseePushService**

`lib/services/aisee_push_service.dart`:

Singleton service that:
- Initializes Firebase + requests notification permission.
- Gets FCM token, uploads to backend via `AiseeFamilyService.updateProfile(accessToken, {'fcm_token': token})`.
- Listens to `FirebaseMessaging.onMessage` (foreground) and `FirebaseMessaging.onBackgroundMessage` (background).
- When receives data message with `type: "incoming_call"`:
  - Extract `caller_name`, `caller_id`, `room_name`, `call_type` from data.
  - Show incoming call UI via `flutter_callkit_incoming`:
    ```dart
    final params = CallKitParams(
      id: roomName,
      nameCaller: callerName,
      type: callType == 'video' ? 1 : 0,
      duration: 30000,
      android: const AndroidParams(isShowFullLockedScreen: true),
      ios: const IOSParams(handleType: 'generic'),
    );
    await FlutterCallkitIncoming.showCallkitIncoming(params);
    ```
- Listen to CallKit events:
  - `accepted` → navigate to CallScreen with room info.
  - `declined` → dismiss.
  - `ended` → end room via AiseeCallService.

- [ ] **Step 3: Initialize in main.dart**

In `main.dart`, after `WidgetsFlutterBinding.ensureInitialized()`:
```dart
await Firebase.initializeApp();
```

- [ ] **Step 4: Upload FCM token after login**

In `auth_shell.dart` `_completeSignInWithRole`, after profile is fetched and stored, call:
```dart
await AiseePushService.instance.initAndUploadToken(tokens.accessToken);
```

Also in `_restoreStoredSession`, after session is resumed:
```dart
await AiseePushService.instance.initAndUploadToken(resumed.tokens.accessToken);
```

- [ ] **Step 5: Verify no analysis errors**

Run: `flutter analyze --no-fatal-infos 2>&1 | tail -5`

- [ ] **Step 6: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/services/aisee_push_service.dart lib/main.dart lib/widgets/auth_shell.dart
git commit -m "feat: add FCM push + CallKit for incoming calls"
```

---

## Task 11: WebSocket lifecycle in UserHomeScreen

**Files:**
- Modify: `lib/screens/user_home_screen.dart`

- [ ] **Step 1: Add WebSocket lifecycle**

In `UserHomeScreen`, add `WidgetsBindingObserver` mixin to `_UserHomeScreenState`.

- Create `AiseeChatSocket _chatSocket` field.
- In `initState`, after LiveKit connect, also connect chat socket:
  ```dart
  final tokens = await AiseeSessionStore.instance.read();
  if (tokens != null) {
    _chatSocket.connect(tokens.accessToken);
  }
  ```
- In `didChangeAppLifecycleState`:
  - `resumed` → reconnect socket.
  - `paused` → disconnect socket.
- In `dispose` → disconnect socket.
- Pass `_chatSocket` to `ContactsTab` so it can listen for new messages to update UI.

- [ ] **Step 2: Verify no analysis errors**

- [ ] **Step 3: Commit**

```bash
git add lib/screens/user_home_screen.dart
git commit -m "feat: manage chat WebSocket lifecycle in UserHomeScreen"
```

---

## Task 12: Final integration verification

- [ ] **Step 1: Run full analysis**

```bash
cd /home/eddiesngu/Desktop/Dang/aiseeapp && flutter analyze --no-fatal-infos
```

Fix any errors.

- [ ] **Step 2: Verify app builds**

```bash
flutter build apk --debug 2>&1 | tail -10
```

- [ ] **Step 3: Final commit if any fixes needed**

```bash
git add -A
git commit -m "fix: resolve analysis errors from calling/messaging integration"
```
