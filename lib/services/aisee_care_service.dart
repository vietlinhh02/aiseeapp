import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_env.dart';
import '../models/aisee_api_models.dart';
import '../models/aisee_care_models.dart';
import '../utils/aisee_api_error_parse.dart';

class AiseeCareService {
  AiseeCareService({http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  final http.Client _http;

  void close() => _http.close();

  Uri _uri(String path) => Uri.parse('${AppEnv.apiBaseUrl}$path');

  Map<String, String> _headers(String accessToken) => <String, String>{
    'Authorization': 'Bearer $accessToken',
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': 'application/json',
  };

  AiseeApiException _error(http.Response res, String fallback) {
    return aiseeApiExceptionFromResponse(res, fallback);
  }

  Map<String, dynamic> _decodeMap(http.Response res, String fallback) {
    final String raw = utf8.decode(res.bodyBytes).trim();
    if (raw.isEmpty) {
      throw AiseeApiException('$fallback (phản hồi trống)');
    }
    final Object? decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    throw AiseeApiException('$fallback (JSON không hợp lệ)');
  }

  Future<CareTimelineResponse> getTimeline(
    String accessToken,
    String caredUserId, {
    int days = 7,
    int limit = 50,
  }) async {
    final Uri u = _uri(
      '/api/v1/dashboard/$caredUserId/care/timeline'
      '?days=$days&limit=$limit',
    );
    final http.Response res = await _http.get(
      u,
      headers: _headers(accessToken),
    );
    if (res.statusCode != 200) {
      throw _error(res, 'Không tải được timeline chăm sóc');
    }
    return CareTimelineResponse.fromJson(_decodeMap(res, 'timeline'));
  }

  Future<CareDailyBriefResponse> getDailyBrief(
    String accessToken,
    String caredUserId, {
    String? date,
  }) async {
    final String q = date != null && date.isNotEmpty ? '?date=$date' : '';
    final http.Response res = await _http.get(
      _uri('/api/v1/dashboard/$caredUserId/care/daily-brief$q'),
      headers: _headers(accessToken),
    );
    if (res.statusCode != 200) {
      throw _error(res, 'Không tải được tóm tắt ngày');
    }
    return CareDailyBriefResponse.fromJson(_decodeMap(res, 'daily_brief'));
  }

  Future<CareWeeklyReportResponse> getWeeklyReport(
    String accessToken,
    String caredUserId, {
    String? endDate,
  }) async {
    final String q = endDate != null && endDate.isNotEmpty
        ? '?end_date=$endDate'
        : '';
    final http.Response res = await _http.get(
      _uri('/api/v1/dashboard/$caredUserId/care/weekly-report$q'),
      headers: _headers(accessToken),
    );
    if (res.statusCode != 200) {
      throw _error(res, 'Không tải được báo cáo tuần');
    }
    return CareWeeklyReportResponse.fromJson(_decodeMap(res, 'weekly_report'));
  }

  Future<CareIncidentReportResponse> getIncidentReport(
    String accessToken,
    String caredUserId,
  ) async {
    final http.Response res = await _http.get(
      _uri('/api/v1/dashboard/$caredUserId/care/incident-report'),
      headers: _headers(accessToken),
    );
    if (res.statusCode != 200) {
      throw _error(res, 'Không tải được báo cáo sự cố');
    }
    return CareIncidentReportResponse.fromJson(
      _decodeMap(res, 'incident_report'),
    );
  }

  Future<CareExportResponse> exportPdf(
    String accessToken,
    String caredUserId, {
    required String reportType,
    String? date,
    String? endDate,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'report_type': reportType,
    };
    if (date != null && date.isNotEmpty) body['date'] = date;
    if (endDate != null && endDate.isNotEmpty) body['end_date'] = endDate;

    final http.Response res = await _http.post(
      _uri('/api/v1/dashboard/$caredUserId/care/export/pdf'),
      headers: _headers(accessToken),
      body: jsonEncode(body),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw _error(res, 'Không xuất được báo cáo');
    }
    return CareExportResponse.fromJson(_decodeMap(res, 'export'));
  }

  Future<List<CareAlert>> listAlerts(
    String accessToken,
    String caredUserId, {
    String? status,
    int limit = 50,
  }) async {
    final String q =
        '?limit=$limit${status != null && status.isNotEmpty ? '&status=$status' : ''}';
    final http.Response res = await _http.get(
      _uri('/api/v1/care/users/$caredUserId/alerts$q'),
      headers: _headers(accessToken),
    );
    if (res.statusCode != 200) {
      throw _error(res, 'Không tải được cảnh báo');
    }
    final Map<String, dynamic> map = _decodeMap(res, 'alerts');
    final List<dynamic> raw = map['alerts'] as List<dynamic>? ?? [];
    return raw
        .map((e) => CareAlert.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> ackAlert(String accessToken, String alertId) async {
    final http.Response res = await _http.post(
      _uri('/api/v1/care/alerts/$alertId/ack'),
      headers: _headers(accessToken),
      body: '{}',
    );
    if (res.statusCode != 200) {
      throw _error(res, 'Không xác nhận được cảnh báo');
    }
  }

  Future<void> resolveAlert(String accessToken, String alertId) async {
    final http.Response res = await _http.post(
      _uri('/api/v1/care/alerts/$alertId/resolve'),
      headers: _headers(accessToken),
      body: '{}',
    );
    if (res.statusCode != 200) {
      throw _error(res, 'Không đóng được cảnh báo');
    }
  }

  Future<void> dismissAlert(String accessToken, String alertId) async {
    final http.Response res = await _http.post(
      _uri('/api/v1/care/alerts/$alertId/dismiss'),
      headers: _headers(accessToken),
      body: '{}',
    );
    if (res.statusCode != 200) {
      throw _error(res, 'Không bỏ qua được cảnh báo');
    }
  }

  Future<List<CareTask>> listTasks(
    String accessToken,
    String caredUserId, {
    int limit = 100,
  }) async {
    final http.Response res = await _http.get(
      _uri('/api/v1/care/users/$caredUserId/tasks?limit=$limit'),
      headers: _headers(accessToken),
    );
    if (res.statusCode != 200) {
      throw _error(res, 'Không tải được việc cần làm');
    }
    final Map<String, dynamic> map = _decodeMap(res, 'tasks');
    final List<dynamic> raw = map['tasks'] as List<dynamic>? ?? [];
    return raw
        .map((e) => CareTask.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<String> createTask(
    String accessToken,
    String caredUserId, {
    required String title,
    DateTime? dueAt,
    Map<String, dynamic>? metadata,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{'title': title};
    if (dueAt != null) {
      body['due_at'] = dueAt.toUtc().toIso8601String();
    }
    if (metadata != null && metadata.isNotEmpty) {
      body['metadata'] = metadata;
    }
    final http.Response res = await _http.post(
      _uri('/api/v1/care/users/$caredUserId/tasks'),
      headers: _headers(accessToken),
      body: jsonEncode(body),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw _error(res, 'Không tạo được việc cần làm');
    }
    final Map<String, dynamic> map = _decodeMap(res, 'task_create');
    return map['id'] as String? ?? '';
  }

  Future<void> updateTask(
    String accessToken,
    String taskId, {
    required String title,
    DateTime? dueAt,
    String? status,
    Map<String, dynamic>? metadata,
  }) async {
    final String t = title.trim();
    if (t.isEmpty) {
      throw AiseeApiException('Tiêu đề việc cần làm không được để trống');
    }
    final Map<String, dynamic> body = <String, dynamic>{'title': t};
    if (dueAt != null) body['due_at'] = dueAt.toUtc().toIso8601String();
    if (status != null) body['status'] = status;
    if (metadata != null) body['metadata'] = metadata;

    final http.Response res = await _http.put(
      _uri('/api/v1/care/tasks/$taskId'),
      headers: _headers(accessToken),
      body: jsonEncode(body),
    );
    if (res.statusCode != 200) {
      throw _error(res, 'Không cập nhật được việc cần làm');
    }
  }

  Future<void> completeTask(String accessToken, String taskId) async {
    final http.Response res = await _http.post(
      _uri('/api/v1/care/tasks/$taskId/complete'),
      headers: _headers(accessToken),
      body: '{}',
    );
    if (res.statusCode != 200) {
      throw _error(res, 'Không hoàn thành được việc');
    }
  }
}
