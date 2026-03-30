# Calling & Messaging Feature Design

## Overview

Add family calling (voice/video via LiveKit) and text messaging to AiSee.
Tab 2 "Công cụ" becomes "Liên lạc" — conversations list with call buttons.
Voice messages deferred (no upload endpoint yet).

## Navigation

3 tabs (unchanged count, tab 2 replaced):

| # | Label | Icon | Content |
|---|-------|------|---------|
| 1 | Trợ lý | ic_wave.svg | AI voice assistant (unchanged) |
| 2 | Liên lạc | ic_3user.svg | Family contacts, chat, calling |
| 3 | Cá nhân | ic_profile.svg | Reminders, health (remove message placeholder) |

Delete: `user_tools_tab.dart` and all camera-tool references.

## Screens

### ContactsTab (tab 2)
- Header: "Liên lạc" + invite button (family-link)
- List from `GET /users/me/family`
- Each row: avatar, name, last message preview, time, unread badge
- Tap row → ChatDetailScreen
- Long-press or trailing icons: voice call, video call

### ChatDetailScreen
- AppBar: contact name + voice call button + video call button
- Message list: infinite scroll via `GET /messages/{contactID}?limit=50&before={id}`
- Messages grouped by date
- Input bar: TextField + send button
- Real-time via WebSocket
- Auto mark-read when viewing (`PUT /messages/{id}/read`)

### CallScreen (shared for outgoing + incoming)
- Full-screen overlay (pushed as route, not tab)
- States: ringing → connected → ended
- Voice mode: contact avatar + name + duration timer + mute/speaker/end buttons
- Video mode: remote video full-screen + local video PiP corner + mute/camera-flip/end buttons
- Uses LiveKit Room for media

### IncomingCallScreen
- Triggered by FCM/VOIP push → CallKit (iOS) / ConnectionService (Android)
- Shows caller name + avatar + accept/decline buttons
- Accept → join LiveKit room → CallScreen

## Services

### AiseeFamilyService (`lib/services/aisee_family_service.dart`)
- `fetchFamily(accessToken)` → `List<AiseeFamilyMember>` — GET /users/me/family
- `createInvite(accessToken, relationship)` → invite code — POST /users/family-link
- `joinFamily(accessToken, inviteCode)` — POST /users/join-family
- `deleteLink(accessToken, linkId)` — DELETE /users/family-link/{linkId}
- `updateProfile(accessToken, fields)` — PUT /users/me (FCM/APNs tokens, etc.)

### AiseeChatService (`lib/services/aisee_chat_service.dart`)
- `fetchMessages(accessToken, contactId, {limit, before})` → `List<AiseeMessage>`
- `sendMessage(accessToken, receiverId, text)` → `AiseeMessage`
- `markRead(accessToken, messageId)` → void
- `fetchUnreadCount(accessToken)` → int

### AiseeChatSocket (`lib/services/aisee_chat_socket.dart`)
- Connects to `GET /ws/chat?token=<jwt>` via dart:io WebSocket
- Exposes `Stream<AiseeMessage>` for new messages
- Auto-reconnect with exponential backoff (1s → 2s → 4s → max 30s)
- Lifecycle: connect on app foreground, close on background (WidgetsBindingObserver)
- Reconnect on token refresh

### AiseeCallService (`lib/services/aisee_call_service.dart`)
- `createRoom(accessToken, calleeId, callType)` → `{roomName, token}`
- `endRoom(accessToken, roomName)` → void
- Manages LiveKit Room for family calls (separate from AI agent session)
- Handles CallKit/ConnectionService integration

## Models

### AiseeFamilyMember (`lib/models/aisee_family_member.dart`)
```dart
class AiseeFamilyMember {
  final String id;
  final String email;
  final String? displayName;
  final String role;
  final String? avatarUrl;
}
```

### AiseeMessage (`lib/models/aisee_message.dart`)
```dart
class AiseeMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String contentText;
  final String? voiceUrl;
  final bool isRead;
  final DateTime createdAt;
}
```

### AiseeCallInfo (`lib/models/aisee_call_info.dart`)
```dart
class AiseeCallInfo {
  final String roomName;
  final String token;
  final String callType; // "voice" | "video"
  final AiseeFamilyMember contact;
}
```

## API Endpoints Used

| Method | Path | Service |
|--------|------|---------|
| GET | /api/v1/users/me/family | AiseeFamilyService |
| POST | /api/v1/users/family-link | AiseeFamilyService |
| POST | /api/v1/users/join-family | AiseeFamilyService |
| DELETE | /api/v1/users/family-link/{id} | AiseeFamilyService |
| PUT | /api/v1/users/me | AiseeFamilyService |
| GET | /api/v1/messages/{contactID} | AiseeChatService |
| POST | /api/v1/messages/send | AiseeChatService |
| PUT | /api/v1/messages/{id}/read | AiseeChatService |
| GET | /api/v1/messages/unread-count | AiseeChatService |
| WS | /api/v1/ws/chat?token= | AiseeChatSocket |
| POST | /api/v1/calls/create-room | AiseeCallService |
| POST | /api/v1/calls/end-room | AiseeCallService |

## Error Handling

All services parse error response: `{"error": "code", "message": "..."}`.
Reuse existing `AiseeApiException` pattern from `AiseeAuthService`.
401 responses trigger token refresh via `AiseeAuthService.refreshTokens()`.

## WebSocket Lifecycle

1. App starts → after auth → connect WebSocket
2. App goes background → close WebSocket (FCM handles push)
3. App returns foreground → reconnect WebSocket
4. Token refreshed → reconnect with new token
5. Connection lost → exponential backoff reconnect

## CallKit / ConnectionService

- iOS: `flutter_callkit_incoming` package for CallKit integration
- Android: same package handles ConnectionService
- FCM data message with `type: "incoming_call"` → show native call UI
- User accepts → fetch LiveKit token (reuse from push data) → join room
- User declines → dismiss

## Dependencies to Add

- `flutter_callkit_incoming` — CallKit/ConnectionService
- `firebase_messaging` — FCM push notifications
- `firebase_core` — Firebase init
- `web_socket_channel` — WebSocket client (cross-platform)

## Out of Scope (deferred)

- Voice message recording + upload (no upload endpoint)
- Read receipts beyond single mark-read
- Typing indicators
- Group chat
- Call history screen
