# Sponsor Screen Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a shared sponsor screen for both user and family personal tabs, showing DAVO with a remote logo, grounded description, and website action.

**Architecture:** Keep one shared `UserSponsorScreen` route and reuse it from both user and family `Cá nhân` tabs. Store DAVO sponsor data statically inside the screen file, render the logo from a remote URL with a safe fallback, and continue using the existing `url_launcher` plus `AppToast` error handling pattern.

**Tech Stack:** Flutter, Dart, `flutter_test`, `url_launcher`, `Image.network`, existing `StyleTokens` and app navigation patterns

---

## File Map

- Modify: `lib/screens/user_personal_tab.dart`
  - Keep the existing sponsor entry wired to the shared screen.
- Modify: `lib/screens/family_personal_tab.dart`
  - Add a tappable sponsor entry in the family `Cá nhân` tab.
- Modify: `lib/screens/user_sponsor_screen.dart`
  - Replace the placeholder icon presentation with a remote DAVO logo, update the description text, and keep the external website action.
- Modify: `test/user_sponsor_screen_test.dart`
  - Extend widget tests to cover the family entry and the updated sponsor content.

### Task 1: Add family sponsor entry coverage and navigation

**Files:**
- Modify: `lib/screens/family_personal_tab.dart`
- Modify: `test/user_sponsor_screen_test.dart`

- [ ] **Step 1: Write the failing widget test for the family personal tab entry**

Add the needed import and test to `test/user_sponsor_screen_test.dart`:

```dart
import 'package:aiseeapp/models/aisee_api_models.dart';
import 'package:aiseeapp/screens/family_personal_tab.dart';
```

```dart
  Widget buildFamilyTab() {
    final AiseeUserProfile profile = AiseeUserProfile(
      id: 'family-1',
      email: 'family@example.com',
      role: 'family',
      createdAt: '2026-04-01T00:00:00.000Z',
      isVolunteer: false,
    );
    return MaterialApp(
      home: Scaffold(
        body: FamilyPersonalTab(
          profile: profile,
          onSignOut: () {},
        ),
      ),
    );
  }

  testWidgets('FamilyPersonalTab hiển thị mục Nhà tài trợ và mở sponsor screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildFamilyTab());
    await tester.pumpAndSettle();

    expect(find.text('Nhà tài trợ'), findsOneWidget);
    expect(find.text('Đơn vị đồng hành cùng dự án AiSee'), findsOneWidget);

    await tester.tap(find.text('Nhà tài trợ'));
    await tester.pumpAndSettle();

    expect(find.text('DAVO'), findsOneWidget);
    expect(find.text('davoice.io'), findsOneWidget);
  });
```

- [ ] **Step 2: Run the focused test file to verify it fails**

Run: `flutter test test/user_sponsor_screen_test.dart`
Expected: FAIL because the family tab does not render the sponsor entry yet.

- [ ] **Step 3: Add the family personal tab entry and route push**

Update `lib/screens/family_personal_tab.dart` with a route helper and a new card row.

Add import:

```dart
import 'user_sponsor_screen.dart';
```

Add helper inside `_FamilyPersonalTabState`:

```dart
  void _openSponsors() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const UserSponsorScreen(),
      ),
    );
  }
```

Insert this card before `_buildSignOutButton()` using the existing card style:

```dart
          const SizedBox(height: 10),
          _ActionCard(
            iconAsset: 'assets/icons/nav/ic_3user.svg',
            title: 'Nhà tài trợ',
            subtitle: 'Đơn vị đồng hành cùng dự án AiSee',
            onTap: _openSponsors,
          ),
```

Create `_ActionCard` near `_InfoCard` so family can keep the same card language with tap support:

```dart
class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.iconAsset,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String iconAsset;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title. $subtitle. Chạm để mở.',
      child: Material(
        color: StyleTokens.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: StyleTokens.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      iconAsset,
                      width: 20,
                      height: 20,
                      colorFilter: const ColorFilter.mode(
                        StyleTokens.buttonPrimary,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: StyleTokens.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: StyleTokens.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                SvgPicture.asset(
                  'assets/icons/nav/ic_arrow_right.svg',
                  width: 8,
                  height: 8,
                  colorFilter: const ColorFilter.mode(
                    StyleTokens.textMuted,
                    BlendMode.srcIn,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run the focused test file again**

Run: `flutter test test/user_sponsor_screen_test.dart`
Expected: PASS for the new family navigation test, while later sponsor-content assertions may still reflect the old screen content.

- [ ] **Step 5: Commit the family entry slice**

```bash
git add lib/screens/family_personal_tab.dart test/user_sponsor_screen_test.dart
git commit -m "feat(family): add sponsors entry"
```

### Task 2: Update sponsor screen with remote DAVO logo and revised description

**Files:**
- Modify: `lib/screens/user_sponsor_screen.dart`
- Modify: `test/user_sponsor_screen_test.dart`

- [ ] **Step 1: Update tests to expect the new sponsor description**

Change the sponsor content test in `test/user_sponsor_screen_test.dart` to assert the full DAVO description:

```dart
    expect(
      find.text(
        'DAVO phát triển công nghệ voice AI chạy trực tiếp trên thiết bị, gồm '
        'wake word, speaker recognition, VAD, STT và TTS, ưu tiên tốc độ và '
        'quyền riêng tư.',
      ),
      findsOneWidget,
    );
