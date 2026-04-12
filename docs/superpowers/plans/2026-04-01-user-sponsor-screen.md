# User Sponsor Screen Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `Nhà tài trợ` destination in the user `Cá nhân` tab that opens a new sponsor screen showing `DAVO` and linking to `https://davoice.io/`.

**Architecture:** Reuse the existing `UserPersonalTab` menu-card pattern and add one new route file for the sponsor UI. Keep sponsor data static in the screen layer for now, and reuse the existing `url_launcher` plus `AppToast` pattern for external link failures.

**Tech Stack:** Flutter, Dart, `flutter_test`, `url_launcher`, existing `StyleTokens` UI primitives

---

## File Map

- Modify: `lib/screens/user_personal_tab.dart`
  - Add a new `Nhà tài trợ` menu card.
  - Push the new sponsor screen from the existing personal-tab menu flow.
- Create: `lib/screens/user_sponsor_screen.dart`
  - Render the sponsor intro and static sponsor card list.
  - Open sponsor URLs with `launchUrl` and show an error toast on failure.
- Create: `test/user_sponsor_screen_test.dart`
  - Verify the personal tab entry exists.
  - Verify navigation to the sponsor screen.
  - Verify sponsor content is rendered.

### Task 1: Add coverage for sponsor navigation entry

**Files:**
- Modify: `lib/screens/user_personal_tab.dart`
- Test: `test/user_sponsor_screen_test.dart`

