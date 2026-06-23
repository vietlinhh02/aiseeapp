import 'package:aiseeapp/models/aisee_reminder.dart';
import 'package:aiseeapp/services/aisee_ai_session.dart';
import 'package:aiseeapp/services/aisee_assistant_device_command_handler.dart';
import 'package:aiseeapp/services/aisee_reminder_service.dart';
import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Fake platform cho flutter_local_notifications — trả về null cho mọi
/// method call nhờ `noSuchMethod`. Cần thiết vì
/// `resolvePlatformSpecificImplementation` trong plugin yêu cầu
/// `FlutterLocalNotificationsPlatform.instance` đã được init.
///
/// MethodChannel mock không đủ vì `_platform` field trong plugin được
/// lấy trực tiếp từ `FlutterLocalNotificationsPlatform.instance`, không
/// qua MethodChannel.
class _FakeLocalNotificationsPlatform extends FlutterLocalNotificationsPlatform {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    // Trả về null cho mọi Future<T?> — plugin chỉ await, không check
    // giá trị. Đây là đủ cho init(), zonedSchedule(), cancel(), show().
    return null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('start_call delegates to injected launcher callback', () async {
    final AiseeDefaultAssistantDeviceCommandHandler handler =
        AiseeDefaultAssistantDeviceCommandHandler(
          onStartCall: (Map<String, dynamic> params) async {
            expect(params['room_name'], 'call-1');
            return <String, Object?>{'status': 'answered'};
          },
        );

    final Map<String, Object?> result = await handler.handle(
      const AiseeAiDeviceCommandRequest(
        requestId: 'tool-1',
        name: 'start_call',
        params: <String, dynamic>{'room_name': 'call-1', 'token': 'abc'},
      ),
    );

    expect(result, <String, Object?>{'status': 'answered'});
    await handler.dispose();
  });

  test('start_call returns unavailable when launcher is missing', () async {
    final AiseeDefaultAssistantDeviceCommandHandler handler =
        AiseeDefaultAssistantDeviceCommandHandler();

    final Map<String, Object?> result = await handler.handle(
      const AiseeAiDeviceCommandRequest(
        requestId: 'tool-2',
        name: 'start_call',
        params: <String, dynamic>{'room_name': 'call-2', 'token': 'def'},
      ),
    );

    expect(result['status'], 'unavailable');
    await handler.dispose();
  });

  // ─────────────────── Bug #5: schedule_reminder device_command ───────────────────
  //
  // Trước fix: WS `device_command` cho `schedule_reminder` rơi vào default
  // case → throw "Unsupported command". Sau fix: route tới
  // AiseeReminderService giống như LiveKit RPC.

  setUpAll(() {
    tz_data.initializeTimeZones();
    // Inject fake platform TRƯỚC khi test chạy — FlutterLocalNotificationsPlugin
    // cache `_platform` từ `FlutterLocalNotificationsPlatform.instance`
    // ngay lần đầu `resolvePlatformSpecificImplementation` được gọi.
    FlutterLocalNotificationsPlatform.instance =
        _FakeLocalNotificationsPlatform();
  });

