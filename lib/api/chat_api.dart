import 'package:dio/dio.dart';
import 'package:retrofit/dio.dart';

class AiseeChatApiClient {
  AiseeChatApiClient(this._dio);

  final Dio _dio;

  Options _auth(String authorization) => Options(
    headers: <String, Object?>{
      'Authorization': authorization,
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
    },
  );

  Future<HttpResponse<dynamic>> fetchMessages(
    String authorization,
    String contactId,
    Map<String, dynamic> query,
  ) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      '/api/v1/messages/$contactId',
      queryParameters: query,
      options: _auth(authorization),
    );
    return HttpResponse<dynamic>(response.data, response);
  }

  Future<HttpResponse<dynamic>> sendMessage(
    String authorization,
    Map<String, dynamic> body,
  ) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      '/api/v1/messages/send',
      data: body,
      options: _auth(authorization),
    );
    return HttpResponse<dynamic>(response.data, response);
  }

  Future<HttpResponse<dynamic>> markRead(
    String authorization,
    String messageId,
  ) async {
    final Response<dynamic> response = await _dio.put<dynamic>(
      '/api/v1/messages/$messageId/read',
      options: _auth(authorization),
    );
    return HttpResponse<dynamic>(response.data, response);
  }

  Future<HttpResponse<dynamic>> fetchUnreadCount(String authorization) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      '/api/v1/messages/unread-count',
      options: _auth(authorization),
    );
    return HttpResponse<dynamic>(response.data, response);
  }
}
