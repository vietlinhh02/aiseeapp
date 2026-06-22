import 'dart:async';

import 'package:aiseeapp/generated/l10n/app_localizations.dart';
import 'package:aiseeapp/services/aisee_health_service.dart';
import 'package:aiseeapp/services/aisee_reminder_service.dart';
import 'package:aiseeapp/services/aisee_token_provider.dart';

enum ReminderFilter { all, medication, appointment, health }

class AiseeRemindersDataProvider {
  AiseeRemindersDataProvider({
    AiseeHealthService? healthService,
    Future<String?> Function()? readAccessToken,
  }) : _healthService = healthService,
       _readAccessToken = readAccessToken;

  final AiseeHealthService? _healthService;
  final Future<String?> Function()? _readAccessToken;

  Future<String?> accessToken() {
    if (_readAccessToken != null) return _readAccessToken();
    return AiseeTokenProvider.instance.accessToken();
  }

  AiseeHealthService _svc() => _healthService ?? AiseeHealthService();

  Future<List<Map<String, dynamic>>> fetchMedications(String accessToken) =>
      _svc().fetchMedications(accessToken);

  Future<List<Map<String, dynamic>>> fetchAppointments(String accessToken) =>
      _svc().fetchAppointments(accessToken);

  Future<List<Map<String, dynamic>>> fetchHealthLogs(String accessToken) =>
      _svc().fetchHealthLogs(accessToken);

  Future<void> markMedicationTaken(
    String accessToken,
    Map<String, dynamic> data,
  ) => _svc().markMedicationTaken(accessToken, data);

  Future<void> markMedicationSkipped(
    String accessToken,
    Map<String, dynamic> data,
  ) => _svc().markMedicationSkipped(accessToken, data);

  Future<void> cancelReminder(int localId) =>
      AiseeReminderService.instance.cancelReminder(localId);

  static String metricType(String type, AppLocalizations l10n) {
    return switch (type) {
      'blood_pressure' => l10n.metricBloodPressure,
      'heart_rate' => l10n.metricHeartRate,
      'temperature' => l10n.metricTemperature,
      'blood_sugar' => l10n.metricBloodSugar,
      'weight' => l10n.metricWeight,
      'height' => l10n.metricHeight,
      'spo2' => 'SpO2',
      _ => type,
    };
  }

  static String frequency(String? freq, AppLocalizations l10n) {
    return switch (freq?.toLowerCase()) {
      'daily' => l10n.freqDaily,
      'weekly' => l10n.freqWeekly,
      'monthly' => l10n.freqMonthly,
      'twice_daily' => l10n.freqTwiceDaily,
      _ => freq ?? '',
    };
  }

  static String itemTitle(Map<String, dynamic> item) {
    return item['name'] as String? ?? item['title'] as String? ?? '';
  }

  static String medSubtitle(
    Map<String, dynamic> item,
    AppLocalizations l10n,
  ) {
    final List<String> times =
        (item['times'] as List<dynamic>?)?.cast<String>() ?? <String>[];
    final String dosage = item['dosage'] as String? ?? '';
    final String freq = frequency(item['frequency'] as String?, l10n);
    final bool taken = item['taken'] == true;
    final bool skipped = item['skipped'] == true;

    final List<String> parts = <String>[];
    if (dosage.isNotEmpty) parts.add(dosage);
    if (times.isNotEmpty) parts.add(times.join(', '));
    if (freq.isNotEmpty) parts.add(freq);
    if (taken) {
      parts.add(l10n.remindersTaken);
    } else if (skipped) {
      parts.add(l10n.remindersSkipped);
    }
    return parts.join(' · ');
  }

  static String apptSubtitle(
    Map<String, dynamic> item,
    AppLocalizations l10n,
  ) {
    final String? dt = item['datetime'] as String?;
    final String? location = item['location'] as String?;
    final List<String> parts = <String>[];

    if (dt != null && dt.isNotEmpty) {
      try {
        final DateTime parsed = DateTime.parse(dt).toLocal();
        parts.add(
          '${parsed.day.toString().padLeft(2, '0')}/'
          '${parsed.month.toString().padLeft(2, '0')}/'
          '${parsed.year}'
          '${l10n.reminderAtSeparator}${parsed.hour.toString().padLeft(2, '0')}:'
          '${parsed.minute.toString().padLeft(2, '0')}',
        );
      } catch (_) {
        parts.add(dt);
      }
    }
    if (location != null && location.isNotEmpty) {
      parts.add(location);
    }
    return parts.join(' · ');
  }
}
