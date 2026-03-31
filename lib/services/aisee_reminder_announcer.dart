import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'aisee_reminder_service.dart';
import '../models/aisee_reminder.dart';

/// Checks reminders every 30 seconds while the app is in foreground.
/// When a reminder matches the current time, announces it via TTS.
class AiseeReminderAnnouncer with WidgetsBindingObserver {
  AiseeReminderAnnouncer._();
  static final AiseeReminderAnnouncer instance = AiseeReminderAnnouncer._();

  final FlutterTts _tts = FlutterTts();
  Timer? _timer;
  bool _running = false;

  /// Tracks announced reminders so we don't repeat within the same window.
  /// Key format: "{reminderId}_{timeSlotOrDatetime}_{dateKey}"
  final Set<String> _announced = <String>{};

  /// Window in minutes: if current time is within ±[_windowMinutes]
  /// of the scheduled time, we announce.
  static const int _windowMinutes = 2;

  Future<void> start() async {
    if (_running) return;
    _running = true;

    await _initTts();
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
    debugPrint('[AiSee:Announcer] Started');
  }

  void dispose() {
    _stopTimer();
    WidgetsBinding.instance.removeObserver(this);
    _tts.stop();
    _running = false;
    debugPrint('[AiSee:Announcer] Disposed');
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('vi-VN');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _check(),
    );
    // Also check immediately on start.
    _check();
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startTimer();
      debugPrint('[AiSee:Announcer] Resumed — timer restarted');
    } else if (state == AppLifecycleState.paused) {
      _stopTimer();
      debugPrint('[AiSee:Announcer] Paused — timer stopped');
    }
  }

  Future<void> _check() async {
    try {
      final List<AiseeReminder> reminders =
          await AiseeReminderService.instance.loadAll();
      final DateTime now = DateTime.now();
      final String dateKey =
          '${now.year}-${now.month}-${now.day}';

      for (final AiseeReminder r in reminders) {
        if (r.type == AiseeReminderType.medication) {
          _checkMedication(r, now, dateKey);
        } else if (r.type == AiseeReminderType.appointment) {
          _checkAppointment(r, now, dateKey);
        }
      }
    } catch (e) {
      debugPrint('[AiSee:Announcer] Check error: $e');
    }
  }

  void _checkMedication(
    AiseeReminder reminder,
    DateTime now,
    String dateKey,
  ) {
    final List<String> times = reminder.times ?? <String>[];
    for (final String time in times) {
      final String key = '${reminder.id}_${time}_$dateKey';
      if (_announced.contains(key)) continue;

      final List<String> parts = time.split(':');
      if (parts.length != 2) continue;
      final int hour = int.tryParse(parts[0]) ?? -1;
      final int minute = int.tryParse(parts[1]) ?? -1;
      if (hour < 0 || minute < 0) continue;

      final DateTime target = DateTime(
        now.year, now.month, now.day, hour, minute,
      );
      final int diffMinutes =
          now.difference(target).inMinutes.abs();

      if (diffMinutes <= _windowMinutes) {
        _announced.add(key);
        _speak(
          'Đến giờ uống thuốc. ${reminder.title}. '
          'Lúc $time.',
        );
        return; // One announcement at a time.
      }
    }
  }

  void _checkAppointment(
    AiseeReminder reminder,
    DateTime now,
    String dateKey,
  ) {
    final String? dt = reminder.datetime;
    if (dt == null || dt.isEmpty) return;

    final String key = '${reminder.id}_appt_$dateKey';
    if (_announced.contains(key)) return;

    try {
      final DateTime parsed = DateTime.parse(
        dt.replaceFirst(' ', 'T'),
      );
      final int minutesBefore =
          parsed.difference(now).inMinutes;

      // Announce when ~30 minutes before (window: 28-32 min).
      if (minutesBefore >= 28 && minutesBefore <= 32) {
        _announced.add(key);
        _speak(
          'Bạn có lịch hẹn ${reminder.title} '
          'sau khoảng 30 phút.',
        );
      }
    } catch (e) {
      debugPrint(
        '[AiSee:Announcer] Parse appointment datetime error: $e',
      );
    }
  }

  Future<void> _speak(String text) async {
    debugPrint('[AiSee:Announcer] Speaking: $text');
    await _tts.speak(text);
  }

  /// Clear announced cache (e.g. at midnight or manual reset).
  void clearCache() {
    _announced.clear();
    debugPrint('[AiSee:Announcer] Cache cleared');
  }
}
