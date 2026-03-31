# Chat Media Upload Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add image and voice note sending to chat with a reusable upload service.

**Architecture:** Three new units — upload service (multipart POST → URL), voice recorder (FlutterSound wrapper), enhanced chat input bar (attachment + hold-to-record + media bubbles). Each unit has one job and communicates through simple interfaces.

**Tech Stack:** Flutter, flutter_sound 9.16.3, image_picker 1.1.2, just_audio (existing), http (existing)

**Spec:** `docs/superpowers/specs/2026-03-30-chat-media-upload-design.md`

---

### Task 1: Add dependencies

**Files:**
- Modify: `pubspec.yaml:60-61`

- [ ] **Step 1: Add flutter_sound and image_picker to pubspec.yaml**

After the `volume_controller` line (and `flutter_tts` line), add:

```yaml
  flutter_sound: 9.16.3
  image_picker: 1.1.2
  path_provider: 2.1.5
```

- [ ] **Step 2: Run flutter pub get**

Run: `flutter pub get`
Expected: resolves without errors

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "feat: add flutter_sound and image_picker dependencies"
```

---

### Task 2: Add imageUrl to AiseeMessage model

**Files:**
- Modify: `lib/models/aisee_message.dart`

- [ ] **Step 1: Add imageUrl field to constructor and class**

In `lib/models/aisee_message.dart`, add `this.imageUrl` parameter after `this.voiceUrl`:

```dart
const AiseeMessage({
  required this.id,
  required this.senderId,
  required this.receiverId,
  this.contentText = '',
  this.voiceUrl,
  this.imageUrl,
  this.isRead = false,
  required this.createdAt,
});
```

Add the field declaration after `voiceUrl`:

```dart
final String? imageUrl;
```

- [ ] **Step 2: Update fromJson to parse image_url**

In the `fromJson` factory, add after the `voiceUrl` line:

```dart
imageUrl: j['image_url'] as String?,
```

- [ ] **Step 3: Run flutter analyze**

Run: `flutter analyze lib/models/aisee_message.dart`
Expected: no issues (callers don't require imageUrl since it's optional)

- [ ] **Step 4: Commit**

```bash
git add lib/models/aisee_message.dart
git commit -m "feat: add imageUrl field to AiseeMessage model"
```

---

### Task 3: Update sendMessage to accept voiceUrl and imageUrl

**Files:**
- Modify: `lib/services/aisee_chat_service.dart:58-80`

- [ ] **Step 1: Add optional named parameters to sendMessage**

Change the signature at line 58-61 from:

```dart
Future<AiseeMessage> sendMessage(
  String accessToken,
  String receiverId,
  String text,
) async {
```

To:

```dart
Future<AiseeMessage> sendMessage(
  String accessToken,
  String receiverId,
  String text, {
  String? voiceUrl,
  String? imageUrl,
}) async {
```

- [ ] **Step 2: Update POST body to include image_url**

Change the body at line 66-70 from:

```dart
body: jsonEncode({
  'receiver_id': receiverId,
  'content_text': text,
  'voice_url': '',
}),
```

To:

```dart
body: jsonEncode({
  'receiver_id': receiverId,
  'content_text': text,
  'voice_url': voiceUrl ?? '',
  'image_url': imageUrl ?? '',
}),
```

- [ ] **Step 3: Run flutter analyze**

Run: `flutter analyze lib/services/aisee_chat_service.dart`
Expected: no issues

- [ ] **Step 4: Commit**

```bash
git add lib/services/aisee_chat_service.dart
git commit -m "feat: add voiceUrl and imageUrl params to sendMessage"
```

---

### Task 4: Create upload service

**Files:**
- Create: `lib/services/aisee_upload_service.dart`

- [ ] **Step 1: Create the upload service**

Create `lib/services/aisee_upload_service.dart`:

```dart
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../config/app_env.dart';
import '../models/aisee_api_models.dart';

class AiseeUploadService {
  AiseeUploadService({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final http.Client _http;

  static const int _maxSizeBytes = 10 * 1024 * 1024;

  static const Set<String> _allowedMimeTypes = <String>{
    'image/jpeg',
    'image/png',
    'image/webp',
  };

  void close() => _http.close();

  /// Upload a file to the backend. Returns the public URL.
  Future<String> uploadFile(
    String accessToken,
    File file,
  ) async {
    final int fileSize = await file.length();
    if (fileSize > _maxSizeBytes) {
      throw AiseeApiException('File quá lớn, tối đa 10MB');
    }

    final String mimeType = _guessMimeType(file.path);
    if (!_isAllowedMime(mimeType)) {
      throw AiseeApiException(
        'Định dạng không được hỗ trợ: $mimeType',
      );
    }

    final Uri uri = Uri.parse('${AppEnv.apiBaseUrl}/api/v1/upload');
    final http.MultipartRequest request =
        http.MultipartRequest('POST', uri)
          ..headers['Authorization'] = 'Bearer $accessToken'
          ..files.add(
            await http.MultipartFile.fromPath('file', file.path),
          );

    final http.StreamedResponse streamedRes = await _http.send(request);
    final String bodyStr = await streamedRes.stream.bytesToString();

    if (streamedRes.statusCode != 200) {
      throw _parseError(bodyStr, streamedRes.statusCode);
    }

    final Map<String, dynamic> body =
        jsonDecode(bodyStr) as Map<String, dynamic>;
    final String? url = body['url'] as String?;
    if (url == null || url.isEmpty) {
      throw AiseeApiException('Upload thành công nhưng không có URL');
    }
    debugPrint('[AiSee:Upload] Uploaded: $url');
    return url;
  }

  static String _guessMimeType(String path) {
    final String ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'aac':
        return 'audio/aac';
      case 'm4a':
        return 'audio/mp4';
      case 'wav':
        return 'audio/wav';
      case 'mp3':
        return 'audio/mpeg';
      default:
        return 'application/octet-stream';
    }
  }

  static bool _isAllowedMime(String mime) {
    if (mime.startsWith('audio/')) return true;
    return _allowedMimeTypes.contains(mime);
  }

  AiseeApiException _parseError(String body, int statusCode) {
    try {
      final Map<String, dynamic> json =
          jsonDecode(body) as Map<String, dynamic>;
      final Map<String, dynamic>? error =
          json['error'] as Map<String, dynamic>?;
      if (error != null) {
        return AiseeApiException(
          error['message'] as String? ?? 'Upload thất bại',
          code: error['code'] as String?,
        );
      }
      return AiseeApiException(
        json['message'] as String? ?? 'Upload thất bại (HTTP $statusCode)',
      );
    } catch (_) {
      return AiseeApiException('Upload thất bại (HTTP $statusCode)');
    }
  }
}
```

- [ ] **Step 2: Run flutter analyze**

Run: `flutter analyze lib/services/aisee_upload_service.dart`
Expected: no issues

- [ ] **Step 3: Commit**

```bash
git add lib/services/aisee_upload_service.dart
git commit -m "feat: add upload service for multipart file upload"
```

---

### Task 5: Create voice recorder wrapper

**Files:**
- Create: `lib/services/aisee_voice_recorder.dart`

- [ ] **Step 1: Create the voice recorder service**

Create `lib/services/aisee_voice_recorder.dart`:

```dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

class RecordProgress {
  const RecordProgress({required this.duration, required this.decibels});
  final Duration duration;
  final double decibels;
}

class AiseeVoiceRecorder {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isInitialized = false;
  String? _currentPath;
  Timer? _autoStopTimer;

  static const int maxDurationSeconds = 120;

  final StreamController<RecordProgress> _progressController =
      StreamController<RecordProgress>.broadcast();

  Stream<RecordProgress> get onProgress => _progressController.stream;

  bool get isRecording => _recorder.isRecording;

  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;
    await _recorder.openRecorder();
    await _recorder.setSubscriptionDuration(
      const Duration(milliseconds: 50),
    );
    _isInitialized = true;
  }

  Future<void> start() async {
    await _ensureInitialized();

    final Directory tempDir =
        await path_provider.getTemporaryDirectory();
    _currentPath =
        '${tempDir.path}/aisee_voice_${DateTime.now().millisecondsSinceEpoch}.aac';

    await _recorder.startRecorder(
      toFile: _currentPath,
      codec: Codec.aacADTS,
    );

    _recorder.onProgress?.listen((RecordingDisposition event) {
      _progressController.add(RecordProgress(
        duration: event.duration,
        decibels: event.decibels ?? 0.0,
      ));
    });

    // Auto-stop after max duration.
    _autoStopTimer?.cancel();
    _autoStopTimer = Timer(
      const Duration(seconds: maxDurationSeconds),
      () {
        debugPrint('[AiSee:Recorder] Auto-stop at $maxDurationSeconds s');
        // Don't await — caller listens via callback.
        stop().then((File? file) {
          if (file != null) {
            _onAutoStop?.call(file);
          }
        });
      },
    );

    debugPrint('[AiSee:Recorder] Recording started: $_currentPath');
  }

  /// Callback for auto-stop. Set by the UI before calling start().
  void Function(File file)? _onAutoStop;
  set onAutoStop(void Function(File file)? callback) =>
      _onAutoStop = callback;

  Future<File?> stop() async {
    _autoStopTimer?.cancel();
    _autoStopTimer = null;

    if (!_recorder.isRecording) return null;

    await _recorder.stopRecorder();
    debugPrint('[AiSee:Recorder] Recording stopped: $_currentPath');

    final String? path = _currentPath;
    _currentPath = null;
    if (path == null) return null;

    final File file = File(path);
    if (await file.exists()) return file;
    return null;
  }

  Future<void> cancel() async {
    _autoStopTimer?.cancel();
    _autoStopTimer = null;

    if (_recorder.isRecording) {
      await _recorder.stopRecorder();
    }

    final String? path = _currentPath;
    _currentPath = null;
    if (path != null) {
      final File file = File(path);
      if (await file.exists()) {
        await file.delete();
        debugPrint('[AiSee:Recorder] Cancelled and deleted: $path');
      }
    }
  }

  Future<void> dispose() async {
    _autoStopTimer?.cancel();
    await _progressController.close();
    if (_isInitialized) {
      await _recorder.closeRecorder();
      _isInitialized = false;
    }
  }
}
```

- [ ] **Step 2: Run flutter analyze**

Run: `flutter analyze lib/services/aisee_voice_recorder.dart`
Expected: no issues

- [ ] **Step 3: Commit**

```bash
git add lib/services/aisee_voice_recorder.dart
git commit -m "feat: add voice recorder wrapper with auto-stop"
```

---

### Task 6: Export play/pause SVG icons from Figma

**Files:**
- Create: `assets/icons/nav/ic_play.svg`
- Create: `assets/icons/nav/ic_pause.svg`

These icons are listed in the Figma Icon Family (node `381:3605`) but not yet exported.

- [ ] **Step 1: Export icons using Figma MCP**

Use `get_design_context` with `fileKey=Z2puEDKMPEUvfZPRFw4NK7`, `nodeId=381:3605` to find Play and pause icons. Export as SVG, save to `assets/icons/nav/`. If Figma MCP is unavailable, create minimal SVG placeholders:

`ic_play.svg` — a right-pointing triangle:
```xml
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none">
  <path d="M8 5v14l11-7L8 5z" fill="#060913"/>
</svg>
```

`ic_pause.svg` — two vertical bars:
```xml
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none">
  <path d="M6 4h4v16H6V4zm8 0h4v16h-4V4z" fill="#060913"/>
</svg>
```

- [ ] **Step 2: Commit**

```bash
git add assets/icons/nav/ic_play.svg assets/icons/nav/ic_pause.svg
git commit -m "feat: add play and pause SVG icons"
```

---

### Task 7: Add media bubbles to chat (image + voice)

**Files:**
- Modify: `lib/screens/chat_detail_screen.dart:401-448` (the `_buildBubble` method)

This task adds image bubble and voice bubble renderers. The existing text bubble stays as fallback.

- [ ] **Step 1: Add imports at top of chat_detail_screen.dart**

Add these imports after the existing ones (line 1-18):

```dart
import 'package:just_audio/just_audio.dart';
import '../services/aisee_upload_service.dart';
import '../services/aisee_voice_recorder.dart';
```

- [ ] **Step 2: Replace _buildBubble with priority-based renderer**

Replace the `_buildBubble` method (lines 401-448) with:

```dart
Widget _buildBubble(AiseeMessage msg) {
  final bool isSent = msg.senderId == widget.currentUserId;
  final double maxBubbleWidth =
      MediaQuery.sizeOf(context).width * 0.75;

  Widget content;
  if (msg.imageUrl != null && msg.imageUrl!.isNotEmpty) {
    content = _buildImageContent(msg.imageUrl!, maxBubbleWidth);
  } else if (msg.voiceUrl != null && msg.voiceUrl!.isNotEmpty) {
    content = _VoiceBubbleContent(
      voiceUrl: msg.voiceUrl!,
      isSent: isSent,
    );
  } else {
    content = Text(
      msg.contentText,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: isSent
            ? StyleTokens.buttonOnPrimary
            : StyleTokens.textPrimary,
      ),
    );
  }

  return Column(
    crossAxisAlignment:
        isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
    children: <Widget>[
      Container(
        constraints: BoxConstraints(maxWidth: maxBubbleWidth),
        padding: EdgeInsets.symmetric(
          horizontal: msg.imageUrl != null ? 4 : 14,
          vertical: msg.imageUrl != null ? 4 : 10,
        ),
        decoration: BoxDecoration(
          color: isSent
              ? StyleTokens.buttonPrimary
              : StyleTokens.surfaceCard,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isSent ? 16 : 4),
            bottomRight: Radius.circular(isSent ? 4 : 16),
          ),
        ),
        child: content,
      ),
      const SizedBox(height: 4),
      Text(
        _formatTime(msg.createdAt),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w400,
          color: StyleTokens.textMuted,
        ),
      ),
    ],
  );
}

