import 'package:dio/dio.dart';
import 'package:retrofit/dio.dart';

class AiseeDashboardApiClient {
  AiseeDashboardApiClient(this._dio);

  final Dio _dio;

  Options _auth(String authorization) =>
      Options(headers: <String, Object?>{'Authorization': authorization});

  Future<HttpResponse<dynamic>> getHealth(
    String authorization,
    String userId,
  ) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      '/api/v1/dashboard/$userId/health',
      options: _auth(authorization),
    );
    return HttpResponse<dynamic>(response.data, response);
  }

  Future<HttpResponse<dynamic>> getMedications(
    String authorization,
    String userId,
  ) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      '/api/v1/dashboard/$userId/medications',
      options: _auth(authorization),
    );
    return HttpResponse<dynamic>(response.data, response);
  }

  Future<HttpResponse<dynamic>> createMedication(
    String authorization,
    String userId,
    Map<String, dynamic> body,
  ) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      '/api/v1/dashboard/$userId/medications',
      data: body,
      options: _auth(authorization),
    );
    return HttpResponse<dynamic>(response.data, response);
  }

  Future<HttpResponse<dynamic>> updateMedication(
    String authorization,
    String userId,
    String medId,
    Map<String, dynamic> body,
  ) async {
    final Response<dynamic> response = await _dio.put<dynamic>(
      '/api/v1/dashboard/$userId/medications/$medId',
      data: body,
      options: _auth(authorization),
    );
    return HttpResponse<dynamic>(response.data, response);
  }

  Future<HttpResponse<dynamic>> deleteMedication(
    String authorization,
    String userId,
    String medId,
  ) async {
    final Response<dynamic> response = await _dio.delete<dynamic>(
      '/api/v1/dashboard/$userId/medications/$medId',
      options: _auth(authorization),
    );
    return HttpResponse<dynamic>(response.data, response);
  }

  Future<HttpResponse<dynamic>> getAuditLog(
    String authorization,
    String userId,
    Map<String, dynamic> query,
  ) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      '/api/v1/dashboard/$userId/audit-log',
      queryParameters: query,
      options: _auth(authorization),
    );
    return HttpResponse<dynamic>(response.data, response);
  }

  Future<HttpResponse<dynamic>> getLocation(
    String authorization,
    String userId,
  ) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      '/api/v1/dashboard/$userId/location',
      options: _auth(authorization),
    );
    return HttpResponse<dynamic>(response.data, response);
  }
}
