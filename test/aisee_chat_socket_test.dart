import 'dart:async';
import 'dart:convert';

import 'package:aiseeapp/models/aisee_incoming_call.dart';
import 'package:aiseeapp/models/aisee_message.dart';
import 'package:aiseeapp/services/aisee_chat_socket.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_socket_client/web_socket_client.dart' as ws;

void main() {
  test('new_message emits stream and in-app handler', () async {
    final _FakeTransport transport = _FakeTransport();
    AiseeMessage? shownMessage;
    final AiseeChatSocket socket = AiseeChatSocket(
      transportFactory: (uri, {Duration? pingInterval, ws.Backoff? backoff}) =>
          transport,
      inAppMessageHandler: (AiseeMessage message) {
        shownMessage = message;
      },
    );

    await socket.connect('token');
    transport.connectionController.add(const ws.Connected());

    final Future<AiseeMessage> nextMessage = socket.onMessage.first;
    transport.messageController.add(
      jsonEncode(<String, Object?>{
        'type': 'new_message',
        'message': <String, Object?>{
          'id': 'm1',
          'sender_id': 'u1',
          'receiver_id': 'u2',
          'content_text': 'hello',
          'created_at': '2026-05-24T00:00:00Z',
        },
      }),
    );

    final AiseeMessage message = await nextMessage;
    expect(message.id, 'm1');
    expect(shownMessage?.id, 'm1');

    socket.dispose();
  });

  test('incoming_call routes to handler with websocket source', () async {
    final _FakeTransport transport = _FakeTransport();
    Map<String, dynamic>? payload;
    AiseeIncomingCallSource? capturedSource;
    final AiseeChatSocket socket = AiseeChatSocket(
      transportFactory: (uri, {Duration? pingInterval, ws.Backoff? backoff}) =>
          transport,
      incomingCallHandler:
          (
            Map<String, dynamic> nextPayload, {
            required AiseeIncomingCallSource source,
          }) {
            payload = nextPayload;
            capturedSource = source;
          },
    );

    await socket.connect('token');
    transport.messageController.add(
      jsonEncode(<String, Object?>{
        'type': 'incoming_call',
        'room_name': 'call-1',
      }),
    );
    await Future<void>.delayed(Duration.zero);

    expect(payload?['room_name'], 'call-1');
    expect(capturedSource, AiseeIncomingCallSource.websocket);
    socket.dispose();
  });

  test('reconnecting updates attempts and resets after connect', () async {
    final _FakeTransport transport = _FakeTransport();
    final AiseeChatSocket socket = AiseeChatSocket(
      transportFactory: (uri, {Duration? pingInterval, ws.Backoff? backoff}) =>
          transport,
    );

    await socket.connect('token');
    transport.connectionController.add(const ws.Reconnecting());
    await Future<void>.delayed(Duration.zero);
    expect(socket.reconnectAttempts.value, 1);
    transport.connectionController.add(const ws.Reconnected());
    await Future<void>.delayed(Duration.zero);
    expect(socket.reconnectAttempts.value, 0);

    socket.dispose();
  });

  test(
    'connect refreshes expired access token before opening websocket',
    () async {
      Uri? openedUri;
      final _FakeTransport transport = _FakeTransport();
      final AiseeChatSocket socket = AiseeChatSocket(
        transportFactory: (uri, {Duration? pingInterval, ws.Backoff? backoff}) {
          openedUri = uri;
          return transport;
        },
      );
      socket.refreshTokenProvider = () async => 'fresh-access';

      await socket.connect(_jwt(exp: 1));

      expect(openedUri?.queryParameters['token'], 'fresh-access');
      socket.dispose();
    },
  );
}

String _jwt({required int exp}) {
  String enc(Map<String, Object?> value) {
    return base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  }

  return '${enc(<String, Object?>{'alg': 'HS256', 'typ': 'JWT'})}.'
      '${enc(<String, Object?>{'exp': exp})}.sig';
}

class _FakeTransport implements AiseeChatSocketTransport {
  final StreamController<dynamic> messageController =
      StreamController<dynamic>.broadcast();
  final StreamController<ws.ConnectionState> connectionController =
      StreamController<ws.ConnectionState>.broadcast();

  @override
  Stream<ws.ConnectionState> get connection => connectionController.stream;

  @override
  Stream<dynamic> get messages => messageController.stream;

  @override
  void close([int? code, String? reason]) {
    unawaited(messageController.close());
    unawaited(connectionController.close());
  }
}
