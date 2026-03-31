import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';

import '../config/aisee_navigator_key.dart';
import '../models/aisee_api_models.dart';
import '../models/aisee_call_info.dart';
import '../models/aisee_family_member.dart';
import '../screens/call_screen.dart';
import 'aisee_call_service.dart';
import 'aisee_family_service.dart';
import 'aisee_session_store.dart';

void _log(String msg) => debugPrint('[AiSee:Push] $msg');

class AiseePushService {
  AiseePushService._();
  static final AiseePushService instance = AiseePushService._();

  bool _initialized = false;
  static bool _callKitListenerAttached = false;

  AiseeCallInfo? _pendingCallInfo;

  /// Gọi từ [AiseeApp] ngay khi khởi động — trước đăng nhập — để bắt Accept/Decline.
  void attachCallKitListenerEarly() {
    if (_callKitListenerAttached) {
      return;
    }
    _callKitListenerAttached = true;
    FlutterCallkitIncoming.onEvent.listen((CallEvent? event) {
      unawaited(instance._onCallKitEvent(event));
    });
    _log('CallKit listener attached (early)');
  }

  AiseeCallInfo? consumePendingCall() {
    final AiseeCallInfo? info = _pendingCallInfo;
    _pendingCallInfo = null;
    return info;
  }

  /// Thử mở [CallScreen] nếu còn pending (sau khi session + navigator sẵn sàng).
  void flushPendingCallNavigation() {
    final AiseeCallInfo? p = _pendingCallInfo;
    if (p != null && _tryOpenCallScreen(p)) {
      _pendingCallInfo = null;
    }
  }

