import 'package:dio/dio.dart';
import 'package:retrofit/dio.dart';

class AiseeHealthApiClient {
  AiseeHealthApiClient(this._dio);

  final Dio _dio;

  Options _auth(String authorization) =>
      Options(headers: <String, Object?>{'Authorization': authorization});

  Future<HttpResponse<dynamic>> postJson(
    String authorization,
    String path,
    Map<String, dynamic> body,
  ) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      path,
      data: body,
      options: _auth(authorization),
    );
    return HttpResponse<dynamic>(response.data, response);
  }

  Future<HttpResponse<dynamic>> getJson(
    String authorization,
    String path,
  ) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      path,
      options: _auth(authorization),
    );
    return HttpResponse<dynamic>(response.data, response);
  }
}
