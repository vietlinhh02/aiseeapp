import 'package:aiseeapp/models/aisee_reminder.dart';
import 'package:aiseeapp/services/aisee_reminder_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds and parses medication notification payload', () {
    final AiseeReminder reminder = AiseeReminder(
      id: 42,
      type: AiseeReminderType.medication,
      title: 'Vitamin D',
      times: const <String>['07:00'],
      frequency: 'daily',
      createdAt: DateTime(2026, 4, 25, 8),
    );

    final String raw = AiseeReminderService.notificationPayloadFor(
      reminder,
      notificationId: 43,
    );
    final AiseeReminderNotificationPayload? payload =
        AiseeReminderService.parseNotificationPayload(raw);

    expect(payload?.reminderId, 42);
    expect(payload?.notificationId, 43);
    expect(payload?.type, AiseeReminderType.medication);
  });

  test('parses legacy reminder payload uri', () {
    final AiseeReminderNotificationPayload? payload =
        AiseeReminderService.parseNotificationPayload(
          'aisee://reminders?type=appointment&id=99&notification_id=100',
        );

    expect(payload?.reminderId, 99);
    expect(payload?.notificationId, 100);
    expect(payload?.type, AiseeReminderType.appointment);
  });

  test('ignores invalid reminder notification payload', () {
    expect(AiseeReminderService.parseNotificationPayload(null), isNull);
    expect(AiseeReminderService.parseNotificationPayload(''), isNull);
    expect(AiseeReminderService.parseNotificationPayload('not-json'), isNull);
  });
}
