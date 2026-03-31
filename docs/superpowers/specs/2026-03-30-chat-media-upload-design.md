# Chat Media Upload — Design Spec

## Overview

Add image and voice note sending to chat, backed by a reusable file upload service.

## Backend API

```
POST /api/v1/upload
Authorization: Bearer <token>
Content-Type: multipart/form-data
Field: file
Max: 10 MB
MIME: audio/*, image/jpeg, image/png, image/webp

Success: { "url": "http://minio:9000/aisee/uploads/{userId}/{ts}-{filename}" }
Error:   { "error": { "code": "file_too_large", "message": "..." } }
```

## Architecture

Three new units, each with one job:

| Unit | File | Responsibility |
|------|------|----------------|
| Upload service | `lib/services/aisee_upload_service.dart` | POST multipart file → return URL |
| Voice recorder | `lib/services/aisee_voice_recorder.dart` | Manage FlutterSoundRecorder lifecycle |
| Chat input bar | Enhanced `chat_detail_screen.dart` | UI for camera, mic, send, recording state |

### Upload Service (`aisee_upload_service.dart`)

Constructable class with optional `http.Client` (follows existing service pattern like `AiseeChatService`).

```
uploadFile(String accessToken, File file) → Future<String>
```

- Uses `http.MultipartRequest`, field name `file`.
- Pre-validates: file size ≤ 10 MB, MIME in whitelist (`audio/*`, `image/jpeg`, `image/png`, `image/webp`).
- Parses error response `{"error": {"code", "message"}}` → throws `AiseeApiException`.
- Stateless, no UI. Reusable for avatar upload later.

### Voice Recorder (`aisee_voice_recorder.dart`)

Wrapper around `FlutterSoundRecorder`.

```
start()             → begin recording to temp AAC file
stop()              → stop, return File
cancel()            → stop, delete temp file
Stream<RecordProgress> onProgress  → (Duration, double decibels) every ~50ms
dispose()           → release recorder resources
```

- Does not upload. Returns file only.
- Microphone permission already declared in AndroidManifest (for LiveKit).
- **Max duration: 120 seconds.** Auto-stops and returns file when limit reached.

### Packages

```yaml
flutter_sound: 9.16.3   # record audio
image_picker: 1.1.2     # pick/capture images
```

Existing packages used: `just_audio` (voice playback), `http` (multipart), `permission_handler`.

## Model Changes

### AiseeMessage (`lib/models/aisee_message.dart`)

Already has `voiceUrl`. Add field and update `fromJson`:

```dart
final String? imageUrl;

// In fromJson:
imageUrl: j['image_url'] as String?,
```

### aisee_chat_service.dart — sendMessage()

Add optional parameters. Keep existing positional param name `text` and return type `Future<AiseeMessage>` (unchanged):

```dart
Future<AiseeMessage> sendMessage(
  String accessToken,
  String receiverId,
  String text, {
  String? voiceUrl,
  String? imageUrl,
})
```

POST body always includes `voice_url` and `image_url` (empty string when null, for backward compatibility with backend):

```dart
body: jsonEncode({
  'receiver_id': receiverId,
  'content_text': text,
  'voice_url': voiceUrl ?? '',
  'image_url': imageUrl ?? '',
}),
```

Caller inserts returned `AiseeMessage` into the message list (existing pattern preserved).

## Chat Input Bar — UI States

### Normal state

```
┌─────────────────────────────────────────────┐
│ [+]  [  Text input field  ]  [mic/send]     │
└─────────────────────────────────────────────┘
```

- Left of text field: **attachment button** (dùng `ic_plus.svg` — vì `ic_paper.svg` đã dùng làm nút send, `ic_camera.svg` dùng cho video call ở app bar)
  - Tap → bottom sheet với 2 lựa chọn rõ ràng: "Chụp ảnh" và "Chọn từ thư viện"
  - Accessibility: mỗi option có Semantics label rõ ràng
- Right of text field:
  - Text empty → mic button (hold to record)
  - Text present → send button (existing behavior)

**Image picker config:** `ImagePicker` sử dụng `maxWidth: 1920`, `maxHeight: 1920`, `imageQuality: 80` để nén ảnh trước khi upload, tránh file quá lớn.

