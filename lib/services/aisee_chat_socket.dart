import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_client/web_socket_client.dart' as ws;

import '../config/app_env.dart';
import '../models/aisee_incoming_call.dart';
import '../models/aisee_message.dart';
import '../utils/jwt_expiry.dart';
import 'aisee_push_service.dart';
import 'in_app_message_controller.dart';

typedef AiseeIncomingCallPayloadHandler =
    void Function(
      Map<String, dynamic> payload, {
      required AiseeIncomingCallSource source,
    });
typedef AiseeCallEndedPayloadHandler =
    Future<void> Function(Map<String, dynamic> payload);
typedef AiseeInAppMessageHandler = void Function(AiseeMessage message);

abstract class AiseeChatSocketTransport {
  Stream<dynamic> get messages;
  Stream<ws.ConnectionState> get connection;
  void close([int? code, String? reason]);
}

typedef AiseeChatSocketTransportFactory =
    AiseeChatSocketTransport Function(
      Uri uri, {
      Duration? pingInterval,
      ws.Backoff? backoff,
    });

class _PackageChatSocketTransport implements AiseeChatSocketTransport {
  _PackageChatSocketTransport(
    Uri uri, {
    Duration? pingInterval,
    ws.Backoff? backoff,
  }) : _socket = ws.WebSocket(
         uri,
         pingInterval: pingInterval,
         backoff:
             backoff ??
             ws.BinaryExponentialBackoff(
               initial: const Duration(seconds: 1),
               maximumStep: 5,
             ),
       );

  final ws.WebSocket _socket;

  @override
  Stream<dynamic> get messages => _socket.messages;

  @override
  Stream<ws.ConnectionState> get connection => _socket.connection;

  @override
  void close([int? code, String? reason]) => _socket.close(code, reason);
}

class AiseeChatSocket {
  AiseeChatSocket({
    AiseeChatSocketTransportFactory? transportFactory,
    AiseeIncomingCallPayloadHandler? incomingCallHandler,
    AiseeCallEndedPayloadHandler? callEndedHandler,
    AiseeInAppMessageHandler? inAppMessageHandler,
  }) : _transportFactory = transportFactory ?? _defaultTransportFactory,
       _incomingCallHandler =
           incomingCallHandler ??
           ((payload, {required source}) {
             AiseePushService.instance.handleIncomingCallPayload(
               payload,
               source: source,
             );
           }),
       _callEndedHandler =
           callEndedHandler ??
           ((payload) {
             return AiseePushService.instance.handleCallEndedPayload(payload);
           }),
       _inAppMessageHandler =
           inAppMessageHandler ??
           ((message) {
             AiseeInAppMessageController.instance.showMessage(message);
           });

  static AiseeChatSocketTransport _defaultTransportFactory(
    Uri uri, {
    Duration? pingInterval,
    ws.Backoff? backoff,
  }) {
    return _PackageChatSocketTransport(
      uri,
      pingInterval: pingInterval,
      backoff: backoff,
    );
  }

  final AiseeChatSocketTransportFactory _transportFactory;
  final AiseeIncomingCallPayloadHandler _incomingCallHandler;
  final AiseeCallEndedPayloadHandler _callEndedHandler;
  final AiseeInAppMessageHandler _inAppMessageHandler;

  AiseeChatSocketTransport? _transport;
  StreamSubscription<dynamic>? _messageSub;
  StreamSubscription<ws.ConnectionState>? _connectionSub;
  int _reconnectAttempts = 0;
  String? _accessToken;
  bool _disposed = false;
  bool _manualDisconnect = false;
  bool _connecting = false;
  ws.ConnectionState _connectionState = const ws.Disconnected();

  static const int _maxReconnectAttempts = 8;

  final ValueNotifier<int> reconnectAttempts = ValueNotifier<int>(0);

  final StreamController<AiseeMessage> _controller =
      StreamController<AiseeMessage>.broadcast();

  Stream<AiseeMessage> get onMessage => _controller.stream;

  bool get isConnected =>
      _connectionState is ws.Connected || _connectionState is ws.Reconnected;

  Future<String?> Function()? tokenProvider;
  Future<String?> Function()? refreshTokenProvider;

  Future<void> connect(String accessToken) async {
    if (_connecting) return;
    _accessToken = await _resolveAccessToken(accessToken);
    _disposed = false;
    _manualDisconnect = false;
    _connecting = true;
    try {
      _closeTransport();
      _reconnectAttempts = 0;
      reconnectAttempts.value = 0;
      _openTransport();
    } finally {
      _connecting = false;
    }
  }

