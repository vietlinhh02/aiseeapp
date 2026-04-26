import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/aisee_family_member.dart';
import '../models/aisee_message.dart';
import 'aisee_notification_feedback.dart';

class AiseeInAppMessageNotification {
  AiseeInAppMessageNotification({
    required this.message,
    required this.preview,
    required this.senderName,
    this.senderAvatarUrl,
    required this.receivedAt,
  });

  final AiseeMessage message;
  final String preview;
  final String senderName;
  final String? senderAvatarUrl;
  final DateTime receivedAt;
}

class AiseeInAppMessageController extends ChangeNotifier {
  AiseeInAppMessageController();

  static final AiseeInAppMessageController instance =
      AiseeInAppMessageController();

  AiseeInAppMessageNotification? _current;
  Timer? _dismissTimer;
  bool _appForeground = true;
  String? _currentUserId;
  String? _activeConversationId;
  final Map<String, AiseeFamilyMember> _contactsById =
      <String, AiseeFamilyMember>{};

  AiseeInAppMessageNotification? get current => _current;

  bool get shouldShow => _appForeground && _current != null;

  void setAppForeground(bool foreground) {
    if (_appForeground == foreground) return;
    _appForeground = foreground;
    if (!foreground) {
      hide();
      return;
    }
    notifyListeners();
  }

  void setCurrentUserId(String? userId) {
    final String? normalized = userId?.trim();
    _currentUserId = normalized == null || normalized.isEmpty
        ? null
        : normalized;
  }

  void setActiveConversation(String? contactId) {
    final String? normalized = contactId?.trim();
    _activeConversationId = normalized == null || normalized.isEmpty
        ? null
        : normalized;
    if (_current?.message.senderId == _activeConversationId) {
      hide();
    }
  }

  void rememberContacts(Iterable<AiseeFamilyMember> contacts) {
    for (final AiseeFamilyMember contact in contacts) {
      _contactsById[contact.id] = contact;
    }
  }

  void showMessage(AiseeMessage message) {
    if (!_appForeground) return;
    if (_isCurrentUserMessage(message)) return;
    if (_currentUserId != null && message.receiverId != _currentUserId) {
      return;
    }
    if (message.senderId == _activeConversationId) return;

    _dismissTimer?.cancel();
    _current = AiseeInAppMessageNotification(
      message: message,
      preview: _previewFor(message),
      senderName: _senderNameFor(message),
      senderAvatarUrl: _senderAvatarFor(message),
      receivedAt: DateTime.now(),
    );
    AiseeNotificationFeedback.instance.playMessageAlert();
    notifyListeners();
    _dismissTimer = Timer(const Duration(seconds: 4), hide);
  }

  String _senderNameFor(AiseeMessage message) {
    final String? payloadName = message.senderName?.trim();
    if (payloadName != null && payloadName.isNotEmpty) {
      return payloadName;
    }
    final AiseeFamilyMember? contact = _contactsById[message.senderId];
    if (contact != null) {
      return contact.label;
    }
    return 'Người thân';
  }

  String? _senderAvatarFor(AiseeMessage message) {
    final String? payloadAvatar = message.senderAvatarUrl?.trim();
    if (payloadAvatar != null && payloadAvatar.isNotEmpty) {
      return payloadAvatar;
    }
    final String? contactAvatar = _contactsById[message.senderId]?.avatarUrl
        ?.trim();
    if (contactAvatar != null && contactAvatar.isNotEmpty) {
      return contactAvatar;
    }
    return null;
  }

  void hide() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    if (_current == null) return;
    _current = null;
    notifyListeners();
  }

  bool _isCurrentUserMessage(AiseeMessage message) {
    final String? currentUserId = _currentUserId;
    return currentUserId != null && message.senderId == currentUserId;
  }

  String _previewFor(AiseeMessage message) {
    final String text = message.contentText.trim();
    if (text.isNotEmpty) {
      if (text.length <= 86) return text;
      return '${text.substring(0, 83)}...';
    }
    if (message.imageUrl != null) return 'Đã gửi một hình ảnh';
    if (message.voiceUrl != null) return 'Đã gửi tin nhắn thoại';
    return 'Tin nhắn mới';
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }
}
