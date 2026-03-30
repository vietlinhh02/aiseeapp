import 'dart:async';
import 'dart:ui' show FrameTiming;

import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Bật bằng `--dart-define=AISEE_DEBUG=true` hoặc `AISEE_DEBUG=true` trong `assets/app_config.env`.
abstract final class AiseeDebugConfig {
  static const bool _dartDebug = bool.fromEnvironment(
    'AISEE_DEBUG',
    defaultValue: false,
  );

  static bool get enabled {
    if (_dartDebug) {
      return true;
    }
    if (!dotenv.isInitialized) {
      return false;
    }
    final String? v = dotenv.maybeGet('AISEE_DEBUG')?.trim().toLowerCase();
    return v == '1' || v == 'true' || v == 'yes';
  }

  /// Lớp phủ FPS/graph (rất nhiều thông tin trên màn hình).
  static bool get showPerformanceOverlay {
    if (!enabled) {
      return false;
    }
    const bool o = bool.fromEnvironment(
      'AISEE_PERF_OVERLAY',
      defaultValue: false,
    );
    if (o) {
      return true;
    }
    if (!dotenv.isInitialized) {
      return false;
    }
    final String? v =
        dotenv.maybeGet('AISEE_PERF_OVERLAY')?.trim().toLowerCase();
    return v == '1' || v == 'true' || v == 'yes';
  }
}

/// Thống kê tải UI / tần suất sự kiện (giúp đoán chỗ làm máy nóng).
final class AiseePerformanceDebug {
  AiseePerformanceDebug._();

  static final AiseePerformanceDebug instance = AiseePerformanceDebug._();

  static const Duration _reportInterval = Duration(seconds: 5);

  bool _installed = false;
  Timer? _reportTimer;
  void Function(List<FrameTiming>)? _timingsHandler;

  int _frames = 0;
  int _slowOver16ms = 0;
  int _slowOver33ms = 0;
  int _maxTotalMicros = 0;

  int _waveTimerTicks = 0;
  int _activeSpeakerEvents = 0;
  int _assistantEnergyUpdates = 0;

  /// Text hiển thị trên HUD (cập nhật mỗi [_reportInterval]).
  final ValueNotifier<String> hudReport = ValueNotifier<String>(
    'AiSee DEBUG\nChờ 5s để có số liệu…',
  );

  void install() {
    if (_installed || !AiseeDebugConfig.enabled) {
      return;
    }
    _installed = true;
    debugPrint(
      '[AiSee:debug] Đã bật (AISEE_DEBUG). Mỗi ${_reportInterval.inSeconds}s in thống kê. '
      'Overlay: thêm AISEE_PERF_OVERLAY=true.',
    );

    _timingsHandler = _onTimings;
    WidgetsBinding.instance.addTimingsCallback(_timingsHandler!);

    _reportTimer = Timer.periodic(_reportInterval, (_) => _emitReport());
  }

  void dispose() {
    if (!_installed) {
      return;
    }
    _reportTimer?.cancel();
    _reportTimer = null;
    if (_timingsHandler != null) {
      WidgetsBinding.instance.removeTimingsCallback(_timingsHandler!);
      _timingsHandler = null;
    }
    _installed = false;
    hudReport.value = 'AiSee DEBUG (đã tắt)';
  }

  void recordWaveTimerTick() {
    _waveTimerTicks++;
  }

  void recordActiveSpeakerEvent() {
    _activeSpeakerEvents++;
  }

  /// Chỉ gọi khi giá trị năng lượng sóng thực sự đổi (gây rebuild UI).
  void recordAssistantEnergyChanged() {
    _assistantEnergyUpdates++;
  }

  void _onTimings(List<FrameTiming> timings) {
    for (final FrameTiming t in timings) {
      _frames++;
      final int total = t.totalSpan.inMicroseconds;
      if (total > _maxTotalMicros) {
        _maxTotalMicros = total;
      }
      if (total > 16666) {
        _slowOver16ms++;
      }
      if (total > 33333) {
        _slowOver33ms++;
      }
    }
  }

  void _emitReport() {
    final int sec = _reportInterval.inSeconds;
    final double fps = sec > 0 && _frames > 0 ? _frames / sec : 0;
    final double maxMs = _maxTotalMicros / 1000.0;
    final double wavePerS = sec > 0 ? _waveTimerTicks / sec : 0;
    hudReport.value =
        'AiSee DEBUG (cửa sổ ${sec}s)\n'
        'Khung hình: $_frames  ~${fps.toStringAsFixed(0)} fps\n'
        'Chậm >16ms: $_slowOver16ms   >33ms: $_slowOver33ms   max: ${maxMs.toStringAsFixed(1)} ms\n'
        'Timer sóng 50ms: $_waveTimerTicks (${wavePerS.toStringAsFixed(0)}/s)\n'
        'ActiveSpeakers: $_activeSpeakerEvents   Đổi năng lượng sóng: $_assistantEnergyUpdates';
    debugPrint(
      '[AiSee:debug] ${sec}s | frames=$_frames (~${fps.toStringAsFixed(0)} fps) '
      'chậm>16ms=$_slowOver16ms chậm>33ms=$_slowOver33ms max=${maxMs.toStringAsFixed(1)}ms',
    );
    debugPrint(
      '[AiSee:debug] ${sec}s | waveTimerTicks=$_waveTimerTicks '
      '(${(_waveTimerTicks / sec).toStringAsFixed(0)}/s) '
      'activeSpeakerEvents=$_activeSpeakerEvents '
      'assistantEnergyUpdates=$_assistantEnergyUpdates',
    );
    _frames = 0;
    _slowOver16ms = 0;
    _slowOver33ms = 0;
    _maxTotalMicros = 0;
    _waveTimerTicks = 0;
    _activeSpeakerEvents = 0;
    _assistantEnergyUpdates = 0;
  }
}
