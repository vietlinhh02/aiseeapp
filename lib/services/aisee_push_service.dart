import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';

import '../models/aisee_api_models.dart';
import '../models/aisee_call_info.dart';
import '../models/aisee_family_member.dart';
import '../services/aisee_call_service.dart';
import '../services/aisee_family_service.dart';
import '../services/aisee_session_store.dart';

void _log(String msg) => debugPrint('[AiSee:Push] $msg');

class AiseePushService {
  AiseePushService._();
  static final AiseePushService instance = AiseePushService._();

  bool _initialized = false;

  final StreamController<AiseeCallInfo> _pendingCallController =
      StreamController<AiseeCallInfo>.broadcast();

  AiseeCallInfo? _pendingCallInfo;

  /// Stream of incoming calls that were accepted.
  Stream<AiseeCallInfo> get onAcceptedCall =>
      _pendingCallController.stream;

  AiseeCallInfo? consumePendingCall() {
    final AiseeCallInfo? info = _pendingCallInfo;
    _pendingCallInfo = null;
    return info;
  }

  /// Initialize FCM, request permission, upload token.
  /// Silently skips if Firebase is not configured.
  Future<void> initAndUploadToken(String accessToken) async {
    try {
      return await _initAndUploadTokenUnsafe(accessToken);
    } catch (e) {
      _log('Push init skipped (Firebase not configured?): $e');
    }
  }

  Future<void> _initAndUploadTokenUnsafe(String accessToken) async {
    if (_initialized) {
      await _uploadFcmToken(accessToken);
      return;
    }
    _initialized = true;

    final FirebaseMessaging messaging = FirebaseMessaging.instance;
    final NotificationSettings settings =
        await messaging.requestPermission();
    _log('Permission: ${settings.authorizationStatus}');

    await _uploadFcmToken(accessToken);

    messaging.onTokenRefresh.listen((String token) async {
      _log('Token refreshed');
      final AiseeAuthTokens? tokens =
          await AiseeSessionStore.instance.read();
      if (tokens == null) return;
      final AiseeFamilyService svc = AiseeFamilyService();
      try {
        await svc.updateProfile(
          tokens.accessToken,
          {'fcm_token': token},
        );
      } catch (e) {
        _log('Upload refreshed token failed: $e');
      } finally {
        svc.close();
      }
    });

    FirebaseMessaging.onMessage.listen(_handleMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    FlutterCallkitIncoming.onEvent.listen(_onCallKitEvent);

    _log('Push service initialized');
  }

  Future<void> _uploadFcmToken(String accessToken) async {
    try {
      final String? token =
          await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) {
        _log('No FCM token available');
        return;
      }
      _log('FCM token: ${token.substring(0, 20)}...');
      final AiseeFamilyService svc = AiseeFamilyService();
      try {
        await svc.updateProfile(
          accessToken,
          {'fcm_token': token},
        );
        _log('FCM token uploaded');
      } finally {
        svc.close();
      }
    } catch (e) {
      _log('Upload FCM token failed: $e');
    }
  }

  void _handleMessage(RemoteMessage message) {
    _log('Message received: ${message.data}');
    final Map<String, dynamic> data = message.data;
    final String? type = data['type'] as String?;

    if (type == 'incoming_call') {
      _showIncomingCall(data);
    }
  }

  Future<void> _showIncomingCall(
    Map<String, dynamic> data,
  ) async {
    final String callerName =
        data['caller_name'] as String? ?? 'Người gọi';
    final String roomName =
        data['room_name'] as String? ?? '';
    final String callType =
        data['call_type'] as String? ?? 'voice';
    final String callerId =
        data['caller_id'] as String? ?? '';

    _log(
      'Incoming call from $callerName, '
      'room=$roomName, type=$callType',
    );

    final CallKitParams params = CallKitParams(
      id: roomName,
      nameCaller: callerName,
      type: callType == 'video' ? 1 : 0,
      duration: 30000,
      extra: <String, dynamic>{
        'caller_id': callerId,
        'caller_name': callerName,
        'room_name': roomName,
        'call_type': callType,
        'token': data['token'] as String? ?? '',
      },
      android: const AndroidParams(
        isShowFullLockedScreen: true,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#1A3263',
        actionColor: '#1A3263',
      ),
      ios: const IOSParams(
        handleType: 'generic',
        supportsVideo: true,
        maximumCallGroups: 1,
        maximumCallsPerCallGroup: 1,
        audioSessionMode: 'default',
        audioSessionActive: true,
        audioSessionPreferredSampleRate: 44100.0,
        audioSessionPreferredIOBufferDuration: 0.005,
        ringtonePath: 'system_ringtone_default',
      ),
    );

    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }

  Future<void> _onCallKitEvent(CallEvent? event) async {
    if (event == null) return;
    _log('CallKit event: ${event.event}');

    switch (event.event) {
      case Event.actionCallAccept:
        await _acceptCall(event);
      case Event.actionCallDecline:
      case Event.actionCallEnded:
        await _declineCall(event);
      default:
        break;
    }
  }

  Future<void> _acceptCall(CallEvent event) async {
    final Map<String, dynamic>? extra =
        (event.body as Map<String, dynamic>?)?['extra']
            as Map<String, dynamic>?;
    if (extra == null) return;

    final String roomName =
        extra['room_name'] as String? ?? '';
    final String callType =
        extra['call_type'] as String? ?? 'voice';
    final String callerName =
        extra['caller_name'] as String? ?? '';
    final String callerId =
        extra['caller_id'] as String? ?? '';
    final String? pushToken =
        extra['token'] as String?;

    if (roomName.isEmpty) return;

    if (pushToken != null && pushToken.isNotEmpty) {
      _navigateToCall(
        AiseeCallInfo(
          roomName: roomName,
          token: pushToken,
          callType: callType,
          contact: AiseeFamilyMember(
            id: callerId,
            email: '',
            displayName: callerName,
            role: 'family',
          ),
        ),
      );
    }
  }

  Future<void> _declineCall(CallEvent event) async {
    final Map<String, dynamic>? extra =
        (event.body as Map<String, dynamic>?)?['extra']
            as Map<String, dynamic>?;
    final String? roomName =
        extra?['room_name'] as String?;
    if (roomName == null || roomName.isEmpty) return;

    final AiseeAuthTokens? tokens =
        await AiseeSessionStore.instance.read();
    if (tokens == null) return;

    final AiseeCallService svc = AiseeCallService();
    try {
      await svc.endRoom(tokens.accessToken, roomName);
    } catch (_) {
      // Server may have already ended the room
    }
    svc.close();
  }

  void _navigateToCall(AiseeCallInfo callInfo) {
    _log('Navigate to call: room=${callInfo.roomName}');
    _pendingCallInfo = callInfo;
    _pendingCallController.add(callInfo);
  }
}
