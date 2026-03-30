# Tool Actions + Reminder Management — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add 3 new tool actions (get_location, open_maps, schedule_reminder) to the LiveKit agent handler, plus a reminder management UI in the Personal tab.

**Architecture:** New service classes for location and reminders, handlers added to existing `_handleToolActionPayload` in `AiseeLiveKitVoiceSession`. Reminders persist to `shared_preferences` as JSON. UI reads from `AiseeReminderService` singleton.

**Tech Stack:** Flutter, geolocator, url_launcher, flutter_local_notifications, shared_preferences (existing), timezone

---

## File Map

| File | Action | Responsibility |
|---|---|---|
| `pubspec.yaml` | Modify | Add geolocator, url_launcher, flutter_local_notifications, timezone |
| `android/app/src/main/AndroidManifest.xml` | Modify | Location + alarm permissions |
| `ios/Runner/Info.plist` | Modify | Location usage description |
| `lib/models/aisee_reminder.dart` | Create | Data model with JSON serialization |
| `lib/services/aisee_reminder_service.dart` | Create | Notification init, schedule, cancel, list, persist |
| `lib/services/aisee_location_service.dart` | Create | Thin geolocator wrapper |
| `lib/services/aisee_livekit_voice_session.dart` | Modify | Add 3 action handlers, extend ACK for extra fields |
| `lib/utils/livekit_payload_display.dart` | Modify | Display rules for new actions |
| `lib/screens/user_personal_tab.dart` | Modify | Live reminder list with delete |
| `lib/main.dart` | Modify | Init notification + timezone on startup |

---

### Task 1: Dependencies + Platform Config

**Files:**
- Modify: `pubspec.yaml`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `ios/Runner/Info.plist`

- [ ] **Step 1:** Add dependencies to `pubspec.yaml`

```yaml
# Add under dependencies:
geolocator: ^13.0.2
url_launcher: ^6.3.1
flutter_local_notifications: ^18.0.1
timezone: ^0.10.0
```

- [ ] **Step 2:** Add location + alarm permissions to `AndroidManifest.xml`

Add before `<application>`:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```

- [ ] **Step 3:** Add location description to `ios/Runner/Info.plist`

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>AiSee can su dung vi tri de tro ly huong dan ban.</string>
```

- [ ] **Step 4:** Add maps URL query scheme for iOS (url_launcher needs this)

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>comgooglemaps</string>
    <string>maps</string>
