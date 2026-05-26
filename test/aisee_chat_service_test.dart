import 'package:aiseeapp/api/chat_api.dart';
import 'package:aiseeapp/models/aisee_message.dart';
import 'package:aiseeapp/services/aisee_chat_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retrofit/dio.dart';

void main() {
  test('fetchMessages parses wrapped message list', () async {
    final _FakeChatApiClient client = _FakeChatApiClient(
      fetchMessagesResponse: _response(<String, Object?>{
        'messages': <Object?>[
          <String, Object?>{
            'id': 'm1',
            'sender_id': 'u1',
            'receiver_id': 'u2',
            'content_text': 'hello',
            'created_at': '2026-05-24T00:00:00Z',
          },
        ],
      }, 200),
    );
    final AiseeChatService service = AiseeChatService(apiClient: client);

    final List<AiseeMessage> messages = await service.fetchMessages(
      'token',
      'contact-1',
      before: 'm0',
    );

    expect(client.lastFetchQuery?['before'], 'm0');
    expect(messages.single.id, 'm1');
    service.close();
  });
}

HttpResponse<dynamic> _response(Map<String, Object?> data, int statusCode) {
  final RequestOptions requestOptions = RequestOptions(path: '/');
  final Response<dynamic> response = Response<dynamic>(
    requestOptions: requestOptions,
    data: data,
    statusCode: statusCode,
  );
  return HttpResponse<dynamic>(data, response);
}

class _FakeChatApiClient extends AiseeChatApiClient {
  _FakeChatApiClient({this.fetchMessagesResponse}) : super(Dio());

  final HttpResponse<dynamic>? fetchMessagesResponse;
  Map<String, dynamic>? lastFetchQuery;

  @override
  Future<HttpResponse<dynamic>> fetchMessages(
    String authorization,
    String contactId,
    Map<String, dynamic> query,
  ) async {
    lastFetchQuery = query;
    return fetchMessagesResponse!;
  }

  @override
  Future<HttpResponse<dynamic>> fetchUnreadCount(String authorization) {
    throw UnimplementedError();
  }

  @override
  Future<HttpResponse<dynamic>> markRead(
    String authorization,
    String messageId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<HttpResponse<dynamic>> sendMessage(
    String authorization,
    Map<String, dynamic> body,
  ) {
    throw UnimplementedError();
  }
}
