import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_env.dart';
import '../models/agent_state.dart';

enum AiseeAiSessionConnectionStatus {
  disconnected,
  starting,
  connected,
  ready,
  reconnecting,
  failed,
}

enum AiseeAiSessionMediaMode {
  audioPcm('audio_pcm'),
  cameraJpeg('camera_jpeg');

  const AiseeAiSessionMediaMode(this.wireValue);

  final String wireValue;
}

class AiseeAiSessionException implements Exception {
  AiseeAiSessionException(this.message, {this.statusCode, this.retryable = true});

  final String message;
  final int? statusCode;
  final bool retryable;

  @override
  String toString() =>
      'AiseeAiSessionException(statusCode: $statusCode, retryable: $retryable, message: $message)';
}

class AiseeAiAudioFormat {
  const AiseeAiAudioFormat({
    required this.encoding,
    required this.sampleRate,
    required this.channels,
  });

  final String encoding;
  final int sampleRate;
  final int channels;

  factory AiseeAiAudioFormat.fromJson(Map<String, dynamic>? json) {
    final Map<String, dynamic> map = json ?? const <String, dynamic>{};
    return AiseeAiAudioFormat(
      encoding: _stringValue(map['encoding']),
      sampleRate: _intValue(map['sample_rate']),
      channels: _intValue(map['channels']),
    );
  }
}

class AiseeAiCameraConfig {
  const AiseeAiCameraConfig({required this.encoding, required this.maxFps});

  final String encoding;
  final int maxFps;

  factory AiseeAiCameraConfig.fromJson(Map<String, dynamic>? json) {
    final Map<String, dynamic> map = json ?? const <String, dynamic>{};
    return AiseeAiCameraConfig(
      encoding: _stringValue(map['encoding']),
      maxFps: _intValue(map['max_fps']),
    );
  }
}

class AiseeAiSessionConfig {
  const AiseeAiSessionConfig({
    required this.sessionId,
    required this.wsUrl,
    required this.audioInput,
    required this.audioOutput,
    required this.camera,
  });

  final String sessionId;
  final String wsUrl;
  final AiseeAiAudioFormat audioInput;
  final AiseeAiAudioFormat audioOutput;
  final AiseeAiCameraConfig camera;

  Uri get wsUri => Uri.parse(wsUrl);

  factory AiseeAiSessionConfig.fromJson(
    Map<String, dynamic> json, {
    required String fallbackWsUrl,
  }) {
    final Map<String, dynamic> payload = _mapValue(json['data']) ?? json;
    final String wsUrl =
        _firstString(payload, const <String>['ws_url', 'url']).isNotEmpty
        ? _firstString(payload, const <String>['ws_url', 'url'])
        : fallbackWsUrl;
    if (wsUrl.isEmpty) {
      throw AiseeAiSessionException('AI session response missing ws_url.');
    }

    return AiseeAiSessionConfig(
      sessionId: _firstString(payload, const <String>['session_id', 'id']),
      wsUrl: wsUrl,
      audioInput: AiseeAiAudioFormat.fromJson(
        _mapValue(payload['audio_input']),
      ),
      audioOutput: AiseeAiAudioFormat.fromJson(
        _mapValue(payload['audio_output']),
      ),
      camera: AiseeAiCameraConfig.fromJson(_mapValue(payload['camera'])),
    );
  }
}

class AiseeAiToolRequest {
  const AiseeAiToolRequest({
    required this.requestId,
    required this.name,
    required this.params,
  });

  final String requestId;
  final String name;
  final Map<String, dynamic> params;
}

class AiseeAiDeviceCommandRequest {
  const AiseeAiDeviceCommandRequest({
    required this.requestId,
    required this.name,
    required this.params,
  });

  final String requestId;
  final String name;
  final Map<String, dynamic> params;

  factory AiseeAiDeviceCommandRequest.fromToolRequest(
    AiseeAiToolRequest request,
  ) {
    return AiseeAiDeviceCommandRequest(
      requestId: request.requestId,
      name: request.name,
      params: request.params,
    );
  }
}

