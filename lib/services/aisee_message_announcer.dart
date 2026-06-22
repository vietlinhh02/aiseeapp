import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../config/aisee_locale_controller.dart';
import '../generated/l10n/app_localizations.dart';
import '../models/aisee_message.dart';
import 'aisee_tts_preferences.dart';
import 'in_app_message_controller.dart';

/// Đọc tin nhắn đến bằng TTS khi app foreground + TTS bật.
/// Tránh đọc khi user đang ở trong màn hình chat với chính người gửi đó
/// (controller đã ẩn popup trong case đó).
class AiseeMessageAnnouncer with WidgetsBindingObserver {
  AiseeMessageAnnouncer._();
  static final AiseeMessageAnnouncer instance = AiseeMessageAnnouncer._();

  final FlutterTts _tts = FlutterTts();
  bool _ttsReady = false;
  bool _ttsEnabled = true;
  AiseeMessage? _lastSpoken;

  Future<void> start() async {
    AiseeTtsPreferences.instance.addListener(_onTtsPrefChanged);
    AiseeInAppMessageController.instance.addListener(_onMessage);
    AiseeLocaleController.instance.addListener(_onLocaleChanged);
    _ttsEnabled = AiseeTtsPreferences.instance.value;
    debugPrint('[AiSee:MsgAnnouncer] Started (TTS deferred, enabled=$_ttsEnabled)');
  }

  void dispose() {
    AiseeTtsPreferences.instance.removeListener(_onTtsPrefChanged);
    AiseeInAppMessageController.instance.removeListener(_onMessage);
    AiseeLocaleController.instance.removeListener(_onLocaleChanged);
    _tts.stop();
  }

  void _onTtsPrefChanged() {
    _ttsEnabled = AiseeTtsPreferences.instance.value;
    if (!_ttsEnabled) {
      _tts.stop();
    }
  }

  void _onLocaleChanged() {
    if (_ttsReady) {
      unawaited(_applyLocaleToTts());
    }
  }

  Future<void> _ensureTts() async {
    if (_ttsReady) return;
    await _initTts();
    _ttsReady = true;
  }

  Future<void> _applyLocaleToTts() async {
    final AppLocalizations l = lookupAppLocalizations(
      AiseeLocaleController.instance.value,
    );
    await _tts.setLanguage(l.ttsLanguageTag);
  }

  Future<void> _initTts() async {
    await _applyLocaleToTts();
    await _tts.setSpeechRate(0.55);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  void _onMessage() {
    if (!_ttsEnabled) return;
    final AiseeInAppMessageController c = AiseeInAppMessageController.instance;
    final AiseeInAppMessageNotification? notif = c.current;
    if (notif == null) return;
    // Tránh đọc lặp cùng một tin nhắn.
    if (_lastSpoken?.id == notif.message.id) return;
    _lastSpoken = notif.message;
    unawaited(_speakMessage(notif));
  }

  /// Đọc 1 message cụ thể (dùng cho test hoặc manual replay).
  Future<void> speakMessage(AiseeMessage message, String senderName) async {
    if (!_ttsEnabled) return;
    final AppLocalizations l = lookupAppLocalizations(
      AiseeLocaleController.instance.value,
    );
    final String body = _bodyFor(message, l);
    await _speak('${l.messageFrom(senderName)}. $body');
  }

  Future<void> _speakMessage(AiseeInAppMessageNotification notif) async {
    final AppLocalizations l = lookupAppLocalizations(
      AiseeLocaleController.instance.value,
    );
    final String body = _bodyFor(notif.message, l);
    await _speak('${l.messageFrom(notif.senderName)}. $body');
  }

  String _bodyFor(AiseeMessage m, AppLocalizations l) {
    final String text = m.contentText.trim();
    if (text.isNotEmpty) return text;
    if (m.imageUrl != null) return l.messageSentImage;
    if (m.voiceUrl != null) return l.messageSentVoice;
    return l.messageNew;
  }

  Future<void> _speak(String text) async {
    if (!_ttsEnabled) return;
    await _ensureTts();
    debugPrint('[AiSee:MsgAnnouncer] Speaking: $text');
    await _tts.stop(); // dừng câu cũ (nếu đang nói) trước khi nói câu mới.
    await _tts.speak(text);
  }

  /// Reset cache (test helper).
  @visibleForTesting
  void resetLastSpoken() => _lastSpoken = null;
}
