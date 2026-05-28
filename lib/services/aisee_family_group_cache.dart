import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/aisee_family_group.dart';

class AiseeFamilyGroupCache {
  AiseeFamilyGroupCache._();
  static final AiseeFamilyGroupCache instance = AiseeFamilyGroupCache._();

  static const String _kGroupJson = 'aisee_family_group_cache_v1';

  Future<AiseeCurrentGroup?> read() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_kGroupJson);
    if (raw == null || raw.isEmpty) return null;
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return AiseeCurrentGroup.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> write(AiseeCurrentGroup group) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kGroupJson, jsonEncode(group.toJson()));
  }

  Future<void> clear() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kGroupJson);
  }
}
