import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:record/record.dart';

class RecordProgress {
  const RecordProgress({required this.duration, required this.decibels});
  final Duration duration;
  final double decibels;
}

class AiseeVoiceRecorder {
  final AudioRecorder _recorder = AudioRecorder();
  String? _currentPath;
  Timer? _autoStopTimer;
  Timer? _progressTimer;
  final Stopwatch _stopwatch = Stopwatch();

  static const int maxDurationSeconds = 120;

  final StreamController<RecordProgress> _progressController =
      StreamController<RecordProgress>.broadcast();

  Stream<RecordProgress> get onProgress => _progressController.stream;

  bool _recording = false;
  bool get isRecording => _recording;

  Future<void> start() async {
    final Directory tempDir = await path_provider.getTemporaryDirectory();
    _currentPath =
        '${tempDir.path}/aisee_voice_'
        '${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: _currentPath!,
    );
    _recording = true;
    _stopwatch
      ..reset()
      ..start();

    // Poll amplitude every 50ms for waveform.
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 50), (
      _,
    ) async {
      final Amplitude amp = await _recorder.getAmplitude();
      _progressController.add(
        RecordProgress(duration: _stopwatch.elapsed, decibels: amp.current),
      );
    });

    // Auto-stop after max duration.
    _autoStopTimer?.cancel();
    _autoStopTimer = Timer(const Duration(seconds: maxDurationSeconds), () {
      debugPrint('[AiSee:Recorder] Auto-stop at $maxDurationSeconds s');
      stop().then((File? file) {
        if (file != null) {
          _onAutoStop?.call(file);
        }
      });
    });

    debugPrint('[AiSee:Recorder] Recording started: $_currentPath');
  }

  /// Callback for auto-stop. Set by the UI before calling start().
  void Function(File file)? _onAutoStop;
  set onAutoStop(void Function(File file)? callback) => _onAutoStop = callback;

  Future<File?> stop() async {
    _autoStopTimer?.cancel();
    _autoStopTimer = null;
    _progressTimer?.cancel();
    _progressTimer = null;
    _stopwatch.stop();

    if (!_recording) return null;
    _recording = false;

    final String? path = await _recorder.stop();
    debugPrint('[AiSee:Recorder] Recording stopped: $path');

    _currentPath = null;
    if (path == null) return null;

    final File file = File(path);
    if (await file.exists()) return file;
    return null;
  }

  Future<void> cancel() async {
    _autoStopTimer?.cancel();
    _autoStopTimer = null;
    _progressTimer?.cancel();
    _progressTimer = null;
    _stopwatch.stop();

    if (_recording) {
      await _recorder.stop();
      _recording = false;
    }

    final String? path = _currentPath;
    _currentPath = null;
    if (path != null) {
      final File file = File(path);
      if (await file.exists()) {
        await file.delete();
        debugPrint('[AiSee:Recorder] Cancelled and deleted: $path');
      }
    }
  }

  Future<void> dispose() async {
    _autoStopTimer?.cancel();
    _progressTimer?.cancel();
    _stopwatch.stop();
    await _progressController.close();
    await _recorder.dispose();
  }
}
