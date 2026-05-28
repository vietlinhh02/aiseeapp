import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/aisee_supporter_models.dart';

class AiseeSupporterCache {
  AiseeSupporterCache._();
  static final AiseeSupporterCache instance = AiseeSupporterCache._();

  static const String _kOverviewJson = 'aisee_supporter_overview_v1';

  Future<SupporterOverviewResponse?> read() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_kOverviewJson);
    if (raw == null || raw.isEmpty) return null;
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return SupporterOverviewResponse.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> write(SupporterOverviewResponse overview) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kOverviewJson, jsonEncode(overview.toJson()));
  }

  Future<void> clear() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kOverviewJson);
  }
}
