# Auth Refresh Fallback Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Automatically reuse the refresh token when the cached access token is expired, and if refresh also fails, clear local session state and route the user back to the login screen.

**Architecture:** Keep the token-rotation logic inside `AiseeAuthService.resumeSession()`, but make the UI shell treat a failed resume as a full logout condition. Add focused service tests for resume behavior and widget tests for auth-shell routing after invalid session revalidation.

**Tech Stack:** Flutter, Dart, `http`, `flutter_test`

---

## File Map

- Modify: `lib/services/aisee_auth_service.dart`
  - Add explicit logging around access-token retry and refresh fallback.
- Modify: `lib/widgets/auth_shell.dart`
  - Centralize the "clear auth state and return to login" behavior.
  - Use that path from both foreground restore and background revalidation.
- Create: `test/aisee_auth_service_test.dart`
  - Cover valid access token, refresh success, and refresh failure.
- Create: `test/auth_shell_test.dart`
  - Cover routing to login after invalid cached session.

### Task 1: Lock Down `resumeSession()` Behavior

**Files:**
- Modify: `lib/services/aisee_auth_service.dart`
- Create: `test/aisee_auth_service_test.dart`

- [ ] **Step 1: Write the failing tests**

Create `test/aisee_auth_service_test.dart`:

```dart
import 'dart:convert';

import 'package:aiseeapp/models/aisee_api_models.dart';
import 'package:aiseeapp/services/aisee_auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test('resumeSession returns rotated tokens after access token 401 and refresh success', () async {
    final _FakeHttpClient client = _FakeHttpClient(<http.Response>[
      http.Response('{"message":"unauthorized"}', 401),
      http.Response(
        jsonEncode({
          'access_token': 'new-access',
          'refresh_token': 'new-refresh',
        }),
        200,
      ),
      http.Response(
        jsonEncode({
          'id': 'u1',
          'email': 'a@b.com',
          'full_name': 'Test User',
          'role': 'family',
          'created_at': '2026-03-31T00:00:00Z',
          'updated_at': '2026-03-31T00:00:00Z',
        }),
        200,
      ),
    ]);
    final AiseeAuthService service = AiseeAuthService(httpClient: client);

    final result = await service.resumeSession(
      const AiseeAuthTokens(accessToken: 'old-access', refreshToken: 'old-refresh'),
    );

    expect(result, isNotNull);
    expect(result!.tokens.accessToken, 'new-access');
    expect(result.tokens.refreshToken, 'new-refresh');
  });

  test('resumeSession returns null when refresh fails', () async {
    final _FakeHttpClient client = _FakeHttpClient(<http.Response>[
      http.Response('{"message":"unauthorized"}', 401),
      http.Response('{"message":"refresh expired"}', 401),
    ]);
    final AiseeAuthService service = AiseeAuthService(httpClient: client);

    final result = await service.resumeSession(
      const AiseeAuthTokens(accessToken: 'old-access', refreshToken: 'bad-refresh'),
    );

    expect(result, isNull);
  });
}

class _FakeHttpClient extends http.BaseClient {
  _FakeHttpClient(this._responses);

  final List<http.Response> _responses;
  int _index = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final http.Response response = _responses[_index++];
    return http.StreamedResponse(
      Stream<List<int>>.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
    );
  }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/aisee_auth_service_test.dart`

Expected: FAIL because the fake profile JSON does not yet match the real parser exactly or because current resume behavior/logging is incomplete.

- [ ] **Step 3: Implement the minimal service update**

Update `lib/services/aisee_auth_service.dart` to make the refresh path explicit and logged:

```dart
Future<({AiseeUserProfile profile, AiseeAuthTokens tokens})?> resumeSession(
  AiseeAuthTokens initial,
) async {
  String access = initial.accessToken;
  String refresh = initial.refreshToken;
  http.Response res = await _http.get(
    _uri('/api/v1/users/me'),
    headers: {
      'Authorization': 'Bearer $access',
      'Accept': 'application/json',
    },
  );
  if (res.statusCode == 401) {
    try {
      final AiseeAuthTokens rotated = await refreshTokens(refresh);
      access = rotated.accessToken;
      refresh = rotated.refreshToken;
      res = await _http.get(
        _uri('/api/v1/users/me'),
        headers: {
          'Authorization': 'Bearer $access',
          'Accept': 'application/json',
        },
      );
    } catch (_) {
      return null;
    }
  }
  if (res.statusCode != 200) {
    return null;
  }
  Map<String, dynamic> map;
  try {
    map = _parseJsonBody(res, fallback: 'Không tải được hồ sơ');
  } catch (_) {
    return null;
  }
  final AiseeUserProfile profile = AiseeUserProfile.fromJson(_unwrapPayload(map));
  return (
    profile: profile,
    tokens: AiseeAuthTokens(accessToken: access, refreshToken: refresh),
  );
}
```

