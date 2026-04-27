import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:aiseeapp/models/agent_state.dart';
import 'package:aiseeapp/services/aisee_ai_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test(
    'start creates session, connects websocket, and routes inbound events',
    () async {
      final _FakeHttpClient httpClient = _FakeHttpClient(<http.Response>[
        http.Response(
          jsonEncode(<String, Object?>{
            'session_id': 'ai-123',
            'ws_url': 'wss://example.test/api/v1/ai/ws?token=ws-token',
            'audio_input': <String, Object?>{
              'encoding': 'pcm_s16le',
              'sample_rate': 16000,
              'channels': 1,
            },
            'audio_output': <String, Object?>{
              'encoding': 'pcm_s16le',
              'sample_rate': 24000,
              'channels': 1,
            },
            'camera': <String, Object?>{'encoding': 'jpeg', 'max_fps': 1},
          }),
          200,
          headers: <String, String>{'content-type': 'application/json'},
        ),
      ]);
      final _FakeSocket socket = _FakeSocket();
      final AiseeAiSession session = AiseeAiSession(
        httpClient: httpClient,
        socketConnector: (Uri uri) async {
          expect(
            uri.toString(),
            'wss://example.test/api/v1/ai/ws?token=ws-token',
          );
          return socket;
        },
      );

      final Future<AiseeAiToolRequest> nextToolRequest =
          session.toolRequests.first;
      final Future<AiseeAiDeviceCommandRequest> nextDeviceCommand =
          session.deviceCommands.first;
      final Future<Uint8List> nextAssistantAudio =
          session.assistantAudioBytes.first;
      final Future<void> nextAssistantAudioInterrupted =
          session.assistantAudioInterrupted.first;

      final AiseeAiSessionConfig config = await session.start('app-jwt');

      expect(
        httpClient.requests.single.url.toString(),
        'http://192.168.1.10:8081/api/v1/ai/session',
      );
      expect(
        httpClient.requests.single.headers['Authorization'],
        'Bearer app-jwt',
      );
      expect(config.sessionId, 'ai-123');
      expect(config.audioInput.sampleRate, 16000);
      expect(config.audioOutput.sampleRate, 24000);
      expect(config.camera.maxFps, 1);
      expect(
        session.connectionStatus.value,
        AiseeAiSessionConnectionStatus.connected,
      );
      expect(session.agentState.value, AgentState.connecting);

      socket.emitText(
        jsonEncode(<String, Object?>{
          'type': 'ready',
          'payload': <String, Object?>{},
        }),
      );
      await pumpEventQueue();
      expect(
        session.connectionStatus.value,
        AiseeAiSessionConnectionStatus.ready,
      );

      socket.emitText(
        jsonEncode(<String, Object?>{
          'type': 'agent_state',
          'payload': <String, Object?>{'state': 'speaking'},
        }),
      );
      await pumpEventQueue();
      expect(session.agentState.value, AgentState.speaking);

      socket.emitText(
        jsonEncode(<String, Object?>{
          'type': 'tool_request',
          'request_id': 'tool-1',
          'payload': <String, Object?>{
            'name': 'enable_camera',
            'params': <String, Object?>{'flash': false},
          },
        }),
      );
      final AiseeAiToolRequest toolRequest = await nextToolRequest;
      final AiseeAiDeviceCommandRequest deviceCommand = await nextDeviceCommand;
      expect(toolRequest.requestId, 'tool-1');
      expect(toolRequest.name, 'enable_camera');
      expect(toolRequest.params['flash'], false);
      expect(deviceCommand.requestId, 'tool-1');
      expect(deviceCommand.name, 'enable_camera');

      socket.emitBinary(Uint8List.fromList(<int>[1, 2, 3, 4]));
      final Uint8List assistantAudio = await nextAssistantAudio;
      expect(assistantAudio, Uint8List.fromList(<int>[1, 2, 3, 4]));

      socket.emitText(
        jsonEncode(<String, Object?>{
          'type': 'assistant_audio_interrupted',
          'payload': <String, Object?>{},
        }),
      );
      await nextAssistantAudioInterrupted;

      socket.emitText(
        jsonEncode(<String, Object?>{
          'type': 'ping',
          'request_id': 'ping-1',
          'payload': <String, Object?>{'ts': 123},
        }),
      );
      await pumpEventQueue();
      expect(
        socket.sentTextMessages.last,
        jsonEncode(<String, Object?>{
          'type': 'pong',
          'request_id': 'ping-1',
          'payload': <String, Object?>{'ts': 123},
        }),
      );

      await session.stop();
      expect(
        session.connectionStatus.value,
        AiseeAiSessionConnectionStatus.disconnected,
      );
      expect(socket.closeCallCount, 1);
      session.dispose();
    },
  );

  test('audio and camera frames send documented mode envelopes', () async {
    final _FakeSocket socket = _FakeSocket();
    final AiseeAiSession session = AiseeAiSession(
      httpClient: _FakeHttpClient(<http.Response>[
        http.Response(
          jsonEncode(<String, Object?>{
            'session_id': 'ai-123',
            'ws_url': 'wss://example.test/api/v1/ai/ws?token=ws-token',
            'audio_input': <String, Object?>{
              'encoding': 'pcm_s16le',
              'sample_rate': 16000,
              'channels': 1,
            },
            'audio_output': <String, Object?>{
              'encoding': 'pcm_s16le',
              'sample_rate': 24000,
              'channels': 1,
            },
            'camera': <String, Object?>{'encoding': 'jpeg', 'max_fps': 1},
          }),
          200,
        ),
      ]),
      socketConnector: (Uri uri) async => socket,
    );

    await session.start('app-jwt');
    await session.sendAudioFrame(Uint8List.fromList(<int>[10, 11]));
    await session.sendAudioFrame(Uint8List.fromList(<int>[12, 13]));
    await session.sendCameraFrame(Uint8List.fromList(<int>[20, 21]));
    await session.sendAudioFrame(Uint8List.fromList(<int>[30, 31]));

    expect(socket.sentMessages, <Object>[
      jsonEncode(<String, Object?>{
        'type': 'media_mode',
        'payload': <String, Object?>{'mode': 'audio_pcm'},
      }),
      jsonEncode(<String, Object?>{
        'type': 'audio_start',
        'payload': <String, Object?>{},
      }),
      Uint8List.fromList(<int>[10, 11]),
      Uint8List.fromList(<int>[12, 13]),
      jsonEncode(<String, Object?>{
        'type': 'audio_stop',
        'payload': <String, Object?>{},
      }),
      jsonEncode(<String, Object?>{
        'type': 'media_mode',
        'payload': <String, Object?>{'mode': 'camera_jpeg'},
      }),
      Uint8List.fromList(<int>[20, 21]),
      jsonEncode(<String, Object?>{
        'type': 'media_mode',
        'payload': <String, Object?>{'mode': 'audio_pcm'},
      }),
      jsonEncode(<String, Object?>{
        'type': 'audio_start',
        'payload': <String, Object?>{},
      }),
      Uint8List.fromList(<int>[30, 31]),
    ]);

    await session.stop();
    expect(
      socket.sentMessages.last,
      jsonEncode(<String, Object?>{
        'type': 'audio_stop',
        'payload': <String, Object?>{},
      }),
    );
    session.dispose();
  });

  test(
    'tool results, interrupts, and terminal server states send/update correctly',
    () async {
      final _FakeSocket socket = _FakeSocket();
      final AiseeAiSession session = AiseeAiSession(
        httpClient: _FakeHttpClient(<http.Response>[
          http.Response(
            jsonEncode(<String, Object?>{
              'session_id': 'ai-123',
              'ws_url': 'wss://example.test/api/v1/ai/ws?token=ws-token',
              'audio_input': <String, Object?>{
                'encoding': 'pcm_s16le',
                'sample_rate': 16000,
                'channels': 1,
              },
              'audio_output': <String, Object?>{
                'encoding': 'pcm_s16le',
                'sample_rate': 24000,
                'channels': 1,
              },
              'camera': <String, Object?>{'encoding': 'jpeg', 'max_fps': 1},
            }),
            200,
          ),
        ]),
        socketConnector: (Uri uri) async => socket,
      );

      await session.start('app-jwt');
      await session.sendToolResult('tool-1', <String, Object?>{
        'status': 'ok',
        'volume': 0.5,
      });
      await session.interrupt();

      expect(socket.sentMessages.takeLast(2), <Object>[
        jsonEncode(<String, Object?>{
          'type': 'tool_result',
          'request_id': 'tool-1',
          'payload': <String, Object?>{'status': 'ok', 'volume': 0.5},
        }),
        jsonEncode(<String, Object?>{
          'type': 'interrupt',
          'payload': <String, Object?>{},
        }),
      ]);

      socket.emitText(
        jsonEncode(<String, Object?>{
          'type': 'agent_state',
          'payload': <String, Object?>{'state': 'error'},
        }),
      );
      await pumpEventQueue();
      expect(session.agentState.value, AgentState.failed);

      socket.emitText(
        jsonEncode(<String, Object?>{
          'type': 'agent_state',
          'payload': <String, Object?>{'state': 'disconnected'},
        }),
      );
      await pumpEventQueue();
      expect(session.agentState.value, AgentState.disconnected);

      await session.stop();
      session.dispose();
    },
  );

  test('non-200 session responses expose the HTTP status code', () async {
    final AiseeAiSession session = AiseeAiSession(
      httpClient: _FakeHttpClient(<http.Response>[
        http.Response(
          jsonEncode(<String, Object?>{
            'error': <String, Object?>{'message': 'token expired'},
          }),
          401,
          headers: <String, String>{'content-type': 'application/json'},
        ),
      ]),
      socketConnector: (Uri uri) async => _FakeSocket(),
    );

    await expectLater(
      session.start('expired-token'),
      throwsA(
        isA<AiseeAiSessionException>()
            .having(
              (AiseeAiSessionException error) => error.statusCode,
              'statusCode',
              401,
            )
            .having(
              (AiseeAiSessionException error) => error.message,
              'message',
              contains('HTTP 401'),
            ),
      ),
    );
  });
}

