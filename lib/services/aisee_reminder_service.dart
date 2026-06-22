import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/aisee_reminder.dart';

@pragma('vm:entry-point')
void aiseeReminderNotificationTapBackground(NotificationResponse response) {
  debugPrint(
    '[AiSee:Reminder] Background notification tapped: '
    'id=${response.id} payload=${response.payload}',
  );
}

@immutable
class AiseeReminderNotificationPayload {
  const AiseeReminderNotificationPayload({
    required this.reminderId,
    required this.notificationId,
    required this.type,
  });

  final int reminderId;
  final int notificationId;
  final AiseeReminderType type;
}

typedef AiseeReminderNotificationTapHandler =
    bool Function(AiseeReminderNotificationPayload payload);

class AiseeReminderService {
  AiseeReminderService._();
  static final AiseeReminderService instance = AiseeReminderService._();

  static const String _storageKey = 'aisee_reminders';

  final FlutterLocalNotificationsPlugin _notif =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  AiseeReminderNotificationPayload? _pendingTap;
  AiseeReminderNotificationTapHandler? _tapHandler;

  Future<void> init() async {
    if (_initialized) return;

    // Timezone: phải set local trước khi dùng tz.local
    tz.initializeTimeZones();
    final String timeZoneName = DateTime.now().timeZoneName;
    try {
      tz.setLocalLocation(tz.getLocation(_mapTimeZoneName(timeZoneName)));
    } catch (_) {
      // Fallback: dùng offset để tìm timezone
      final Duration offset = DateTime.now().timeZoneOffset;
      final String fallback = _guessTimezoneFromOffset(offset);
      tz.setLocalLocation(tz.getLocation(fallback));
    }
    debugPrint('[AiSee:Reminder] Timezone: ${tz.local.name}');

    const AndroidInitializationSettings android = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const DarwinInitializationSettings ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const InitializationSettings settings = InitializationSettings(
      android: android,
      iOS: ios,
    );
    await _notif.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
      onDidReceiveBackgroundNotificationResponse:
          aiseeReminderNotificationTapBackground,
    );

