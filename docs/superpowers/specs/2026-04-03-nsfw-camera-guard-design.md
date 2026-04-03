# On-device NSFW Camera Guard

## Problem

When users point the camera at sensitive/explicit content, the video frames go directly to the AI server via LiveKit. This can trigger account bans. We need client-side filtering before frames reach the server.

## Solution

Run a lightweight TFLite NSFW classifier on-device. Periodically capture frames from the local video track, classify them, and disable the camera if explicit content is detected.

## Architecture

### New files

- `lib/services/aisee_content_guard_service.dart` — periodic frame capture + TFLite inference
- `assets/models/nsfw_mobilenet.tflite` — MobileNet NSFW classifier (~2-3MB)
- `test/aisee_content_guard_service_test.dart` — unit tests

### Dependencies

- `tflite_flutter` — TFLite interpreter for Flutter
- `image` (dart package) — frame pixel decoding and resize to 224x224

### Flow

```
enable_camera RPC
  → AiseeContentGuardService.start(localVideoTrack)
  → Timer.periodic(1.5s):
      1. Capture frame from LocalVideoTrack (via frame callback)
      2. Resize to 224x224 RGB
      3. Run TFLite inference
      4. If nsfw_score > 0.7:
         - Call onUnsafeDetected callback
         - Stop timer
  → callback in LiveKitVoiceSession:
      - setCameraEnabled(false)
      - syncLocalCameraPreviewTrack()
      - Show toast: "Camera tạm tắt vì phát hiện nội dung không phù hợp"

disable_camera RPC
  → AiseeContentGuardService.stop()
```

### Integration point

In `AiseeLiveKitVoiceSession._registerRpcMethods`:

- `enable_camera`: after `setCameraEnabled(true)`, call `_contentGuard.start(track, onUnsafe: _disableCameraUnsafe)`
- `disable_camera`: call `_contentGuard.stop()` before disabling camera

### Detection logic

- Model: MobileNet-based NSFW classifier (TFLite, ~2-3MB)
- Input: 224x224x3 float32 tensor, normalized [0,1]
- Output: [sfw_score, nsfw_score] — use nsfw_score > 0.7 as threshold
- Check interval: 1.5 seconds (balance between responsiveness and CPU)

### When unsafe detected

1. Disable camera immediately (`setCameraEnabled(false)`)
2. Show toast via `AppToast`: "Camera tạm tắt vì phát hiện nội dung không phù hợp"
3. Stop the guard timer
4. User can re-enable camera through the AI assistant (which triggers `enable_camera` RPC again → guard restarts)

### Edge cases

- **Model fails to load**: Log warning, camera works without guard. Do not block user.
- **Frame capture fails**: Skip that tick, try next cycle.
- **False positive**: User asks assistant to re-enable camera. Guard restarts fresh.
- **App backgrounded**: LiveKit pauses video track. Guard timer continues but frame capture returns null — skip.
- **Multiple enable_camera calls**: `start()` stops previous timer before starting new one.

### Testing

- Unit test: mock TFLite interpreter, verify `onUnsafeDetected` fires when score > threshold
- Unit test: verify guard stops on `stop()`
- Unit test: verify guard handles model load failure gracefully
