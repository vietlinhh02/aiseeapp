import 'package:dio/dio.dart';
import 'package:retrofit/dio.dart';

class AiseeCareApiClient {
  AiseeCareApiClient(this._dio);

  final Dio _dio;

  Options _auth(String authorization) => Options(
    headers: <String, Object?>{
      'Authorization': authorization,
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
    },
  );

  Future<HttpResponse<dynamic>> getTimeline(
    String authorization,
    String caredUserId,
    Map<String, dynamic> query,
  ) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      '/api/v1/dashboard/$caredUserId/care/timeline',
      queryParameters: query,
      options: _auth(authorization),
    );
    return HttpResponse<dynamic>(response.data, response);
  }

  Future<HttpResponse<dynamic>> getDailyBrief(
    String authorization,
    String caredUserId,
    Map<String, dynamic>? query,
  ) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      '/api/v1/dashboard/$caredUserId/care/daily-brief',
      queryParameters: query,
      options: _auth(authorization),
    );
    return HttpResponse<dynamic>(response.data, response);
  }

  Future<HttpResponse<dynamic>> getWeeklyReport(
    String authorization,
    String caredUserId,
    Map<String, dynamic>? query,
  ) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      '/api/v1/dashboard/$caredUserId/care/weekly-report',
      queryParameters: query,
      options: _auth(authorization),
    );
    return HttpResponse<dynamic>(response.data, response);
  }

  Future<HttpResponse<dynamic>> getIncidentReport(
    String authorization,
    String caredUserId,
  ) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      '/api/v1/dashboard/$caredUserId/care/incident-report',
      options: _auth(authorization),
    );
    return HttpResponse<dynamic>(response.data, response);
  }

  Future<HttpResponse<dynamic>> exportPdf(
    String authorization,
    String caredUserId,
    Map<String, dynamic> body,
  ) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      '/api/v1/dashboard/$caredUserId/care/export/pdf',
      data: body,
      options: _auth(authorization),
    );
    return HttpResponse<dynamic>(response.data, response);
  }

  Future<HttpResponse<dynamic>> listAlerts(
    String authorization,
    String caredUserId,
    Map<String, dynamic> query,
  ) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      '/api/v1/care/users/$caredUserId/alerts',
      queryParameters: query,
      options: _auth(authorization),
    );
    return HttpResponse<dynamic>(response.data, response);
  }

  Future<HttpResponse<dynamic>> ackAlert(
    String authorization,
    String alertId,
  ) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      '/api/v1/care/alerts/$alertId/ack',
      data: const <String, dynamic>{},
      options: _auth(authorization),
    );
    return HttpResponse<dynamic>(response.data, response);
  }

  Future<HttpResponse<dynamic>> resolveAlert(
    String authorization,
    String alertId,
  ) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      '/api/v1/care/alerts/$alertId/resolve',
      data: const <String, dynamic>{},
      options: _auth(authorization),
    );
    return HttpResponse<dynamic>(response.data, response);
  }

  Future<HttpResponse<dynamic>> dismissAlert(
    String authorization,
    String alertId,
  ) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      '/api/v1/care/alerts/$alertId/dismiss',
      data: const <String, dynamic>{},
      options: _auth(authorization),
    );
    return HttpResponse<dynamic>(response.data, response);
  }

  Future<HttpResponse<dynamic>> listTasks(
    String authorization,
    String caredUserId,
    Map<String, dynamic> query,
  ) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      '/api/v1/care/users/$caredUserId/tasks',
      queryParameters: query,
      options: _auth(authorization),
    );
    return HttpResponse<dynamic>(response.data, response);
  }

  Future<HttpResponse<dynamic>> createTask(
    String authorization,
    String caredUserId,
    Map<String, dynamic> body,
  ) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      '/api/v1/care/users/$caredUserId/tasks',
      data: body,
      options: _auth(authorization),
    );
    return HttpResponse<dynamic>(response.data, response);
  }

  Future<HttpResponse<dynamic>> updateTask(
    String authorization,
    String taskId,
    Map<String, dynamic> body,
  ) async {
    final Response<dynamic> response = await _dio.put<dynamic>(
      '/api/v1/care/tasks/$taskId',
      data: body,
      options: _auth(authorization),
    );
    return HttpResponse<dynamic>(response.data, response);
  }

  Future<HttpResponse<dynamic>> completeTask(
    String authorization,
    String taskId,
  ) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      '/api/v1/care/tasks/$taskId/complete',
      data: const <String, dynamic>{},
      options: _auth(authorization),
    );
    return HttpResponse<dynamic>(response.data, response);
  }
}
