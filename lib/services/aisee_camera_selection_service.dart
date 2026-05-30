import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';

/// Camera usage modes with different lens/resolution requirements.
enum CameraMode {
  /// OCR reading text/labels — needs standard wide, high resolution, autofocus.
  agentVisionTextReading,

  /// Object detection — needs standard wide camera.
  agentVisionObject,

  /// Support volunteer looking through camera — needs back camera.
  supportLookThrough,

  /// Family face-to-face call — front camera by default.
  familyFaceCall,

  /// Emergency SOS — back camera to show surroundings.
  emergencySOS,
}

/// Selects the best camera for each use case, avoiding ultra-wide/fisheye
/// lenses that distort text and make OCR inaccurate.
class AiseeCameraSelectionService {
  AiseeCameraSelectionService._();

  /// Select the best back camera for Agent vision/OCR.
  ///
  /// Preference order:
  /// 1. Standard wide back camera (not ultra-wide)
  /// 2. Any back camera if only one exists
  /// 3. First available camera as fallback
  static Future<CameraDescription?> selectForAgentVision() async {
    final List<CameraDescription> cameras = await availableCameras();
    if (cameras.isEmpty) return null;

    final List<CameraDescription> backCameras = cameras
        .where((CameraDescription c) =>
            c.lensDirection == CameraLensDirection.back)
        .toList();

    if (backCameras.isEmpty) {
      debugPrint('[AiSee:Camera] No back camera found, using first camera');
      return cameras.first;
    }

    if (backCameras.length == 1) {
      debugPrint(
          '[AiSee:Camera] Single back camera: ${backCameras.first.name}');
      return backCameras.first;
    }

    // Multiple back cameras — try to skip ultra-wide.
    for (final CameraDescription cam in backCameras) {
      if (!_isLikelyUltraWide(cam.name)) {
        debugPrint(
            '[AiSee:Camera] Selected standard back camera: ${cam.name}');
        return cam;
      }
    }

    // All cameras look like ultra-wide (unusual) — use first back camera.
    debugPrint(
        '[AiSee:Camera] All back cameras flagged as ultra-wide, '
        'using first: ${backCameras.first.name}');
    return backCameras.first;
  }

  /// Select camera for video call with a support volunteer.
  ///
  /// Back camera so volunteer can see the user's surroundings.
  static Future<CameraDescription?> selectForSupportCall() async {
    return selectForAgentVision(); // Same logic: back standard camera.
  }

  /// Select camera for family face call.
  ///
  /// Front camera by default (like FaceTime).
  static Future<CameraDescription?> selectForFamilyFaceCall() async {
    final List<CameraDescription> cameras = await availableCameras();
    if (cameras.isEmpty) return null;

    return cameras.firstWhere(
      (CameraDescription c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
  }

  /// Create a CameraController optimized for OCR text reading.
  ///
  /// Uses high resolution (1080p) for better text recognition.
  static Future<CameraController> createOCRController(
    CameraDescription camera,
  ) async {
    final CameraController controller = CameraController(
      camera,
      ResolutionPreset.high, // 1080p for OCR accuracy.
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    await controller.initialize();

    // Enable continuous autofocus for text reading.
    try {
      await controller.setFocusMode(FocusMode.auto);
      await controller.setExposureMode(ExposureMode.auto);
    } catch (e) {
      debugPrint('[AiSee:Camera] Focus/exposure config not supported: $e');
    }

    return controller;
  }

  /// Select the best LiveKit MediaDevice for Agent vision.
  ///
  /// Scans device labels for ultra-wide indicators and skips them.
  static Future<MediaDevice?> selectLiveKitDeviceForAgentVision() async {
    try {
      final List<MediaDevice> inputs = await Hardware.instance.videoInputs();
      if (inputs.isEmpty) return null;

      if (inputs.length == 1) {
        debugPrint(
            '[AiSee:Camera] Single video input: ${inputs.first.label}');
        return inputs.first;
      }

      // Try to find a non-ultra-wide back camera.
      for (final MediaDevice input in inputs) {
        if (!_isLikelyUltraWideDevice(input)) {
          debugPrint(
              '[AiSee:Camera] Selected LiveKit device: ${input.label}');
          return input;
        }
      }

      // Fallback to first device.
      debugPrint(
          '[AiSee:Camera] All devices flagged as ultra-wide, '
          'using first: ${inputs.first.label}');
      return inputs.first;
    } catch (e) {
      debugPrint('[AiSee:Camera] videoInputs error: $e');
      return null;
    }
  }

  /// Heuristic: detect ultra-wide cameras by name patterns.
  ///
  /// Camera package doesn't expose focal length metadata, so we rely on
  /// common naming conventions from manufacturers.
  static bool _isLikelyUltraWide(String name) {
    final String lower = name.toLowerCase();
    return lower.contains('ultra') ||
        lower.contains('0.5') ||
        lower.contains('wide angle') ||
        lower.contains('fisheye') ||
        lower.contains('uw') ||
        lower.contains('macro');
  }

  /// Same heuristic for LiveKit MediaDevice labels.
  static bool _isLikelyUltraWideDevice(MediaDevice device) {
    return _isLikelyUltraWide(device.label);
  }
}
