import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../config/app_env.dart';
import '../models/aisee_message.dart';
import '../models/aisee_incoming_call.dart';
import 'aisee_push_service.dart';
import 'in_app_message_controller.dart';

class AiseeChatSocket {
  WebSocket? _socket;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  String? _accessToken;
  bool _disposed = false;
  bool _connecting = false;
  final Random _random = Random();

  static const int _maxReconnectAttempts = 8;
  static const double _reconnectJitterMaxSeconds = 1.5;

  final ValueNotifier<int> reconnectAttempts = ValueNotifier<int>(0);

  final StreamController<AiseeMessage> _controller =
      StreamController<AiseeMessage>.broadcast();

  Stream<AiseeMessage> get onMessage => _controller.stream;

  bool get isConnected => _socket != null;

  Future<String?> Function()? tokenProvider;
  Future<String?> Function()? refreshTokenProvider;

  Future<void> connect(String accessToken) async {
    if (_connecting) return;
    _accessToken = accessToken;
    _disposed = false;
    _connecting = true;
    try {
      // Close existing socket before opening new one.
      final WebSocket? existing = _socket;
      if (existing != null) {
        _socket = null;
        _reconnectTimer?.cancel();
        _reconnectTimer = null;
        try {
          await existing.close();
        } catch (_) {}
      }
      _reconnectAttempts = 0;
      await _doConnect();
    } finally {
      _connecting = false;
    }
  }

  Future<void> _doConnect() async {
    if (_disposed) return;
    final String token = _accessToken ?? '';
    if (token.isEmpty) return;

    final String baseUrl = AppEnv.apiBaseUrl;
    final String wsUrl = baseUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
    final String url = '$wsUrl/api/v1/ws/chat?token=$token';

    try {
      debugPrint('[AiSee:WS] Connecting to $wsUrl/api/v1/ws/chat');
      final WebSocket ws = await WebSocket.connect(url);
      if (_disposed) {
        await ws.close();
        return;
      }
      ws.pingInterval = const Duration(seconds: 30);
      _socket = ws;
      _reconnectAttempts = 0;
      reconnectAttempts.value = 0;
      debugPrint('[AiSee:WS] Connected');

      ws.listen(
        _onData,
        onError: (Object error) {
          debugPrint('[AiSee:WS] Error: $error');
          _scheduleReconnect();
        },
        onDone: () {
          debugPrint('[AiSee:WS] Closed');
          _socket = null;
          _scheduleReconnect();
        },
      );
    } catch (e) {
      debugPrint('[AiSee:WS] Connect failed: $e');
      _scheduleReconnect();
    }
  }

  void _onData(dynamic raw) {
    if (raw is! String) return;
    try {
      final Map<String, dynamic> map = jsonDecode(raw) as Map<String, dynamic>;
      final String? t = map['type'] as String?;
      if (t == 'incoming_call') {
        AiseePushService.instance.handleIncomingCallPayload(
          Map<String, dynamic>.from(map),
          source: AiseeIncomingCallSource.websocket,
        );
        return;
      }
      if (t == 'call_ended') {
        unawaited(
          AiseePushService.instance.handleCallEndedPayload(
            Map<String, dynamic>.from(map),
          ),
        );
        return;
      }
      if (t == 'new_message') {
        final Map<String, dynamic> msgMap =
            map['message'] as Map<String, dynamic>;
        final AiseeMessage message = AiseeMessage.fromJson(msgMap);
        _controller.add(message);
        AiseeInAppMessageController.instance.showMessage(message);
      }
    } catch (e) {
      debugPrint('[AiSee:WS] Parse error: $e');
    }
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _reconnectTimer?.cancel();

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint(
        '[AiSee:WS] Max reconnect attempts ($_maxReconnectAttempts) reached',
      );
      return;
    }

    final double jitter = _random.nextDouble() * _reconnectJitterMaxSeconds;
    final int delaySec = min(30, pow(2, _reconnectAttempts).toInt() + jitter.toInt());
    _reconnectAttempts++;
    reconnectAttempts.value = _reconnectAttempts;
    debugPrint(
      '[AiSee:WS] Reconnect in ${delaySec}s '
      '(attempt $_reconnectAttempts/$_maxReconnectAttempts)',
    );
    _reconnectTimer = Timer(Duration(seconds: delaySec), () {
      unawaited(_attemptReconnect());
    });
  }

  Future<void> _attemptReconnect() async {
    final Future<String?> Function()? freshProvider = tokenProvider;
    if (freshProvider != null) {
      try {
        final String? fresh = await freshProvider();
        if (fresh != null && fresh.isNotEmpty) {
          _accessToken = fresh;
        }
      } catch (_) {}
    }

    if (_accessToken == null || (_accessToken?.isEmpty ?? true)) {
      return;
    }

    try {
      await _doConnect();
    } catch (_) {
      _scheduleReconnect();
    }
  }

  Future<void> disconnect() async {
    _disposed = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    final WebSocket? ws = _socket;
    _socket = null;
    if (ws != null) {
      try {
        await ws.close();
      } catch (_) {}
    }
  }

  void dispose() {
    disconnect();
    _controller.close();
    reconnectAttempts.dispose();
  }
}