abstract interface class AiseeAiSessionSocket {
  Stream<dynamic> get stream;
  Duration? get pingInterval;
  set pingInterval(Duration? value);
  void add(dynamic data);
  Future<void> close([int? code, String? reason]);
}

typedef AiseeAiSessionSocketConnector =
    Future<AiseeAiSessionSocket> Function(Uri uri);

typedef TokenProvider = Future<String?> Function();

class AiseeAiSession {
  AiseeAiSession({
    http.Client? httpClient,
    AiseeAiSessionSocketConnector? socketConnector,
  }) : _http = httpClient ?? http.Client(),
       _ownsHttp = httpClient == null,
       _socketConnector = socketConnector ?? _defaultSocketConnector;

  TokenProvider? tokenProvider;
  TokenProvider? refreshTokenProvider;

  static const Duration _connectTimeout = Duration(seconds: 45);
  static const Duration _socketPingInterval = Duration(seconds: 30);
  static const int _maxReconnectAttempts = 8;
  static const double _reconnectJitterMaxSeconds = 1.5;

  final http.Client _http;
  final bool _ownsHttp;
  final AiseeAiSessionSocketConnector _socketConnector;

  final ValueNotifier<AgentState> agentState = ValueNotifier<AgentState>(
    AgentState.disconnected,
  );
  final ValueNotifier<AiseeAiSessionConnectionStatus> connectionStatus =
      ValueNotifier<AiseeAiSessionConnectionStatus>(
        AiseeAiSessionConnectionStatus.disconnected,
      );
  final ValueNotifier<AiseeAiSessionConfig?> sessionConfig =
      ValueNotifier<AiseeAiSessionConfig?>(null);
  final ValueNotifier<int> reconnectAttempt = ValueNotifier<int>(0);

  final StreamController<Uint8List> _assistantAudioController =
      StreamController<Uint8List>.broadcast();
  final StreamController<void> _assistantAudioInterruptedController =
      StreamController<void>.broadcast();
  final StreamController<AiseeAiToolRequest> _toolRequestController =
      StreamController<AiseeAiToolRequest>.broadcast();
  final StreamController<AiseeAiDeviceCommandRequest> _deviceCommandController =
      StreamController<AiseeAiDeviceCommandRequest>.broadcast();

  AiseeAiSessionSocket? _socket;
  StreamSubscription<dynamic>? _socketSub;
  Completer<AiseeAiSessionConfig>? _startCompleter;
  AiseeAiSessionMediaMode? _outgoingMediaMode;
  bool _audioStreaming = false;
  bool _disposed = false;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  String? _lastAccessToken;
  final Random _random = Random();

  Stream<Uint8List> get assistantAudioBytes => _assistantAudioController.stream;

  Stream<void> get assistantAudioInterrupted =>
      _assistantAudioInterruptedController.stream;

  Stream<AiseeAiToolRequest> get toolRequests => _toolRequestController.stream;

  Stream<AiseeAiDeviceCommandRequest> get deviceCommands =>
      _deviceCommandController.stream;

  bool get isConnected => _socket != null;

  Future<AiseeAiSessionConfig> start(String accessToken) {
    final Completer<AiseeAiSessionConfig>? existing = _startCompleter;
    if (existing != null) {
      return existing.future;
    }

    final Completer<AiseeAiSessionConfig> completer =
        Completer<AiseeAiSessionConfig>();
    _startCompleter = completer;
    unawaited(
      _doStart(accessToken)
          .then(completer.complete)
          .catchError((Object error, StackTrace stackTrace) {
            completer.completeError(error, stackTrace);
          })
          .whenComplete(() {
            if (identical(_startCompleter, completer)) {
              _startCompleter = null;
            }
          }),
    );
    return completer.future;
  }