    _initialized = true;
    await _consumeLaunchNotificationIfNeeded();
    debugPrint('[AiSee:Reminder] Service initialized');
  }

  static void _onNotificationTap(NotificationResponse response) {
    debugPrint(
      '[AiSee:Reminder] Notification tapped: '
      'id=${response.id} payload=${response.payload}',
    );
    unawaited(instance._handleNotificationTap(response));
  }

  Future<void> requestPermissions() async {
    if (!_initialized) await init();
    final AndroidFlutterLocalNotificationsPlugin? android = _notif
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    try {
      await android?.requestNotificationsPermission();
      final bool? canScheduleExact = await android
          ?.canScheduleExactNotifications();
      if (canScheduleExact == false) {
        await android?.requestExactAlarmsPermission();
      }
    } catch (e) {
      debugPrint('[AiSee:Reminder] Android permission request failed: $e');
    }

    final IOSFlutterLocalNotificationsPlugin? ios = _notif
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    try {
      await ios?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (e) {
      debugPrint('[AiSee:Reminder] iOS permission request failed: $e');
    }
  }

  void setNotificationTapHandler(AiseeReminderNotificationTapHandler handler) {
    _tapHandler = handler;
    flushPendingNotificationNavigation();
  }

  Future<void> _consumeLaunchNotificationIfNeeded() async {
    try {
      final NotificationAppLaunchDetails? details = await _notif
          .getNotificationAppLaunchDetails();
      final NotificationResponse? response = details?.notificationResponse;
      if (details?.didNotificationLaunchApp == true && response != null) {
        await _handleNotificationTap(response);
      }
    } catch (e) {
      debugPrint('[AiSee:Reminder] Launch details failed: $e');
    }
  }

  Future<void> _handleNotificationTap(NotificationResponse response) async {
    final AiseeReminderNotificationPayload? payload = parseNotificationPayload(
      response.payload,
    );
    if (payload == null) {
      return;
    }
    _pendingTap = payload;
    flushPendingNotificationNavigation();
  }

  void flushPendingNotificationNavigation() {
    final AiseeReminderNotificationPayload? payload = _pendingTap;
    if (payload == null) {
      return;
    }
    if (_tapHandler?.call(payload) == true) {
      _pendingTap = null;
    }
  }

  @visibleForTesting
  static String notificationPayloadFor(
    AiseeReminder reminder, {
    required int notificationId,
  }) {
    return jsonEncode(<String, Object>{
      'screen': 'reminders',
      'id': reminder.id,
      'notification_id': notificationId,
      'type': reminder.type.name,
    });
  }

  @visibleForTesting
  static AiseeReminderNotificationPayload? parseNotificationPayload(
    String? raw,
  ) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    final String text = raw.trim();
    try {
      final Object? decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) {
        return _payloadFromMap(decoded);
      }
      if (decoded is Map) {
        return _payloadFromMap(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {
      return _payloadFromUri(text);
    }
    return _payloadFromUri(text);
  }

  static AiseeReminderNotificationPayload? _payloadFromUri(String raw) {
    final Uri? uri = Uri.tryParse(raw);
    if (uri == null || uri.scheme != 'aisee' || uri.host != 'reminders') {
      return null;
    }
    return _payloadFromMap(<String, dynamic>{
      'id': uri.queryParameters['id'],
      'notification_id': uri.queryParameters['notification_id'],
      'type': uri.queryParameters['type'],
    });
  }

  static AiseeReminderNotificationPayload? _payloadFromMap(
    Map<String, dynamic> map,
  ) {
    final int? reminderId = _intField(map, const <String>['id', 'reminder_id']);
    final int? notificationId = _intField(map, const <String>[
      'notification_id',
      'notificationId',
    ]);
    final String typeName = map['type']?.toString() ?? '';
    final AiseeReminderType? type = AiseeReminderType.values
        .where((AiseeReminderType t) => t.name == typeName)
        .firstOrNull;
    if (reminderId == null || notificationId == null || type == null) {
      return null;
    }
    return AiseeReminderNotificationPayload(
      reminderId: reminderId,
      notificationId: notificationId,
      type: type,
    );
  }

  static int? _intField(Map<String, dynamic> map, List<String> keys) {
    for (final String key in keys) {
      final Object? value = map[key];
      if (value is int) {
        return value;
      }
      if (value is String) {
        final int? parsed = int.tryParse(value);
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }

  /// Map tên timezone ngắn (VD: "ICT", "GMT+7") sang IANA.
  static String _mapTimeZoneName(String name) {
    const Map<String, String> map = <String, String>{
      'ICT': 'Asia/Ho_Chi_Minh',
      'VST': 'Asia/Ho_Chi_Minh',
      'SGT': 'Asia/Singapore',
      'JST': 'Asia/Tokyo',
      'KST': 'Asia/Seoul',
      'CST': 'Asia/Shanghai',
      'IST': 'Asia/Kolkata',
    };
    if (map.containsKey(name)) return map[name]!;
    // Thử dùng trực tiếp (nếu đã là IANA)
    return name;
  }

  static String _guessTimezoneFromOffset(Duration offset) {
    final int hours = offset.inHours;
    switch (hours) {
      case 7:
        return 'Asia/Ho_Chi_Minh';
      case 8:
        return 'Asia/Singapore';
      case 9:
        return 'Asia/Tokyo';
      default:
        return 'UTC';
    }
  }

  Future<List<AiseeReminder>> loadAll() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return <AiseeReminder>[];
    try {
      return AiseeReminder.listFromJsonString(raw);
    } catch (e) {
      debugPrint('[AiSee:Reminder] loadAll parse error: $e');
      return <AiseeReminder>[];
    }
  }

  Future<void> _persist(List<AiseeReminder> items) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, AiseeReminder.listToJsonString(items));
  }

  Future<void> scheduleReminder(AiseeReminder reminder) async {
    if (!_initialized) await init();
    debugPrint(
      '[AiSee:Reminder] scheduleReminder: '
      'type=${reminder.type.name} title=${reminder.title}',
    );
    debugPrint(
      '[AiSee:Reminder] tz.local=${tz.local.name} '
      'now=${tz.TZDateTime.now(tz.local)}',
    );

    switch (reminder.type) {
      case AiseeReminderType.medication:
        await _scheduleMedication(reminder);
      case AiseeReminderType.appointment:
        await _scheduleAppointment(reminder);
    }

    final List<AiseeReminder> all = await loadAll();
    all.add(reminder);
    await _persist(all);
    debugPrint('[AiSee:Reminder] Saved: ${reminder.title} (id=${reminder.id})');
  }

  /// Test: push notification ngay lập tức để verify hệ thống hoạt động.
  Future<void> showTestNotification() async {
    if (!_initialized) await init();
    await _notif.show(
      id: 99999,
      title: 'Test nhắc nhở',
      body: 'Nếu bạn thấy thông báo này, notification hoạt động!',
      notificationDetails: _notificationDetails(),
    );
    debugPrint('[AiSee:Reminder] Test notification pushed');
  }

  Future<void> _scheduleMedication(AiseeReminder reminder) async {
    final List<String> times = reminder.times ?? <String>[];
    for (int i = 0; i < times.length; i++) {
      final List<String> parts = times[i].split(':');
      if (parts.length != 2) continue;
      final int hour = int.tryParse(parts[0]) ?? 0;
      final int minute = int.tryParse(parts[1]) ?? 0;
      final int notifId = reminder.id + i;

      final tz.TZDateTime scheduled = _nextInstanceOfTime(hour, minute);

      await _notif.zonedSchedule(
        id: notifId,
        title: 'Nhắc uống thuốc',
        body: '${reminder.title} - ${times[i]}',
        scheduledDate: scheduled,
        notificationDetails: _notificationDetails(),
        payload: notificationPayloadFor(reminder, notificationId: notifId),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint(
        '[AiSee:Reminder] Scheduled medication notif #$notifId'
        ' at ${times[i]} daily',
      );
    }
  }

  Future<void> _scheduleAppointment(AiseeReminder reminder) async {
    final String? dt = reminder.datetime;
    if (dt == null || dt.isEmpty) return;

    final DateTime parsed = DateTime.parse(dt.replaceFirst(' ', 'T'));
    final DateTime alertTime = parsed.subtract(const Duration(minutes: 30));
    final tz.TZDateTime scheduled = tz.TZDateTime.from(alertTime, tz.local);

    if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) {
      debugPrint(
        '[AiSee:Reminder] Appointment in the past, skipping notification',
      );
      return;
    }

    await _notif.zonedSchedule(
      id: reminder.id,
      title: 'Lịch hẹn sắp tới',
      body: '${reminder.title} lúc $dt',
      scheduledDate: scheduled,
      notificationDetails: _notificationDetails(),
      payload: notificationPayloadFor(reminder, notificationId: reminder.id),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
    debugPrint(
      '[AiSee:Reminder] Scheduled appointment notif #${reminder.id}'
      ' at $alertTime',
    );
  }

  Future<void> cancelReminder(int reminderId) async {
    final List<AiseeReminder> all = await loadAll();
    final int idx = all.indexWhere((AiseeReminder r) => r.id == reminderId);
    if (idx == -1) return;

    final AiseeReminder reminder = all[idx];
    for (final int notifId in reminder.notificationIds) {
      await _notif.cancel(id: notifId);
    }
    all.removeAt(idx);
    await _persist(all);
    debugPrint(
      '[AiSee:Reminder] Cancelled: ${reminder.title} (id=$reminderId)',
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'aisee_reminders',
        'Nhắc nhở AiSee',
        channelDescription: 'Nhắc nhở uống thuốc và lịch hẹn',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }
}
