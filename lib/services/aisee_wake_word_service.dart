import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:permission_handler/permission_handler.dart';

const String _aiseeWakeInstanceId = 'aisee_wake';
const MethodChannel _wakeWordMethodChannel = MethodChannel(
  'com.aisee.aiseeapp/livekit_wake_word',
);
const MethodChannel _nativePlatformMethodChannel = MethodChannel(
  'com.aisee.aiseeapp/platform',
);

abstract class AiseeWakeWordBackend {
  void setDetectionHandler(void Function(Map<String, dynamic> event)? handler);

  Future<void> configure({
    required String id,
    required List<String> modelNames,
    required double threshold,
    required int debounceMs,
  });

  Future<void> startListening();

  Future<void> stopListening();

  Future<void> dispose();
}

class _LiveKitWakeWordBackend implements AiseeWakeWordBackend {
  _LiveKitWakeWordBackend() {
    _wakeWordMethodChannel.setMethodCallHandler(_handleNativeMethodCall);
  }

  void Function(Map<String, dynamic> event)? _onDetectionEvent;

  @override
  void setDetectionHandler(void Function(Map<String, dynamic> event)? handler) {
    _onDetectionEvent = handler;
  }

  Future<void> _handleNativeMethodCall(MethodCall call) async {
    if (call.method != 'onWakeWordDetected') {
      throw MissingPluginException('Unknown wake word method ${call.method}');
    }
    final Object? arguments = call.arguments;
    final Map<String, dynamic> event = <String, dynamic>{};
    if (arguments is Map) {
      for (final MapEntry<Object?, Object?> entry in arguments.entries) {
        event[entry.key.toString()] = entry.value;
      }
    }
    _onDetectionEvent?.call(event);
  }

  @override
  Future<void> configure({
    required String id,
    required List<String> modelNames,
    required double threshold,
    required int debounceMs,
  }) {
    return _wakeWordMethodChannel.invokeMethod<void>('configure', {
      'id': id,
      'modelNames': modelNames,
      'threshold': threshold,
      'debounceMs': debounceMs,
    });
  }

  @override
  Future<void> startListening() {
    return _wakeWordMethodChannel.invokeMethod<void>('startListening');
  }

  @override
  Future<void> stopListening() {
    return _wakeWordMethodChannel.invokeMethod<void>('stopListening');
  }

  @override
  Future<void> dispose() {
    return _wakeWordMethodChannel.invokeMethod<void>('dispose');
  }
}

/// LiveKit/openWakeWord-compatible on-device wake word.
///
/// Cấu hình trong `assets/app_config.env`:
/// - `LIVEKIT_WAKEWORD_MODELS` — tên file `.onnx`, cách nhau bằng dấu phẩy
/// - `LIVEKIT_WAKEWORD_THRESHOLD` — ngưỡng 0-1, mặc định 0.5
///
/// Nếu danh sách model rỗng, service không khởi chạy (không lỗi).
class AiseeWakeWordService {
  AiseeWakeWordService._()
    : _wakeModel = _LiveKitWakeWordBackend(),
      _debugIsSupportedPlatform = null,
      _debugMicrophoneGranted = null,
      _debugModelNames = null;

  @visibleForTesting
  AiseeWakeWordService.test({
    required AiseeWakeWordBackend wakeModel,
    bool started = false,
    bool listening = false,
    bool pausedForLiveKit = false,
    bool isSupportedPlatform = false,
    bool microphoneGranted = false,
    List<String>? modelNames,
  }) : _wakeModel = wakeModel,
       _started = started,
       _listening = listening,
       _pausedForLiveKit = pausedForLiveKit,
       _debugIsSupportedPlatform = isSupportedPlatform,
       _debugMicrophoneGranted = microphoneGranted,
       _debugModelNames = modelNames;

  static final AiseeWakeWordService instance = AiseeWakeWordService._();

  final AiseeWakeWordBackend _wakeModel;
  final bool? _debugIsSupportedPlatform;
  final bool? _debugMicrophoneGranted;
  final List<String>? _debugModelNames;
  bool _started = false;
  bool _listening = false;

  /// Wake đang tắt mic native vì LiveKit giữ phòng.
  bool _pausedForLiveKit = false;

  bool get isConfiguredAndStarted => _started;
  bool get isListening => _listening;
  bool get isFeatureEnabledByConfig {
    return _loadModelNames().isNotEmpty;
  }

  /// Gọi khi phát hiện wake (giá trị `phrase` từ native, thường là tên model).
  void Function(String phrase)? onWakePhrase;

  Future<void> startIdleListening() async {
    if (!_started) {
      await startIfConfigured(liveKitMicActive: false);
      return;
    }
    if (_listening) {
      return;
    }
    try {
      await _wakeModel.startListening();
      _pausedForLiveKit = false;
      _listening = true;
      debugPrint('[AiSee:WakeWord] Idle listening ON');
    } catch (e, st) {
      debugPrint('[AiSee:WakeWord] startIdleListening: $e\n$st');
    }
  }