  Future<AiseeAiSessionConfig> _doStart(String accessToken) async {
    _disposed = false;
    _lastAccessToken = accessToken;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await stop(resetState: false);
    connectionStatus.value = AiseeAiSessionConnectionStatus.starting;
    agentState.value = AgentState.connecting;

    final AiseeAiSessionConfig config;
    try {
      config = await _createSession(accessToken);
    } catch (error) {
      if (!_disposed) {
        connectionStatus.value = AiseeAiSessionConnectionStatus.failed;
      }
      rethrow;
    }
    if (_disposed) {
      throw AiseeAiSessionException('AI session disposed before connect.');
    }

    final AiseeAiSessionSocket socket = await _socketConnector(config.wsUri);
    if (_disposed) {
      await socket.close();
      throw AiseeAiSessionException(
        'AI session disposed before websocket ready.',
      );
    }

    socket.pingInterval = _socketPingInterval;
    _socket = socket;
    // Chỉ reset reconnect counter sau khi kết nối sống sót > 10 giây
    // để tránh rapid reconnect loop khi upstream liên tục disconnect
    Future<void>.delayed(const Duration(seconds: 10), () {
      if (_socket == socket && !_disposed) {
        _reconnectAttempts = 0;
        reconnectAttempt.value = 0;
      }
    });
    _socketSub = socket.stream.listen(
      _onSocketData,
      onError: _onSocketError,
      onDone: _onSocketDone,
      cancelOnError: false,
    );
    sessionConfig.value = config;
    connectionStatus.value = AiseeAiSessionConnectionStatus.connected;
    return config;
  }

  Future<AiseeAiSessionConfig> _createSession(String accessToken) async {
    final Uri uri = Uri.parse('${AppEnv.apiBaseUrl}/api/v1/ai/session');
    final http.Response response = await _http
        .post(
          uri,
          headers: <String, String>{
            'Authorization': 'Bearer $accessToken',
            'Accept': 'application/json',
          },
        )
        .timeout(_connectTimeout);
    final String raw = utf8.decode(response.bodyBytes).trim();

    if (response.statusCode != 200) {
      final bool isServerError = response.statusCode >= 500;
      throw AiseeAiSessionException(
        raw.isEmpty
            ? 'AI session request failed with HTTP ${response.statusCode}.'
            : 'AI session request failed with HTTP ${response.statusCode}: $raw',
        statusCode: response.statusCode,
        retryable: isServerError,
      );
    }

    if (raw.isEmpty) {
      throw AiseeAiSessionException('AI session response was empty.');
    }

    final Object? decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw AiseeAiSessionException(
        'AI session response must be a JSON object.',
      );
    }

