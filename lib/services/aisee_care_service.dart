import 'package:dio/dio.dart';
import 'package:retrofit/dio.dart';

import '../api/aisee_api_auth.dart';
import '../api/aisee_api_dio.dart';
import '../api/care_api.dart';
import '../models/aisee_api_models.dart';
import '../models/aisee_care_models.dart';
import '../utils/aisee_api_error_parse.dart';

class AiseeCareService {
  AiseeCareService({AiseeCareApiClient? apiClient, Dio? dio})
    : this._(dio: dio ?? AiseeApiDioFactory.create(), apiClient: apiClient);

  AiseeCareService._({required Dio dio, AiseeCareApiClient? apiClient})
    : _dio = dio,
      _ownsDio = apiClient == null,
      _apiClient = apiClient ?? AiseeCareApiClient(dio);

  final Dio _dio;
  final bool _ownsDio;
  final AiseeCareApiClient _apiClient;

  void close() {
    if (_ownsDio) {
      _dio.close(force: true);
    }
  }

  AiseeApiException _error(HttpResponse<dynamic> res, String fallback) {
    final Map<String, dynamic>? body = _asMap(res.data);
    if (res.response.statusCode == 402 && body != null) {
      final AiseeQuotaApiException? quota = aiseeQuotaExceptionFromJsonMap(
        body,
      );
      if (quota != null) {
        return quota;
      }
    }
    final Map<String, dynamic>? error = body?['error'] as Map<String, dynamic>?;
    return AiseeApiException(
      error?['message'] as String? ?? body?['message'] as String? ?? fallback,
      code: error?['code'] as String?,
    );
  }

  Map<String, dynamic> _decodeMap(HttpResponse<dynamic> res, String fallback) {
    final Map<String, dynamic>? decoded = _asMap(res.data);
    if (decoded == null) {
      throw AiseeApiException('$fallback (phản hồi trống)');
    }
    return decoded;
  }

  Map<String, dynamic>? _asMap(Object? data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  Future<CareTimelineResponse> getTimeline(
    String accessToken,
    String caredUserId, {
    int days = 7,
    int limit = 50,
  }) async {
    final HttpResponse<dynamic> res = await _apiClient.getTimeline(
      AiseeApiAuth.bearer(accessToken),
      caredUserId,
      <String, dynamic>{'days': days, 'limit': limit},
    );
    if (res.response.statusCode != 200) {
      throw _error(res, 'Không tải được timeline chăm sóc');
    }
    return CareTimelineResponse.fromJson(_decodeMap(res, 'timeline'));
  }

  Future<CareDailyBriefResponse> getDailyBrief(
    String accessToken,
    String caredUserId, {
    String? date,
  }) async {
    final HttpResponse<dynamic> res = await _apiClient.getDailyBrief(
      AiseeApiAuth.bearer(accessToken),
      caredUserId,
      date != null && date.isNotEmpty ? <String, dynamic>{'date': date} : null,
    );
    if (res.response.statusCode != 200) {
      throw _error(res, 'Không tải được tóm tắt ngày');
    }
    return CareDailyBriefResponse.fromJson(_decodeMap(res, 'daily_brief'));
  }

  Future<CareWeeklyReportResponse> getWeeklyReport(
    String accessToken,
    String caredUserId, {
    String? endDate,
  }) async {
    final HttpResponse<dynamic> res = await _apiClient.getWeeklyReport(
      AiseeApiAuth.bearer(accessToken),
      caredUserId,
      endDate != null && endDate.isNotEmpty
          ? <String, dynamic>{'end_date': endDate}
          : null,
    );
    if (res.response.statusCode != 200) {
      throw _error(res, 'Không tải được báo cáo tuần');
    }
    return CareWeeklyReportResponse.fromJson(_decodeMap(res, 'weekly_report'));
  }

  Future<CareIncidentReportResponse> getIncidentReport(
    String accessToken,
    String caredUserId,
  ) async {
    final HttpResponse<dynamic> res = await _apiClient.getIncidentReport(
      AiseeApiAuth.bearer(accessToken),
      caredUserId,
    );
    if (res.response.statusCode != 200) {
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

    final HttpResponse<dynamic> res = await _apiClient.exportPdf(
      AiseeApiAuth.bearer(accessToken),
      caredUserId,
      body,
    );
    if (res.response.statusCode != 200 && res.response.statusCode != 201) {
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
    final Map<String, dynamic> query = <String, dynamic>{'limit': limit};
    if (status != null && status.isNotEmpty) {
      query['status'] = status;
    }
    final HttpResponse<dynamic> res = await _apiClient.listAlerts(
      AiseeApiAuth.bearer(accessToken),
      caredUserId,
      query,
    );
    if (res.response.statusCode != 200) {
      throw _error(res, 'Không tải được cảnh báo');
    }
    final Map<String, dynamic> map = _decodeMap(res, 'alerts');
    final List<dynamic> raw = map['alerts'] as List<dynamic>? ?? [];
    return raw
        .map((e) => CareAlert.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> ackAlert(String accessToken, String alertId) async {
    final HttpResponse<dynamic> res = await _apiClient.ackAlert(
      AiseeApiAuth.bearer(accessToken),
      alertId,
    );
    if (res.response.statusCode != 200) {
      throw _error(res, 'Không xác nhận được cảnh báo');
    }
  }

  Future<void> resolveAlert(String accessToken, String alertId) async {
    final HttpResponse<dynamic> res = await _apiClient.resolveAlert(
      AiseeApiAuth.bearer(accessToken),
      alertId,
    );
    if (res.response.statusCode != 200) {
      throw _error(res, 'Không đóng được cảnh báo');
    }
  }

  Future<void> dismissAlert(String accessToken, String alertId) async {
    final HttpResponse<dynamic> res = await _apiClient.dismissAlert(
      AiseeApiAuth.bearer(accessToken),
      alertId,
    );
    if (res.response.statusCode != 200) {
      throw _error(res, 'Không bỏ qua được cảnh báo');
    }
  }

  Future<List<CareTask>> listTasks(
    String accessToken,
    String caredUserId, {
    int limit = 100,
  }) async {
    final HttpResponse<dynamic> res = await _apiClient.listTasks(
      AiseeApiAuth.bearer(accessToken),
      caredUserId,
      <String, dynamic>{'limit': limit},
    );
    if (res.response.statusCode != 200) {
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
    final HttpResponse<dynamic> res = await _apiClient.createTask(
      AiseeApiAuth.bearer(accessToken),
      caredUserId,
      body,
    );
    if (res.response.statusCode != 200 && res.response.statusCode != 201) {
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

    final HttpResponse<dynamic> res = await _apiClient.updateTask(
      AiseeApiAuth.bearer(accessToken),
      taskId,
      body,
    );
    if (res.response.statusCode != 200) {
      throw _error(res, 'Không cập nhật được việc cần làm');
    }
  }

  Future<void> completeTask(String accessToken, String taskId) async {
    final HttpResponse<dynamic> res = await _apiClient.completeTask(
      AiseeApiAuth.bearer(accessToken),
      taskId,
    );
    if (res.response.statusCode != 200) {
      throw _error(res, 'Không hoàn thành được việc');
    }
  }
}
