import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:aiseeapp/models/aisee_api_models.dart';
import 'package:aiseeapp/screens/family_personal_tab.dart';
import 'package:aiseeapp/screens/user_personal_tab.dart';
import 'package:aiseeapp/screens/user_sponsor_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildPersonalTab() {
    return MaterialApp(
      home: Scaffold(body: UserPersonalTab(onSignOut: () {})),
    );
  }

  Widget buildFamilyTab() {
    const AiseeUserProfile profile = AiseeUserProfile(
      id: 'family-1',
      email: 'family@example.com',
      role: 'family',
      createdAt: '2026-04-01T00:00:00.000Z',
      isVolunteer: false,
    );
    return MaterialApp(
      home: Scaffold(
        body: FamilyPersonalTab(profile: profile, onSignOut: () {}),
      ),
    );
  }

  testWidgets('UserPersonalTab hiển thị mục Nhà tài trợ', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildPersonalTab());
    await tester.pumpAndSettle();

    expect(find.text('Nhà tài trợ'), findsOneWidget);
    expect(find.text('Các đơn vị đang đồng hành cùng dự án'), findsOneWidget);
  });

  testWidgets('Chạm mục Nhà tài trợ sẽ mở sponsor screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildPersonalTab());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nhà tài trợ'));
    await tester.pumpAndSettle();

    expect(find.text('DAVO'), findsWidgets);
    expect(find.text('davoice.io'), findsOneWidget);
    expect(find.text('Mở website'), findsOneWidget);
  });

  testWidgets('Sponsor screen hiển thị phần giới thiệu và card DAVO', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: UserSponsorScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Nhà tài trợ'), findsOneWidget);
    expect(
      find.text('Những đơn vị đang đồng hành cùng AiSee.'),
      findsOneWidget,
    );
    expect(find.text('DAVO'), findsWidgets);
    expect(find.text('davoice.io'), findsOneWidget);
    expect(
      find.text(
        'DAVO phát triển công nghệ voice AI chạy trực tiếp trên thiết bị, gồm '
        'wake word, speaker recognition, VAD, STT và TTS, ưu tiên tốc độ và '
        'quyền riêng tư.',
      ),
      findsOneWidget,
    );
    expect(find.text('Mở website'), findsOneWidget);
  });

  testWidgets(
    'FamilyPersonalTab hiển thị mục Nhà tài trợ và mở sponsor screen',
    (WidgetTester tester) async {
      await tester.pumpWidget(buildFamilyTab());
      await tester.pump();

      expect(find.text('Nhà tài trợ'), findsOneWidget);
      expect(find.text('Đơn vị đồng hành cùng dự án AiSee'), findsOneWidget);

      await tester.tap(find.text('Nhà tài trợ'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('DAVO'), findsWidgets);
      expect(find.text('davoice.io'), findsOneWidget);
    },
  );

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
      MaterialApp(home: UserSponsorScreen(launchUrlFn: fakeLaunchUrl)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mở website'));
    await tester.pumpAndSettle();

    expect(launchedUri, Uri.parse('https://davoice.io/'));
    expect(launchedMode, LaunchMode.externalApplication);
  });
}
