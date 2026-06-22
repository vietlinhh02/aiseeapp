import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';

import '../config/aisee_navigator_key.dart';
import '../config/aisee_locale_controller.dart';
import '../models/aisee_call_info.dart';
import '../models/aisee_incoming_call.dart';
import '../screens/call_screen.dart';
import '../utils/app_toast.dart';
import 'aisee_call_service.dart';
import 'aisee_assistant_incoming_call_bridge.dart';
import 'aisee_family_service.dart';
import 'aisee_token_provider.dart';
import 'incoming_call_controller.dart';

void _log(String msg) => debugPrint('[AiSee:Push] $msg');

class AiseePushService {
  AiseePushService._();
  static final AiseePushService instance = AiseePushService._();

  bool _initialized = false;
  static bool _callKitListenerAttached = false;

  AiseeCallInfo? _pendingCallInfo;
  final AiseeIncomingCallController _incomingCalls =
      AiseeIncomingCallController.instance;

  /// Called before navigating to call screen — pause AI mic.
  Future<void> Function()? onBeforeIncomingCallAnswered;

  /// Called when call screen is dismissed — resume AI mic.
  Future<void> Function()? onCallScreenDismissed;

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
    if (_initialized) {
      await _uploadFcmToken(accessToken);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        flushPendingCallNavigation();
        unawaited(syncActiveAcceptedCall());
      });
      return;
    }
    _initialized = true;

    // Android 13+ requires runtime POST_NOTIFICATIONS — ask CallKit directly
    // so its custom channels (incoming call / missed call) are usable in
    // both foreground and background/killed states.
    //
    // Lưu ý: KHÔNG await các request quyền này — popup hệ thống sẽ pause
    // Activity và "kẹt" màn "Đang xác thực với máy chủ" của auth flow.
    // Chạy fire-and-forget để user thấy Home Screen trước, popup hiện trên
    // Home. FCM token vẫn upload ngay (không phụ thuộc quyền granted).
    if (!kIsWeb && Platform.isAndroid) {
      unawaited(
        FlutterCallkitIncoming.requestNotificationPermission(
          <String, dynamic>{
            'rationaleMessagePermission':
                'Cấp quyền thông báo để AiSee có thể báo cuộc gọi và tin nhắn.',
            'postNotificationMessageRequired':
                'Vui lòng bật thông báo trong Cài đặt để nhận cuộc gọi và tin nhắn.',
          },
        ).catchError((Object e) {
          _log('requestNotificationPermission skipped: $e');
        }),
      );
      // Android 14+ requires the user to grant USE_FULL_SCREEN_INTENT for the
      // full-screen incoming CallKit UI. Without it, calls are silently dropped
      // when the app is in background or the device is locked.
      unawaited(
        FlutterCallkitIncoming.requestFullIntentPermission().catchError(
          (Object e) {
            _log('requestFullIntentPermission skipped: $e');
          },
        ),
      );
    }

    final FirebaseMessaging messaging = FirebaseMessaging.instance;
    unawaited(
      messaging
          .requestPermission(alert: true, badge: true, sound: true)
          .then((NotificationSettings settings) {
            _log('FCM permission: ${settings.authorizationStatus}');
          })
          .catchError((Object e) {
            _log('FCM requestPermission skipped: $e');
          }),
    );

    await _uploadFcmToken(accessToken);

    messaging.onTokenRefresh.listen((String token) async {
      _log('Token refreshed');
      final String? accessToken = await AiseeTokenProvider.instance
          .accessToken();
      if (accessToken == null) return;
      final AiseeFamilyService svc = AiseeFamilyService();
      try {
        await svc.updateProfile(accessToken, {'fcm_token': token});
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
      final String? token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) {
        _log('No FCM token available');
        return;
      }
      _log('FCM token: ${token.substring(0, 20)}...');
      final AiseeFamilyService svc = AiseeFamilyService();
      try {
        await svc.updateProfile(accessToken, {'fcm_token': token});
        _log('FCM token uploaded');
      } finally {
        svc.close();
      }
    } catch (e) {
      _log('Upload FCM token failed: $e');
    }
  }

  void _handleMessage(RemoteMessage message) {
    final Map<String, dynamic> raw = Map<String, dynamic>.from(message.data);
    final Map<String, dynamic> data = _normalizeStringMap(raw);
    _log(
      'Message received: id=${message.messageId} type=${data['type']} '
      'room=${data['room_name']} caller=${data['caller_name']}',
    );
    final String type = _stringField(data, const ['type']);

    if (type == 'incoming_call' || type == 'volunteer_match') {
      handleIncomingCallPayload(data, source: AiseeIncomingCallSource.fcm);
      return;
    }
    if (type == 'call_ended') {
      unawaited(handleCallEndedPayload(data));
    }
  }

  void handleIncomingCallPayload(
    Map<String, dynamic> data, {
    required AiseeIncomingCallSource source,
  }) {
    final AiseeIncomingCall call = AiseeIncomingCall.fromPayload(
      data,
      source: source,
    );
    _log(
      'Incoming call: source=$source room=${call.roomName} '
      'type=${call.callType} foreground=${_incomingCalls.isAppForeground}',
    );
    // Always notify AI so it can announce via audio + accept voice commands.
    unawaited(
      AiseeAssistantIncomingCallBridge.instance.notifyIncomingCall(call),
    );
    if (_incomingCalls.isAppForeground) {
      _incomingCalls.showIncomingCall(call);
      return;
    }
    unawaited(showIncomingCallUi(data));
  }

  Future<void> handleCallEndedPayload(Map<String, dynamic> data) async {
    await endIncomingCallUi(data);
    final Map<String, dynamic> payload = _unwrapMessagePayload(data);
    final String roomName = _roomNameFromPayload(payload);
    if (roomName.isNotEmpty) {
      _incomingCalls.hideIncomingCallForRoom(roomName);
      unawaited(
        AiseeAssistantIncomingCallBridge.instance.clearPendingForRoom(roomName),
      );
    }
  }

  static Future<void> endIncomingCallUi(Map<String, dynamic> data) async {
    final Map<String, dynamic> payload = _unwrapMessagePayload(data);
    final String roomName = _roomNameFromPayload(payload);
    if (roomName.isEmpty) {
      return;
    }
    _log('Call ended: room=$roomName');
    try {
      await FlutterCallkitIncoming.endCall(roomName);
    } catch (e) {
      _log('CallKit endCall skipped: $e');
    }
  }

  static String _roomNameFromPayload(Map<String, dynamic> payload) {
    return _stringField(payload, const [
      'room_name',
      'roomName',
      'call_id',
      'callId',
      'id',
    ]);
  }

  static Map<String, dynamic> _unwrapMessagePayload(Map<String, dynamic> data) {
    final Object? nested = data['message'];
    if (nested is Map) {
      return <String, dynamic>{
        ...Map<String, dynamic>.from(nested),
        for (final MapEntry<String, dynamic> entry in data.entries)
          if (entry.key != 'message') entry.key: entry.value,
      };
    }
    return data;
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

  /// Normalize FCM / WebSocket payload values to String. Required for
  /// `flutter_callkit_incoming` which expects String fields in `extra`, and
  /// for fields used to build the native UI (id, nameCaller, handle).
  static Map<String, dynamic> _normalizeStringMap(Map<String, dynamic> input) {
    return <String, dynamic>{
      for (final MapEntry<String, dynamic> entry in input.entries)
        entry.key: entry.value == null
            ? ''
            : (entry.value is String
                ? entry.value as String
                : entry.value.toString()),
    };
  }

  /// Build URL avatar cho CallKit notification.
  /// - Ưu tiên `callerAvatarUrl` thật từ server (nếu có).
  /// - Fallback: generate từ chữ cái đầu tên người gọi qua ui-avatars.com,
  ///   nền xanh brand (#1A3263) + chữ trắng, để noti không hiện icon mặc
  ///   định trông như số / chữ cái rỗng.
  static String _buildCallerAvatarUrl(AiseeIncomingCall call) {
    final String? real = call.callerAvatarUrl;
    if (real != null && real.trim().isNotEmpty) {
      return real;
    }
    final String name = call.callerName.trim();
    final String initial = name.isEmpty
        ? '?'
        : name.characters.first.toUpperCase();
    return 'https://ui-avatars.com/api/'
        '?name=${Uri.encodeComponent(initial)}'
        '&size=128'
        '&background=1A3263'
        '&color=FFFFFF'
        '&bold=true'
        '&format=png';
  }

  /// FCM (foreground), FCM background isolate, hoặc WebSocket — payload phẳng; FCM hay trả toàn String.
  static Future<void> showIncomingCallUi(Map<String, dynamic> data) async {
    final Map<String, dynamic> normalized = _normalizeStringMap(data);
    final AiseeIncomingCall call = AiseeIncomingCall.fromPayload(
      normalized,
      source: AiseeIncomingCallSource.fcm,
    );
    _log(
      'Incoming native UI: name=${call.callerName} room=${call.roomName} '
      'callerId=${call.callerId} callType=${call.callType} '
      'tokenLen=${call.token.length}',
    );
    if (call.roomName.isEmpty || call.token.isEmpty) {
      _log(
        'showIncomingCallUi: missing room/token — skip native UI '
        '(will rely on in-app overlay if app is foreground).',
      );
      return;
    }

    String languageCode;
    try {
      languageCode = AiseeLocaleController.instance.value.languageCode;
    } catch (_) {
      languageCode = 'vi';
    }
    final String textAccept = languageCode == 'en' ? 'Answer' : 'Nghe';
    final String textDecline = languageCode == 'en' ? 'Decline' : 'Từ chối';

    final CallKitParams params = CallKitParams(
      id: call.callId,
      nameCaller: call.callerName,
      appName: 'AiSee',
      handle: call.callerName,
      avatar: _buildCallerAvatarUrl(call),
      type: call.isVideo ? 1 : 0,
      duration: 45000,
      textAccept: textAccept,
      textDecline: textDecline,
      extra: <String, dynamic>{
        'caller_id': call.callerId,
        'caller_name': call.callerName,
        if (call.callerAvatarUrl != null)
          'caller_avatar_url': call.callerAvatarUrl,
        'room_name': call.roomName,
        'call_type': call.callType,
        'token': call.token,
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

    try {
      await FlutterCallkitIncoming.showCallkitIncoming(params);
      _log('showCallkitIncoming dispatched: id=${call.callId}');
    } catch (e, stack) {
      _log('showCallkitIncoming failed: $e\n$stack');
      rethrow;
    }
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

  static AiseeCallInfo? _callInfoFromCallKitPayload(Map<String, dynamic> src) {
    final AiseeIncomingCall? call = _incomingCallFromCallKitPayload(src);
    if (call == null || !call.isValidForAccept) {
      return null;
    }
    return call.toCallInfo();
  }

  static AiseeIncomingCall? _incomingCallFromCallKitPayload(
    Map<String, dynamic> src,
  ) {
    final Map<String, dynamic> merged = <String, dynamic>{};
    final Map<String, dynamic> body = Map<String, dynamic>.from(src);
    final dynamic extra = body['extra'];
    if (extra is Map) {
      extra.forEach((dynamic key, dynamic value) {
        merged[key.toString()] = value;
      });
    }
    for (final MapEntry<String, dynamic> entry in body.entries) {
      merged.putIfAbsent(entry.key, () => entry.value);
    }
    if ((merged['room_name']?.toString().isEmpty ?? true) &&
        body['id'] != null) {
      merged['room_name'] = body['id'];
    }
    if ((merged['caller_name']?.toString().isEmpty ?? true) &&
        body['nameCaller'] != null) {
      merged['caller_name'] = body['nameCaller'];
    }
    final AiseeIncomingCall call = AiseeIncomingCall.fromPayload(
      merged,
      source: AiseeIncomingCallSource.callkit,
    );
    return call;
  }

  Future<void> _acceptCall(CallEvent event) async {
    final AiseeIncomingCall? call = _incomingCallFromCallKitPayload(
      _bodyAsMap(event),
    );
    if (call == null) {
      _log('Accept: payload callkit không đọc được');
      return;
    }
    await acceptIncomingCall(call);
  }

  Future<void> acceptIncomingCall(AiseeIncomingCall call) async {
    _incomingCalls.hideIncomingCall();
    if (!call.isValidForAccept) {
      _log('Accept rejected: thiếu room/token cho callId=${call.callId}');
      await AppToast.show(
        'Cuộc gọi này chưa sẵn sàng để kết nối. Vui lòng thử lại.',
        isError: true,
      );
      return;
    }
    AiseeAssistantIncomingCallBridge.instance.clearPending();
    // Pause AI mic before navigating to call screen.
    try {
      await onBeforeIncomingCallAnswered?.call();
    } catch (e) {
      _log('onBeforeIncomingCallAnswered error: $e');
    }
    _navigateToCall(call.toCallInfo());
  }

  Future<void> _declineCall(CallEvent event) async {
    final AiseeIncomingCall? call = _incomingCallFromCallKitPayload(
      _bodyAsMap(event),
    );
    if (call == null) {
      return;
    }
    await declineIncomingCall(call);
  }

  Future<void> declineIncomingCall(AiseeIncomingCall call) async {
    _incomingCalls.hideIncomingCall();
    final String room = call.roomName;
    if (room.isEmpty) {
      AiseeAssistantIncomingCallBridge.instance.clearPending();
      return;
    }

    AiseeAssistantIncomingCallBridge.instance.clearPending();
    final String? accessToken = await AiseeTokenProvider.instance.accessToken();
    if (accessToken == null) {
      return;
    }

    final AiseeCallService svc = AiseeCallService();
    try {
      await svc.endRoom(accessToken, room);
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
    final Route<void> route = MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => CallScreen(callInfo: callInfo),
    );
    unawaited(
      nav.push(route).whenComplete(() {
        try {
          onCallScreenDismissed?.call();
        } catch (e) {
          _log('onCallScreenDismissed error: $e');
        }
      }),
    );
    return true;
  }
}
