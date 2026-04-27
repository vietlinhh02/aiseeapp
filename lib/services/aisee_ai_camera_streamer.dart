import 'dart:async';
import 'dart:io' show File;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';

import 'aisee_content_guard_service.dart';
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
  static const int _maxFrameWidth = 640;
  static const int _jpegQuality = 68;

  CameraController? _controller;
  Timer? _frameTimer;
  AiseeContentGuardService? _contentGuard;
  AiseeNsfwClassifier? _classifier;
  Uint8List? _latestJpeg;
  void Function(Uint8List jpeg)? _onFrame;
  bool _capturing = false;
  bool _disposed = false;

  @override
  ValueListenable<Widget?> get preview => _preview;

  @override
  Future<void> start({required void Function(Uint8List jpeg) onFrame}) async {
    if (_disposed) {
      throw StateError('AI camera streamer has been disposed.');
    }

    _onFrame = onFrame;
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
    unawaited(_startContentGuard());
    await _captureAndSend();
    _frameTimer = Timer.periodic(frameInterval, (_) {
      unawaited(_captureAndSend());
    });
  }

  @override
  Future<void> stop() async {
    _frameTimer?.cancel();
    _frameTimer = null;
    _contentGuard?.stop();
    _contentGuard = null;
    _latestJpeg = null;
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

  Future<void> _captureAndSend() async {
    final CameraController? controller = _controller;
    final void Function(Uint8List jpeg)? onFrame = _onFrame;
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
      if (bytes.isNotEmpty) {
        _latestJpeg = await compute(_prepareJpegForGemini, bytes);
        onFrame(_latestJpeg!);
      }
      if (!kIsWeb) {
        unawaited(_deleteCaptureFile(file.path));
      }
    } on CameraException catch (error) {
      debugPrint('[AiSee:AICamera] capture failed: ${error.code} ${error.description}');
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

  Future<void> _startContentGuard() async {
    _classifier ??= await AiseeNsfwClassifier.load();
    final AiseeNsfwClassifier? classifier = _classifier;
    if (classifier == null || _controller == null) {
      return;
    }

    final AiseeContentGuardService guard = AiseeContentGuardService(
      classifier: classifier,
    );
    _contentGuard = guard;
    guard.startWithFrameProvider(
      frameProvider: _latestFrameForGuard,
      onUnsafeDetected: () {
        unawaited(_handleUnsafeContent());
      },
    );
  }

  Future<CapturedFrame?> _latestFrameForGuard() async {
    final Uint8List? jpeg = _latestJpeg;
    if (jpeg == null || jpeg.isEmpty) {
      return null;
    }
    return compute(_decodeJpegForGuard, jpeg);
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

CapturedFrame? _decodeJpegForGuard(Uint8List jpeg) {
  final img.Image? decoded = img.decodeJpg(jpeg);
  if (decoded == null) {
    return null;
  }
  return (
    pixels: decoded.getBytes(order: img.ChannelOrder.argb),
    width: decoded.width,
    height: decoded.height,
  );
}

Uint8List _prepareJpegForGemini(Uint8List jpeg) {
  final img.Image? decoded = img.decodeJpg(jpeg);
  if (decoded == null) {
    return jpeg;
  }

  img.Image output = decoded;
  if (decoded.width > AiseeCameraPackageStreamer._maxFrameWidth) {
    output = img.copyResize(
      decoded,
      width: AiseeCameraPackageStreamer._maxFrameWidth,
      interpolation: img.Interpolation.linear,
    );
  }

  return Uint8List.fromList(
    img.encodeJpg(
      output,
      quality: AiseeCameraPackageStreamer._jpegQuality,
    ),
  );
}
