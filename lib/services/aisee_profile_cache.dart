import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/aisee_api_models.dart';

/// Bản sao hồ sơ AiSee gần nhất (không thay thế xác thực token; chỉ UI / gợi ý khi khởi động).
class AiseeProfileCache {
  AiseeProfileCache._();
  static final AiseeProfileCache instance = AiseeProfileCache._();

  static const String _kProfileJson = 'aisee_profile_cache_v1';

  Future<AiseeUserProfile?> read() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_kProfileJson);
    if (raw == null || raw.isEmpty) return null;
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return AiseeUserProfile.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> write(AiseeUserProfile profile) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kProfileJson, jsonEncode(profile.toJson()));
  }

  Future<void> clear() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kProfileJson);
  }
}