  Future<String> _resolveAccessToken(String accessToken) async {
    final Future<String?> Function()? provider = tokenProvider;
    String resolved = accessToken;
    if (provider == null) {
      return _refreshIfNeeded(resolved);
    }
    try {
      final String? fresh = await provider();
      if (fresh != null && fresh.isNotEmpty) {
        resolved = fresh;
      }
    } catch (_) {}
    return _refreshIfNeeded(resolved);
  }

  Future<String> _refreshIfNeeded(String accessToken) async {
    if (!isJwtExpiringSoon(accessToken)) {
      return accessToken;
    }
    final Future<String?> Function()? refresh = refreshTokenProvider;
    if (refresh == null) {
      return accessToken;
    }
    try {
      final String? rotated = await refresh();
      if (rotated != null && rotated.isNotEmpty) {
        return rotated;
      }
    } catch (_) {}
    return accessToken;
  }

  Uri _socketUri(String token) {
    final String baseUrl = AppEnv.apiBaseUrl;
    final String wsUrl = baseUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
    return Uri.parse('$wsUrl/api/v1/ws/chat?token=$token');
  }

  void _openTransport() {
    if (_disposed) return;
    final String token = _accessToken ?? '';
    if (token.isEmpty) return;
    final Uri uri = _socketUri(token);
    debugPrint('[AiSee:WS] Connecting to ${uri.path}');

    final AiseeChatSocketTransport transport = _transportFactory(
      uri,
      pingInterval: const Duration(seconds: 30),
      backoff: ws.BinaryExponentialBackoff(
        initial: const Duration(seconds: 1),
        maximumStep: 5,
      ),
    );
    _transport = transport;
    _messageSub = transport.messages.listen(
      _onData,
      onError: (Object error) {
        debugPrint('[AiSee:WS] Message stream error: $error');
      },
    );
    _connectionSub = transport.connection.listen(_onConnectionState);
  }

  void _onData(dynamic raw) {
    if (raw is! String) return;
    try {
      final Map<String, dynamic> map = jsonDecode(raw) as Map<String, dynamic>;
      final String? t = map['type'] as String?;
      if (t == 'incoming_call') {
        _incomingCallHandler(
          Map<String, dynamic>.from(map),
          source: AiseeIncomingCallSource.websocket,
        );
        return;
      }
      if (t == 'call_ended') {
        unawaited(_callEndedHandler(Map<String, dynamic>.from(map)));
        return;
      }
      if (t == 'new_message') {
        final Map<String, dynamic> msgMap =
            map['message'] as Map<String, dynamic>;
        final AiseeMessage message = AiseeMessage.fromJson(msgMap);
        _controller.add(message);
        _inAppMessageHandler(message);
      }
    } catch (e) {
      debugPrint('[AiSee:WS] Parse error: $e');
    }
  }

  void _onConnectionState(ws.ConnectionState state) {
    _connectionState = state;
    switch (state) {
      case ws.Connected():
        _reconnectAttempts = 0;
        reconnectAttempts.value = 0;
        debugPrint('[AiSee:WS] Connected');
      case ws.Reconnected():
        _reconnectAttempts = 0;
        reconnectAttempts.value = 0;
        debugPrint('[AiSee:WS] Reconnected');
      case ws.Reconnecting():
        if (_disposed || _manualDisconnect) {
          return;
        }
        _reconnectAttempts++;
        reconnectAttempts.value = _reconnectAttempts;
        debugPrint(
          '[AiSee:WS] Reconnecting '
          '($_reconnectAttempts/$_maxReconnectAttempts)',
        );
        if (_reconnectAttempts >= _maxReconnectAttempts) {
          debugPrint(
            '[AiSee:WS] Max reconnect attempts ($_maxReconnectAttempts) reached',
          );
          _manualDisconnect = true;
          _closeTransport(code: 4000, reason: 'reconnect_limit_reached');
        }
      case ws.Disconnected():
        debugPrint(
          '[AiSee:WS] Disconnected ${state.code ?? ''} ${state.reason ?? ''}',
        );
      case ws.Connecting():
        debugPrint('[AiSee:WS] Connecting');
      case ws.Disconnecting():
        debugPrint('[AiSee:WS] Disconnecting');
    }
  }

  Future<void> disconnect() async {
    _disposed = true;
    _manualDisconnect = true;
    _closeTransport(code: 1000, reason: 'client_disconnect');
  }

  void _closeTransport({int? code, String? reason}) {
    _messageSub?.cancel();
    _messageSub = null;
    _connectionSub?.cancel();
    _connectionSub = null;
    final AiseeChatSocketTransport? transport = _transport;
    _transport = null;
    if (transport != null) {
      transport.close(code, reason);
    }
    _connectionState = const ws.Disconnected();
  }

  void dispose() {
    unawaited(disconnect());
    _controller.close();
    reconnectAttempts.dispose();
  }
}
