import 'package:shared_preferences/shared_preferences.dart';

class AiseeFamilyContextStore {
  AiseeFamilyContextStore._();

  static final AiseeFamilyContextStore instance = AiseeFamilyContextStore._();

  static const String _kLastCaredUserId = 'aisee_family_last_cared_user_id_v1';

  Future<String?> readLastCaredUserId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? value = prefs.getString(_kLastCaredUserId);
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return value.trim();
  }

  Future<void> writeLastCaredUserId(String caredUserId) async {
    final String trimmed = caredUserId.trim();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (trimmed.isEmpty) {
      await prefs.remove(_kLastCaredUserId);
      return;
    }
    await prefs.setString(_kLastCaredUserId, trimmed);
  }

  Future<void> clear() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLastCaredUserId);
  }
}
