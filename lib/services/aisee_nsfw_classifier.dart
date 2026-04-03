import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import 'aisee_content_guard_service.dart';

/// TFLite-based NSFW classifier backed by a MobileNet model.
///
/// Model output: 5 classes [Drawing, Hentai, Neutral, Porn, Sexy].
/// NSFW score = sum of Hentai (1) + Porn (3) + Sexy (4).
class AiseeNsfwClassifier implements NsfwClassifier {
  AiseeNsfwClassifier._(this._interpreter);

  final Interpreter _interpreter;

  static const String _modelAsset = 'assets/models/nsfw_mobilenet.tflite';
  static const int _inputSize = 224;
  static const List<int> _nsfwIndices = [1, 3, 4];

  /// Loads the classifier from bundled assets.
  ///
  /// Returns null if loading fails so the app can continue without the model.
  static Future<AiseeNsfwClassifier?> load() async {
    try {
      final interpreter = await Interpreter.fromAsset(_modelAsset);
      return AiseeNsfwClassifier._(interpreter);
    } catch (e) {
      dev.log(
        'AiseeNsfwClassifier: failed to load model — $e',
        name: 'AiseeNsfwClassifier',
      );
      return null;
    }
  }

  @override
  Future<double> classify(
    Uint8List argbPixels,
    int width,
    int height,
  ) async {
    final input = await compute(
      _preprocess,
      (pixels: argbPixels, width: width, height: height),
    );

    // Shape: [1, 224, 224, 3]
    final inputTensor = input.reshape([1, _inputSize, _inputSize, 3]);
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
  void dispose() => _interpreter.close();
}

/// Preprocessing step that runs in an isolate via [compute].
///
/// Decodes ARGB pixels, resizes to 224×224, and normalises to [0, 1].
Float32List _preprocess(
  ({Uint8List pixels, int width, int height}) data,
) {
  final source = img.Image.fromBytes(
    width: data.width,
    height: data.height,
    bytes: data.pixels.buffer,
    order: img.ChannelOrder.argb,
  );

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
