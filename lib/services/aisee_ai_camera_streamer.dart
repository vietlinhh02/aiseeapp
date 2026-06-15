import 'dart:async';
import 'dart:io' show File;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'aisee_camera_selection_service.dart';
import 'aisee_nsfw_classifier.dart';

abstract interface class AiseeAiCameraStreamer {
  ValueListenable<Widget?> get preview;

  Future<void> start({required void Function(Uint8List jpeg) onFrame});

  Future<void> stop();

  /// Live-update the capture period (e.g. faster FPS during walking nav).
  /// No-op if streamer not running.
  Future<void> setFrameInterval(Duration interval);

  Future<void> dispose();
}

class AiseeCameraPackageStreamer implements AiseeAiCameraStreamer {
  AiseeCameraPackageStreamer({
    Duration frameInterval = const Duration(seconds: 1),
    this.onUnsafeContent,
  }) : _frameInterval = frameInterval;

  Duration _frameInterval;
  Duration get frameInterval => _frameInterval;
  final FutureOr<void> Function()? onUnsafeContent;

  final ValueNotifier<Widget?> _preview = ValueNotifier<Widget?>(null);

  CameraController? _controller;
  Timer? _frameTimer;
  AiseeNsfwClassifier? _classifier;
  void Function(Uint8List jpeg)? _onFrame;
  bool _capturing = false;
  bool _disposed = false;
  bool _blocked = false;

  @override
  ValueListenable<Widget?> get preview => _preview;

  @override
  Future<void> start({required void Function(Uint8List jpeg) onFrame}) async {
    if (_disposed) {
      throw StateError('AI camera streamer has been disposed.');
    }

    debugPrint('[AiSee:AICamera] start() called, wasBlocked=$_blocked, hasController=${_controller != null}');
    _onFrame = onFrame;
    _blocked = false;
    if (_controller != null) {
      debugPrint('[AiSee:AICamera] start() reusing existing controller');
      return;
    }

    if (!kIsWeb) {
      final PermissionStatus status = await Permission.camera.request();
      if (!status.isGranted) {
        throw StateError('Cần quyền camera để trợ lý nhìn được.');
      }
    }

    // Use camera selection service to pick standard wide back camera,
    // avoiding ultra-wide/fisheye lenses that distort text for OCR.
    final CameraDescription? camera =
        await AiseeCameraSelectionService.selectForAgentVision();
    if (camera == null) {
      throw StateError('Thiết bị không có camera khả dụng.');
    }
    debugPrint('[AiSee:AICamera] selected camera: ${camera.name} '
        '(${camera.lensDirection})');

    // Use high resolution (1080p) for better OCR text recognition.
    // Also enable autofocus for reading labels and text.
    final CameraController controller =
        await AiseeCameraSelectionService.createOCRController(camera);
    if (_disposed) {
      await controller.dispose();
      return;
    }

    _controller = controller;
    _preview.value = _AssistantCameraPreview(controller: controller);
    unawaited(_loadClassifier());
    await _captureAndSend();
    _frameTimer = Timer.periodic(frameInterval, (_) {
      unawaited(_captureAndSend());
    });
  }

  @override
  Future<void> setFrameInterval(Duration interval) async {
    if (interval == _frameInterval) {
      return;
    }
    debugPrint('[AiSee:AICamera] setFrameInterval: $interval (was $_frameInterval)');
    _frameInterval = interval;
    final Timer? existing = _frameTimer;
    if (existing != null) {
      existing.cancel();
      _frameTimer = Timer.periodic(interval, (_) {
        unawaited(_captureAndSend());
      });
    }
  }

  @override
  Future<void> stop() async {
    debugPrint('[AiSee:AICamera] stop() called');
    _frameTimer?.cancel();
    _frameTimer = null;
    _onFrame = null;

    final CameraController? controller = _controller;
    _controller = null;
    _preview.value = null;
    if (controller != null) {
      await controller.dispose();
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    await stop();
    _classifier?.dispose();
    _classifier = null;
    _preview.dispose();
  }

  Future<void> _loadClassifier() async {
    if (_classifier != null) return;
    _classifier = await AiseeNsfwClassifier.instance;
  }

  Future<void> _captureAndSend() async {
    final CameraController? controller = _controller;
    final void Function(Uint8List jpeg)? onFrame = _onFrame;
    if (_blocked) {
      return;
    }
    if (controller == null ||
        onFrame == null ||
        _capturing ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture) {
      return;
    }

    _capturing = true;
    try {
      final XFile file = await controller.takePicture();
      final Uint8List bytes = await file.readAsBytes();
      if (bytes.isEmpty) return;

      final AiseeNsfwClassifier? classifier = _classifier;
      if (classifier == null) {
        onFrame(bytes);
        return;
      }

      final classifyInput = await AiseeNsfwClassifier.decodeAndPrepare(bytes);
      final score = classifier.runInference(classifyInput.tfliteInput);

      if (score > AiseeNsfwClassifier.defaultThreshold) {
        debugPrint('[AiSee:AICamera] NSFW detected, score=$score — blocking camera');
        _blocked = true;
        unawaited(_handleUnsafeContent());
        return;
      }

      onFrame(classifyInput.jpegForSend);

      if (!kIsWeb) {
        unawaited(_deleteCaptureFile(file.path));
      }
    } on CameraException catch (error) {
      debugPrint(
        '[AiSee:AICamera] capture failed: ${error.code} ${error.description}',
      );
    } catch (error, stackTrace) {
      debugPrint('[AiSee:AICamera] capture failed: $error\n$stackTrace');
    } finally {
      _capturing = false;
    }
  }

  Future<void> _deleteCaptureFile(String path) async {
    try {
      await File(path).delete();
    } catch (_) {}
  }

  Future<void> _handleUnsafeContent() async {
    debugPrint('[AiSee:AICamera] _handleUnsafeContent — stopping camera and notifying backend');
    await stop();
    await onUnsafeContent?.call();
  }
}

class _AssistantCameraPreview extends StatelessWidget {
  const _AssistantCameraPreview({required this.controller});

  final CameraController controller;

  static const double _radius = 28;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 2, 0, 6),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(_radius),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: CameraPreview(controller),
      ),
    );
  }
}