</array>
```

- [ ] **Step 5:** Run `flutter pub get` to verify deps resolve

- [ ] **Step 6:** Commit: "feat: add deps + platform config for location, maps, notifications"

---

### Task 2: AiseeReminder Model

**Files:**
- Create: `lib/models/aisee_reminder.dart`

- [ ] **Step 1:** Create `lib/models/aisee_reminder.dart`

```dart
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
  List<int> get notificationIds {
    if (type == AiseeReminderType.medication && times != null) {
      return List<int>.generate(times!.length, (i) => id + i);
    }
    return [id];
  }

  Map<String, dynamic> toJson() => {
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
    return jsonEncode(items.map((r) => r.toJson()).toList());
  }
}
```

- [ ] **Step 2:** Commit: "feat: add AiseeReminder model"

---

### Task 3: AiseeReminderService

**Files:**
- Create: `lib/services/aisee_reminder_service.dart`
- Modify: `lib/main.dart`

- [ ] **Step 1:** Create `lib/services/aisee_reminder_service.dart`

Key responsibilities:
- Singleton instance
- `init()` — init `FlutterLocalNotificationsPlugin` + configure timezone
- `scheduleReminder(AiseeReminder)` — schedule notification(s) based on type
- `cancelReminder(int id)` — cancel notification(s) + remove from storage
- `loadAll()` → `List<AiseeReminder>` — read from shared_preferences
- `_persist(List<AiseeReminder>)` — write to shared_preferences

Medication scheduling: `zonedSchedule` per time with `matchDateTimeComponents: DateTimeComponents.time` for daily repeat.

Appointment scheduling: `zonedSchedule` one-time, 30 minutes before the datetime.

Notification channel (Android): "aisee_reminders", name "Nhac nho AiSee".

Storage key: `"aisee_reminders"` in shared_preferences.

ID generation: `DateTime.now().millisecondsSinceEpoch % 100000` — gives space for time slot offsets.

- [ ] **Step 2:** Add init call in `lib/main.dart`

In `main()` after `dotenv.load(...)`, add:
```dart
await AiseeReminderService.instance.init();
```

- [ ] **Step 3:** Run `flutter analyze` to verify no errors

- [ ] **Step 4:** Commit: "feat: add AiseeReminderService with scheduling + persistence"

---

### Task 4: AiseeLocationService

**Files:**
- Create: `lib/services/aisee_location_service.dart`

- [ ] **Step 1:** Create `lib/services/aisee_location_service.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class AiseeLocationService {
  /// Returns (lat, lng) or throws with user-facing message.
  static Future<(double lat, double lng)> getCurrentLocation() async {
    if (kIsWeb) {
      throw Exception('Location not supported on web');
    }

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('GPS dang tat. Hay bat dinh vi.');
    }

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }
    }
    if (perm == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission denied forever. Hay bat trong Cai dat.',
      );
    }

    // Fast path: cached position.
    Position? last = await Geolocator.getLastKnownPosition();
    if (last != null) {
      return (last.latitude, last.longitude);
    }

    // Fallback: fresh GPS fix.
    final Position pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 4),
      ),
    );
    return (pos.latitude, pos.longitude);
  }
}
```

- [ ] **Step 2:** Commit: "feat: add AiseeLocationService"

---

### Task 5: Tool Action Handlers

**Files:**
- Modify: `lib/services/aisee_livekit_voice_session.dart`

- [ ] **Step 1:** Extend `_sendToolActionAck` to support extra fields

Add optional `Map<String, Object?>? extra` parameter. Merge into body before publishing.

```dart
Future<void> _sendToolActionAck(
  String requestId, {
  String status = 'ok',
  String? message,
  Map<String, Object?>? extra,
}) async {
  // ... existing code ...
  final Map<String, Object?> body = <String, Object?>{
    'type': 'tool_action_ack',
    'request_id': requestId,
    'status': status,
  };
  if (message != null && message.isNotEmpty) body['message'] = message;
  if (extra != null) body.addAll(extra);
  // ... publish ...
}
```

- [ ] **Step 2:** Add imports at top of file

```dart
import 'dart:io' show Platform;
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/aisee_reminder_service.dart';
import '../models/aisee_reminder.dart';
import '../services/aisee_location_service.dart';
```

- [ ] **Step 3:** Add `get_location` handler after `enable_camera`/`disable_camera` block

```dart
if (action == 'get_location') {
  _log('Location', 'Agent yeu cau vi tri GPS');
  try {
    final (double lat, double lng) =
        await AiseeLocationService.getCurrentLocation();
    _log('Location', 'Lay duoc: lat=$lat lng=$lng');
    await _sendToolActionAck(
      requestId,
      extra: {'lat': lat, 'lng': lng},
    );
  } catch (e, st) {
    debugPrint('get_location: $e\n$st');
    await _sendToolActionAck(
      requestId,
      status: 'error',
      extra: {'error_message': e.toString()},
    );
  }
  return;
}
```

- [ ] **Step 4:** Add `open_maps` handler

```dart
if (action == 'open_maps') {
  final String dest = _paramString(
    params,
    const ['destination', 'dest', 'query', 'q'],
  );
  final String latStr = _paramString(params, const ['lat', 'latitude']);
  final String lngStr = _paramString(params, const ['lng', 'longitude']);
  _log('Maps', 'open_maps dest="$dest" lat=$latStr lng=$lngStr');

  Uri? mapUri;
  if (dest.isNotEmpty) {
    if (!kIsWeb && Platform.isIOS) {
      mapUri = Uri.parse(
        'https://maps.apple.com/?daddr=${Uri.encodeComponent(dest)}',
      );
    } else {
      mapUri = Uri.parse(
        'google.navigation:q=${Uri.encodeComponent(dest)}',
      );
    }
  } else if (latStr.isNotEmpty && lngStr.isNotEmpty) {
    if (!kIsWeb && Platform.isIOS) {
      mapUri = Uri.parse('https://maps.apple.com/?daddr=$latStr,$lngStr');
    } else {
      mapUri = Uri.parse('google.navigation:q=$latStr,$lngStr');
    }
  }

  if (mapUri == null) {
    await _sendToolActionAck(
      requestId,
      status: 'error',
      extra: {'error_message': 'Thieu destination hoac lat/lng'},
    );
    return;
  }

  try {
    final bool launched = await launchUrl(
      mapUri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) throw Exception('Cannot open maps');
    _log('Maps', 'Da mo ban do');
    await _sendToolActionAck(requestId);
  } catch (e, st) {
    debugPrint('open_maps: $e\n$st');
    await _sendToolActionAck(
      requestId,
      status: 'error',
      extra: {'error_message': e.toString()},
    );
  }
  return;
}
```

- [ ] **Step 5:** Add `schedule_reminder` handler (fire-and-forget)

```dart
if (action == 'schedule_reminder') {
  _log('Reminder', 'Agent gui schedule_reminder');
  try {
    final String typeStr = _paramString(
      params,
      const ['type', 'reminder_type'],
    );
    final String name = _paramString(
      params,
      const ['name', 'title'],
    );
    final int baseId =
        DateTime.now().millisecondsSinceEpoch % 100000;

    if (typeStr == 'medication') {
      final List<String> times = (params?['times'] as List<dynamic>?)
              ?.cast<String>() ??
          [];
      final String freq = _paramString(
        params,
        const ['frequency', 'freq'],
      );
      final AiseeReminder reminder = AiseeReminder(
        id: baseId,
        type: AiseeReminderType.medication,
        title: name,
        times: times,
        frequency: freq.isEmpty ? 'daily' : freq,
        createdAt: DateTime.now(),
      );
      await AiseeReminderService.instance.scheduleReminder(reminder);
      _log('Reminder', 'Medication "$name" x${times.length} times');
    } else if (typeStr == 'appointment') {
      final String dt = _paramString(
        params,
        const ['datetime', 'date_time', 'time'],
      );
      final AiseeReminder reminder = AiseeReminder(
        id: baseId,
        type: AiseeReminderType.appointment,
        title: name,
        datetime: dt,
        createdAt: DateTime.now(),
      );
      await AiseeReminderService.instance.scheduleReminder(reminder);
      _log('Reminder', 'Appointment "$name" at $dt');
    } else {
      _log('Reminder', 'Type khong ho tro: $typeStr');
    }
  } catch (e, st) {
    debugPrint('schedule_reminder: $e\n$st');
  }
  // Fire-and-forget: no ACK
  return;
}
```

- [ ] **Step 6:** Run `flutter analyze`

- [ ] **Step 7:** Commit: "feat: add get_location, open_maps, schedule_reminder handlers"

---

### Task 6: Update Display Rules

**Files:**
- Modify: `lib/utils/livekit_payload_display.dart`

- [ ] **Step 1:** Add new actions to `_displayForJsonMap`

In the `type == 'tool_action'` block, add before the fallback:
```dart
if (action == 'get_location') return null;  // silent
if (action == 'open_maps') return 'Tro ly dang mo ban do';
if (action == 'schedule_reminder') return 'Tro ly da dat nhac nho';
```

- [ ] **Step 2:** Add to `_isSilentToolPayload`:

```dart
if (t == 'tool_action' && a == 'get_location') return true;
```

- [ ] **Step 3:** Commit: "feat: display rules for new tool actions"

---

### Task 7: Personal Tab — Live Reminder Management

**Files:**
- Modify: `lib/screens/user_personal_tab.dart`

- [ ] **Step 1:** Convert to StatefulWidget

Need state to load/refresh reminder list from `AiseeReminderService`.

- [ ] **Step 2:** Replace static "Lich uong thuoc" section

Load reminders in `initState` via `AiseeReminderService.instance.loadAll()`.

Split into two sections:
- **Thuoc** — filter `type == medication`, show name + times, delete button
- **Lich hen** — filter `type == appointment`, show title + datetime, delete button

Each item: card with icon, title, subtitle (times/datetime), trailing delete IconButton.

On delete: call `AiseeReminderService.instance.cancelReminder(id)` then refresh state.

Empty state: keep current placeholder text.

- [ ] **Step 3:** Keep the existing "Tin nhan thoai" and "Nhat ky suc khoe" placeholder sections as-is

- [ ] **Step 4:** Run `flutter analyze`

- [ ] **Step 5:** Commit: "feat: live reminder management in personal tab"

---

### Task 8: Smoke Test

- [ ] **Step 1:** Run `flutter analyze` on full project — fix all warnings
- [ ] **Step 2:** Run `flutter build apk --debug` to verify build succeeds
- [ ] **Step 3:** Final commit if any fixes needed