Add two log lines only:

```dart
developer.log('resumeSession: access token expired, trying refresh', name: 'AiSeeAuth');
developer.log('resumeSession: refresh failed', name: 'AiSeeAuth');
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/aisee_auth_service_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/services/aisee_auth_service.dart test/aisee_auth_service_test.dart
git commit -m "fix: fall back to refresh during session restore"
```

### Task 2: Route to Login After Refresh Failure

**Files:**
- Modify: `lib/widgets/auth_shell.dart`
- Create: `test/auth_shell_test.dart`

- [ ] **Step 1: Write the failing widget test**

Create `test/auth_shell_test.dart`:

```dart
import 'package:aiseeapp/widgets/auth_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('invalid stored session returns user to login UI', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: AuthShell()));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Đăng nhập'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/auth_shell_test.dart`

Expected: FAIL because `AuthShell` currently depends on real stores/services and does not yet expose a deterministic invalid-session path for test.

- [ ] **Step 3: Add one small auth-reset path in `AuthShell`**

Refactor `lib/widgets/auth_shell.dart` minimally by extracting the repeated invalid-session cleanup into one method:

```dart
Future<void> _clearSessionAndRouteToLogin({bool showExpiredToast = false}) async {
  await AiseeSessionStore.instance.clear();
  await AiseeProfileCache.instance.clear();
  if (!mounted) return;
  setState(() {
    _aiseeProfile = null;
    _profileLoading = false;
    _profileError = null;
  });
  if (showExpiredToast) {
    unawaited(AppToast.show('Phiên hết hạn, vui lòng đăng nhập lại', isError: true));
  }
}
```

Use it in both places:

```dart
if (resumed == null) {
  _authLog('syncSession(nền): refresh failed, về login');
  await _clearSessionAndRouteToLogin(showExpiredToast: true);
  return;
}
```

and:

```dart
if (resumed == null) {
  _authLog('restoreSession: refresh failed, về login');
  await _clearSessionAndRouteToLogin();
  return;
}
```

For testability, add the smallest constructor injection needed for `AiseeAuthService` and the two stores only if the widget test cannot be written otherwise.

- [ ] **Step 4: Update the widget test to use the minimal seam and verify it passes**

If constructor injection is added, adjust the test so `AuthShell` receives a fake auth service that returns `null` from resume and fake stores that report cached state once.

Run: `flutter test test/auth_shell_test.dart`

Expected: PASS.

- [ ] **Step 5: Run focused verification**

Run:

```bash
flutter test test/aisee_auth_service_test.dart test/auth_shell_test.dart
flutter analyze "lib/services/aisee_auth_service.dart" "lib/widgets/auth_shell.dart" "test/aisee_auth_service_test.dart" "test/auth_shell_test.dart"
```

Expected:

- all tests PASS
- analyzer reports no issues

- [ ] **Step 6: Commit**

```bash
git add lib/widgets/auth_shell.dart test/auth_shell_test.dart test/aisee_auth_service_test.dart lib/services/aisee_auth_service.dart
git commit -m "fix: return to login when refresh fails"
```

## Spec Coverage Check

- Access-token expiry retries refresh token: Task 1.
- Refresh success rotates tokens and continues: Task 1.
- Refresh failure clears session/profile state: Task 2.
- UI returns to login instead of stale authenticated screen: Task 2.
- Focused tests for service and shell behavior: Tasks 1 and 2.

## Placeholder Scan

- No `TODO`, `TBD`, or deferred behavior remains.
- Every task references exact files and concrete commands.

## Type Consistency Check

- `resumeSession()` remains the service entrypoint for session restore.
- `_clearSessionAndRouteToLogin()` is the single shell cleanup path.
- `AiseeAuthTokens` and `AiseeUserProfile` stay unchanged.
