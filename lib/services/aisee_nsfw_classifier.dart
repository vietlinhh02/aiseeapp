import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import 'aisee_content_guard_service.dart';

/// Combined result of single-pass decode + preprocess.
typedef ClassifyInput = ({Float32List tfliteInput, Uint8List jpegForSend});

/// TFLite-based NSFW classifier backed by a MobileNet model.
///
/// Model output: 5 classes [Drawing, Hentai, Neutral, Porn, Sexy].
/// NSFW score = sum of Hentai (1) + Porn (3) + Sexy (4).
class AiseeNsfwClassifier implements NsfwClassifier {
  AiseeNsfwClassifier._(this._interpreter);

  final Interpreter _interpreter;

  static const String _modelAsset = 'assets/models/nsfw_mobilenet.tflite';
  static const int _inputSize = 224;
  static const int _maxFrameWidth = 640;
  static const int _jpegQuality = 68;
  static const List<int> _nsfwIndices = [1, 3, 4];
  static const double defaultThreshold = 0.7;

  /// Loads the classifier from bundled assets with GPU delegate if available.
  ///
  /// Returns null if loading fails so the app can continue without the model.
  static Future<AiseeNsfwClassifier?> load() async {
    try {
      final options = InterpreterOptions();
      try {
        options.addDelegate(GpuDelegateV2());
      } catch (_) {
        dev.log(
          'AiseeNsfwClassifier: GPU delegate unavailable, using CPU',
          name: 'AiseeNsfwClassifier',
        );
      }

      final interpreter = await Interpreter.fromAsset(
        _modelAsset,
        options: options,
      );
      return AiseeNsfwClassifier._(interpreter);
    } catch (e) {
      dev.log(
        'AiseeNsfwClassifier: failed to load model — $e',
        name: 'AiseeNsfwClassifier',
      );
      return null;
    }
  }

  /// Decodes raw JPEG, preprocesses for TFLite, and prepares send-ready JPEG
  /// in a single isolate — the JPEG is decoded only once.
  static Future<ClassifyInput> decodeAndPrepare(Uint8List jpeg) {
    return compute(_decodeAndPrepare, jpeg);
  }

  /// Runs TFLite inference on the preprocessed input.
  double runInference(Float32List tfliteInput) {
    final inputTensor = tfliteInput.reshape([1, _inputSize, _inputSize, 3]);
    final output = List.filled(5, 0.0).reshape([1, 5]);
    _interpreter.run(inputTensor, output);

    final scores = output[0] as List<double>;
    final nsfwScore = _nsfwIndices.fold<double>(
      0.0,
      (sum, i) => sum + scores[i],
    );
    return nsfwScore.clamp(0.0, 1.0);
  }

  @override
  Future<double> classify(Uint8List argbPixels, int width, int height) async {
    final input = await compute(_preprocess, (
      pixels: argbPixels,
      width: width,
      height: height,
    ));
    return runInference(input);
  }

  @override
  void dispose() => _interpreter.close();
}

/// Decodes JPEG once, produces both the TFLite input tensor (224×224 RGB)
/// and the send-ready JPEG (max 640px width, quality 68). Runs in an isolate.
ClassifyInput _decodeAndPrepare(Uint8List jpeg) {
  final img.Image? decoded = img.decodeJpg(jpeg);
  if (decoded == null) {
    final empty = Float32List(224 * 224 * 3);
    return (tfliteInput: empty, jpegForSend: jpeg);
  }

  final tfliteInput = _imageToTfliteInput(decoded);

  img.Image output = decoded;
  if (decoded.width > AiseeNsfwClassifier._maxFrameWidth) {
    output = img.copyResize(
      decoded,
      width: AiseeNsfwClassifier._maxFrameWidth,
      interpolation: img.Interpolation.linear,
    );
  }
  final jpegForSend = Uint8List.fromList(
    img.encodeJpg(output, quality: AiseeNsfwClassifier._jpegQuality),
  );

  return (tfliteInput: tfliteInput, jpegForSend: jpegForSend);
}

Float32List _imageToTfliteInput(img.Image source) {
  final resized = img.copyResize(
    source,
    width: 224,
    height: 224,
    interpolation: img.Interpolation.linear,
  );

  const pixelCount = 224 * 224 * 3;
  final buffer = Float32List(pixelCount);
  var idx = 0;
  for (var y = 0; y < 224; y++) {
    for (var x = 0; x < 224; x++) {
      final pixel = resized.getPixel(x, y);
      buffer[idx++] = pixel.r / 255.0;
      buffer[idx++] = pixel.g / 255.0;
      buffer[idx++] = pixel.b / 255.0;
    }
  }
  return buffer;
}

/// Preprocessing step that runs in an isolate via [compute].
///
/// Decodes ARGB pixels, resizes to 224×224, and normalises to [0, 1].
Float32List _preprocess(({Uint8List pixels, int width, int height}) data) {
  final source = img.Image.fromBytes(
    width: data.width,
    height: data.height,
    bytes: data.pixels.buffer,
    order: img.ChannelOrder.argb,
  );
  return _imageToTfliteInput(source);
}