  /// Đồng bộ khi app resume / cold start: Android lưu cuộc gọi đã Accept.
  Future<void> syncActiveAcceptedCall() async {
    if (CallScreen.openRouteCount > 0) {
      return;
    }
    try {
      final dynamic calls = await FlutterCallkitIncoming.activeCalls();
      if (calls is! List || calls.isEmpty) {
        return;
      }
      final dynamic first = calls.first;
      if (first is! Map) {
        return;
      }
      final Map<String, dynamic> map = Map<String, dynamic>.from(first);
      final bool accepted = map['isAccepted'] == true;
      if (!accepted) {
        return;
      }
      final AiseeCallInfo? info = _callInfoFromCallKitPayload(map);
      if (info == null) {
        _log('syncActiveAcceptedCall: thiếu token hoặc room');
        return;
      }
      _navigateToCall(info);
    } catch (e) {
      _log('syncActiveAcceptedCall: $e');
    }
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
    if (!kIsWeb && Platform.isAndroid) {
      unawaited(FlutterCallkitIncoming.requestFullIntentPermission());
    }

    if (_initialized) {
      await _uploadFcmToken(accessToken);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        flushPendingCallNavigation();
        unawaited(syncActiveAcceptedCall());
      });
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      flushPendingCallNavigation();
      unawaited(syncActiveAcceptedCall());
    });

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
    final Map<String, dynamic> data = Map<String, dynamic>.from(message.data);
    final String type = _stringField(data, const ['type']);

    if (type == 'incoming_call') {
      unawaited(showIncomingCallUi(data));
    }
  }

  static String _stringField(Map<String, dynamic> map, List<String> keys) {
    for (final String k in keys) {
      final Object? v = map[k];
      if (v == null) {
        continue;
      }
      final String s = v is String ? v : v.toString();
      if (s.isNotEmpty) {
        return s;
      }
    }
    return '';
  }

  /// FCM (foreground), FCM background isolate, hoặc WebSocket — payload phẳng; FCM hay trả toàn String.
  static Future<void> showIncomingCallUi(Map<String, dynamic> data) async {
    final Map<String, dynamic> d = Map<String, dynamic>.from(data);

    final String callerName = _stringField(
      d,
      const ['caller_name', 'callerName', 'name_caller', 'nameCaller'],
    );
    final String displayName =
        callerName.isNotEmpty ? callerName : 'Người gọi';

    final String roomName = _stringField(
      d,
      const ['room_name', 'roomName', 'room', 'id'],
    );
    final String callType =
        _stringField(d, const ['call_type', 'callType']).isEmpty
            ? 'voice'
            : _stringField(d, const ['call_type', 'callType']);

    final String callerId = _stringField(
      d,
      const ['caller_id', 'callerId', 'from_user_id'],
    );

    final String token = _stringField(
      d,
      const ['token', 'livekit_token', 'livekitToken', 'jwt'],
    );

    final String callId =
        roomName.isNotEmpty ? roomName : 'call-${DateTime.now().millisecondsSinceEpoch}';

    _log(
      'Incoming call UI: name=$displayName room=$roomName type=$callType',
    );

    final CallKitParams params = CallKitParams(
      id: callId,
      nameCaller: displayName,
      appName: 'AiSee',
      handle: displayName,
      type: callType == 'video' ? 1 : 0,
      duration: 45000,
      textAccept: 'Nghe',
      textDecline: 'Từ chối',
      extra: <String, dynamic>{
        'caller_id': callerId,
        'caller_name': displayName,
        'room_name': roomName.isNotEmpty ? roomName : callId,
        'call_type': callType,
        'token': token,
      },
      android: AndroidParams(
        isShowFullLockedScreen: true,
        isShowLogo: false,
        isImportant: true,
        isCustomNotification: true,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#1A3263',
        actionColor: '#FFFFFF',
        textColor: '#FFFFFF',
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
    if (event == null) {
      return;
    }
    _log('CallKit event: ${event.event}');

    if (event.event == Event.actionCallAccept) {
      await _acceptCall(event);
      return;
    }
    if (event.event == Event.actionCallDecline ||
        event.event == Event.actionCallEnded) {
      await _declineCall(event);
    }
  }

  static Map<String, dynamic> _bodyAsMap(CallEvent event) {
    final dynamic b = event.body;
    if (b is! Map) {
      return <String, dynamic>{};
    }
    return Map<String, dynamic>.from(b);
  }

  /// Gộp [extra] với các trường trên cùng body (Android gửi nameCaller, id, extra riêng).
  static Map<String, dynamic> _mergedExtra(CallEvent event) {
    final Map<String, dynamic> body = _bodyAsMap(event);
    final Map<String, dynamic> merged = <String, dynamic>{};

    void put(String key, Object? value) {
      if (value == null) {
        return;
      }
      final String s = value is String ? value : value.toString();
      if (s.isEmpty) {
        return;
      }
      if (!merged.containsKey(key) ||
          (merged[key]?.toString().isEmpty ?? true)) {
        merged[key] = value;
      }
    }

    final dynamic rawExtra = body['extra'];
    if (rawExtra is Map) {
      rawExtra.forEach((dynamic k, dynamic v) {
        put(k.toString(), v);
      });
    }

    put('room_name', body['room_name']);
    put('caller_name', body['caller_name']);
    put('caller_id', body['caller_id']);
    put('call_type', body['call_type']);
    put('token', body['token']);

    put('room_name', merged['room_name'] ?? body['id']);
    put('caller_name', merged['caller_name'] ?? body['nameCaller']);
    put('handle', body['number']);

    return merged;
  }

  static AiseeCallInfo? _callInfoFromCallKitPayload(Map<String, dynamic> src) {
    final Map<String, dynamic> m = Map<String, dynamic>.from(src);
    final Map<String, dynamic> extra = <String, dynamic>{};
    final dynamic ex = m['extra'];
    if (ex is Map) {
      ex.forEach((dynamic k, dynamic v) {
        extra[k.toString()] = v;
      });
    }

    String pick(List<String> keys) {
      for (final String k in keys) {
        final Object? v = extra[k] ?? m[k];
        if (v == null) {
          continue;
        }
        final String s = v is String ? v : v.toString();
        if (s.isNotEmpty) {
          return s;
        }
      }
      return '';
    }

    final String roomName =
        pick(const ['room_name', 'roomName', 'id']);

    final String token = pick(const ['token', 'livekit_token', 'livekitToken']);
    final String callType = pick(const ['call_type', 'callType']);
    final String ct = callType.isEmpty ? 'voice' : callType;
    final String callerName =
        pick(const ['caller_name', 'callerName', 'nameCaller']);
    final String display =
        callerName.isNotEmpty ? callerName : 'Người gọi';
    final String callerId = pick(const ['caller_id', 'callerId']);

    if (roomName.isEmpty || token.isEmpty) {
      return null;
    }
    return AiseeCallInfo(
      roomName: roomName,
      token: token,
      callType: ct,
      contact: AiseeFamilyMember(
        id: callerId.isNotEmpty ? callerId : roomName,
        email: '',
        displayName: display,
        role: 'family',
      ),
    );
  }

  Future<void> _acceptCall(CallEvent event) async {
    final Map<String, dynamic> merged = _mergedExtra(event);
    final String room = _stringField(
      merged,
      const ['room_name', 'roomName'],
    );
    final String idFallback = _stringField(_bodyAsMap(event), const ['id']);
    final String roomName = room.isNotEmpty ? room : idFallback;

    final String token = _stringField(
      merged,
      const ['token', 'livekit_token', 'livekitToken'],
    );
    final String callType = _stringField(
      merged,
      const ['call_type', 'callType'],
    );
    final String ct = callType.isEmpty ? 'voice' : callType;
    final String callerName = _stringField(
      merged,
      const ['caller_name', 'callerName', 'nameCaller'],
    );
    final String display =
        callerName.isNotEmpty ? callerName : 'Người gọi';
    final String callerId = _stringField(
      merged,
      const ['caller_id', 'callerId'],
    );

    if (roomName.isEmpty) {
      _log('Accept: thiếu room');
      return;
    }
    if (token.isEmpty) {
      _log('Accept: thiếu token trong extra — kiểm tra payload FCM/backend');
      return;
    }

    _navigateToCall(
      AiseeCallInfo(
        roomName: roomName,
        token: token,
        callType: ct,
        contact: AiseeFamilyMember(
          id: callerId.isNotEmpty ? callerId : roomName,
          email: '',
          displayName: display,
          role: 'family',
        ),
      ),
    );
  }

  Future<void> _declineCall(CallEvent event) async {
    final Map<String, dynamic> merged = _mergedExtra(event);
    final Map<String, dynamic> body = _bodyAsMap(event);
    String room = _stringField(merged, const ['room_name', 'roomName']);
    if (room.isEmpty) {
      room = _stringField(body, const ['id']);
    }
    if (room.isEmpty) {
      return;
    }

    final AiseeAuthTokens? tokens =
        await AiseeSessionStore.instance.read();
    if (tokens == null) {
      return;
    }

    final AiseeCallService svc = AiseeCallService();
    try {
      await svc.endRoom(tokens.accessToken, room);
    } catch (_) {
      // Server may have already ended the room
    }
    svc.close();
  }

  void _navigateToCall(AiseeCallInfo callInfo) {
    _log('Navigate to call: room=${callInfo.roomName}');
    if (_tryOpenCallScreen(callInfo)) {
      _pendingCallInfo = null;
      return;
    }
    _pendingCallInfo = callInfo;
  }

  bool _tryOpenCallScreen(AiseeCallInfo callInfo) {
    if (CallScreen.openRouteCount > 0) {
      return true;
    }
    final BuildContext? ctx = aiseeNavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) {
      return false;
    }
    final NavigatorState? nav = Navigator.maybeOf(ctx, rootNavigator: true);
    if (nav == null) {
      return false;
    }
    nav.push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => CallScreen(callInfo: callInfo),
      ),
    );
    return true;
  }
}
