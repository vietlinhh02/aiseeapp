import 'dart:async';
import 'dart:io' show File;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'aisee_nsfw_classifier.dart';

abstract interface class AiseeAiCameraStreamer {
  ValueListenable<Widget?> get preview;

  Future<void> start({required void Function(Uint8List jpeg) onFrame});

  Future<void> stop();

  Future<void> dispose();
}

class AiseeCameraPackageStreamer implements AiseeAiCameraStreamer {
  AiseeCameraPackageStreamer({
    this.frameInterval = const Duration(seconds: 1),
    this.onUnsafeContent,
  });

  final Duration frameInterval;
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

    _onFrame = onFrame;
    _blocked = false;
    if (_controller != null) {
      return;
    }

    if (!kIsWeb) {
      final PermissionStatus status = await Permission.camera.request();
      if (!status.isGranted) {
        throw StateError('Cần quyền camera để trợ lý nhìn được.');
      }
    }

    final List<CameraDescription> cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw StateError('Thiết bị không có camera khả dụng.');
    }

    final CameraDescription camera = cameras.firstWhere(
      (CameraDescription item) =>
          item.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    final CameraController controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await controller.initialize();
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
  Future<void> stop() async {
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
    if (controller == null ||
        onFrame == null ||
        _capturing ||
        _blocked ||
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
