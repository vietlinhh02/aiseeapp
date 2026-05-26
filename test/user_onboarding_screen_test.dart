import 'package:aiseeapp/generated/l10n/app_localizations.dart';
import 'package:aiseeapp/screens/user_onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('battery step blocks skip and continue until granted', (
    WidgetTester tester,
  ) async {
    final _FakeBatteryOptimizationController batteryController =
        _FakeBatteryOptimizationController(granted: false);

    await tester.pumpWidget(
      _buildScreen(
        batteryController: batteryController,
        showBatteryOptimizationStep: true,
      ),
    );

    await _goToBatteryStep(tester);

    final FilledButton continueButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Tiếp tục'),
    );
    final TextButton skipButton = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Bỏ qua'),
    );

    expect(find.text('Để cuộc gọi không bị bỏ lỡ'), findsOneWidget);
    expect(skipButton.onPressed, isNull);
    expect(continueButton.onPressed, isNull);
  });

  testWidgets(
    'granting battery optimization unlocks continue on battery step',
    (WidgetTester tester) async {
      final _FakeBatteryOptimizationController batteryController =
          _FakeBatteryOptimizationController(granted: false);

      await tester.pumpWidget(
        _buildScreen(
          batteryController: batteryController,
          showBatteryOptimizationStep: true,
        ),
      );

      await _goToBatteryStep(tester);

      await tester.ensureVisible(find.text('Tắt tối ưu pin cho AiSee'));
      await tester.tap(find.text('Tắt tối ưu pin cho AiSee'));
      await tester.pumpAndSettle();

      final FilledButton continueButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Tiếp tục'),
      );

      expect(find.text('Đã cho phép chạy nền'), findsOneWidget);
      expect(continueButton.onPressed, isNotNull);
    },
  );

  testWidgets('battery step keeps action card and removes old bullet list', (
    WidgetTester tester,
  ) async {
    final _FakeBatteryOptimizationController batteryController =
        _FakeBatteryOptimizationController(granted: false);

    await tester.pumpWidget(
      _buildScreen(
        batteryController: batteryController,
        showBatteryOptimizationStep: true,
      ),
    );

    await _goToBatteryStep(tester);

    await tester.ensureVisible(find.text('Tắt tối ưu pin cho AiSee'));

    expect(find.text('Tắt tối ưu pin cho AiSee'), findsOneWidget);
    expect(
      find.text('Cuộc gọi đến hiện ngay cả khi tắt màn hình'),
      findsNothing,
    );
  });
}

Widget _buildScreen({
  required _FakeBatteryOptimizationController batteryController,
  required bool showBatteryOptimizationStep,
}) {
  return MaterialApp(
    locale: const Locale('vi'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: AppOnboardingScreen(
      onCompleted: (_) {},
      batteryOptimizationController: batteryController,
      showBatteryOptimizationStep: showBatteryOptimizationStep,
    ),
  );
}

Future<void> _goToBatteryStep(WidgetTester tester) async {
  for (int i = 0; i < 3; i++) {
    await tester.tap(find.text('Tiếp tục'));
    await tester.pumpAndSettle();
  }
}

class _FakeBatteryOptimizationController
    implements BatteryOptimizationController {
  _FakeBatteryOptimizationController({required this.granted});

  bool granted;
  int requestCount = 0;

  @override
  Future<bool> isGranted() async => granted;

  @override
  Future<void> openSettings() async {}

  @override
  Future<bool> request() async {
    requestCount += 1;
    granted = true;
    return granted;
  }
}
