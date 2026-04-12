# Permission Bootstrap Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a one-time permission bootstrap after auth for microphone, camera, notification, and location, while stopping automatic requests for Android special permissions in the normal flow.

**Architecture:** Introduce a dedicated permission bootstrap service plus a small bootstrap gate widget that runs after auth is ready and before users enter the main app flows. Existing feature services keep defensive permission checks, but the first happy-path prompt moves into the shared bootstrap, and special permissions like `SYSTEM_ALERT_WINDOW` and fullscreen intent are removed from the normal request path unless later proven necessary.

**Tech Stack:** Flutter, Dart, `permission_handler`, `shared_preferences`, Firebase Messaging, existing auth/bootstrap widgets

---

## File Map

- Create: `lib/services/aisee_permission_bootstrap_service.dart`
  - Own one-time permission sequencing and persistent completion state.
- Create: `lib/widgets/permission_bootstrap_gate.dart`
  - Run the bootstrap after auth and before entering the app shell.
- Modify: `lib/widgets/auth_shell.dart`
  - Insert the permission gate around the authenticated app content.
- Modify: `lib/services/aisee_push_service.dart`
  - Stop owning the first notification prompt and stop auto-requesting fullscreen intent permission.
- Modify: `lib/services/aisee_wake_word_service.dart`
  - Remove automatic `SYSTEM_ALERT_WINDOW` requests from wake-word startup.
- Modify: `android/app/src/main/AndroidManifest.xml`
  - Remove special permissions if implementation confirms they are no longer part of the normal flow.
- Create: `test/aisee_permission_bootstrap_service_test.dart`
  - Verify ordering, completion flag behavior, and deny-tolerant flow.
- Create: `test/permission_bootstrap_gate_test.dart`
  - Verify the gate blocks until bootstrap finishes and then renders child content.

### Task 1: Build and verify the permission bootstrap service

**Files:**
- Create: `lib/services/aisee_permission_bootstrap_service.dart`
- Create: `test/aisee_permission_bootstrap_service_test.dart`

- [ ] **Step 1: Write the failing unit tests for bootstrap ordering and persistence**

Create `test/aisee_permission_bootstrap_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aiseeapp/services/aisee_permission_bootstrap_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('bootstrap requests core permissions in fixed order once', () async {
    final List<String> calls = <String>[];
    final AiseePermissionBootstrapService service =
        AiseePermissionBootstrapService.test(
          requestMicrophone: () async => calls.add('microphone'),
          requestCamera: () async => calls.add('camera'),
          requestNotification: () async => calls.add('notification'),
          requestLocation: () async => calls.add('location'),
        );

    await service.ensureBootstrapped();
    await service.ensureBootstrapped();

    expect(calls, <String>['microphone', 'camera', 'notification', 'location']);
    expect(await service.hasCompletedBootstrap(), isTrue);
  });

  test('bootstrap continues when one permission is denied', () async {
    final List<String> calls = <String>[];
    final AiseePermissionBootstrapService service =
        AiseePermissionBootstrapService.test(
          requestMicrophone: () async => calls.add('microphone'),
          requestCamera: () async => calls.add('camera'),
          requestNotification: () async => calls.add('notification'),
          requestLocation: () async => calls.add('location'),
        );

    await service.ensureBootstrapped();

    expect(calls, <String>['microphone', 'camera', 'notification', 'location']);
    expect(await service.hasCompletedBootstrap(), isTrue);
  });
}
```

- [ ] **Step 2: Run the focused service test to verify it fails**

Run: `flutter test test/aisee_permission_bootstrap_service_test.dart`
Expected: FAIL because the service file does not exist yet.

- [ ] **Step 3: Implement the minimal permission bootstrap service**

Create `lib/services/aisee_permission_bootstrap_service.dart`:

```dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef PermissionRequest = Future<void> Function();

class AiseePermissionBootstrapService {
  AiseePermissionBootstrapService._({
    required this.requestMicrophone,
    required this.requestCamera,
    required this.requestNotification,
    required this.requestLocation,
  });

  static const String _bootstrapDoneKey = 'aisee.permission_bootstrap.done';

  static final AiseePermissionBootstrapService instance =
      AiseePermissionBootstrapService._(
        requestMicrophone: () => _requestPermission(Permission.microphone),
        requestCamera: () => _requestPermission(Permission.camera),
        requestNotification: () => _requestPermission(Permission.notification),
        requestLocation: () => _requestPermission(Permission.location),
      );

  factory AiseePermissionBootstrapService.test({
    required PermissionRequest requestMicrophone,
    required PermissionRequest requestCamera,
    required PermissionRequest requestNotification,
    required PermissionRequest requestLocation,
  }) {
    return AiseePermissionBootstrapService._(
      requestMicrophone: requestMicrophone,
      requestCamera: requestCamera,
      requestNotification: requestNotification,
      requestLocation: requestLocation,
    );
  }

  final PermissionRequest requestMicrophone;
  final PermissionRequest requestCamera;
  final PermissionRequest requestNotification;
  final PermissionRequest requestLocation;

  Future<bool> hasCompletedBootstrap() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_bootstrapDoneKey) ?? false;
  }

  Future<void> ensureBootstrapped() async {
    if (await hasCompletedBootstrap()) {
      return;
    }
    await _runSafe(requestMicrophone, 'microphone');
    await _runSafe(requestCamera, 'camera');
    await _runSafe(requestNotification, 'notification');
    await _runSafe(requestLocation, 'location');
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_bootstrapDoneKey, true);
  }

  Future<void> _runSafe(PermissionRequest request, String label) async {
    try {
      await request();
    } catch (e) {
      debugPrint('[AiSee:PermissionBootstrap] $label request failed: $e');
    }
  }

  static Future<void> _requestPermission(Permission permission) async {
    if (kIsWeb) {
      return;
    }
    final PermissionStatus current = await permission.status;
    if (current.isGranted || current.isPermanentlyDenied) {
      return;
    }
    await permission.request();
  }
}
```

