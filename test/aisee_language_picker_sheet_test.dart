import 'package:aiseeapp/config/aisee_locale_controller.dart';
import 'package:aiseeapp/generated/l10n/app_localizations.dart';
import 'package:aiseeapp/widgets/aisee_language_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('language change waits until picker route is closed', (
    WidgetTester tester,
  ) async {
    await AiseeLocaleController.instance.setLocale(const Locale('vi'));
    int localeChangeCount = 0;
    void listener() => localeChangeCount++;
    AiseeLocaleController.instance.addListener(listener);
    addTearDown(() => AiseeLocaleController.instance.removeListener(listener));

    await tester.pumpWidget(
      ValueListenableBuilder<Locale>(
        valueListenable: AiseeLocaleController.instance,
        builder: (BuildContext context, Locale locale, _) {
          return MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (BuildContext context) {
                return Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () => AiseeLanguagePickerSheet.show(context),
                      child: const Text('Open language picker'),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );

    await tester.tap(find.text('Open language picker'));
    await tester.pumpAndSettle();
    expect(find.byType(AiseeLanguagePickerSheet), findsOneWidget);

    await tester.tap(find.text('English').first);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(localeChangeCount, 1);
    expect(AiseeLocaleController.instance.value.languageCode, 'en');
    expect(find.byType(AiseeLanguagePickerSheet), findsNothing);
  });
}