    return AiseeAiSessionConfig.fromJson(
      decoded,
      fallbackWsUrl: _fallbackWsUrl(decoded, accessToken),
    );
  }

  Future<void> sendAudioFrame(Uint8List bytes) async {
    final AiseeAiSessionSocket socket = _requireSocket();
    await _ensureMediaMode(AiseeAiSessionMediaMode.audioPcm);
    if (!_audioStreaming) {
      await _sendEnvelope('audio_start');
      _audioStreaming = true;
    }
    socket.add(Uint8List.fromList(bytes));
  }

  Future<void> sendCameraFrame(Uint8List bytes) async {
    final AiseeAiSessionSocket socket = _requireSocket();
    if (_audioStreaming) {
      await _sendEnvelope('audio_stop');
      _audioStreaming = false;
    }
    await _ensureMediaMode(AiseeAiSessionMediaMode.cameraJpeg);
    socket.add(Uint8List.fromList(bytes));
  }

  Future<void> sendControl(
    String action, {
    Map<String, Object?> payload = const <String, Object?>{},
  }) {
    return _sendEnvelope(
      'control',
      payload: <String, Object?>{'action': action, ...payload},
    );
  }

  Future<void> sendNsfwDetected() {
    return _sendEnvelope('nsfw_detected');
  }

  Future<void> stopAudioStream() async {
    if (!_audioStreaming) {
      return;
    }
    await _sendEnvelope('audio_stop');
    _audioStreaming = false;
  }

  Future<void> sendToolResult(String requestId, Object? result) {
    final Map<String, dynamic> payload = switch (result) {
      Map<String, dynamic> value => value,
      Map value => value.map(
        (Object? key, Object? value) => MapEntry(key.toString(), value),
      ),
      null => const <String, dynamic>{'status': 'ok'},
      _ => <String, dynamic>{'result': result},
    };

    return _sendEnvelope('tool_result', requestId: requestId, payload: payload);
  }

  Future<void> interrupt() {
    return _sendEnvelope('interrupt');
  }

  Future<void> stop({
    bool resetState = true,
    int? closeCode,
    String? reason,
  }) async {
    final AiseeAiSessionSocket? socket = _socket;
    final StreamSubscription<dynamic>? sub = _socketSub;
    _socket = null;
    _socketSub = null;

    if (socket != null && _audioStreaming) {
      socket.add(
        jsonEncode(<String, Object?>{
          'type': 'audio_stop',
          'payload': const <String, Object?>{},
        }),
      );
    }

    _audioStreaming = false;
    _outgoingMediaMode = null;

    await sub?.cancel();
    if (socket != null) {
      try {
        await socket.close(closeCode, reason);
      } catch (_) {}
    }

    if (resetState) {
      sessionConfig.value = null;
      agentState.value = AgentState.disconnected;
      reconnectAttempt.value = 0;
    }
    connectionStatus.value = AiseeAiSessionConnectionStatus.disconnected;
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    // Await stop() để đảm bảo agentState không bị dispose khi đang được dùng
    await stop(resetState: false);
    agentState.dispose();
    connectionStatus.dispose();
    sessionConfig.dispose();
    reconnectAttempt.dispose();
    _assistantAudioController.close();
    _assistantAudioInterruptedController.close();
    _toolRequestController.close();
    _deviceCommandController.close();
    if (_ownsHttp) {
      _http.close();
    }
  }

  Future<void> _ensureMediaMode(AiseeAiSessionMediaMode mode) async {
    if (_outgoingMediaMode == mode) {
      return;
    }
    await _sendEnvelope(
      'media_mode',
      payload: <String, Object?>{'mode': mode.wireValue},
    );
    _outgoingMediaMode = mode;
  }

  Future<void> _sendEnvelope(
    String type, {
    String? requestId,
    Map<String, Object?> payload = const <String, Object?>{},
  }) async {
    final AiseeAiSessionSocket socket = _requireSocket();
    socket.add(
      jsonEncode(<String, Object?>{
        'type': type,
        if (requestId != null && requestId.isNotEmpty) 'request_id': requestId,
        'payload': payload,
      }),
    );
  }

  AiseeAiSessionSocket _requireSocket() {
    final AiseeAiSessionSocket? socket = _socket;
    if (socket == null) {
      throw StateError('AI session websocket is not connected.');
    }
    return socket;
  }

  void _onSocketData(dynamic raw) {
    if (raw is String) {
      _handleTextFrame(raw);
      return;
    }
    if (raw is Uint8List) {
      _assistantAudioController.add(Uint8List.fromList(raw));
      return;
    }
    if (raw is List<int>) {
      _assistantAudioController.add(Uint8List.fromList(raw));
    }
  }

  void _handleTextFrame(String raw) {
    Map<String, dynamic> envelope;
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return;
      }
      envelope = decoded;
    } on FormatException {
      return;
    }

    final String type = _stringValue(envelope['type']);
    final String requestId = _stringValue(envelope['request_id']);
    final Map<String, dynamic> payload =
        _mapValue(envelope['payload']) ?? const <String, dynamic>{};
    final Map<String, dynamic> eventPayload = payload.isEmpty
        ? envelope
        : payload;

    switch (type) {
      case 'ready':
        connectionStatus.value = AiseeAiSessionConnectionStatus.ready;
        break;
      case 'agent_state':
        _handleAgentState(eventPayload);
        break;
      case 'tool_request':
        _handleToolRequest(requestId, eventPayload);
        break;
      case 'device_command':
        _handleDeviceCommand(requestId, eventPayload);
        break;
      case 'assistant_audio_interrupted':
        _assistantAudioInterruptedController.add(null);
        break;
      case 'ping':
        unawaited(
          _sendEnvelope('pong', requestId: requestId, payload: payload),
        );
        break;
      case 'error':
        if (connectionStatus.value !=
            AiseeAiSessionConnectionStatus.disconnected) {
          connectionStatus.value = AiseeAiSessionConnectionStatus.failed;
        }
        break;
      default:
        break;
    }
  }

  void _handleAgentState(Map<String, dynamic> payload) {
    final String rawState = _firstString(payload, const <String>[
      'state',
      'agent_state',
      'value',
    ]);
    if (rawState.isEmpty) {
      return;
    }
    final AgentState next = rawState == 'error'
        ? AgentState.failed
        : AgentState.fromString(rawState);
    agentState.value = next;
    if (next == AgentState.disconnected) {
      connectionStatus.value = AiseeAiSessionConnectionStatus.disconnected;
    } else if (next == AgentState.failed) {
      connectionStatus.value = AiseeAiSessionConnectionStatus.failed;
    }
  }

  void _handleToolRequest(String requestId, Map<String, dynamic> payload) {
    final String name = _firstString(payload, const <String>[
      'name',
      'tool',
      'command',
    ]);
    if (name.isEmpty) {
      debugPrint(
        '[AiSee:ToolCall] tool_request skipped: no name in payload keys=${payload.keys}',
      );
      return;
    }
    final Map<String, dynamic> params =
        _mapValue(payload['params']) ??
        _mapValue(payload['arguments']) ??
        _mapValue(payload['payload']) ??
        const <String, dynamic>{};
    debugPrint(
      '[AiSee:ToolCall] received name=$name requestId=$requestId paramKeys=${params.keys.toList()}',
    );
    final AiseeAiToolRequest request = AiseeAiToolRequest(
      requestId: requestId,
      name: name,
      params: params,
    );
    _toolRequestController.add(request);
    _deviceCommandController.add(
      AiseeAiDeviceCommandRequest.fromToolRequest(request),
    );
  }

  void _handleDeviceCommand(String requestId, Map<String, dynamic> payload) {
    final String name = _firstString(payload, const <String>[
      'command',
      'name',
      'action',
    ]);
    if (name.isEmpty) {
      return;
    }
    debugPrint(
      '[AiSee:ToolCall] device_command received name=$name requestId=$requestId',
    );
    final Map<String, dynamic> params =
        _mapValue(payload['params']) ??
        _mapValue(payload['arguments']) ??
        const <String, dynamic>{};
    final AiseeAiDeviceCommandRequest request = AiseeAiDeviceCommandRequest(
      requestId: requestId,
      name: name,
      params: params,
    );
    _deviceCommandController.add(request);
    _toolRequestController.add(
      AiseeAiToolRequest(requestId: requestId, name: name, params: params),
    );
  }

  void _onSocketError(Object error, StackTrace stackTrace) {
    _socket = null;
    _socketSub = null;
    _audioStreaming = false;
    _outgoingMediaMode = null;
    if (_disposed) {
      return;
    }
    _scheduleReconnect();
  }

  void _onSocketDone() {
    _socket = null;
    _socketSub = null;
    _audioStreaming = false;
    _outgoingMediaMode = null;
    if (_disposed) {
      return;
    }
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _reconnectTimer?.cancel();

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      connectionStatus.value = AiseeAiSessionConnectionStatus.failed;
      agentState.value = AgentState.failed;
      debugPrint(
        '[AiSee:Session] Max reconnect attempts ($_maxReconnectAttempts) reached',
      );
      return;
    }

    final double jitter = _random.nextDouble() * _reconnectJitterMaxSeconds;
    final int delaySec = min(30, pow(2, _reconnectAttempts).toInt() + jitter.toInt());
    _reconnectAttempts++;
    reconnectAttempt.value = _reconnectAttempts;
    connectionStatus.value = AiseeAiSessionConnectionStatus.reconnecting;
    debugPrint(
      '[AiSee:Session] Reconnect in ${delaySec}s '
      '(attempt $_reconnectAttempts/$_maxReconnectAttempts)',
    );
    _reconnectTimer = Timer(Duration(seconds: delaySec), () {
      unawaited(_attemptReconnect());
    });
  }

  Future<void> _attemptReconnect() async {
    String? token = _lastAccessToken;

    final TokenProvider? freshProvider = tokenProvider;
    if (freshProvider != null) {
      try {
        final String? fresh = await freshProvider();
        if (fresh != null && fresh.isNotEmpty) {
          token = fresh;
          _lastAccessToken = fresh;
        }
      } catch (_) {}
    }

    if (token == null || token.isEmpty) {
      connectionStatus.value = AiseeAiSessionConnectionStatus.failed;
      agentState.value = AgentState.failed;
      return;
    }

    try {
      await _doStart(token);
    } catch (error) {
      debugPrint('[AiSee:Session] Reconnect failed: $error');

      if (error is AiseeAiSessionException &&
          error.statusCode == 401 &&
          refreshTokenProvider != null) {
        try {
          final String? refreshed = await refreshTokenProvider!();
          if (refreshed != null && refreshed.isNotEmpty) {
            _lastAccessToken = refreshed;
            debugPrint('[AiSee:Session] Token refreshed, retrying reconnect');
            await _doStart(refreshed);
            return;
          }
        } catch (_) {}
      }

      final bool shouldRetry =
          error is! AiseeAiSessionException || error.retryable;
      if (shouldRetry) {
        _scheduleReconnect();
      } else {
        connectionStatus.value = AiseeAiSessionConnectionStatus.failed;
        agentState.value = AgentState.failed;
      }
    }
  }

  static Future<AiseeAiSessionSocket> _defaultSocketConnector(Uri uri) async {
    final WebSocket socket = await WebSocket.connect(uri.toString());
    return _IoAiseeAiSessionSocket(socket);
  }
}