  setUp(() {
    tz.setLocalLocation(tz.getLocation('UTC'));
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('schedule_reminder tạo medication reminder và persist vào storage',
      () async {
    final AiseeDefaultAssistantDeviceCommandHandler handler =
        AiseeDefaultAssistantDeviceCommandHandler();

    final Map<String, Object?> result = await handler.handle(
      const AiseeAiDeviceCommandRequest(
        requestId: 'tool-3',
        name: 'schedule_reminder',
        params: <String, dynamic>{
          'type': 'medication',
          'name': 'Vitamin D',
          'times': <String>['08:00', '20:00'],
          'frequency': 'daily',
        },
      ),
    );

    expect(result['status'], 'ok');
    expect(result['type'], 'medication');
    expect(result['reminder_id'], isA<int>());
    expect((result['reminder_id']! as int), greaterThan(0));

    // Verify reminder đã được persist.
    final List<AiseeReminder> stored =
        await AiseeReminderService.instance.loadAll();
    expect(stored, hasLength(1));
    expect(stored.first.title, 'Vitamin D');
    expect(stored.first.type, AiseeReminderType.medication);
    expect(stored.first.times, <String>['08:00', '20:00']);
    expect(stored.first.frequency, 'daily');
    expect(stored.first.id, result['reminder_id']);

    await handler.dispose();
  });

  test('schedule_reminder tạo appointment reminder với datetime', () async {
    final AiseeDefaultAssistantDeviceCommandHandler handler =
        AiseeDefaultAssistantDeviceCommandHandler();

    final Map<String, Object?> result = await handler.handle(
      const AiseeAiDeviceCommandRequest(
        requestId: 'tool-4',
        name: 'schedule_reminder',
        params: <String, dynamic>{
          'type': 'appointment',
          'name': 'Khám định kỳ',
          'datetime': '2026-12-01 10:00',
        },
      ),
    );

    expect(result['status'], 'ok');
    expect(result['type'], 'appointment');

    final List<AiseeReminder> stored =
        await AiseeReminderService.instance.loadAll();
    expect(stored, hasLength(1));
    expect(stored.first.type, AiseeReminderType.appointment);
    expect(stored.first.datetime, '2026-12-01 10:00');
    expect(stored.first.title, 'Khám định kỳ');

    await handler.dispose();
  });

  test('schedule_reminder chấp nhận alias "title" và "reminder_type"', () async {
    // Một số serializer có thể dùng key khác — verify fallback path.
    final AiseeDefaultAssistantDeviceCommandHandler handler =
        AiseeDefaultAssistantDeviceCommandHandler();

    final Map<String, Object?> result = await handler.handle(
      const AiseeAiDeviceCommandRequest(
        requestId: 'tool-5',
        name: 'schedule_reminder',
        params: <String, dynamic>{
          'reminder_type': 'medication',
          'title': 'Aspirin',
          'times': <String>['09:00'],
        },
      ),
    );

    expect(result['status'], 'ok');
    final List<AiseeReminder> stored =
        await AiseeReminderService.instance.loadAll();
    expect(stored.first.title, 'Aspirin');
    expect(stored.first.type, AiseeReminderType.medication);

    await handler.dispose();
  });

  test('schedule_reminder throw khi missing name', () async {
    final AiseeDefaultAssistantDeviceCommandHandler handler =
        AiseeDefaultAssistantDeviceCommandHandler();

    expect(
      () => handler.handle(
        const AiseeAiDeviceCommandRequest(
          requestId: 'tool-6',
          name: 'schedule_reminder',
          params: <String, dynamic>{
            'type': 'medication',
            'times': <String>['08:00'],
          },
        ),
      ),
      throwsA(isA<AiseeAssistantDeviceCommandException>()),
    );

    await handler.dispose();
  });

  test('schedule_reminder throw khi type không hỗ trợ', () async {
    final AiseeDefaultAssistantDeviceCommandHandler handler =
        AiseeDefaultAssistantDeviceCommandHandler();

    expect(
      () => handler.handle(
        const AiseeAiDeviceCommandRequest(
          requestId: 'tool-7',
          name: 'schedule_reminder',
          params: <String, dynamic>{
            'type': 'unknown_type',
            'name': 'whatever',
          },
        ),
      ),
      throwsA(isA<AiseeAssistantDeviceCommandException>()),
    );

    await handler.dispose();
  });

  test('2 schedule_reminder liên tiếp đều ra reminder_id khác nhau '
      '(regression Bug #2)', () async {
    // Verify bug #2 fix cũng áp dụng cho WS device_command path.
    final AiseeDefaultAssistantDeviceCommandHandler handler =
        AiseeDefaultAssistantDeviceCommandHandler();

    final Map<String, Object?> r1 = await handler.handle(
      const AiseeAiDeviceCommandRequest(
        requestId: 'tool-8',
        name: 'schedule_reminder',
        params: <String, dynamic>{
          'type': 'medication',
          'name': 'Thuốc A',
          'times': <String>['08:00'],
        },
      ),
    );
    final Map<String, Object?> r2 = await handler.handle(
      const AiseeAiDeviceCommandRequest(
        requestId: 'tool-9',
        name: 'schedule_reminder',
        params: <String, dynamic>{
          'type': 'medication',
          'name': 'Thuốc B',
          'times': <String>['20:00'],
        },
      ),
    );

    expect(r1['reminder_id'], isNot(equals(r2['reminder_id'])));
    final List<AiseeReminder> stored =
        await AiseeReminderService.instance.loadAll();
    expect(stored, hasLength(2));

    await handler.dispose();
  });
}
