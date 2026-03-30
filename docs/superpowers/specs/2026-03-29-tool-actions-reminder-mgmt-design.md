# Tool Actions + Reminder Management — Design Spec

## Summary

Add 3 new tool actions to handle agent commands via LiveKit Data Channel, plus a reminder management UI in the Personal tab.

## New Tool Actions

### 1. get_location (ACK)

**Receive:** `{"type": "tool_action", "action": "get_location", "request_id": "...", "params": {}}`

**Behavior:**
- Use `geolocator` package
- Try `getLastKnownPosition()` first (fast, cached)
- Fallback to `getCurrentPosition()` if null
- Timeout: agent waits 5s, so keep location fetch quick

**ACK success:** `{"type": "tool_action_ack", "request_id": "...", "status": "ok", "lat": 21.0285, "lng": 105.8542}`
**ACK error:** `{"type": "tool_action_ack", "request_id": "...", "status": "error", "error_message": "Location permission denied"}`

**Permissions:**
- Android: `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`
- iOS: `NSLocationWhenInUseUsageDescription`

### 2. open_maps (ACK)

**Receive:** `{"type": "tool_action", "action": "open_maps", "request_id": "...", "params": {"destination": "benh vien Mat trung uong"}}`

**Behavior:**
- Use `url_launcher`
- Android: `google.navigation:q={destination}` (opens Google Maps navigation)
- iOS: Apple Maps URL `https://maps.apple.com/?daddr={destination}`
- Also support `lat`/`lng` params as alternative to text destination

**ACK success:** `{"type": "tool_action_ack", "request_id": "...", "status": "ok"}`
**ACK error:** `{"type": "tool_action_ack", "request_id": "...", "status": "error", "error_message": "Cannot open maps"}`

### 3. schedule_reminder (fire-and-forget)

**Receive:** `{"type": "tool_action", "action": "schedule_reminder", "request_id": "...", "params": {...}}`

**Medication params:** `{"type": "medication", "name": "Paracetamol", "times": ["07:00", "21:00"], "frequency": "daily"}`
**Appointment params:** `{"type": "appointment", "title": "Kham mat", "datetime": "2026-04-01 09:00"}`

**Behavior:**
- Use `flutter_local_notifications` with `zonedSchedule`
- Medication: create recurring notification per time entry using `DateTimeComponents.time`
- Appointment: create one-time notification 30 minutes before datetime
- Persist to `shared_preferences` as JSON list for management/cancel
- No ACK required (fire-and-forget)

## Data Model

```dart
class AiseeReminder {
  final int id;              // notification ID
  final String type;         // "medication" | "appointment"
  final String title;        // drug name or appointment title
  final String? time;        // "07:00" for medication
  final String? datetime;    // "2026-04-01 09:00" for appointment
  final String? frequency;   // "daily" for medication
  final DateTime createdAt;
}
```

ID generation: use `DateTime.now().millisecondsSinceEpoch % 100000` base, increment per time entry.

## File Plan

### New files
| File | Purpose |
|---|---|
| `lib/models/aisee_reminder.dart` | AiseeReminder model with JSON serialization |
| `lib/services/aisee_reminder_service.dart` | Init notifications, schedule, cancel, list, persist |
| `lib/services/aisee_location_service.dart` | Thin geolocator wrapper |

### Modified files
| File | Changes |
|---|---|
| `lib/services/aisee_livekit_voice_session.dart` | Add handlers for get_location, open_maps, schedule_reminder |
| `lib/utils/livekit_payload_display.dart` | Display rules for new actions (all silent except schedule_reminder shows confirmation) |
| `lib/screens/user_personal_tab.dart` | Replace static placeholders with live reminder list + delete |
| `pubspec.yaml` | Add geolocator, url_launcher, flutter_local_notifications |
| `android/app/src/main/AndroidManifest.xml` | Location permissions, SCHEDULE_EXACT_ALARM |
| `ios/Runner/Info.plist` | NSLocationWhenInUseUsageDescription |

## UI — Personal Tab Reminder Management

Replace the static "Lich uong thuoc hom nay" card with live data:

- **Medication section:** List of active medication reminders, each showing name + times. Swipe or tap icon to delete (cancels notification + removes from storage).
- **Appointment section:** List of upcoming appointments, each showing title + datetime. Same delete interaction.
- **Empty state:** Keep current placeholder text when no reminders exist.
- Style: Same `_InfoSection` card pattern (dark card, border, icon + text).

## Platform Configuration

### Android
- `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION` in AndroidManifest
- `SCHEDULE_EXACT_ALARM` for notification scheduling
- `RECEIVE_BOOT_COMPLETED` to reschedule after reboot

### iOS
- `NSLocationWhenInUseUsageDescription` in Info.plist
