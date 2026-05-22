import 'package:aiseeapp/services/aisee_onboarding_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('app onboarding completion stores selected role', () async {
    final AiseeOnboardingStore store = AiseeOnboardingStore();

    expect(await store.hasCompletedAppOnboarding(), isFalse);
    expect(await store.readSelectedRole(), isNull);

    await store.completeAppOnboarding(role: 'user');

    expect(await store.hasCompletedAppOnboarding(), isTrue);
    expect(await store.readSelectedRole(), 'user');
  });

  test(
    'role can be preserved for future logins without clearing app data',
    () async {
      final AiseeOnboardingStore store = AiseeOnboardingStore();

      await store.completeAppOnboarding(role: 'family');

      expect(await store.hasCompletedAppOnboarding(), isTrue);
      expect(await store.readSelectedRole(), 'family');
    },
  );
}