  Future<void> stopForLiveSession() async {
    if (!_started) {
      return;
    }
    _pausedForLiveKit = true;

    // Nếu detection vừa xảy ra, đợi native thực sự nhả AudioRecord
    // trước khi trả quyền cho WebRTC.
    final Completer<void>? pending = _detectionStopCompleter;
    if (pending != null && !pending.isCompleted) {
      debugPrint('[AiSee:WakeWord] Waiting for detection stop to finish...');
      await pending.future;
      _detectionStopCompleter = null;
    }

    if (!_listening) {
      debugPrint('[AiSee:WakeWord] Idle listening already OFF for LiveKit');
      return;
    }
    try {
      await _wakeModel.stopListening();
      _listening = false;
      debugPrint('[AiSee:WakeWord] Idle listening OFF for LiveKit');
    } catch (e, st) {
      debugPrint('[AiSee:WakeWord] stopForLiveSession: $e\n$st');
    }
  }

  /// Dừng lắng nghe wake khi LiveKit (hoặc app khác) độc quyền mic.
  Future<void> pauseForExclusiveMic() async {
    await stopForLiveSession();
  }

  /// Bật lại wake sau khi phòng LiveKit đã nhả mic.
  Future<void> resumeAfterExclusiveMic() async {
    if (!_started || !_pausedForLiveKit) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 400));
    await startIdleListening();
  }

  /// [liveKitMicActive]: true khi phòng LiveKit đã bật mic.
  ///
  /// Wake sẽ khởi tạo engine rồi tạm dừng để không tranh AudioRecord với WebRTC.
  Future<void> startIfConfigured({bool liveKitMicActive = false}) async {
    if (_started) {
      if (liveKitMicActive) {
        await pauseForExclusiveMic();
      }
      return;
    }
    if (!_isSupportedPlatform()) {
      return;
    }

    final List<String> modelNames = _loadModelNames();
    if (modelNames.isEmpty) {
      debugPrint(
        '[AiSee:WakeWord] Bỏ qua: đặt LIVEKIT_WAKEWORD_MODELS '
        'trong app_config.env để bật.',
      );
      return;
    }

    if (!await _isNativeRuntimeSupported()) {
      return;
    }

    if (!await _ensureMicrophonePermission()) {
      debugPrint('[AiSee:WakeWord] Chưa có quyền microphone.');
      return;
    }

    final double threshold = _parseThreshold();
    final int debounceMs = _parseDebounceMs();
    try {
      _wakeModel.setDetectionHandler(_onDetectionEvent);
      await _wakeModel.configure(
        id: _aiseeWakeInstanceId,
        modelNames: modelNames,
        threshold: threshold,
        debounceMs: debounceMs,
      );
      _started = true;
      _pausedForLiveKit = false;
      debugPrint(
        '[AiSee:WakeWord] Engine sẵn sàng (${modelNames.length} model).',
      );
      if (liveKitMicActive) {
        _pausedForLiveKit = true;
        _listening = false;
        debugPrint('[AiSee:WakeWord] Idle listening OFF for LiveKit');
        return;
      }
      await _wakeModel.startListening();
      _listening = true;
      debugPrint('[AiSee:WakeWord] Idle listening ON');
    } catch (e, st) {
      debugPrint('[AiSee:WakeWord] Lỗi khởi tạo: $e\n$st');
      await _cleanupFailedStart();
    }
  }

  /// Completer cho lần stop sau detection — [stopForLiveSession] await nó
  /// để đảm bảo native AudioRecord đã giải phóng trước khi WebRTC chiếm mic.
  Completer<void>? _detectionStopCompleter;

  void _onDetectionEvent(Map<String, dynamic> event) {
    final String phrase = (event['phrase'] as String?)?.trim() ?? '';
    _listening = false;
    debugPrint(
      '[AiSee:WakeWord] Wake detected: ${phrase.isEmpty ? 'wake' : phrase}',
    );
    final Completer<void> completer = Completer<void>();
    _detectionStopCompleter = completer;
    // Phải chờ native mic release TRƯỚC khi gọi callback
    // để coordinator không bị lỗi "audio in use"
    _wakeModel
        .stopListening()
        .then((_) {
          debugPrint('[AiSee:WakeWord] Native mic released after detection');
          completer.complete();
          onWakePhrase?.call(phrase.isEmpty ? 'wake' : phrase);
        })
        .catchError((Object e, StackTrace st) {
          debugPrint('[AiSee:WakeWord] stopListening after detection: $e\n$st');
          completer.complete();
          onWakePhrase?.call(phrase.isEmpty ? 'wake' : phrase);
        });
  }

  Future<void> stop() async {
    if (!_started) {
      return;
    }
    try {
      await _wakeModel.dispose();
    } catch (e, st) {
      debugPrint('[AiSee:WakeWord] Lỗi stop: $e\n$st');
    }
    _listening = false;
    _pausedForLiveKit = false;
    _started = false;
    onWakePhrase = null;
    _wakeModel.setDetectionHandler(null);
  }

  bool _isSupportedPlatform() {
    final bool? debugIsSupportedPlatform = _debugIsSupportedPlatform;
    if (debugIsSupportedPlatform != null) {
      return debugIsSupportedPlatform;
    }
    return Platform.isAndroid;
  }

  List<String> _loadModelNames() {
    final List<String>? debugModelNames = _debugModelNames;
    if (debugModelNames != null) {
      return debugModelNames
          .map((String s) => s.trim())
          .where((String s) => s.isNotEmpty)
          .toList();
    }
    final String modelsRaw = (dotenv.env['LIVEKIT_WAKEWORD_MODELS'] ?? '')
        .trim();
    return modelsRaw
        .split(',')
        .map((String s) => s.trim())
        .where((String s) => s.isNotEmpty)
        .toList();
  }

  Future<bool> _ensureMicrophonePermission() async {
    final bool? debugMicrophoneGranted = _debugMicrophoneGranted;
    if (debugMicrophoneGranted != null) {
      return debugMicrophoneGranted;
    }
    PermissionStatus mic = await Permission.microphone.status;
    if (!mic.isGranted) {
      mic = await Permission.microphone.request();
    }
    return mic.isGranted;
  }

  Future<void> _cleanupFailedStart() async {
    try {
      await _wakeModel.dispose();
    } catch (e, st) {
      debugPrint('[AiSee:WakeWord] cleanupFailedStart: $e\n$st');
    }
    debugPrint('[AiSee:WakeWord] Đã cleanup instance lỗi để có thể thử lại.');
    _started = false;
    _listening = false;
    _pausedForLiveKit = false;
  }

  Future<bool> _isNativeRuntimeSupported() async {
    try {
      final Map<Object?, Object?>? result = await _nativePlatformMethodChannel
          .invokeMethod<Map<Object?, Object?>>('getWakeWordRuntimeSupport');
      final bool isSupported = _isNativeProbeSupported(result);
      if (!isSupported) {
        final String reason = (result?['reason'] as String?) ?? 'unknown';
        final List<String> supportedAbis = _stringList(
          result?['supportedAbis'],
        );
        final List<String> requiredAbis = _stringList(result?['requiredAbis']);
        final String abiDetail = supportedAbis.isEmpty || requiredAbis.isEmpty
            ? ''
            : ' processAbi=${supportedAbis.first} required=${requiredAbis.join(",")}';
        debugPrint(
          '[AiSee:WakeWord] Bỏ qua native wake word: $reason$abiDetail',
        );
      }
      return isSupported;
    } on MissingPluginException {
      // Tests and non-Android embeddings may not expose this probe.
      return true;
    } catch (e, st) {
      debugPrint('[AiSee:WakeWord] Probe native runtime failed: $e\n$st');
      return true;
    }
  }

  static bool _isNativeProbeSupported(Map<Object?, Object?>? result) {
    if (result?['isSupported'] != true) {
      return false;
    }

    final List<String> supportedAbis = _stringList(result?['supportedAbis']);
    final List<String> requiredAbis = _stringList(result?['requiredAbis']);
    if (supportedAbis.isEmpty || requiredAbis.isEmpty) {
      return true;
    }

    final String processAbi = supportedAbis.first;
    return requiredAbis.contains(processAbi);
  }

  static List<String> _stringList(Object? value) {
    if (value is List) {
      return value
          .map((Object? item) => item?.toString().trim() ?? '')
          .where((String item) => item.isNotEmpty)
          .toList();
    }
    return const <String>[];
  }

  /// 0-1; mặc định 0.5. Env: `LIVEKIT_WAKEWORD_THRESHOLD`.
  static double _parseThreshold() {
    String? raw;
    try {
      raw = dotenv.env['LIVEKIT_WAKEWORD_THRESHOLD']?.trim();
    } catch (_) {
      raw = null;
    }
    if (raw != null && raw.isNotEmpty) {
      final double? v = double.tryParse(raw);
      if (v != null && v > 0 && v <= 1.0) {
        return v;
      }
    }
    return 0.50;
  }

  static int _parseDebounceMs() {
    String? raw;
    try {
      raw = dotenv.env['LIVEKIT_WAKEWORD_DEBOUNCE_MS']?.trim();
    } catch (_) {
      raw = null;
    }
    if (raw != null && raw.isNotEmpty) {
      final int? v = int.tryParse(raw);
      if (v != null && v >= 0) {
        return v;
      }
    }
    return 2000;
  }
}
