// ignore_for_file: implementation_imports

import 'package:flutter/foundation.dart';
import 'package:flutter_nnnoiseless/src/rust/api/nnnoiseless.dart'
    as nnnoiseless;
import 'package:flutter_nnnoiseless/src/rust/frb_generated.dart';

abstract interface class AiseeRealtimeNoiseSuppressor {
  Future<Uint8List> process(Uint8List bytes, {required int sampleRate});

  Future<void> dispose();
}

class AiseeNoopNoiseSuppressor implements AiseeRealtimeNoiseSuppressor {
  const AiseeNoopNoiseSuppressor();

  @override
  Future<Uint8List> process(Uint8List bytes, {required int sampleRate}) async {
    return Uint8List.fromList(bytes);
  }

  @override
  Future<void> dispose() async {}
}

class AiseeNnNoiselessNoiseSuppressor implements AiseeRealtimeNoiseSuppressor {
  static const int _modelSampleRate = 48000;

  Future<void>? _initFuture;
  bool _disabled = false;

  @override
  Future<Uint8List> process(Uint8List bytes, {required int sampleRate}) async {
    if (_disabled || bytes.isEmpty) {
      return Uint8List.fromList(bytes);
    }

    try {
      await _ensureInitialized();
      final Uint8List denoised = await nnnoiseless.denoiseChunk(
        input: bytes,
        inputSampleRate: sampleRate,
      );
      if (denoised.isEmpty) {
        return Uint8List(0);
      }
      if (sampleRate == _modelSampleRate) {
        return denoised;
      }
      if (_modelSampleRate % sampleRate == 0) {
        return _downsamplePcm16(
          denoised,
          factor: _modelSampleRate ~/ sampleRate,
        );
      }
      return _resampleNearestPcm16(
        denoised,
        sourceRate: _modelSampleRate,
        targetRate: sampleRate,
      );
    } catch (error, stackTrace) {
      _disabled = true;
      debugPrint(
        '[AiSee:Audio] NNNoiseless disabled after processing error: '
        '$error\n$stackTrace',
      );
      return Uint8List.fromList(bytes);
    }
  }

  @override
  Future<void> dispose() async {}

  Future<void> _ensureInitialized() {
    return _initFuture ??= RustLib.init();
  }

  static Uint8List _downsamplePcm16(Uint8List bytes, {required int factor}) {
    if (factor <= 1 || bytes.length < 2) {
      return Uint8List.fromList(bytes);
    }

    final int sourceSamples = bytes.length ~/ 2;
    const int filterLen = 5;
    const int halfWindow = filterLen ~/ 2;

    if (sourceSamples < filterLen) {
      return _downsampleSimple(bytes, factor: factor);
    }

    final int outputSamples =
        (sourceSamples - filterLen) ~/ factor + 1;
    if (outputSamples <= 0) {
      return Uint8List(0);
    }

    final Uint8List output = Uint8List(outputSamples * 2);
    final ByteData inputData = ByteData.sublistView(bytes);
    final ByteData outputData = ByteData.sublistView(output);

    for (int i = 0; i < outputSamples; i++) {
      final int center = i * factor + halfWindow;
      int sum = 0;
      for (int j = -halfWindow; j <= halfWindow; j++) {
        sum += inputData.getInt16(
          (center + j) * 2,
          Endian.little,
        );
      }
      outputData.setInt16(i * 2, sum ~/ filterLen, Endian.little);
    }
    return output;
  }

  static Uint8List _downsampleSimple(Uint8List bytes, {required int factor}) {
    final int sourceSamples = bytes.length ~/ 2;
    final int outputSamples = sourceSamples ~/ factor;
    final Uint8List output = Uint8List(outputSamples * 2);
    final ByteData inputData = ByteData.sublistView(bytes);
    final ByteData outputData = ByteData.sublistView(output);
    for (int outputIndex = 0; outputIndex < outputSamples; outputIndex += 1) {
      int sum = 0;
      for (int offset = 0; offset < factor; offset += 1) {
        sum += inputData.getInt16(
          (outputIndex * factor + offset) * 2,
          Endian.little,
        );
      }
      outputData.setInt16(outputIndex * 2, sum ~/ factor, Endian.little);
    }
    return output;
  }

  static Uint8List _resampleNearestPcm16(
    Uint8List bytes, {
    required int sourceRate,
    required int targetRate,
  }) {
    if (sourceRate == targetRate || bytes.length < 2) {
      return Uint8List.fromList(bytes);
    }

    final int sourceSamples = bytes.length ~/ 2;
    final int outputSamples = (sourceSamples * targetRate / sourceRate).floor();
    final Uint8List output = Uint8List(outputSamples * 2);
    final ByteData inputData = ByteData.sublistView(bytes);
    final ByteData outputData = ByteData.sublistView(output);
    for (int outputIndex = 0; outputIndex < outputSamples; outputIndex += 1) {
      final int sourceIndex = (outputIndex * sourceRate / targetRate)
          .floor()
          .clamp(0, sourceSamples - 1);
      outputData.setInt16(
        outputIndex * 2,
        inputData.getInt16(sourceIndex * 2, Endian.little),
        Endian.little,
      );
    }
    return output;
  }
}
