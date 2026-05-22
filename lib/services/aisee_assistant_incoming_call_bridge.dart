import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/aisee_incoming_call.dart';

typedef AiseeAssistantIncomingCallAnnouncer =
    Future<void> Function(AiseeIncomingCall call);
typedef AiseeAssistantIncomingCallClearer =
    Future<void> Function(String roomName);

/// Cầu nối giữa PushService (nhận FCM/WS) và AssistantController (gửi control
/// xuống Gemini Live). Giữ ref tới cuộc gọi đang đổ chuông để các tool
/// answer_incoming_call / decline_incoming_call có dữ liệu thực hiện.
class AiseeAssistantIncomingCallBridge {
  AiseeAssistantIncomingCallBridge._();

  static final AiseeAssistantIncomingCallBridge instance =
      AiseeAssistantIncomingCallBridge._();

  AiseeIncomingCall? _pending;
  AiseeAssistantIncomingCallAnnouncer? _announcer;
  AiseeAssistantIncomingCallClearer? _clearer;

  AiseeIncomingCall? get pendingCall => _pending;

  void registerHandlers({
    required AiseeAssistantIncomingCallAnnouncer announce,
    required AiseeAssistantIncomingCallClearer clear,
  }) {
    _announcer = announce;
    _clearer = clear;
  }

  void unregisterHandlers() {
    _announcer = null;
    _clearer = null;
  }

  Future<void> notifyIncomingCall(AiseeIncomingCall call) async {
    _pending = call;
    final AiseeAssistantIncomingCallAnnouncer? announcer = _announcer;
    if (announcer == null) {
      debugPrint(
        '[AiSee:IncomingBridge] No announcer registered yet; '
        'storing call for later (room=${call.roomName}).',
      );
      return;
    }
    try {
      await announcer(call);
    } catch (error, stack) {
      debugPrint('[AiSee:IncomingBridge] announce failed: $error\n$stack');
    }
  }

  Future<void> clearPendingForRoom(String roomName) async {
    final AiseeIncomingCall? current = _pending;
    if (current != null && current.roomName == roomName) {
      _pending = null;
    }
    final AiseeAssistantIncomingCallClearer? clearer = _clearer;
    if (clearer == null) {
      return;
    }
    try {
      await clearer(roomName);
    } catch (error, stack) {
      debugPrint('[AiSee:IncomingBridge] clear failed: $error\n$stack');
    }
  }

  void clearPending() {
    _pending = null;
  }
}