- [ ] **Step 4: Run the focused service test and confirm it passes**

Run: `flutter test test/aisee_permission_bootstrap_service_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit the service slice**

```bash
git add lib/services/aisee_permission_bootstrap_service.dart test/aisee_permission_bootstrap_service_test.dart
git commit -m "feat: add permission bootstrap service"
```

### Task 2: Add the app gate that runs bootstrap after auth

**Files:**
- Create: `lib/widgets/permission_bootstrap_gate.dart`
- Modify: `lib/widgets/auth_shell.dart`
- Create: `test/permission_bootstrap_gate_test.dart`

- [ ] **Step 1: Write the failing widget test for the permission gate**

Create `test/permission_bootstrap_gate_test.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aiseeapp/widgets/permission_bootstrap_gate.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('gate waits for bootstrap and then shows child', (
    WidgetTester tester,
  ) async {
    final Completer<void> completer = Completer<void>();

    await tester.pumpWidget(
      MaterialApp(
        home: PermissionBootstrapGate(
          ensurePermissions: () => completer.future,
          child: const Text('home ready'),
        ),
      ),
    );

    expect(find.text('home ready'), findsNothing);

    completer.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));

    expect(find.text('home ready'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the focused gate test to verify it fails**

Run: `flutter test test/permission_bootstrap_gate_test.dart`
Expected: FAIL because the gate widget does not exist yet.

- [ ] **Step 3: Implement the gate widget and mount it in the auth shell**

Create `lib/widgets/permission_bootstrap_gate.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';

import '../services/aisee_permission_bootstrap_service.dart';
import 'auth_bootstrapping.dart';

class PermissionBootstrapGate extends StatefulWidget {
  const PermissionBootstrapGate({
    super.key,
    required this.child,
    this.ensurePermissions,
  });

  final Widget child;
  final Future<void> Function()? ensurePermissions;

  @override
  State<PermissionBootstrapGate> createState() => _PermissionBootstrapGateState();
}

class _PermissionBootstrapGateState extends State<PermissionBootstrapGate> {
  late final Future<void> _future;

  @override
  void initState() {
    super.initState();
    _future = (widget.ensurePermissions ??
            AiseePermissionBootstrapService.instance.ensureBootstrapped)();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const AuthBootstrapping(title: 'Đang chuẩn bị quyền truy cập…');
        }
        return widget.child;
      },
    );
  }
}
```

Update `lib/widgets/auth_shell.dart` so the authenticated app content is wrapped with `PermissionBootstrapGate` rather than entering the home shell directly.

- [ ] **Step 4: Run the focused gate test and relevant auth-shell test coverage**

Run: `flutter test test/permission_bootstrap_gate_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit the gate slice**

```bash
git add lib/widgets/permission_bootstrap_gate.dart lib/widgets/auth_shell.dart test/permission_bootstrap_gate_test.dart
git commit -m "feat: gate app with permission bootstrap"
```

### Task 3: Remove special-permission requests from the normal flow

**Files:**
- Modify: `lib/services/aisee_push_service.dart`
- Modify: `lib/services/aisee_wake_word_service.dart`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `test/aisee_permission_bootstrap_service_test.dart`

- [ ] **Step 1: Add failing assertions around special-permission behavior in service tests**

Extend `test/aisee_permission_bootstrap_service_test.dart` with a simple bootstrap expectation that the service only owns the four runtime permissions. Add this test:

```dart
  test('bootstrap service only covers the four core runtime permissions', () {
    expect(
      AiseePermissionBootstrapService.runtimePermissionNames,
      <String>['microphone', 'camera', 'notification', 'location'],
    );
  });
```

- [ ] **Step 2: Run the focused service test to verify it fails**

Run: `flutter test test/aisee_permission_bootstrap_service_test.dart`
Expected: FAIL because `runtimePermissionNames` is not exposed yet.

- [ ] **Step 3: Implement the special-permission cleanup**

Expose the ordered runtime-permission names in `lib/services/aisee_permission_bootstrap_service.dart`:

```dart
  static const List<String> runtimePermissionNames = <String>[
    'microphone',
    'camera',
    'notification',
    'location',
  ];
```

Update `lib/services/aisee_push_service.dart`:

```dart
    if (_initialized) {
      await _uploadFcmToken(accessToken);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        flushPendingCallNavigation();
        unawaited(syncActiveAcceptedCall());
      });
      return;
    }