class _FakeHttpClient extends http.BaseClient {
  _FakeHttpClient(this._responses);

  final List<http.Response> _responses;
  final List<http.BaseRequest> requests = <http.BaseRequest>[];
  int _index = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(request);
    final http.Response response = _responses[_index++];
    return http.StreamedResponse(
      Stream<List<int>>.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      request: request,
    );
  }
}

class _FakeSocket implements AiseeAiSessionSocket {
  final StreamController<dynamic> _controller =
      StreamController<dynamic>.broadcast();

  final List<Object> sentMessages = <Object>[];
  int closeCallCount = 0;
  Duration? _pingInterval;

  List<String> get sentTextMessages =>
      sentMessages.whereType<String>().toList(growable: false);

  @override
  Duration? get pingInterval => _pingInterval;

  @override
  set pingInterval(Duration? value) {
    _pingInterval = value;
  }

  @override
  Stream<dynamic> get stream => _controller.stream;

  @override
  void add(dynamic data) {
    if (data is Uint8List) {
      sentMessages.add(Uint8List.fromList(data));
      return;
    }
    if (data is List<int>) {
      sentMessages.add(Uint8List.fromList(data));
      return;
    }
    sentMessages.add(data as Object);
  }

  void emitText(String text) {
    _controller.add(text);
  }

  void emitBinary(Uint8List bytes) {
    _controller.add(bytes);
  }

  @override
  Future<void> close([int? code, String? reason]) async {
    closeCallCount += 1;
  }
}

extension on Iterable<Object> {
  List<Object> takeLast(int count) {
    final List<Object> items = toList(growable: false);
    return items.sublist(items.length - count);
  }
}
