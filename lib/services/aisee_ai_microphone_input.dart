import 'dart:async';
import 'dart:typed_data';

import 'package:record/record.dart';

import 'aisee_realtime_noise_suppressor.dart';

abstract interface class AiseeAiMicrophoneInput {
  Future<void> start({required void Function(Uint8List bytes) onFrame});

  Future<void> stop();

  Future<void> dispose();
}

class AiseeAiRecordMicrophoneInput implements AiseeAiMicrophoneInput {
  AiseeAiRecordMicrophoneInput({
    AudioRecorder? recorder,
    AiseeRealtimeNoiseSuppressor? noiseSuppressor,
  }) : _recorder = recorder ?? AudioRecorder(),
       _noiseSuppressor = noiseSuppressor ?? const AiseeNoopNoiseSuppressor();

  static const int _sampleRate = 16000;
  static const RecordConfig _config = RecordConfig(
    encoder: AudioEncoder.pcm16bits,
    sampleRate: _sampleRate,
    numChannels: 1,
    autoGain: true,
    echoCancel: true,
    noiseSuppress: true,
    streamBufferSize: 1600,
  );

  final AudioRecorder _recorder;
  final AiseeRealtimeNoiseSuppressor _noiseSuppressor;

  StreamSubscription<Uint8List>? _streamSub;
  bool _streaming = false;
  bool _processing = false;
  Uint8List? _pendingFrame;

  @override
  Future<void> start({required void Function(Uint8List bytes) onFrame}) async {
    if (_streaming) {
      return;
    }

    final bool hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      throw StateError('Cần quyền micro để dùng trợ lý.');
    }

    final Stream<Uint8List> stream = await _recorder.startStream(_config);
    _streamSub = stream.listen((Uint8List bytes) {
      if (bytes.isEmpty || !_streaming) {
        return;
      }
      // Chỉ giữ frame mới nhất, drop frame cũ nếu processing跟不上
      _pendingFrame = bytes;
      if (!_processing) {
        _drainPending(onFrame);
      }
    });
    _streaming = true;
  }

  Future<void> _drainPending(void Function(Uint8List bytes) onFrame) async {
    _processing = true;
    while (_pendingFrame != null && _streaming) {
      final Uint8List frame = _pendingFrame!;
      _pendingFrame = null;
      try {
        final Uint8List cleaned = await _noiseSuppressor.process(
          Uint8List.fromList(frame),
          sampleRate: _sampleRate,
        );
        if (cleaned.isNotEmpty && _streaming) {
          onFrame(cleaned);
        }
      } catch (_) {
        // Bỏ qua lỗi processing, tiếp tục frame tiếp theo
      }
    }
    _processing = false;
  }

  @override
  Future<void> stop() async {
    await _streamSub?.cancel();
    _streamSub = null;
    _pendingFrame = null;
    if (_streaming) {
      _streaming = false;
      await _recorder.stop();
    }
    // Chờ processing hiện tại hoàn thành
    while (_processing) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _noiseSuppressor.dispose();
    await _recorder.dispose();
  }
}