class _IoAiseeAiSessionSocket implements AiseeAiSessionSocket {
  _IoAiseeAiSessionSocket(this._socket);

  final WebSocket _socket;

  @override
  Duration? get pingInterval => _socket.pingInterval;

  @override
  set pingInterval(Duration? value) {
    _socket.pingInterval = value;
  }

  @override
  Stream<dynamic> get stream => _socket;

  @override
  void add(dynamic data) {
    _socket.add(data);
  }

  @override
  Future<void> close([int? code, String? reason]) {
    return _socket.close(code, reason);
  }
}

String _firstString(Map<String, dynamic> map, List<String> keys) {
  for (final String key in keys) {
    final String value = _stringValue(map[key]);
    if (value.isNotEmpty) {
      return value;
    }
  }
  return '';
}

Map<String, dynamic>? _mapValue(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map(
      (Object? key, Object? value) => MapEntry(key.toString(), value),
    );
  }
  return null;
}

String _stringValue(Object? value) {
  if (value is String) {
    return value;
  }
  return '';
}

int _intValue(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return 0;
}

String _fallbackWsUrl(Map<String, dynamic> json, String accessToken) {
  final Map<String, dynamic> payload = _mapValue(json['data']) ?? json;
  final String token = _firstString(payload, const <String>[
    'ws_token',
    'token',
    'access_token',
  ]);
  final String baseUrl = AppEnv.apiBaseUrl
      .replaceFirst('https://', 'wss://')
      .replaceFirst('http://', 'ws://');
  final String resolvedToken = token.isNotEmpty ? token : accessToken;
  return '$baseUrl/api/v1/ai/ws?token=$resolvedToken';
}
