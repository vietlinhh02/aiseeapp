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
      'PHT': 'Asia/Manila',
      'WIB': 'Asia/Jakarta',
      'MYT': 'Asia/Kuala_Lumpur',
      'BST': 'Europe/London',
      'CET': 'Europe/Paris',
      'EET': 'Europe/Athens',
      'EST': 'America/New_York',
      'PST': 'America/Los_Angeles',
    };
    if (map.containsKey(name)) return map[name]!;
    // Thử dùng trực tiếp (nếu đã là IANA)
    return name;
  }

  /// Fallback cuối cùng: chọn IANA zone gần nhất theo offset.
  /// Tránh trả 'UTC' cho mọi offset không match (bug cũ làm notification
  /// bắn sai giờ ở Châu Âu/Mỹ/Ấn Độ).
  @visibleForTesting
  static String debugGuessTimezoneFromOffset(Duration offset) =>
      _guessTimezoneFromOffset(offset);

  static String _guessTimezoneFromOffset(Duration offset) {
    final int totalMinutes = offset.inMinutes;
    // (offset_minutes → IANA). Chỉ liệt kê zone lệch giờ nguyên hoặc
    // quá phổ biến để giữ map nhỏ.
    const Map<int, String> map = <int, String>{
      -480: 'America/Los_Angeles', // PST
      -300: 'America/New_York', // EST (chấp nhận lệch EDT)
      0: 'Europe/London',
      60: 'Europe/Paris',
      120: 'Europe/Athens',
      330: 'Asia/Kolkata',
      420: 'Asia/Ho_Chi_Minh',
      480: 'Asia/Singapore',
      540: 'Asia/Tokyo',
    };
    if (map.containsKey(totalMinutes)) return map[totalMinutes]!;
    // Offset không có trong map → thử tìm zone gần nhất (±60 phút)
    int bestDelta = 999999;
    String bestZone = 'UTC';
    for (final MapEntry<int, String> e in map.entries) {
      final int delta = (e.key - totalMinutes).abs();
      if (delta < bestDelta) {
        bestDelta = delta;
        bestZone = e.value;
      }
    }
    if (bestDelta <= 60) return bestZone;
    return 'UTC';
  }

  /// Sinh reminder ID mới, đảm bảo không trùng với bất kỳ reminder nào
  /// đã lưu trong storage.
  ///
  /// Bug fix #2: trước đây nhiều chỗ dùng
  /// `DateTime.now().millisecondsSinceEpoch % 100000` — modulo nhỏ khiến
  /// cứ ~100 giây ID lặp lại, 2 reminder tạo cách nhau < 100s sẽ có
  /// cùng ID → reminder cũ bị ghi đè (cả trong storage lẫn notification).
  ///
  /// Cách mới:
  /// 1. Lấy microsecondsSinceEpoch (int64) → modulo về max int32 an toàn
  ///    cho plugin notification. Microsecond nên cứ mỗi µs mới trùng.
  /// 2. Nếu vẫn trùng với ID đã lưu (rất hiếm) → +1 và bỏ qua wrap-around.
  /// 3. Thread-safe trong ngữ cảnh RPC serial của LiveKit (mỗi RPC chạy
  ///    tuần tự trong cùng isolate), nên không cần lock.
  @visibleForTesting
  static int debugNextReminderId(Set<int> taken) =>
      _nextReminderId(taken);

  static int _nextReminderId(Set<int> taken) {
    int candidate = DateTime.now().microsecondsSinceEpoch & 0x7FFFFFFF;
    if (candidate <= 0) {
      candidate = 1;
    }
    while (taken.contains(candidate)) {
      candidate = (candidate + 1) & 0x7FFFFFFF;
      if (candidate == 0) {
        candidate = 1;
      }
    }
    return candidate;
  }

  /// Sinh ID mới đồng bộ với storage hiện tại. Dùng khi AI/LiveKit tạo
  /// reminder mới (gọi trước khi build AiseeReminder).
  Future<int> nextReminderId() async {
    final List<AiseeReminder> all = await loadAll();
    return _nextReminderId(all.map((AiseeReminder r) => r.id).toSet());
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

    // Persist FIRST so a malformed datetime (or plugin failure) can never
    // drop the reminder from local storage. The backend already has the
    // authoritative copy; this is just to keep the in-app list + UI in sync
    // and let rescheduleAll() recover after a force-stop / reboot.
    final List<AiseeReminder> all = await loadAll();
    all.removeWhere((AiseeReminder r) => r.id == reminder.id);
    all.add(reminder);
    await _persist(all);

    try {
      switch (reminder.type) {
        case AiseeReminderType.medication:
          await _scheduleMedication(reminder);
        case AiseeReminderType.appointment:
          await _scheduleAppointment(reminder);
      }
    } catch (e, st) {
      // Lỗi parse datetime / plugin / permission → vẫn giữ reminder trong
      // local storage nhưng log rõ để debug. Backend FCM vẫn sẽ push nếu
      // backend schedule thành công.
      debugPrint(
        '[AiSee:Reminder] schedule failed for "${reminder.title}" '
        '(type=${reminder.type.name}): $e\n$st',
      );
    }
    debugPrint('[AiSee:Reminder] Saved: ${reminder.title} (id=${reminder.id})');
  }

  /// Re-schedule mọi reminder đã lưu. Gọi sau `init()` để phục hồi
  /// notification sau khi app bị force-stop / reboot / update.
  Future<int> rescheduleAll() async {
    if (!_initialized) await init();
    final List<AiseeReminder> all = await loadAll();
    if (all.isEmpty) {
      debugPrint('[AiSee:Reminder] rescheduleAll: nothing to do');
      return 0;
    }
    int ok = 0;
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    for (final AiseeReminder r in all) {
      try {
        bool shouldFire = true;
        if (r.type == AiseeReminderType.appointment) {
          final String? dt = r.datetime;
          if (dt == null || dt.isEmpty) {
            shouldFire = false;
          } else {
            try {
              // Bug fix #1: parse theo HCM rồi convert về local, tránh lệch
              // TZ với user ngoài VN.
              final tz.TZDateTime parsedHcm = _parseHcmDateTime(dt);
              final tz.TZDateTime grace =
                  parsedHcm.add(const Duration(hours: 1)).toLocal();
              shouldFire = grace.isAfter(now);
            } catch (_) {
              shouldFire = true; // giữ lại, hi vọng schedule sẽ parse OK
            }
          }
        }
        if (!shouldFire) continue;
        await _cancelExisting(r);
        switch (r.type) {
          case AiseeReminderType.medication:
            await _scheduleMedication(r);
          case AiseeReminderType.appointment:
            await _scheduleAppointment(r);
        }
        ok++;
      } catch (e) {
        debugPrint(
          '[AiSee:Reminder] reschedule failed for "${r.title}": $e',
        );
      }
    }
    debugPrint('[AiSee:Reminder] rescheduleAll: $ok/${all.length} ok');
    return ok;
  }

  Future<void> _cancelExisting(AiseeReminder reminder) async {
    for (final int notifId in reminder.notificationIds) {
      try {
        await _notif.cancel(id: notifId);
      } catch (_) {/* notif id not registered yet — ignore */}
    }
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
    if (dt == null || dt.isEmpty) {
      debugPrint(
        '[AiSee:Reminder] Appointment has empty datetime, skipping schedule',
      );
      return;
    }

    // Bug fix #1: `dt` từ AI luôn ở Asia/Ho_Chi_Minh (xem prompts.py).
    // Trước đây `DateTime.parse(...)` không có TZ → hiểu là local time của
    // máy → user ngoài VN sẽ thấy noti lệch tới mấy tiếng. Giờ parse thẳng
    // ở HCM rồi convert về `tz.local` để `zonedSchedule` chuyển sang giờ
    // local của user một cách chính xác.
    final tz.TZDateTime parsedHcm;
    try {
      parsedHcm = _parseHcmDateTime(dt);
    } catch (e) {
      debugPrint(
        '[AiSee:Reminder] Appointment datetime parse failed for "$dt": $e',
      );
      return;
    }

    final tz.TZDateTime nowLocal = tz.TZDateTime.now(tz.local);
    // Bug fix #4: đồng bộ với backend (internal/appointment/service.go
    // dùng 60 + 15 phút). Giữ thứ tự mốc 1h trước → 15m trước.
    const List<int> offsets = <int>[60, 15];
    // Mốc 1h dùng id+100, mốc 15m dùng id (khớp với AiseeReminder
    // .notificationIds để cancel đúng).
    final List<int> notifIds = <int>[reminder.id + 100, reminder.id];

    for (int i = 0; i < offsets.length; i++) {
      // Trừ trên TZDateTime HCM để giữ đúng ngày/giờ tuyệt đối rồi
      // convert về local timezone cho `zonedSchedule`.
      final tz.TZDateTime alertHcm = parsedHcm.subtract(
        Duration(minutes: offsets[i]),
      );
      final tz.TZDateTime scheduled = alertHcm.toLocal();
      if (!scheduled.isAfter(nowLocal)) {
        debugPrint(
          '[AiSee:Reminder] Appointment offset ${offsets[i]}m '
          'is in the past, skipping notif #${notifIds[i]}',
        );
        continue;
      }
      await _notif.zonedSchedule(
        id: notifIds[i],
        title: 'Lịch hẹn sắp tới',
        body: '${reminder.title} lúc $dt '
            '(còn ${offsets[i]} phút)',
        scheduledDate: scheduled,
        notificationDetails: _notificationDetails(),
        payload: notificationPayloadFor(
          reminder,
          notificationId: notifIds[i],
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      debugPrint(
        '[AiSee:Reminder] Scheduled appointment notif #${notifIds[i]} '
        'at $scheduled (offset ${offsets[i]}m)',
      );
    }
  }

  /// Parse string "yyyy-MM-dd HH:mm" thành [tz.TZDateTime] ở Asia/Ho_Chi_Minh.
  /// Vì AI luôn trả giờ theo GMT+7 (xem agent_worker/prompts.py), ta coi
  /// input là giờ HCM rồi mới convert sang `tz.local` khi cần schedule.
  @visibleForTesting
  static tz.TZDateTime debugParseHcmDateTime(String dt) => _parseHcmDateTime(dt);

  static tz.TZDateTime _parseHcmDateTime(String dt) {
    final String isoLike = dt.trim().replaceFirst(' ', 'T');
    final DateTime naive = DateTime.parse(isoLike); // chỉ lấy y/m/d/h/m
    final tz.Location hcm = tz.getLocation('Asia/Ho_Chi_Minh');
    return tz.TZDateTime(
      hcm,
      naive.year,
      naive.month,
      naive.day,
      naive.hour,
      naive.minute,
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