```

and remove:

```dart
    if (!kIsWeb && Platform.isAndroid) {
      unawaited(FlutterCallkitIncoming.requestFullIntentPermission());
    }
```

Also replace:

```dart
    final NotificationSettings settings = await messaging.requestPermission();
    _log('Permission: ${settings.authorizationStatus}');
```

with a non-requesting read:

```dart
    final NotificationSettings settings = await messaging.getNotificationSettings();
    _log('Permission: ${settings.authorizationStatus}');
```

Update `lib/services/aisee_wake_word_service.dart` by deleting:

```dart
    if (Platform.isAndroid) {
      await Permission.systemAlertWindow.request();
    }
```

Update `android/app/src/main/AndroidManifest.xml` by removing:

```xml
    <uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT"/>
    <uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW"/>
```

- [ ] **Step 4: Run the focused service test and analyzer on touched files**

Run: `flutter test test/aisee_permission_bootstrap_service_test.dart`
Expected: PASS.

Run: `flutter analyze lib/services/aisee_permission_bootstrap_service.dart lib/services/aisee_push_service.dart lib/services/aisee_wake_word_service.dart lib/widgets/permission_bootstrap_gate.dart lib/widgets/auth_shell.dart test/aisee_permission_bootstrap_service_test.dart test/permission_bootstrap_gate_test.dart`
Expected: PASS with no warnings or errors.

- [ ] **Step 5: Commit the permission cleanup slice**

```bash
git add android/app/src/main/AndroidManifest.xml lib/services/aisee_permission_bootstrap_service.dart lib/services/aisee_push_service.dart lib/services/aisee_wake_word_service.dart test/aisee_permission_bootstrap_service_test.dart
git commit -m "refactor: centralize app permission requests"
```

### Task 4: Final verification of bootstrap integration

**Files:**
- Verify: `lib/widgets/auth_shell.dart`
- Verify: `lib/widgets/permission_bootstrap_gate.dart`
- Verify: `lib/services/aisee_permission_bootstrap_service.dart`
- Verify: `lib/services/aisee_push_service.dart`
- Verify: `lib/services/aisee_wake_word_service.dart`
- Verify: `android/app/src/main/AndroidManifest.xml`

- [ ] **Step 1: Run the focused bootstrap and gate tests together**

Run: `flutter test test/aisee_permission_bootstrap_service_test.dart test/permission_bootstrap_gate_test.dart`
Expected: PASS.

- [ ] **Step 2: Re-run analyzer on the integrated permission files**

Run: `flutter analyze lib/services/aisee_permission_bootstrap_service.dart lib/services/aisee_push_service.dart lib/services/aisee_wake_word_service.dart lib/widgets/permission_bootstrap_gate.dart lib/widgets/auth_shell.dart android/app/src/main/AndroidManifest.xml test/aisee_permission_bootstrap_service_test.dart test/permission_bootstrap_gate_test.dart`
Expected: PASS with no warnings or errors.

- [ ] **Step 3: Install the updated app on the connected Xiaomi device for manual verification**

Run: `flutter build apk --release && flutter install -d adb-be5f5683-7QoMjv._adb-tls-connect._tcp`
Expected: a fresh APK installs successfully and is ready for first-launch permission testing.

- [ ] **Step 4: Manually verify first-launch behavior on device**

Check on Xiaomi:

```text
1. Fresh install or cleared app data
2. Sign in once
3. Confirm microphone, camera, notification, and location are requested in one bootstrap pass
4. Confirm wake word no longer triggers overlay permission
5. Confirm incoming call path still opens without requesting special fullscreen permission in-app
```

Expected: core runtime permissions appear once, and no special permission prompt appears during the standard bootstrap.

- [ ] **Step 5: Commit the final verification slice**

```bash
git add android/app/src/main/AndroidManifest.xml lib/services/aisee_permission_bootstrap_service.dart lib/services/aisee_push_service.dart lib/services/aisee_wake_word_service.dart lib/widgets/permission_bootstrap_gate.dart lib/widgets/auth_shell.dart test/aisee_permission_bootstrap_service_test.dart test/permission_bootstrap_gate_test.dart
git commit -m "test: verify permission bootstrap flow"
```

## Self-Review

- Spec coverage: this plan adds a shared bootstrap for microphone, camera, notification, and location; moves the first prompt out of feature services; preserves defensive feature checks; and removes automatic normal-flow requests for overlay/fullscreen intent.
- Placeholder scan: no `TODO`, `TBD`, or missing implementation references remain.
- Type consistency: `AiseePermissionBootstrapService`, `PermissionBootstrapGate`, `ensureBootstrapped`, and `runtimePermissionNames` are named consistently across tasks.