### Recording state (holding mic)

```
┌─────────────────────────────────────────────┐
│ 🔴 0:05   ▐▌▌▐▐▌▐▌▌▐▌▐    < Vuốt để huỷ  │
└─────────────────────────────────────────────┘
```

- Input bar transforms into recording bar.
- Left: red dot (blinking) + elapsed timer.
- Center: waveform bars animated by decibels from recorder stream.
- Right: "< Vuốt để huỷ" hint text.
- Release finger → `stop()` → upload → send message with `voice_url`.
- Swipe left > 100px → `cancel()` → return to normal state.
- Auto-stop at 120 seconds → same as release (upload + send).

**Accessibility note:** Hold-to-record + swipe-to-cancel is a complex motor gesture. This is a known tradeoff — the gesture matches user expectation from mainstream apps (Zalo, Telegram). If accessibility testing reveals issues, a follow-up iteration can add tap-to-toggle mode.

### Sending state (after pick image or release mic)

- Loading indicator on input bar until upload + send completes.
- On success: returned `AiseeMessage` inserted into message list.
- On failure: snackbar with error. User must re-pick or re-record (no automatic retry).

## Message Bubbles — Rendering Priority

When rendering a message bubble, use this priority:

1. `imageUrl` present → **image bubble** (ignore `contentText`)
2. `voiceUrl` present → **voice bubble** (ignore `contentText`)
3. Otherwise → **text bubble** (`contentText`)

A message carries only one media type. `contentText` is not used as caption for media messages.

### Voice message bubble

```
┌──────────────────────────┐
│ [▶]  ▐▌▌▐▐▌▐▌  0:12     │
└──────────────────────────┘
```

- Play/pause toggle using `just_audio`.
- Static waveform visualization.
- Duration label.

### Image message bubble

- Image with `borderRadius: 12`, constrained max width ~250px.
- Tap → full screen viewer (simple `InteractiveViewer` in a dialog/page).
- Loading placeholder while image downloads.

## Data Flow

### Send image

```
Tap attachment → bottom sheet → "Chụp ảnh" / "Chọn từ thư viện"
→ ImagePicker (maxWidth: 1920, quality: 80) → File
→ uploadService.uploadFile(token, file) → URL
→ chatService.sendMessage(token, receiverId, '', imageUrl: url)
→ returned AiseeMessage inserted into list
```

### Send voice note

```
Hold mic → recorder.start()
Release (or auto-stop at 120s) → recorder.stop() → File
→ uploadService.uploadFile(token, file) → URL
→ chatService.sendMessage(token, receiverId, '', voiceUrl: url)
→ returned AiseeMessage inserted into list
```

### Cancel voice

```
Hold mic → recorder.start()
Swipe left → recorder.cancel() → temp file deleted → return to normal
```

## Error Handling

| Scenario | Behavior |
|----------|----------|
| Image > 10 MB after compression | Snackbar "Ảnh quá lớn, tối đa 10MB" — no upload attempt |
| Upload API returns error | Snackbar with API error message — user must re-pick/re-record |
| Network lost during upload | Snackbar "Mất kết nối" — user must re-pick/re-record |
| Camera/gallery permission denied | Show permission rationale dialog via `permission_handler` |
| Microphone permission denied | Show permission rationale dialog |
| Recorder init fails | Snackbar "Không thể ghi âm", mic button disabled |
| Voice file > 10 MB (unlikely at 120s AAC) | Same as image too large — snackbar, no upload |

No retry queue. Failed uploads require the user to perform the action again. This keeps the implementation simple; a retry mechanism can be added later if needed.

## File Structure (new/modified)

```
lib/
  services/
    aisee_upload_service.dart      # NEW — file upload to backend
    aisee_voice_recorder.dart      # NEW — FlutterSound wrapper
    aisee_chat_service.dart        # MODIFIED — sendMessage params + image_url in body
  models/
    aisee_message.dart             # MODIFIED — AiseeMessage.imageUrl + fromJson
  screens/
    chat_detail_screen.dart        # MODIFIED — input bar, recording UI, bubbles
```