```

- [ ] **Step 2: Run the focused test file to verify it fails on the old description**

Run: `flutter test test/user_sponsor_screen_test.dart`
Expected: FAIL because the screen still renders the earlier placeholder sponsor description.

- [ ] **Step 3: Replace the placeholder icon card with remote-logo sponsor rendering**

Update `lib/screens/user_sponsor_screen.dart` to use a small local model and network image.

Add this model near the top of the file:

```dart
class _SponsorInfo {
  const _SponsorInfo({
    required this.name,
    required this.websiteLabel,
    required this.websiteUri,
    required this.logoUrl,
    required this.description,
  });

  final String name;
  final String websiteLabel;
  final Uri websiteUri;
  final String logoUrl;
  final String description;
}
```

Replace the static URI with this constant:

```dart
  static final _SponsorInfo _davo = _SponsorInfo(
    name: 'DAVO',
    websiteLabel: 'davoice.io',
    websiteUri: Uri.parse('https://davoice.io/'),
    logoUrl: 'https://davoice.io/logo%20new%2096px.jpg',
    description:
        'DAVO phát triển công nghệ voice AI chạy trực tiếp trên thiết bị, gồm '
        'wake word, speaker recognition, VAD, STT và TTS, ưu tiên tốc độ và '
        'quyền riêng tư.',
  );
```

Update the launcher to use `_davo.websiteUri`.

Replace the top-left icon box with a network image plus fallback:

```dart
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: StyleTokens.background,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.network(
                          _davo.logoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) {
                            return Center(
                              child: Text(
                                _davo.name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: StyleTokens.buttonPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          },
                        ),
                      ),
```

Update all hard-coded `DAVO`, `davoice.io`, and description strings in the card body to read from `_davo`.

- [ ] **Step 4: Run the focused test file and confirm it passes**

Run: `flutter test test/user_sponsor_screen_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit the remote-logo sponsor slice**

```bash
git add lib/screens/user_sponsor_screen.dart test/user_sponsor_screen_test.dart
git commit -m "feat(user): show sponsor logo and details"
```

### Task 3: Final verification for shared user and family sponsor flow

**Files:**
- Modify: `test/user_sponsor_screen_test.dart`
- Verify: `lib/screens/user_personal_tab.dart`
- Verify: `lib/screens/family_personal_tab.dart`
- Verify: `lib/screens/user_sponsor_screen.dart`

- [ ] **Step 1: Add a focused website-launch assertion for the updated screen**

Keep or update the existing callback test so it still asserts the remote-logo version launches the
DAVO URL:

```dart
  testWidgets('Nút mở website gọi launchUrl với link DAVO', (
    WidgetTester tester,
  ) async {
    Uri? launchedUri;
    LaunchMode? launchedMode;

    Future<bool> fakeLaunchUrl(
      Uri url, {
      LaunchMode mode = LaunchMode.platformDefault,
    }) async {
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

- [ ] **Step 2: Run the focused test file to verify the whole sponsor flow**

Run: `flutter test test/user_sponsor_screen_test.dart`
Expected: PASS with user entry, family entry, sponsor content, and website-launch coverage all green.

- [ ] **Step 3: Run analyzer on all touched sponsor-flow files**

Run: `flutter analyze lib/screens/user_personal_tab.dart lib/screens/family_personal_tab.dart lib/screens/user_sponsor_screen.dart test/user_sponsor_screen_test.dart`
Expected: PASS with no warnings or errors.

- [ ] **Step 4: Optionally install the updated app on the connected Xiaomi debug device**

Run: `flutter install -d adb-be5f5683-7QoMjv._adb-tls-connect._tcp`
Expected: app installs successfully on the connected Android device.

- [ ] **Step 5: Commit the verification slice**

```bash
git add lib/screens/family_personal_tab.dart lib/screens/user_sponsor_screen.dart test/user_sponsor_screen_test.dart
git commit -m "test(sponsor): verify shared sponsor flow"
```

## Self-Review

- Spec coverage: this plan covers both user and family entry points, one shared sponsor screen, DAVO remote logo handling with fallback, the grounded description, URL launch behavior, and focused verification.
- Placeholder scan: no `TODO`, deferred work markers, or undefined references remain.
- Type consistency: `UserSponsorScreen`, `_ActionCard`, `_SponsorInfo`, `launchUrlFn`, and the DAVO URL fields are named consistently across tasks.
