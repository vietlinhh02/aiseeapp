import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_pcm_sound/flutter_pcm_sound.dart';

abstract interface class AiseeAiPcmPlayer {
  Future<void> enqueuePcm16(Uint8List bytes);
  Future<void> stop({String reason = 'manual'});
  Future<void> dispose();
  bool get hasPendingAudio;
}

class AiseeFlutterPcmAudioPlayer implements AiseeAiPcmPlayer {
  static const int _sampleRate = 24000;
  static const int _channelCount = 1;
  static const int _feedThresholdFrames = 9600;

  final Queue<PcmArrayInt16> _queuedBuffers = Queue<PcmArrayInt16>();

  bool _initialized = false;
  bool _disposed = false;
  Future<void> _operationQueue = Future<void>.value();

  @override
  bool get hasPendingAudio => _queuedBuffers.isNotEmpty || _pendingFeedCount > 0;

  int _pendingFeedCount = 0;
  int _feedGeneration = 0;

  @override
  Future<void> enqueuePcm16(Uint8List bytes) async {
    if (bytes.isEmpty) {
      return;
    }

    await _runSerial(() async {
      if (_disposed) {
        return;
      }

      await _ensureInitialized();
      _queuedBuffers.add(_pcmArrayFromBytes(bytes));
      _pendingFeedCount++;
      FlutterPcmSound.start();
      final int gen = ++_feedGeneration;
      scheduleMicrotask(() {
        unawaited(
          _runSerial(() => _feedLoop(gen)).catchError((
            Object error,
            StackTrace stackTrace,
          ) {
            debugPrint('[AiSee:PCM] feed failed: $error\n$stackTrace');
          }),
        );
      });
    });
  }

  @override
  Future<void> stop({String reason = 'manual'}) async {
    _feedGeneration++;
    _pendingFeedCount = 0;
    await _runSerial(() async {
      _queuedBuffers.clear();
      if (_initialized) {
        debugPrint('[AiSee:PCM] release reason=$reason');
        FlutterPcmSound.setFeedCallback(null);
        await FlutterPcmSound.release();
        _initialized = false;
      }
    });
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    await stop(reason: 'dispose');
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) {
      return;
    }

    await FlutterPcmSound.setup(
      sampleRate: _sampleRate,
      channelCount: _channelCount,
      iosAudioCategory: IosAudioCategory.playAndRecord,
    );
    await FlutterPcmSound.setFeedThreshold(_feedThresholdFrames);
    FlutterPcmSound.setFeedCallback((int remainingFrames) {
      if (_disposed) {
        return;
      }
      if (_queuedBuffers.isNotEmpty || remainingFrames <= 0) {
        final int gen = ++_feedGeneration;
        scheduleMicrotask(() {
          unawaited(
            _runSerial(() => _feedLoop(gen)).catchError((
              Object error,
              StackTrace stackTrace,
            ) {
              debugPrint('[AiSee:PCM] feed failed: $error\n$stackTrace');
            }),
          );
        });
      }
    });
    _initialized = true;
  }

  Future<void> _runSerial(Future<void> Function() action) {
    final Future<void> next = _operationQueue.then<void>(
      (_) => action(),
      onError: (Object _, StackTrace _) => action(),
    );
    _operationQueue = next.catchError((Object _) {});
    return next;
  }

  Future<void> _feedLoop(int generation) async {
    while (true) {
      if (_disposed || !_initialized || generation != _feedGeneration) {
        return;
      }
      if (_queuedBuffers.isEmpty) {
        return;
      }

      final PcmArrayInt16 chunk = _queuedBuffers.removeFirst();
      _pendingFeedCount--;
      await FlutterPcmSound.feed(chunk);
    }
  }

  PcmArrayInt16 _pcmArrayFromBytes(Uint8List bytes) {
    final ByteData byteData = ByteData.sublistView(bytes);
    return PcmArrayInt16(bytes: byteData);
  }
}
