import 'package:shared_preferences/shared_preferences.dart';

class AiseeOnboardingStore {
  static final AiseeOnboardingStore instance = AiseeOnboardingStore();

  static const String _appOnboardingCompletedKey =
      'aisee.app_onboarding_completed.v1';
  static const String _selectedRoleKey = 'aisee.selected_role.v1';

  Future<bool> hasCompletedAppOnboarding() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_appOnboardingCompletedKey) ?? false;
  }

  Future<String?> readSelectedRole() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? role = prefs.getString(_selectedRoleKey)?.trim();
    if (role == null || role.isEmpty) {
      return null;
    }
    return role;
  }

  Future<void> completeAppOnboarding({required String role}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedRoleKey, role);
    await prefs.setBool(_appOnboardingCompletedKey, true);
  }
}
