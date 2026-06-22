import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../config/aisee_locale_controller.dart';
import '../generated/l10n/app_localizations.dart';
import 'aisee_reminder_service.dart';
import 'aisee_tts_preferences.dart';
import '../models/aisee_reminder.dart';

/// Checks reminders every 30 seconds while the app is in foreground.
/// When a reminder matches the current time, announces it via TTS.
class AiseeReminderAnnouncer with WidgetsBindingObserver {
  AiseeReminderAnnouncer._();
  static final AiseeReminderAnnouncer instance = AiseeReminderAnnouncer._();

  final FlutterTts _tts = FlutterTts();
  Timer? _timer;
  bool _running = false;
  bool _ttsReady = false;
  bool _ttsEnabled = true;

  /// Tracks announced reminders so we don't repeat within the same window.
  /// Key format: "{reminderId}_{timeSlotOrDatetime}_{dateKey}"
  final Set<String> _announced = <String>{};

  /// Window in minutes: if current time is within ±[_windowMinutes]
  /// of the scheduled time, we announce.
  static const int _windowMinutes = 2;

  Future<void> start() async {
    if (_running) return;
    _running = true;
    _ttsEnabled = AiseeTtsPreferences.instance.value;

    AiseeLocaleController.instance.addListener(_onLocaleChanged);
    AiseeTtsPreferences.instance.addListener(_onTtsPrefChanged);
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
    debugPrint(
      '[AiSee:Announcer] Started (TTS deferred, enabled=$_ttsEnabled)',
    );
  }

  void dispose() {
    _stopTimer();
    AiseeLocaleController.instance.removeListener(_onLocaleChanged);
    AiseeTtsPreferences.instance.removeListener(_onTtsPrefChanged);
    WidgetsBinding.instance.removeObserver(this);
    _tts.stop();
    _running = false;
    debugPrint('[AiSee:Announcer] Disposed');
  }

  void _onTtsPrefChanged() {
    _ttsEnabled = AiseeTtsPreferences.instance.value;
    if (!_ttsEnabled) {
      _tts.stop();
    }
  }

  Future<void> _ensureTts() async {
    if (_ttsReady) return;
    await _initTts();
    _ttsReady = true;
  }

  void _onLocaleChanged() {
    if (_ttsReady) {
      unawaited(_applyLocaleToTts());
    }
  }

  Future<void> _applyLocaleToTts() async {
    final AppLocalizations l = lookupAppLocalizations(
      AiseeLocaleController.instance.value,
    );
    await _tts.setLanguage(l.ttsLanguageTag);
  }

  Future<void> _initTts() async {
    await _applyLocaleToTts();
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _check());
    // Also check immediately on start.
    _check();
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _startTimer();
        debugPrint('[AiSee:Announcer] Resumed — timer restarted');
      case AppLifecycleState.paused:
        _stopTimer();
        debugPrint('[AiSee:Announcer] Paused — timer stopped');
      case _:
    }
  }

  Future<void> _check() async {
    try {
      final List<AiseeReminder> reminders = await AiseeReminderService.instance
          .loadAll();
      final DateTime now = DateTime.now();
      final String dateKey = '${now.year}-${now.month}-${now.day}';

      for (final AiseeReminder r in reminders) {
        switch (r.type) {
          case AiseeReminderType.medication:
            _checkMedication(r, now, dateKey);
          case AiseeReminderType.appointment:
            _checkAppointment(r, now, dateKey);
        }
      }
    } catch (e) {
      debugPrint('[AiSee:Announcer] Check error: $e');
    }
  }

  void _checkMedication(AiseeReminder reminder, DateTime now, String dateKey) {
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
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );
      final int diffMinutes = now.difference(target).inMinutes.abs();

      if (diffMinutes <= _windowMinutes) {
        _announced.add(key);
        final AppLocalizations l = lookupAppLocalizations(
          AiseeLocaleController.instance.value,
        );
        _speak(l.announcerMedication(reminder.title, time));
        return; // One announcement at a time.
      }
    }
  }

  void _checkAppointment(AiseeReminder reminder, DateTime now, String dateKey) {
    final String? dt = reminder.datetime;
    if (dt == null || dt.isEmpty) return;

    final String key = '${reminder.id}_appt_$dateKey';
    if (_announced.contains(key)) return;

    try {
      final DateTime parsed = DateTime.parse(dt.replaceFirst(' ', 'T'));
      final int minutesBefore = parsed.difference(now).inMinutes;

      // Announce when ~30 minutes before (window: 28-32 min).
      if (minutesBefore >= 28 && minutesBefore <= 32) {
        _announced.add(key);
        final AppLocalizations l = lookupAppLocalizations(
          AiseeLocaleController.instance.value,
        );
        _speak(l.announcerAppointment(reminder.title));
      }
    } catch (e) {
      debugPrint('[AiSee:Announcer] Parse appointment datetime error: $e');
    }
  }

  Future<void> _speak(String text) async {
    if (!_ttsEnabled) return;
    await _ensureTts();
    debugPrint('[AiSee:Announcer] Speaking: $text');
    await _tts.stop();
    await _tts.speak(text);
  }

  /// Đọc 1 reminder cụ thể — dùng khi user tap notification background
  /// và mở app, announcer phát TTS trước/sau khi navigate.
  Future<void> speakReminder(AiseeReminder reminder) async {
    if (!_ttsEnabled) return;
    final AppLocalizations l = lookupAppLocalizations(
      AiseeLocaleController.instance.value,
    );
    final String text = switch (reminder.type) {
      AiseeReminderType.medication =>
        l.announcerMedication(reminder.title, reminder.times?.first ?? ''),
      AiseeReminderType.appointment =>
        l.announcerAppointment(reminder.title),
    };
    await _speak(text);
  }

  /// Clear announced cache (e.g. at midnight or manual reset).
  void clearCache() {
    _announced.clear();
    debugPrint('[AiSee:Announcer] Cache cleared');
  }
}