- [ ] **Step 1: Write the failing widget tests for the new menu entry and navigation**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aiseeapp/screens/user_personal_tab.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildSubject() {
    return MaterialApp(
      home: Scaffold(
        body: UserPersonalTab(onSignOut: () {}),
      ),
    );
  }

  testWidgets('UserPersonalTab hiển thị mục Nhà tài trợ', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('Nhà tài trợ'), findsOneWidget);
    expect(find.text('Các đơn vị đang đồng hành cùng dự án'), findsOneWidget);
  });

  testWidgets('Chạm mục Nhà tài trợ sẽ mở sponsor screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nhà tài trợ'));
    await tester.pumpAndSettle();

    expect(find.text('Nhà tài trợ'), findsWidgets);
    expect(find.text('DAVO'), findsOneWidget);
    expect(find.text('davoice.io'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the focused test file to verify it fails**

Run: `flutter test test/user_sponsor_screen_test.dart`
Expected: FAIL because `Nhà tài trợ` is not rendered yet.

- [ ] **Step 3: Add the new personal-tab menu entry and route push**

Update `lib/screens/user_personal_tab.dart` with a new import, a small route helper, and the
extra `_MenuCard`:

```dart
import 'user_sponsor_screen.dart';

void _openSponsors() {
  HapticFeedback.lightImpact();
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const UserSponsorScreen()),
  );
}
```

Insert the new card above the sign-out button:

```dart
_MenuCard(
  iconAsset: 'assets/icons/nav/ic_3user.svg',
  title: 'Nhà tài trợ',
  subtitle: 'Các đơn vị đang đồng hành cùng dự án',
  onTap: _openSponsors,
),
```

Add semantics by relying on the existing `_MenuCard` label format so the new title and subtitle
are exposed automatically.

- [ ] **Step 4: Run the focused test file again**

Run: `flutter test test/user_sponsor_screen_test.dart`
Expected: FAIL because `UserSponsorScreen` does not exist yet.

- [ ] **Step 5: Commit the first slice**

```bash
git add lib/screens/user_personal_tab.dart test/user_sponsor_screen_test.dart
git commit -m "feat(user): add sponsors entry point"
```

### Task 2: Build the sponsor screen and external-link flow

**Files:**
- Create: `lib/screens/user_sponsor_screen.dart`
- Test: `test/user_sponsor_screen_test.dart`

- [ ] **Step 1: Extend the failing test file with sponsor-screen content expectations**

Append these tests to `test/user_sponsor_screen_test.dart`:

```dart
testWidgets('Sponsor screen hiển thị phần giới thiệu và card DAVO', (
  WidgetTester tester,
) async {
  await tester.pumpWidget(
    const MaterialApp(home: UserSponsorScreen()),
  );
  await tester.pumpAndSettle();

  expect(find.text('Nhà tài trợ'), findsOneWidget);
  expect(find.text('Những đơn vị đang đồng hành cùng AiSee.'), findsOneWidget);
  expect(find.text('DAVO'), findsOneWidget);
  expect(find.text('davoice.io'), findsOneWidget);
  expect(find.text('Mở website'), findsOneWidget);
});
```

Also add the missing import:

```dart
import 'package:aiseeapp/screens/user_sponsor_screen.dart';
```

- [ ] **Step 2: Run the focused test file to verify it still fails**

Run: `flutter test test/user_sponsor_screen_test.dart`
Expected: FAIL because `UserSponsorScreen` is still missing.

- [ ] **Step 3: Implement the sponsor screen with static DAVO content**

Create `lib/screens/user_sponsor_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/style_tokens.dart';
import '../utils/app_toast.dart';

class UserSponsorScreen extends StatelessWidget {
  const UserSponsorScreen({super.key, this.launchUrlFn = launchUrl});

  final Future<bool> Function(Uri url, {LaunchMode mode}) launchUrlFn;

  static final Uri _davoUri = Uri.parse('https://davoice.io/');

  Future<void> _openSponsorWebsite() async {
    try {
      final bool launched = await launchUrlFn(
        _davoUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        AppToast.show('Không mở được website nhà tài trợ.', isError: true);
      }
    } catch (_) {
      AppToast.show('Không mở được website nhà tài trợ.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StyleTokens.background,
      appBar: AppBar(title: const Text('Nhà tài trợ')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          Text(
            'Những đơn vị đang đồng hành cùng AiSee.',
            style: StyleTokens.bodySmall().copyWith(fontSize: 14),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: StyleTokens.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: StyleTokens.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: StyleTokens.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          'assets/icons/nav/ic_3user.svg',
                          width: 22,
                          height: 22,
                          colorFilter: const ColorFilter.mode(
                            StyleTokens.buttonPrimary,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'DAVO',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: StyleTokens.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'davoice.io',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: StyleTokens.linkAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'DAVO là nhà tài trợ đầu tiên đang đồng hành cùng dự án AiSee.',
                  style: StyleTokens.bodySmall(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _openSponsorWebsite,
                    style: FilledButton.styleFrom(
                      backgroundColor: StyleTokens.buttonPrimary,
                      foregroundColor: StyleTokens.buttonOnPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Mở website'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run the focused test file and confirm it passes**

Run: `flutter test test/user_sponsor_screen_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit the sponsor screen slice**

```bash
git add lib/screens/user_sponsor_screen.dart test/user_sponsor_screen_test.dart
git commit -m "feat(user): add sponsor screen"
```

### Task 3: Cover URL-launch injection and final verification

**Files:**
- Modify: `lib/screens/user_sponsor_screen.dart`
- Modify: `test/user_sponsor_screen_test.dart`

- [ ] **Step 1: Add a focused test for the website action callback**

Append this test to `test/user_sponsor_screen_test.dart`:

```dart
testWidgets('Nút mở website gọi launchUrl với link DAVO', (
  WidgetTester tester,
) async {
  Uri? launchedUri;
  LaunchMode? launchedMode;

  Future<bool> fakeLaunchUrl(Uri url, {LaunchMode mode = LaunchMode.platformDefault}) async {
    launchedUri = url;
    launchedMode = mode;
    return true;
  }

  await tester.pumpWidget(
    MaterialApp(
      home: UserSponsorScreen(launchUrlFn: fakeLaunchUrl),
    ),
  );
  await tester.pumpAndSettle();

  await tester.tap(find.text('Mở website'));
  await tester.pumpAndSettle();

  expect(launchedUri, Uri.parse('https://davoice.io/'));
  expect(launchedMode, LaunchMode.externalApplication);
});
```

- [ ] **Step 2: Run the focused test file to verify the new test behavior**

Run: `flutter test test/user_sponsor_screen_test.dart`
Expected: PASS if the injected launcher signature matches the screen implementation, otherwise
FAIL with a type/signature mismatch that should be fixed before moving on.

- [ ] **Step 3: Tighten the sponsor screen API only if needed to satisfy the test cleanly**

If the launcher typedef is awkward, replace the raw function type with a local typedef in
`lib/screens/user_sponsor_screen.dart`:

```dart
typedef SponsorUrlLauncher = Future<bool> Function(
  Uri url, {
  LaunchMode mode,
});

class UserSponsorScreen extends StatelessWidget {
  const UserSponsorScreen({super.key, this.launchUrlFn = launchUrl});

  final SponsorUrlLauncher launchUrlFn;
}
```

Keep the rest of the behavior unchanged.

- [ ] **Step 4: Run the focused verification commands**

Run: `flutter test test/user_sponsor_screen_test.dart`
Expected: PASS.

Run: `flutter analyze lib/screens/user_personal_tab.dart lib/screens/user_sponsor_screen.dart test/user_sponsor_screen_test.dart`
Expected: PASS with no warnings.

- [ ] **Step 5: Commit the verification slice**

```bash
git add lib/screens/user_personal_tab.dart lib/screens/user_sponsor_screen.dart test/user_sponsor_screen_test.dart
git commit -m "test(user): cover sponsor navigation and link"
```

## Self-Review

- Spec coverage: the plan covers the new `Cá nhân` entry, the dedicated sponsor screen, static
  `DAVO` content, external link opening, accessibility via existing semantics pattern, and widget
  test coverage.
- Placeholder scan: no `TODO` or deferred implementation markers remain.
- Type consistency: `UserSponsorScreen`, `launchUrlFn`, and the `https://davoice.io/` URI are used
  consistently across tasks.