Widget _buildImageContent(String imageUrl, double maxWidth) {
  return GestureDetector(
    onTap: () => _showFullImage(imageUrl),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        imageUrl,
        width: maxWidth - 8,
        fit: BoxFit.cover,
        loadingBuilder: (
          BuildContext context,
          Widget child,
          ImageChunkEvent? loadingProgress,
        ) {
          if (loadingProgress == null) return child;
          return SizedBox(
            width: maxWidth - 8,
            height: 150,
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: StyleTokens.buttonPrimary,
              ),
            ),
          );
        },
        errorBuilder: (BuildContext context, Object e, StackTrace? st) {
          return SizedBox(
            width: maxWidth - 8,
            height: 100,
            child: Center(
              child: Text(
                'Không tải được ảnh',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: StyleTokens.textMuted,
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

void _showFullImage(String imageUrl) {
  showDialog<void>(
    context: context,
    builder: (BuildContext ctx) {
      return GestureDetector(
        onTap: () => Navigator.pop(ctx),
        child: Scaffold(
          backgroundColor: Colors.black87,
          body: Center(
            child: InteractiveViewer(
              child: Image.network(imageUrl),
            ),
          ),
        ),
      );
    },
  );
}
```

- [ ] **Step 3: Add _VoiceBubbleContent StatefulWidget at end of file**

Add this widget class at the bottom of the file (before the closing of the file, outside `_ChatDetailScreenState`):

```dart
class _RecordingDot extends StatefulWidget {
  const _RecordingDot();

  @override
  State<_RecordingDot> createState() => _RecordingDotState();
}

class _RecordingDotState extends State<_RecordingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 1.0).animate(_ctrl),
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: StyleTokens.error,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _VoiceBubbleContent extends StatefulWidget {
  const _VoiceBubbleContent({
    required this.voiceUrl,
    required this.isSent,
  });

  final String voiceUrl;
  final bool isSent;

  @override
  State<_VoiceBubbleContent> createState() => _VoiceBubbleContentState();
}

class _VoiceBubbleContentState extends State<_VoiceBubbleContent> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<PlayerState>? _stateSub;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      final Duration? d = await _player.setUrl(widget.voiceUrl);
      if (d != null && mounted) {
        setState(() => _duration = d);
      }
    } catch (e) {
      debugPrint('[AiSee:VoiceBubble] Error loading audio: $e');
    }

    _posSub = _player.positionStream.listen((Duration pos) {
      if (!mounted) return;
      setState(() => _position = pos);
    });

    _stateSub = _player.playerStateStream.listen((PlayerState state) {
      if (!mounted) return;
      setState(() => _isPlaying = state.playing);
      if (state.processingState == ProcessingState.completed) {
        _player.seek(Duration.zero);
        _player.pause();
      }
    });
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _stateSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final int mins = d.inMinutes;
    final int secs = d.inSeconds.remainder(60);
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final Color iconColor = widget.isSent
        ? StyleTokens.buttonOnPrimary
        : StyleTokens.textPrimary;
    final Color mutedColor = widget.isSent
        ? StyleTokens.buttonOnPrimary.withValues(alpha: 0.7)
        : StyleTokens.textMuted;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        GestureDetector(
          onTap: () {
            if (_isPlaying) {
              _player.pause();
            } else {
              _player.play();
            }
          },
          child: SvgPicture.asset(
            _isPlaying
                ? 'assets/icons/nav/ic_pause.svg'
                : 'assets/icons/nav/ic_play.svg',
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
          ),
        ),
        const SizedBox(width: 8),
        // Simple progress bar.
        SizedBox(
          width: 100,
          height: 4,
          child: LinearProgressIndicator(
            value: _duration.inMilliseconds > 0
                ? _position.inMilliseconds / _duration.inMilliseconds
                : 0,
            backgroundColor: mutedColor.withValues(alpha: 0.3),
            valueColor: AlwaysStoppedAnimation<Color>(iconColor),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _formatDuration(
            _isPlaying ? _position : _duration,
          ),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: mutedColor,
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Run flutter analyze**

Run: `flutter analyze lib/screens/chat_detail_screen.dart`
Expected: no issues

- [ ] **Step 5: Commit**

```bash
git add lib/screens/chat_detail_screen.dart
git commit -m "feat: add image and voice message bubble renderers"
```

---

### Task 8: Enhance chat input bar — attachment, mic/send toggle, recording UI

**Files:**
- Modify: `lib/screens/chat_detail_screen.dart` — `_buildInputBar` method and state fields

This is the largest task. It adds: attachment button (+ icon), mic/send toggle, hold-to-record gesture, recording bar with waveform, and image picking via bottom sheet.

- [ ] **Step 1: Add state fields and services to _ChatDetailScreenState**

Add these fields after the existing state fields (after line 50 `bool _callingInProgress = false;`):

```dart
// Media sending state.
bool _uploadingMedia = false;
bool _isRecording = false;
final AiseeUploadService _uploadService = AiseeUploadService();
final AiseeVoiceRecorder _voiceRecorder = AiseeVoiceRecorder();
Duration _recordDuration = Duration.zero;
double _recordDecibels = 0.0;
StreamSubscription<RecordProgress>? _recorderSub;
bool _hasText = false;
```

- [ ] **Step 2: Add _textController listener in initState**

In `initState`, after `_scrollController.addListener(_onScroll);` (line 58), add:

```dart
_textController.addListener(() {
  final bool nowHasText = _textController.text.trim().isNotEmpty;
  if (nowHasText != _hasText) {
    setState(() => _hasText = nowHasText);
  }
});
```

- [ ] **Step 3: Update dispose to clean up new resources**

In `dispose`, before `_chatService.close();` (line 71), add:

```dart
_recorderSub?.cancel();
_voiceRecorder.dispose();
_uploadService.close();
```

- [ ] **Step 4: Add image picker import and _pickImage method**

Add imports at top:

```dart
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
```

Add method after `_sendMessage()`:

```dart
void _showAttachmentSheet() {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (BuildContext ctx) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        decoration: BoxDecoration(
          color: StyleTokens.surfaceCard,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: StyleTokens.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _attachOption(
              ctx,
              icon: 'assets/icons/nav/ic_camera.svg',
              label: 'Chụp ảnh',
              semanticsLabel: 'Chụp ảnh bằng camera',
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: 8),
            _attachOption(
              ctx,
              icon: 'assets/icons/nav/ic_category.svg',
              label: 'Chọn từ thư viện',
              semanticsLabel: 'Chọn ảnh từ thư viện',
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      );
    },
  );
}

Widget _attachOption(
  BuildContext ctx, {
  required String icon,
  required String label,
  required String semanticsLabel,
  required VoidCallback onTap,
}) {
  return Semantics(
    button: true,
    label: semanticsLabel,
    child: Material(
      color: StyleTokens.background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          child: Row(
            children: <Widget>[
              SvgPicture.asset(
                icon,
                width: 20,
                height: 20,
                colorFilter: const ColorFilter.mode(
                  StyleTokens.textPrimary,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: StyleTokens.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> _pickImage(ImageSource source) async {
  if (source == ImageSource.camera) {
    final PermissionStatus status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        AppToast.snack(
          context,
          'Cần quyền camera để chụp ảnh.',
          isError: true,
        );
      }
      return;
    }
  }
  final ImagePicker picker = ImagePicker();
  final XFile? picked = await picker.pickImage(
    source: source,
    maxWidth: 1920,
    maxHeight: 1920,
    imageQuality: 80,
  );
  if (picked == null || !mounted) return;
  await _uploadAndSend(File(picked.path), isImage: true);
}
```

- [ ] **Step 5: Add _uploadAndSend and _startRecording / _stopRecording methods**

```dart
Future<void> _uploadAndSend(
  File file, {
  required bool isImage,
}) async {
  if (_uploadingMedia) return;
  setState(() => _uploadingMedia = true);

  final AiseeAuthTokens? tokens =
      await AiseeSessionStore.instance.read();
  if (tokens == null) {
    if (mounted) setState(() => _uploadingMedia = false);
    return;
  }

  try {
    final String url = await _uploadService.uploadFile(
      tokens.accessToken,
      file,
    );
    final AiseeMessage msg = await _chatService.sendMessage(
      tokens.accessToken,
      widget.contact.id,
      '',
      voiceUrl: isImage ? null : url,
      imageUrl: isImage ? url : null,
    );
    if (!mounted) return;
    setState(() {
      _messages.insert(0, msg);
      _uploadingMedia = false;
    });
  } catch (e) {
    if (!mounted) return;
    setState(() => _uploadingMedia = false);
    AppToast.snack(
      context,
      e is AiseeApiException ? e.message : 'Gửi không thành công.',
      isError: true,
    );
  }
}

Future<void> _startRecording() async {
  final PermissionStatus micStatus =
      await Permission.microphone.request();
  if (!micStatus.isGranted) {
    if (mounted) {
      AppToast.snack(
        context,
        'Cần quyền microphone để ghi âm.',
        isError: true,
      );
    }
    return;
  }
  HapticFeedback.mediumImpact();
  try {
    _voiceRecorder.onAutoStop = (File file) {
      if (mounted) {
        setState(() => _isRecording = false);
        _uploadAndSend(file, isImage: false);
      }
    };
    _recorderSub?.cancel();
    _recorderSub = _voiceRecorder.onProgress.listen(
      (RecordProgress p) {
        if (!mounted) return;
        setState(() {
          _recordDuration = p.duration;
          _recordDecibels = p.decibels;
        });
      },
    );
    await _voiceRecorder.start();
    if (mounted) setState(() => _isRecording = true);
  } catch (e) {
    if (mounted) {
      AppToast.snack(context, 'Không thể ghi âm.', isError: true);
    }
  }
}

Future<void> _stopRecording() async {
  _recorderSub?.cancel();
  final File? file = await _voiceRecorder.stop();
  if (!mounted) return;
  setState(() => _isRecording = false);
  if (file != null) {
    await _uploadAndSend(file, isImage: false);
  }
}

Future<void> _cancelRecording() async {
  _recorderSub?.cancel();
  await _voiceRecorder.cancel();
  if (mounted) {
    setState(() {
      _isRecording = false;
      _recordDuration = Duration.zero;
      _recordDecibels = 0.0;
    });
  }
}
```

- [ ] **Step 6: Replace _buildInputBar with new version**

Replace the entire `_buildInputBar` method (lines 451-536) with:

```dart
Widget _buildInputBar() {
  return Container(
    decoration: const BoxDecoration(
      color: StyleTokens.surfaceCard,
      border: Border(
        top: BorderSide(color: StyleTokens.cardBorder),
      ),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: SafeArea(
      top: false,
      child: _isRecording
          ? _buildRecordingBar()
          : _uploadingMedia
              ? _buildUploadingBar()
              : _buildNormalInputBar(),
    ),
  );
}

Widget _buildNormalInputBar() {
  return Row(
    children: <Widget>[
      // Attachment button.
      Semantics(
        button: true,
        label: 'Đính kèm ảnh',
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _showAttachmentSheet,
            child: SizedBox(
              width: 36,
              height: 36,
              child: Center(
                child: SvgPicture.asset(
                  'assets/icons/nav/ic_plus.svg',
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    StyleTokens.textMuted,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(width: 4),
      Expanded(
        child: TextField(
          controller: _textController,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: StyleTokens.textPrimary,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: StyleTokens.surfaceCard,
            hintText: 'Nhắn tin...',
            hintStyle: StyleTokens.inputHint(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: const BorderSide(
                color: StyleTokens.cardBorder,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: const BorderSide(
                color: StyleTokens.cardBorder,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: const BorderSide(
                color: StyleTokens.buttonPrimary,
              ),
            ),
          ),
          textInputAction: TextInputAction.send,
          onSubmitted: (_) => _sendMessage(),
        ),
      ),
      const SizedBox(width: 8),
      _hasText ? _buildSendButton() : _buildMicButton(),
    ],
  );
}

Widget _buildSendButton() {
  return Semantics(
    button: true,
    label: 'Gửi tin nhắn',
    child: Material(
      color: StyleTokens.buttonPrimary,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _sendMessage,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Center(
            child: SvgPicture.asset(
              'assets/icons/nav/ic_paper.svg',
              width: 16,
              height: 16,
              colorFilter: const ColorFilter.mode(
                StyleTokens.buttonOnPrimary,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _buildMicButton() {
  return GestureDetector(
    onLongPressStart: (_) => _startRecording(),
    onLongPressEnd: (LongPressEndDetails details) {
      if (details.localPosition.dx < -100) {
        _cancelRecording();
      } else {
        _stopRecording();
      }
    },
    child: Semantics(
      button: true,
      label: 'Giữ để ghi âm',
      child: Material(
        color: StyleTokens.buttonPrimary,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Center(
            child: SvgPicture.asset(
              'assets/icons/nav/ic_voice.svg',
              width: 16,
              height: 16,
              colorFilter: const ColorFilter.mode(
                StyleTokens.buttonOnPrimary,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _buildRecordingBar() {
  final String mins =
      _recordDuration.inMinutes.toString();
  final String secs =
      (_recordDuration.inSeconds.remainder(60))
          .toString()
          .padLeft(2, '0');

  return Row(
    children: <Widget>[
      // Blinking red dot — use _RecordingDot for repeating animation.
      const _RecordingDot(),
      const SizedBox(width: 8),
      Text(
        '$mins:$secs',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: StyleTokens.textPrimary,
        ),
      ),
      const SizedBox(width: 12),
      // Simple waveform bars.
      Expanded(child: _buildWaveform()),
      const SizedBox(width: 12),
      Text(
        '< Vuốt để huỷ',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: StyleTokens.textMuted,
        ),
      ),
    ],
  );
}

Widget _buildWaveform() {
  // Generate 20 bars from decibels.
  final double normalizedDb =
      ((_recordDecibels + 40) / 60).clamp(0.0, 1.0);
  return SizedBox(
    height: 24,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List<Widget>.generate(20, (int i) {
        final double height =
            4 + (normalizedDb * 20 * ((i % 3 + 1) / 3));
        return AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width: 3,
          height: height,
          decoration: BoxDecoration(
            color: StyleTokens.buttonPrimary,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    ),
  );
}

Widget _buildUploadingBar() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: <Widget>[
      const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: StyleTokens.buttonPrimary,
        ),
      ),
      const SizedBox(width: 12),
      Text(
        'Đang gửi...',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: StyleTokens.textMuted,
        ),
      ),
    ],
  );
}
```

- [ ] **Step 7: Run flutter analyze on the full file**

Run: `flutter analyze lib/screens/chat_detail_screen.dart`
Expected: no issues

- [ ] **Step 8: Commit**

```bash
git add lib/screens/chat_detail_screen.dart
git commit -m "feat: add attachment button, mic recording, and media input bar"
```

---

### Task 9: Full build verification

- [ ] **Step 1: Run full project analysis**

Run: `flutter analyze`
Expected: no issues

- [ ] **Step 2: Verify the build compiles**

Run: `flutter build apk --debug 2>&1 | tail -5`
Expected: build succeeds

- [ ] **Step 3: Final commit if any fixes were needed**

If any fixes were applied, commit them:

```bash
git add -A
git commit -m "fix: resolve build issues from chat media integration"
```
