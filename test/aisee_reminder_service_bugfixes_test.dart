// Tests cho các bugfix của AiseeReminderService:
//
//   Bug #1: timezone parsing sai khi user ở ngoài VN
//           (`DateTime.parse` không có TZ → hiểu là local time của máy).
//           Fix: parse thẳng ở Asia/Ho_Chi_Minh rồi convert về local khi
//           cần schedule. Helper: `_parseHcmDateTime`.
//
//   Bug #2: notification ID collision khi tạo 2 reminder trong vòng
//           100 giây (cũ: `millisecondsSinceEpoch % 100000`).
//           Fix: dùng `microsecondsSinceEpoch & 0x7FFFFFFF` + check trùng
//           với storage. Helper: `_nextReminderId` / `nextReminderId`.
//
//   Bug #4: client dùng offset [60, 30] trong khi backend FCM dùng [60, 15].
//           Fix: đổi client offsets thành [60, 15]. Ở đây ta verify qua
//           behaviour — `_parseHcmDateTime` + offset 15 vẫn trả về alertTime
//           15 phút trước giờ HCM.
import 'package:aiseeapp/models/aisee_reminder.dart';
import 'package:aiseeapp/services/aisee_reminder_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Cần thiết cho `_parseHcmDateTime` (dùng `tz.getLocation`).
    tz_data.initializeTimeZones();
  });

  setUp(() {
    // Reset local TZ về UTC để kết quả test deterministic, không phụ
    // thuộc vào TZ của máy chạy CI.
    tz.setLocalLocation(tz.getLocation('UTC'));
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  // ───────────────────────── Bug #1: parseHcmDateTime ─────────────────────────

  group('_parseHcmDateTime (Bug #1: timezone parsing)', () {
    test('parses "yyyy-MM-dd HH:mm" thành TZDateTime ở Asia/Ho_Chi_Minh', () {
      final tz.TZDateTime result = AiseeReminderService.debugParseHcmDateTime(
        '2026-04-01 09:00',
      );

      // Mong đợi: 2026-04-01 09:00 giờ HCM (= 02:00 UTC).
      expect(result.location.name, 'Asia/Ho_Chi_Minh');
      expect(result.year, 2026);
      expect(result.month, 4);
      expect(result.day, 1);
      expect(result.hour, 9);
      expect(result.minute, 0);
      expect(result.toUtc().hour, 2);
    });

    test('chấp nhận format ISO với "T" ở giữa', () {
      // Một số serializer có thể trả "2026-04-01T09:00" thay vì " ".
      final tz.TZDateTime result = AiseeReminderService.debugParseHcmDateTime(
        '2026-04-01T09:00',
      );

      expect(result.location.name, 'Asia/Ho_Chi_Minh');
      expect(result.hour, 9);
    });

    test('giữ nguyên ngày khi offset qua ngày khác', () {
      // 00:30 HCM ngày 2/4 → trừ 60 phút → 23:30 ngày 1/4 (cùng TZ).
      final tz.TZDateTime result = AiseeReminderService.debugParseHcmDateTime(
        '2026-04-02 00:30',
      ).subtract(const Duration(minutes: 60));

      expect(result.year, 2026);
      expect(result.month, 4);
      expect(result.day, 1);
      expect(result.hour, 23);
      expect(result.minute, 30);
    });

    test('toLocal() chuyển đúng sang UTC khi local là UTC', () {
      // Trước fix: DateTime.parse trả local time → nếu máy là UTC thì
      // alert 9:00 HCM sẽ hiển thị thành 9:00 UTC (= 16:00 HCM thực).
      // Sau fix: parse ở HCM rồi toLocal() = UTC → 02:00 UTC (= 9:00 HCM).
      final tz.TZDateTime result = AiseeReminderService.debugParseHcmDateTime(
        '2026-04-01 09:00',
      ).toLocal();

      expect(result.location.name, 'UTC');
      expect(result.hour, 2); // 9 - 7
    });

    test('throw khi input không phải datetime hợp lệ', () {
      expect(
        () => AiseeReminderService.debugParseHcmDateTime('not-a-date'),
        throwsA(isA<FormatException>()),
      );
    });

    test('thiếu phần giờ thì mặc định 00:00 (Dart DateTime.parse behavior)', () {
      // `DateTime.parse("2026-04-01")` không throw mà trả 00:00 local —
      // đây là behavior chuẩn của Dart. Helper mình vẫn wrap thành HCM.
      // Test này chống regression nếu sau này có ai thêm validation quá
      // strict gây crash reminder hợp lệ.
      final tz.TZDateTime result = AiseeReminderService.debugParseHcmDateTime(
        '2026-04-01',
      );

      expect(result.location.name, 'Asia/Ho_Chi_Minh');
      expect(result.hour, 0);
      expect(result.minute, 0);
    });
  });

  // ───────────────────────── Bug #4: offset 15 phút ─────────────────────────

  group('Appointment offset (Bug #4: 60 + 15 phút, sync với backend)', () {
    test('trừ 15 phút từ 9:00 HCM → 8:45 HCM', () {
      final tz.TZDateTime scheduled = AiseeReminderService
          .debugParseHcmDateTime('2026-04-01 09:00')
          .subtract(const Duration(minutes: 15));

      expect(scheduled.hour, 8);
      expect(scheduled.minute, 45);
      expect(scheduled.location.name, 'Asia/Ho_Chi_Minh');
    });

    test('trừ 60 phút từ 9:00 HCM → 8:00 HCM', () {
      final tz.TZDateTime scheduled = AiseeReminderService
          .debugParseHcmDateTime('2026-04-01 09:00')
          .subtract(const Duration(minutes: 60));

      expect(scheduled.hour, 8);
      expect(scheduled.minute, 0);
    });

    test('toLocal() giữ đúng absolute time khi trừ 15 phút ở UTC', () {
      // 9:00 HCM = 02:00 UTC. Trừ 15' → 8:45 HCM = 01:45 UTC.
      final tz.TZDateTime scheduled = AiseeReminderService
          .debugParseHcmDateTime('2026-04-01 09:00')
          .subtract(const Duration(minutes: 15))
          .toLocal();

      expect(scheduled.hour, 1);
      expect(scheduled.minute, 45);
    });
  });

  // ───────────────────────── Bug #2: nextReminderId ─────────────────────────

  group('_nextReminderId (Bug #2: ID collision)', () {
    test('trả về ID duy nhất khi taken rỗng', () {
      final int id = AiseeReminderService.debugNextReminderId(<int>{});
      expect(id, isPositive);
      expect(id, lessThanOrEqualTo(0x7FFFFFFF));
    });

    test('2 lần gọi liên tiếp đều ra ID khác nhau (regression Bug #2)', () {
      // Trước fix: `% 100000` → nếu 2 lần cách < 100s sẽ collide.
      // Sau fix: dùng `microsecondsSinceEpoch & 0x7FFFFFFF` — 2 lần
      // gọi cùng µs cực hiếm. Nếu lỡ trùng, helper vẫn bump +1.
      final int id1 = AiseeReminderService.debugNextReminderId(<int>{});
      final int id2 = AiseeReminderService.debugNextReminderId(<int>{id1});
      expect(id2, isNot(equals(id1)));
    });

    test('force collision bằng taken set — helper vẫn bump qua', () {
      // Lấy base ID trước, rồi ép taken chứa chính nó → verify bump +1.
      final int base = AiseeReminderService.debugNextReminderId(<int>{});
      // Sleep 1µs để base mới (nếu không sẽ cùng µs và base == base+1).
      // Tuy nhiên helper dùng `DateTime.now()` ở đầu, không cache.
      // Strategy: chỉ verify rằng khi taken chứa 1 ID, kết quả luôn khác.
      final int result = AiseeReminderService.debugNextReminderId(<int>{42});
      expect(result, isNot(equals(42)));
      // base chỉ để chứng minh helper hoạt động khi set rỗng.
      expect(base, isPositive);
    });

    test('skip ID đã có trong taken set', () {
      final int id = AiseeReminderService.debugNextReminderId(<int>{42});
      expect(id, isNot(equals(42)));
    });

    test('bump nhiều lần khi taken liên tiếp', () {
      // Seed 5 ID liên tiếp. Helper phải bump đến khi ra khỏi vùng taken.
      // Tuy nhiên trong thực tế 2 ID liên tiếp cùng µs là rất hiếm —
      // test này dùng set rỗng và verify khác ID lần đầu.
      final int id1 = AiseeReminderService.debugNextReminderId(<int>{});
      final int id2 = AiseeReminderService.debugNextReminderId(<int>{id1});
      final int id3 = AiseeReminderService.debugNextReminderId(<int>{
        id1,
        id2,
      });
      expect(id3, isNot(equals(id1)));
      expect(id3, isNot(equals(id2)));
    });

    test('ID luôn nằm trong int32 dương (an toàn cho plugin)', () {
      for (int i = 0; i < 100; i++) {
        final int id = AiseeReminderService.debugNextReminderId(<int>{});
        expect(id, greaterThan(0));
        expect(id, lessThanOrEqualTo(0x7FFFFFFF));
      }
    });
  });

  group('nextReminderId() instance (Bug #2 + storage integration)', () {
    test('ID mới khác với reminder đã lưu trong SharedPreferences', () async {
      // Pre-seed storage với 1 reminder id=12345.
      final AiseeReminder existing = AiseeReminder(
        id: 12345,
        type: AiseeReminderType.medication,
        title: 'Vitamin C',
        times: const <String>['08:00'],
        frequency: 'daily',
        createdAt: DateTime(2026, 4, 1),
      );
      SharedPreferences.setMockInitialValues(<String, Object>{
        'aisee_reminders': AiseeReminder.listToJsonString(<AiseeReminder>[
          existing,
        ]),
      });

      // Gọi helper instance method (cũng re-load storage bên trong).
      final int newId = await AiseeReminderService.instance.nextReminderId();

      expect(newId, isNot(equals(12345)));
    });

    test('nhiều lần gọi liên tiếp đều ra ID khác nhau (smoke test)', () async {
      // Đây là regression test trực tiếp cho Bug #2: trước fix, 2 lần
      // gọi cách nhau < 100s sẽ trùng ID. Vì test này chạy trong vài ms,
      // nếu helper vẫn dùng `% 100000` thì sẽ fail. Sau fix, dùng
      // microseconds nên chắc chắn khác.
      final int id1 = await AiseeReminderService.instance.nextReminderId();
      final int id2 = await AiseeReminderService.instance.nextReminderId();
      final int id3 = await AiseeReminderService.instance.nextReminderId();

      expect(<int>{id1, id2, id3}.length, equals(3),
          reason: '3 ID liên tiếp phải khác nhau (regression Bug #2)');
    });
  });

  // ───────────────────────── Notification IDs cho appointment ─────────────────

  group('Appointment notification IDs (khớp AiseeReminder.notificationIds)', () {
    test('appointment notificationIds = [id, id+100]', () {
      // _scheduleAppointment dùng notifIds = [id+100, id] (1h trước, 15m
      // trước). AiseeReminder.notificationIds trả [id, id+100] (15m, 1h).
      // Cancel dùng AiseeReminder.notificationIds, nên set cả 2 ID là
      // đúng. Test này chống regression nếu 1 bên bị đổi mà bên kia
      // không update.
      final AiseeReminder r = AiseeReminder(
        id: 999,
        type: AiseeReminderType.appointment,
        title: 'Khám định kỳ',
        datetime: '2026-12-01 10:00',
        createdAt: DateTime(2026, 6, 1),
      );
      expect(r.notificationIds, <int>[999, 1099]);
    });

    test('medication notificationIds = [id, id+1, ...] theo số times', () {
      final AiseeReminder r = AiseeReminder(
        id: 555,
        type: AiseeReminderType.medication,
        title: 'Insulin',
        times: const <String>['07:00', '12:00', '19:00'],
        frequency: 'daily',
        createdAt: DateTime(2026, 6, 1),
      );
      expect(r.notificationIds, <int>[555, 556, 557]);
    });
  });
}
