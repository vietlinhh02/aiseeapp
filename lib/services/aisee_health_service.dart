import 'package:dio/dio.dart';
import 'package:retrofit/dio.dart';

import '../api/aisee_api_auth.dart';
import '../api/aisee_api_dio.dart';
import '../api/health_api.dart';
import '../models/aisee_api_models.dart';

class AiseeHealthService {
  AiseeHealthService({AiseeHealthApiClient? apiClient, Dio? dio})
    : this._(dio: dio ?? AiseeApiDioFactory.create(), apiClient: apiClient);

  AiseeHealthService._({required Dio dio, AiseeHealthApiClient? apiClient})
    : _dio = dio,
      _ownsDio = apiClient == null,
      _apiClient = apiClient ?? AiseeHealthApiClient(dio);

  final Dio _dio;
  final bool _ownsDio;
  final AiseeHealthApiClient _apiClient;

  void close() {
    if (_ownsDio) {
      _dio.close(force: true);
    }
  }

  Future<void> markMedicationTaken(
    String accessToken,
    Map<String, dynamic> data,
  ) async {
    final HttpResponse<dynamic> res = await _apiClient.postJson(
      AiseeApiAuth.bearer(accessToken),
      '/api/v1/health/medication/taken',
      data,
    );
    if (res.response.statusCode != 200) {
      throw _error(res, 'Không ghi nhận uống thuốc được');
    }
  }

  Future<void> markMedicationSkipped(
    String accessToken,
    Map<String, dynamic> data,
  ) async {
    final HttpResponse<dynamic> res = await _apiClient.postJson(
      AiseeApiAuth.bearer(accessToken),
      '/api/v1/health/medication/skipped',
      data,
    );
    if (res.response.statusCode != 200) {
      throw _error(res, 'Không ghi nhận bỏ thuốc được');
    }
  }

  Future<void> logSymptom(String accessToken, Map<String, dynamic> data) async {
    final HttpResponse<dynamic> res = await _apiClient.postJson(
      AiseeApiAuth.bearer(accessToken),
      '/api/v1/health/symptoms',
      data,
    );
    if (res.response.statusCode != 200) {
      throw _error(res, 'Không ghi triệu chứng được');
    }
  }

  Future<void> logMetric(String accessToken, Map<String, dynamic> data) async {
    final HttpResponse<dynamic> res = await _apiClient.postJson(
      AiseeApiAuth.bearer(accessToken),
      '/api/v1/health/metrics',
      data,
    );
    if (res.response.statusCode != 200) {
      throw _error(res, 'Không ghi chỉ số sức khoẻ được');
    }
  }

  Future<Map<String, dynamic>> sendEmergencyAlert(
    String accessToken,
    Map<String, dynamic> data,
  ) async {
    final HttpResponse<dynamic> res = await _apiClient.postJson(
      AiseeApiAuth.bearer(accessToken),
      '/api/v1/emergency/alert',
      data,
    );
    if (res.response.statusCode != 200) {
      throw _error(res, 'Không gửi được cảnh báo khẩn cấp');
    }
    final dynamic payload = res.data;
    if (payload is Map<String, dynamic>) return payload;
    if (payload is Map) return Map<String, dynamic>.from(payload);
    return <String, dynamic>{};
  }

  Future<void> rateVolunteer(
    String accessToken,
    Map<String, dynamic> data,
  ) async {
    final HttpResponse<dynamic> res = await _apiClient.postJson(
      AiseeApiAuth.bearer(accessToken),
      '/api/v1/volunteers/rate',
      data,
    );
    if (res.response.statusCode != 200) {
      throw _error(res, 'Không đánh giá được tình nguyện viên');
    }
  }

  Future<List<Map<String, dynamic>>> fetchMedications(
    String accessToken,
  ) async {
    final HttpResponse<dynamic> res = await _apiClient.getJson(
      AiseeApiAuth.bearer(accessToken),
      '/api/v1/me/medications',
    );
    if (res.response.statusCode != 200) {
      throw _error(res, 'Không tải được lịch thuốc');
    }
    final Map<String, dynamic> body = _decodeMap(res);
    final List<dynamic> items =
        body['medications'] as List<dynamic>? ?? <dynamic>[];
    return items.map((dynamic e) {
      final Map<String, dynamic> entry = e as Map<String, dynamic>;
      final Map<String, dynamic> med =
          entry['medication'] as Map<String, dynamic>? ?? <String, dynamic>{};
      return <String, dynamic>{
        ...med,
        'taken': entry['taken'] ?? false,
        'skipped': entry['skipped'] ?? false,
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> fetchAppointments(
    String accessToken,
  ) async {
    final HttpResponse<dynamic> res = await _apiClient.getJson(
      AiseeApiAuth.bearer(accessToken),
      '/api/v1/me/appointments',
    );
    if (res.response.statusCode != 200) {
      throw _error(res, 'Không tải được lịch hẹn');
    }
    final Map<String, dynamic> body = _decodeMap(res);
    final List<dynamic> items =
        body['appointments'] as List<dynamic>? ?? <dynamic>[];
    return items.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> fetchHealthLogs(String accessToken) async {
    final HttpResponse<dynamic> res = await _apiClient.getJson(
      AiseeApiAuth.bearer(accessToken),
      '/api/v1/me/health',
    );
    if (res.response.statusCode != 200) {
      throw _error(res, 'Không tải được nhật ký sức khỏe');
    }
    final Map<String, dynamic> body = _decodeMap(res);
    final List<Map<String, dynamic>> result = <Map<String, dynamic>>[];
    final List<dynamic> symptoms =
        body['recent_symptoms'] as List<dynamic>? ?? <dynamic>[];
    for (final dynamic s in symptoms) {
      final Map<String, dynamic> m = s as Map<String, dynamic>;
      result.add(<String, dynamic>{...m, '_kind': 'symptom'});
    }
    final List<dynamic> metrics =
        body['recent_metrics'] as List<dynamic>? ?? <dynamic>[];
    for (final dynamic s in metrics) {
      final Map<String, dynamic> m = s as Map<String, dynamic>;
      result.add(<String, dynamic>{...m, '_kind': 'metric'});
    }
    return result;
  }

  Map<String, dynamic> _decodeMap(HttpResponse<dynamic> res) {
    final dynamic payload = res.data;
    if (payload is Map<String, dynamic>) return payload;
    if (payload is Map) return Map<String, dynamic>.from(payload);
    return <String, dynamic>{};
  }

  AiseeApiException _error(HttpResponse<dynamic> res, String fallback) {
    final dynamic data = res.data;
    final Map<String, dynamic>? body = switch (data) {
      Map<String, dynamic> value => value,
      Map value => Map<String, dynamic>.from(value),
      _ => null,
    };
    final Map<String, dynamic>? error = body?['error'] as Map<String, dynamic>?;
    return AiseeApiException(
      error?['message'] as String? ?? body?['message'] as String? ?? fallback,
      code: error?['code'] as String?,
    );
  }
}
