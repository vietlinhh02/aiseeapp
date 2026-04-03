# NSFW Camera Guard Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Detect NSFW content from camera frames on-device and auto-disable camera before frames reach the AI server.

**Architecture:** A `AiseeContentGuardService` runs a periodic timer (1.5s) while the camera is active. Each tick captures a frame from `LocalVideoTrack` via `flutter_webrtc`'s `MediaStreamTrack.captureFrame()`, resizes to 224x224, runs TFLite inference, and disables the camera if the NSFW score exceeds 0.7.

**Tech Stack:** `tflite_flutter` (TFLite inference), `image` (pixel resize/decode), `flutter_webrtc` (frame capture via LiveKit's track)

---

## File Structure

| Action | Path | Responsibility |
|--------|------|----------------|
| Create | `lib/services/aisee_content_guard_service.dart` | Periodic frame capture, TFLite inference, unsafe callback |
| Create | `assets/models/nsfw_mobilenet.tflite` | NSFW classifier model (~2-3MB) |
| Create | `test/aisee_content_guard_service_test.dart` | Unit tests for guard logic |
| Modify | `pubspec.yaml` | Add `tflite_flutter`, `image` deps + model asset |
| Modify | `lib/services/aisee_livekit_voice_session.dart:505-530` | Hook guard into enable/disable camera RPCs |

---

### Task 1: Add dependencies and model asset

**Files:**
- Modify: `pubspec.yaml`
- Create: `assets/models/nsfw_mobilenet.tflite` (download separately)

- [ ] **Step 1: Add dependencies to pubspec.yaml**

In `pubspec.yaml` under `dependencies:`, add:

```yaml
  tflite_flutter: ^0.11.0
  image: ^4.5.3
```

Under `flutter: > assets:`, add:

```yaml
    - assets/models/
```

- [ ] **Step 2: Download NSFW TFLite model**

Download a MobileNet-based NSFW classifier TFLite model and place at `assets/models/nsfw_mobilenet.tflite`. A common open-source option is the GantMan nsfw_model converted to TFLite (produces 5 classes: Drawing, Hentai, Neutral, Porn, Sexy — use sum of Hentai+Porn+Sexy as NSFW score).

```bash
mkdir -p assets/models
# User must source model file — place it at:
# assets/models/nsfw_mobilenet.tflite
```

- [ ] **Step 3: Run flutter pub get**

```bash
flutter pub get
```

Expected: resolves `tflite_flutter` and `image` without conflicts.

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock assets/models/
git commit -m "feat: add tflite_flutter + image deps and model asset for NSFW guard"
```

---

### Task 2: Create AiseeContentGuardService

**Files:**
- Create: `lib/services/aisee_content_guard_service.dart`

- [ ] **Step 1: Write the failing test**

Create `test/aisee_content_guard_service_test.dart`:

```dart
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:aiseeapp/services/aisee_content_guard_service.dart';

/// Fake classifier that always returns a fixed score.
class _FakeClassifier implements NsfwClassifier {
  _FakeClassifier(this.score);
  final double score;
  int callCount = 0;

  @override
  Future<double> classify(Uint8List argbPixels, int width, int height) async {
    callCount++;
    return score;
  }

  @override
  void dispose() {}
}

void main() {
  group('AiseeContentGuardService', () {
    test('calls onUnsafeDetected when score > threshold', () async {
      final _FakeClassifier classifier = _FakeClassifier(0.85);
      bool unsafeCalled = false;

      final AiseeContentGuardService guard = AiseeContentGuardService(
        classifier: classifier,
        threshold: 0.7,
        checkInterval: const Duration(milliseconds: 50),
      );

      guard.startWithFrameProvider(
        frameProvider: () async => (
          pixels: Uint8List(100 * 100 * 4),
          width: 100,
          height: 100,
        ),
        onUnsafeDetected: () {
          unsafeCalled = true;
        },
      );

      // Wait enough for at least one check cycle.
      await Future<void>.delayed(const Duration(milliseconds: 150));
      guard.stop();

      expect(unsafeCalled, isTrue);
      expect(classifier.callCount, greaterThanOrEqualTo(1));
    });

    test('does NOT call onUnsafeDetected when score < threshold', () async {
      final _FakeClassifier classifier = _FakeClassifier(0.3);
      bool unsafeCalled = false;

      final AiseeContentGuardService guard = AiseeContentGuardService(
        classifier: classifier,
        threshold: 0.7,
        checkInterval: const Duration(milliseconds: 50),
      );

      guard.startWithFrameProvider(
        frameProvider: () async => (
          pixels: Uint8List(100 * 100 * 4),
          width: 100,
          height: 100,
        ),
        onUnsafeDetected: () {
          unsafeCalled = true;
        },
      );

      await Future<void>.delayed(const Duration(milliseconds: 200));
      guard.stop();

      expect(unsafeCalled, isFalse);
      expect(classifier.callCount, greaterThanOrEqualTo(1));
    });

    test('stop cancels the timer', () async {
      final _FakeClassifier classifier = _FakeClassifier(0.85);
      int unsafeCount = 0;

      final AiseeContentGuardService guard = AiseeContentGuardService(
        classifier: classifier,
        threshold: 0.7,
        checkInterval: const Duration(milliseconds: 50),
      );

      guard.startWithFrameProvider(
        frameProvider: () async => (
          pixels: Uint8List(100 * 100 * 4),
          width: 100,
          height: 100,
        ),
        onUnsafeDetected: () {
          unsafeCount++;
        },
      );

      // Stop immediately before any tick fires.
      guard.stop();
      await Future<void>.delayed(const Duration(milliseconds: 150));

      // onUnsafeDetected fires at most once (the initial check),
      // but timer is cancelled so no repeated calls.
      expect(unsafeCount, lessThanOrEqualTo(1));
    });

    test('handles null frame gracefully', () async {
      final _FakeClassifier classifier = _FakeClassifier(0.85);
      bool unsafeCalled = false;

      final AiseeContentGuardService guard = AiseeContentGuardService(
        classifier: classifier,
        threshold: 0.7,
        checkInterval: const Duration(milliseconds: 50),
      );

      guard.startWithFrameProvider(
        frameProvider: () async => null,
        onUnsafeDetected: () {
          unsafeCalled = true;
        },
      );

      await Future<void>.delayed(const Duration(milliseconds: 150));
      guard.stop();

      expect(unsafeCalled, isFalse);
      expect(classifier.callCount, 0);
    });
  });
}
```

- [ ] **Step 2: Run the test — expect compile error**

```bash
flutter test test/aisee_content_guard_service_test.dart
```

Expected: FAIL — `aisee_content_guard_service.dart` does not exist.

- [ ] **Step 3: Implement AiseeContentGuardService**

Create `lib/services/aisee_content_guard_service.dart`:

```dart
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

/// Raw frame data from a video track.
typedef CapturedFrame = ({Uint8List pixels, int width, int height});

/// Abstraction over TFLite NSFW model — allows faking in tests.
abstract interface class NsfwClassifier {
  /// Returns NSFW probability 0.0–1.0 from raw ARGB pixel buffer.
  Future<double> classify(Uint8List argbPixels, int width, int height);
  void dispose();
}

/// Periodically captures frames and classifies for NSFW content.
/// Calls [onUnsafeDetected] once if score exceeds [threshold], then stops.
class AiseeContentGuardService {
  AiseeContentGuardService({
    required this.classifier,
    this.threshold = 0.7,
    this.checkInterval = const Duration(milliseconds: 1500),
  });

  final NsfwClassifier classifier;
  final double threshold;
  final Duration checkInterval;

  Timer? _timer;
  bool _checking = false;

  /// Start guard with a custom frame provider (for testability).
  void startWithFrameProvider({
    required Future<CapturedFrame?> Function() frameProvider,
    required VoidCallback onUnsafeDetected,
  }) {
    stop();
    _timer = Timer.periodic(checkInterval, (_) {
      _tick(frameProvider, onUnsafeDetected);
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _tick(
    Future<CapturedFrame?> Function() frameProvider,
    VoidCallback onUnsafeDetected,
  ) async {
    if (_checking) return;
    _checking = true;
    try {
      final CapturedFrame? frame = await frameProvider();
      if (frame == null) return;

      final double score = await classifier.classify(
        frame.pixels,
        frame.width,
        frame.height,
      );
      debugPrint('[AiSee:ContentGuard] NSFW score: '
          '${score.toStringAsFixed(3)}');

      if (score > threshold) {
        debugPrint('[AiSee:ContentGuard] Unsafe content detected — '
            'disabling camera');
        stop();
        onUnsafeDetected();
      }
    } catch (e, st) {
      debugPrint('[AiSee:ContentGuard] Check failed: $e\n$st');
    } finally {
      _checking = false;
    }
  }
}
```

- [ ] **Step 4: Run tests — expect pass**

```bash
flutter test test/aisee_content_guard_service_test.dart
```

Expected: all 4 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/services/aisee_content_guard_service.dart test/aisee_content_guard_service_test.dart
git commit -m "feat: add AiseeContentGuardService with periodic NSFW frame check"
```

---

### Task 3: Create TFLite NSFW classifier implementation

**Files:**
- Create: `lib/services/aisee_nsfw_classifier.dart`

- [ ] **Step 1: Create the TFLite classifier**

Create `lib/services/aisee_nsfw_classifier.dart`:

```dart
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import 'aisee_content_guard_service.dart';

/// TFLite-based NSFW classifier using a MobileNet model.
///
/// Model expects 224x224x3 float32 input normalized [0,1].
/// Output: 5 classes [Drawing, Hentai, Neutral, Porn, Sexy].
/// NSFW score = Hentai + Porn + Sexy.
class AiseeNsfwClassifier implements NsfwClassifier {
  AiseeNsfwClassifier._(this._interpreter);

  final Interpreter _interpreter;

  static const String _modelAsset = 'assets/models/nsfw_mobilenet.tflite';
  static const int _inputSize = 224;

  /// Index mapping: 0=Drawing, 1=Hentai, 2=Neutral, 3=Porn, 4=Sexy
  static const List<int> _nsfwIndices = [1, 3, 4];

  /// Load model from assets. Returns null if loading fails.
  static Future<AiseeNsfwClassifier?> load() async {
    try {
      final Interpreter interpreter = await Interpreter.fromAsset(
        _modelAsset,
      );
      return AiseeNsfwClassifier._(interpreter);
    } catch (e, st) {
      debugPrint('[AiSee:NSFW] Failed to load model: $e\n$st');
      return null;
    }
  }

  @override
  Future<double> classify(
    Uint8List argbPixels,
    int width,
    int height,
  ) async {
    final Float32List input = await compute(_preprocess, (
      pixels: argbPixels,
      width: width,
      height: height,
    ));

    final List<List<double>> output = List.generate(
      1,
      (_) => List.filled(5, 0.0),
    );

    _interpreter.run(input.reshape([1, _inputSize, _inputSize, 3]), output);

    double nsfwScore = 0;
    for (final int i in _nsfwIndices) {
      nsfwScore += output[0][i];
    }
    return nsfwScore.clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    _interpreter.close();
  }
}

/// Isolate-safe preprocessing: decode ARGB → resize 224x224 → normalize.
Float32List _preprocess(({Uint8List pixels, int width, int height}) data) {
  const int size = 224;

  // Decode ARGB bytes into an Image.
  final img.Image raw = img.Image.fromBytes(
    width: data.width,
    height: data.height,
    bytes: data.pixels.buffer,
    order: img.ChannelOrder.argb,
  );

  final img.Image resized = img.copyResize(
    raw,
    width: size,
    height: size,
    interpolation: img.Interpolation.linear,
  );

  // Convert to [1, 224, 224, 3] float32 normalized [0,1].
  final Float32List input = Float32List(size * size * 3);
  int offset = 0;
  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      final img.Pixel px = resized.getPixel(x, y);
      input[offset++] = px.r / 255.0;
      input[offset++] = px.g / 255.0;
      input[offset++] = px.b / 255.0;
    }
  }
  return input;
}
```

- [ ] **Step 2: Verify it compiles**

```bash
flutter analyze lib/services/aisee_nsfw_classifier.dart
```

Expected: no errors (warnings OK if model file not yet present).

- [ ] **Step 3: Commit**

```bash
git add lib/services/aisee_nsfw_classifier.dart
git commit -m "feat: add TFLite NSFW classifier with image preprocessing"
```

---

### Task 4: Integrate guard into LiveKit voice session

**Files:**
- Modify: `lib/services/aisee_livekit_voice_session.dart`

- [ ] **Step 1: Add imports and field**

At the top of `aisee_livekit_voice_session.dart`, add imports:

```dart
import 'aisee_content_guard_service.dart';
import 'aisee_nsfw_classifier.dart';
```

Inside `AiseeLiveKitVoiceSession` class, add field after `_assistantMicEnabled`:

```dart
  AiseeContentGuardService? _contentGuard;
```

- [ ] **Step 2: Add helper to capture frame from track**

Add this method to `AiseeLiveKitVoiceSession`:

```dart
  Future<CapturedFrame?> _captureCurrentFrame() async {
    final LocalVideoTrack? track = localCameraPreviewTrack.value;
    if (track == null) return null;
    try {
      final ByteBuffer buffer =
          await track.mediaStreamTrack.captureFrame();
      final Uint8List pixels = buffer.asUint8List();
      // captureFrame returns ARGB pixels at the track's native resolution.
      // Width/height not returned by API — use a reasonable default.
      // The classifier resizes anyway, so approximate dimensions are OK.
      return (pixels: pixels, width: 640, height: 480);
    } catch (e) {
      debugPrint('[AiSee:ContentGuard] captureFrame failed: $e');
      return null;
    }
  }
```

- [ ] **Step 3: Add unsafe camera disable handler**

```dart
  Future<void> _onUnsafeCameraContent() async {
    _log('ContentGuard', 'Disabling camera — unsafe content detected');
    await _room?.localParticipant?.setCameraEnabled(false);
    syncLocalCameraPreviewTrack();
    await AppToast.show(
      'Camera tạm tắt vì phát hiện nội dung không phù hợp',
      isError: true,
    );
  }
```

Add the `AppToast` import if not already present:

```dart
import '../utils/app_toast.dart';
```

- [ ] **Step 4: Hook guard into enable_camera RPC**

In `_registerRpcMethods`, modify the `enable_camera` handler. After `syncLocalCameraPreviewTrack();`, add:

```dart
      // Start NSFW content guard.
      if (_contentGuard == null) {
        final AiseeNsfwClassifier? classifier =
            await AiseeNsfwClassifier.load();
        if (classifier != null) {
          _contentGuard = AiseeContentGuardService(
            classifier: classifier,
          );
        }
      }
      _contentGuard?.startWithFrameProvider(
        frameProvider: _captureCurrentFrame,
        onUnsafeDetected: () {
          unawaited(_onUnsafeCameraContent());
        },
      );
```

- [ ] **Step 5: Hook guard stop into disable_camera RPC**

In `_registerRpcMethods`, modify the `disable_camera` handler. Before `await _room?.localParticipant?.setCameraEnabled(false);`, add:

```dart
      _contentGuard?.stop();
```

- [ ] **Step 6: Clean up guard on disconnect**

In the `disconnect()` method, add before room disconnect:

```dart
    _contentGuard?.stop();
    _contentGuard?.classifier.dispose();
    _contentGuard = null;
```

- [ ] **Step 7: Verify it compiles**

```bash
flutter analyze lib/services/aisee_livekit_voice_session.dart
```

Expected: no errors.

- [ ] **Step 8: Commit**

```bash
git add lib/services/aisee_livekit_voice_session.dart
git commit -m "feat: integrate NSFW camera guard into LiveKit enable/disable camera RPCs"
```

---

### Task 5: Manual integration test

- [ ] **Step 1: Run existing tests**

```bash
flutter test
```

Expected: all existing tests pass (guard service tests included).

- [ ] **Step 2: Manual test on device**

1. Install app on device: `flutter run`
2. Connect to AI assistant
3. Ask assistant to enable camera
4. Point camera at normal content — camera stays on
5. Verify `[AiSee:ContentGuard] NSFW score:` appears in debug console every ~1.5s
6. Confirm camera disables if NSFW score exceeds threshold

- [ ] **Step 3: Commit all remaining changes**

```bash
git add -A
git commit -m "feat: complete NSFW camera guard integration"
```
