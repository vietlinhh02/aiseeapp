import 'package:aiseeapp/models/aisee_supporter_models.dart';
import 'package:aiseeapp/screens/family_support_widgets.dart';
import 'package:aiseeapp/theme/style_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('supporter action panel fits narrow mobile width', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: StyleTokens.lightTheme(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 312,
              child: SupporterActionPanel(
                watchAdLabel: 'Xem quảng cáo để ủng hộ',
                redeemLabel: 'Đổi ngay để ủng hộ',
                familyLinkLabel: 'Gia đình của tôi',
                busy: false,
                canRedeem: true,
                onWatchAd: () {},
                onRedeem: () {},
                onOpenFamily: () {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('supporter welcome banner fits narrow mobile width', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: StyleTokens.lightTheme(),
        home: const Scaffold(
          body: Center(
            child: SizedBox(
              width: 312,
              child: SupporterWelcomeBanner(
                title: 'Mỗi đóng góp của bạn đều tạo nên sự khác biệt.',
                message:
                    'Hỗ trợ quảng cáo, nhận xu và đổi lượt hỗ trợ để giúp nhiều người hơn nữa.',
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'community stats row uses dicebear avatar fallback and fits narrow width',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: StyleTokens.lightTheme(),
          home: const Scaffold(
            body: Center(
              child: SizedBox(
                width: 312,
                child: SupporterCommunityStatsRow(
                  totalCaredUsers: 1,
                  totalAITurns: 300,
                  activeSupporters: 2,
                  supporters: <CommunitySupporterProfile>[
                    CommunitySupporterProfile(anonSeed: 'seed1'),
                    CommunitySupporterProfile(anonSeed: 'seed2'),
                  ],
                  title: 'Cộng đồng',
                  labelPeople: 'Người được hỗ trợ',
                  labelAITurns: 'Lượt hỗ trợ',
                  labelSupporters: 'Người hỗ trợ',
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Image), findsAtLeastNWidgets(2));
      expect(tester.takeException(), isNull);
    },
  );
}
