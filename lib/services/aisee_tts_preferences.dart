import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User preference: bật/tắt đọc thông báo bằng giọng nói (TTS).
/// Mặc định BẬT vì target chính là người khiếm thị.
///
/// Shared giữa:
/// - AiseeReminderAnnouncer (đọc giờ uống thuốc, lịch hẹn)
/// - AiseeMessageAnnouncer (đọc tin nhắn đến)
class AiseeTtsPreferences extends ValueNotifier<bool> {
  AiseeTtsPreferences._() : super(true);

  static final AiseeTtsPreferences instance = AiseeTtsPreferences._();

  static const String _prefsKey = 'aisee.prefs.voice_announcements';

  bool _loaded = false;

  /// Load persisted value. Safe to call multiple times.
  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    // Default = true nếu chưa có key.
    value = prefs.getBool(_prefsKey) ?? true;
  }

  /// Bật / tắt voice announcement và persist.
  Future<void> setEnabled(bool enabled) async {
    if (value == enabled) return;
    value = enabled;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, enabled);
  }
}
