import 'dart:convert';

enum AiseeReminderType { medication, appointment }

class AiseeReminder {
  AiseeReminder({
    required this.id,
    required this.type,
    required this.title,
    this.times,
    this.datetime,
    this.frequency,
    required this.createdAt,
  });

  final int id;
  final AiseeReminderType type;
  final String title;

  /// "07:00", "21:00" — for medication only.
  final List<String>? times;

  /// "2026-04-01 09:00" — for appointment only.
  final String? datetime;

  /// "daily" — for medication only.
  final String? frequency;
  final DateTime createdAt;

  /// Each time slot gets its own notification ID: base id + index.
  /// Appointment uses 2 IDs: `id + 100` (1h before) và `id` (30m before),
  /// khớp với logic `_scheduleAppointment`.
  List<int> get notificationIds {
    if (type == AiseeReminderType.medication && times != null) {
      return List<int>.generate(times!.length, (int i) => id + i);
    }
    if (type == AiseeReminderType.appointment) {
      return <int>[id, id + 100];
    }
    return <int>[id];
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'type': type.name,
    'title': title,
    if (times != null) 'times': times,
    if (datetime != null) 'datetime': datetime,
    if (frequency != null) 'frequency': frequency,
    'createdAt': createdAt.toIso8601String(),
  };

  factory AiseeReminder.fromJson(Map<String, dynamic> j) => AiseeReminder(
    id: j['id'] as int,
    type: AiseeReminderType.values.byName(j['type'] as String),
    title: j['title'] as String,
    times: (j['times'] as List<dynamic>?)?.cast<String>(),
    datetime: j['datetime'] as String?,
    frequency: j['frequency'] as String?,
    createdAt: DateTime.parse(j['createdAt'] as String),
  );

  static List<AiseeReminder> listFromJsonString(String raw) {
    final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
    return list
        .cast<Map<String, dynamic>>()
        .map(AiseeReminder.fromJson)
        .toList();
  }

  static String listToJsonString(List<AiseeReminder> items) {
    return jsonEncode(items.map((AiseeReminder r) => r.toJson()).toList());
  }
}
