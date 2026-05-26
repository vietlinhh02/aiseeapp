import 'package:dio/dio.dart';
import 'package:retrofit/dio.dart';

class AiseeVolunteerApiClient {
  AiseeVolunteerApiClient(this._dio);

  final Dio _dio;

  Options _auth(String authorization) => Options(
    headers: <String, Object?>{
      'Authorization': authorization,
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
    },
  );

  Future<HttpResponse<dynamic>> fetchStatus(String authorization) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      '/api/v1/volunteers/status',
      options: _auth(authorization),
    );
    return HttpResponse<dynamic>(response.data, response);
  }

  Future<HttpResponse<dynamic>> register(
    String authorization,
    Map<String, dynamic> body,
  ) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      '/api/v1/volunteers/register',
      data: body,
      options: _auth(authorization),
    );
    return HttpResponse<dynamic>(response.data, response);
  }

  Future<HttpResponse<dynamic>> setAvailability(
    String authorization,
    Map<String, dynamic> body,
  ) async {
    final Response<dynamic> response = await _dio.put<dynamic>(
      '/api/v1/volunteers/availability',
      data: body,
      options: _auth(authorization),
    );
    return HttpResponse<dynamic>(response.data, response);
  }
}
