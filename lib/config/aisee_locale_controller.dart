import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks the user's preferred app locale and persists it across launches.
///
/// Backend stores the same value in `users.settings.preferred_language` so
/// push notifications can be localized when the app is offline.
class AiseeLocaleController extends ValueNotifier<Locale> {
  AiseeLocaleController._() : super(_defaultLocale());

  static final AiseeLocaleController instance = AiseeLocaleController._();

  static const String _prefsKey = 'aisee.app.locale';
  static const List<Locale> supportedLocales = <Locale>[
    Locale('vi'),
    Locale('en'),
  ];

  bool _loaded = false;

  /// Resolve the device's default language to one we ship.
  static Locale _defaultLocale() {
    final String code = PlatformDispatcher.instance.locale.languageCode
        .toLowerCase();
    if (code.startsWith('en')) return const Locale('en');
    return const Locale('vi');
  }

  static Locale _normalize(String code) {
    final String c = code.trim().toLowerCase();
    if (c.startsWith('en')) return const Locale('en');
    return const Locale('vi');
  }

  /// Load the persisted locale; safe to call multiple times.
  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? saved = prefs.getString(_prefsKey);
    if (saved != null && saved.isNotEmpty) {
      value = _normalize(saved);
    }
  }

  /// Update the active locale and persist it. The backend is updated
  /// separately via the user profile API so push notifications follow.
  Future<void> setLocale(Locale locale) async {
    final Locale next = _normalize(locale.languageCode);
    if (next.languageCode == value.languageCode) return;
    value = next;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, next.languageCode);
  }
}
