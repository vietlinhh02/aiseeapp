import 'package:aiseeapp/generated/l10n/app_localizations.dart';
import 'package:aiseeapp/models/aisee_message.dart';
import 'package:aiseeapp/models/aisee_family_member.dart';
import 'package:aiseeapp/services/in_app_message_controller.dart';
import 'package:aiseeapp/widgets/in_app_message_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  AiseeMessage message({
    String senderId = 'family-1',
    String receiverId = 'user-1',
    String contentText = 'Bạn ổn không?',
    String? senderName,
    String? senderAvatarUrl,
  }) {
    return AiseeMessage(
      id: 'msg-1',
      senderId: senderId,
      receiverId: receiverId,
      contentText: contentText,
      senderName: senderName,
      senderAvatarUrl: senderAvatarUrl,
      createdAt: DateTime(2026, 4, 26, 9),
    );
  }

  test('message popup filters outgoing and unrelated messages', () {
    final AiseeInAppMessageController controller =
        AiseeInAppMessageController();
    controller.setAppForeground(true);
    controller.setCurrentUserId('user-1');

    controller.showMessage(message(senderId: 'user-1', receiverId: 'family-1'));
    expect(controller.current, isNull);

    controller.showMessage(message(receiverId: 'other-user'));
    expect(controller.current, isNull);

    controller.showMessage(message());
    expect(controller.current?.preview, 'Bạn ổn không?');

    controller.dispose();
  });

  test('message popup is suppressed for the active conversation', () {
    final AiseeInAppMessageController controller =
        AiseeInAppMessageController();
    controller.setAppForeground(true);
    controller.setCurrentUserId('user-1');
    controller.setActiveConversation('family-1');

    controller.showMessage(message());
    expect(controller.current, isNull);

    controller.setActiveConversation(null);
    controller.showMessage(message());
    expect(controller.current, isNotNull);

    controller.dispose();
  });

  test('message popup resolves sender name from payload or contacts', () {
    final AiseeInAppMessageController controller =
        AiseeInAppMessageController();
    controller.setAppForeground(true);
    controller.setCurrentUserId('user-1');
    controller.rememberContacts(const <AiseeFamilyMember>[
      AiseeFamilyMember(
        id: 'family-1',
        email: 'linh@example.com',
        displayName: 'Linh Viết',
        role: 'family',
        avatarUrl: 'https://example.com/avatar.png',
      ),
    ]);

    controller.showMessage(message());
    expect(controller.current?.senderName, 'Linh Viết');
    expect(
      controller.current?.senderAvatarUrl,
      'https://example.com/avatar.png',
    );

    controller.showMessage(message(senderName: 'Tên từ payload'));
    expect(controller.current?.senderName, 'Tên từ payload');

    controller.dispose();
  });

  testWidgets('message overlay renders and dismisses notification', (
    WidgetTester tester,
  ) async {
    final AiseeInAppMessageController controller =
        AiseeInAppMessageController();
    controller.setAppForeground(true);
    controller.setCurrentUserId('user-1');

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: InAppMessageOverlayHost(
          controller: controller,
          child: const Scaffold(body: SizedBox.expand()),
        ),
      ),
    );

    controller.showMessage(message());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 240));

    expect(find.text('Người thân'), findsOneWidget);
    expect(find.text('Bạn ổn không?'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();

    expect(find.text('Người thân'), findsNothing);

    controller.dispose();
  });

  testWidgets('message overlay renders sender name, avatar, and content', (
    WidgetTester tester,
  ) async {
    final AiseeInAppMessageController controller =
        AiseeInAppMessageController();
    controller.setAppForeground(true);
    controller.setCurrentUserId('user-1');

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: InAppMessageOverlayHost(
          controller: controller,
          child: const Scaffold(body: SizedBox.expand()),
        ),
      ),
    );

    controller.showMessage(
      message(
        senderName: 'Linh Viết',
        senderAvatarUrl: 'https://example.com/avatar.png',
        contentText: 'Mình vừa gửi thuốc hôm nay.',
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 260));

    expect(find.text('Linh Viết'), findsOneWidget);
    expect(find.text('Mình vừa gửi thuốc hôm nay.'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);

    controller.dispose();
  });

  testWidgets('message overlay works from MaterialApp builder', (
    WidgetTester tester,
  ) async {
    final AiseeInAppMessageController controller =
        AiseeInAppMessageController();
    controller.setAppForeground(true);
    controller.setCurrentUserId('user-1');

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (BuildContext context, Widget? child) {
          return InAppMessageOverlayHost(
            controller: controller,
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const Scaffold(body: SizedBox.expand()),
      ),
    );

    controller.showMessage(message());
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Người thân'), findsOneWidget);

    controller.dispose();
  });
}
