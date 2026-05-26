import 'package:aiseeapp/api/call_api.dart';
import 'package:aiseeapp/services/aisee_call_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retrofit/dio.dart';

void main() {
  test('createRoom parses room name and token', () async {
    final _FakeCallApiClient client = _FakeCallApiClient(
      createRoomResponse: _response(<String, Object?>{
        'room_name': 'call-1',
        'token': 'lk-token',
      }, 200),
    );
    final AiseeCallService service = AiseeCallService(apiClient: client);

    final ({String roomName, String token}) result = await service.createRoom(
      'access-token',
      'user-b',
      'video',
    );

    expect(client.lastCreateAuthorization, 'Bearer access-token');
    expect(client.lastCreateBody?['callee_id'], 'user-b');
    expect(result.roomName, 'call-1');
    expect(result.token, 'lk-token');
    service.close();
  });

  test('endRoom throws API error on non-200 response', () async {
    final _FakeCallApiClient client = _FakeCallApiClient(
      endRoomResponse: _response(<String, Object?>{
        'error': <String, Object?>{
          'code': 'end_room_failed',
          'message': 'boom',
        },
      }, 500),
    );
    final AiseeCallService service = AiseeCallService(apiClient: client);

    expect(
      () => service.endRoom('access-token', 'call-1'),
      throwsA(isA<Exception>()),
    );
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

class _FakeCallApiClient extends AiseeCallApiClient {
  _FakeCallApiClient({this.createRoomResponse, this.endRoomResponse})
    : super(Dio());

  final HttpResponse<dynamic>? createRoomResponse;
  final HttpResponse<dynamic>? endRoomResponse;
  String? lastCreateAuthorization;
  Map<String, dynamic>? lastCreateBody;

  @override
  Future<HttpResponse<dynamic>> createRoom(
    String authorization,
    Map<String, dynamic> body,
  ) async {
    lastCreateAuthorization = authorization;
    lastCreateBody = body;
    return createRoomResponse!;
  }

  @override
  Future<HttpResponse<dynamic>> endRoom(
    String authorization,
    Map<String, dynamic> body,
  ) async {
    return endRoomResponse!;
  }
}
