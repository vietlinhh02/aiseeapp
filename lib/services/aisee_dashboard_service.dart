import 'package:dio/dio.dart';
import 'package:retrofit/dio.dart';

import '../api/aisee_api_auth.dart';
import '../api/aisee_api_dio.dart';
import '../api/dashboard_api.dart';
import '../models/aisee_api_models.dart';
import '../models/aisee_dashboard_models.dart';

class AiseeDashboardService {
  AiseeDashboardService({AiseeDashboardApiClient? apiClient, Dio? dio})
    : this._(dio: dio ?? AiseeApiDioFactory.create(), apiClient: apiClient);

  AiseeDashboardService._({
    required Dio dio,
    AiseeDashboardApiClient? apiClient,
  }) : _dio = dio,
       _ownsDio = apiClient == null,
       _apiClient = apiClient ?? AiseeDashboardApiClient(dio);

  final Dio _dio;
  final bool _ownsDio;
  final AiseeDashboardApiClient _apiClient;

  void close() {
    if (_ownsDio) {
      _dio.close(force: true);
    }
  }

  Future<DashboardHealth> getHealth(String accessToken, String userId) async {
    final HttpResponse<dynamic> res = await _apiClient.getHealth(
      AiseeApiAuth.bearer(accessToken),
      userId,
    );
    if (res.response.statusCode != 200) {
      throw _error(res, 'Không tải được dữ liệu sức khỏe');
    }
    return DashboardHealth.fromJson(
      _decodeMap(res, 'Không tải được dữ liệu sức khỏe'),
    );
  }

  Future<List<MedStatus>> getMedications(
    String accessToken,
    String userId,
  ) async {
    final HttpResponse<dynamic> res = await _apiClient.getMedications(
      AiseeApiAuth.bearer(accessToken),
      userId,
    );
    if (res.response.statusCode != 200) {
      throw _error(res, 'Không tải được danh sách thuốc');
    }
    final Map<String, dynamic> body = _decodeMap(
      res,
      'Không tải được danh sách thuốc',
    );
    final List<dynamic> list = body['medications'] as List<dynamic>? ?? [];
    return list
        .map((e) => MedStatus.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DashboardMedication> createMedication(
    String accessToken,
    String userId, {
    required String name,
    required String dosage,
    required List<String> times,
    String frequency = 'daily',
  }) async {
    final HttpResponse<dynamic> res = await _apiClient.createMedication(
      AiseeApiAuth.bearer(accessToken),
      userId,
      <String, dynamic>{
        'name': name,
        'dosage': dosage,
        'times': times,
        'frequency': frequency,
      },
    );
    if (res.response.statusCode != 200 && res.response.statusCode != 201) {
      throw _error(res, 'Không thêm được thuốc');
    }
    return DashboardMedication.fromJson(
      _decodeMap(res, 'Không thêm được thuốc'),
    );
  }

  Future<DashboardMedication> updateMedication(
    String accessToken,
    String userId,
    String medId, {
    required String name,
    required String dosage,
    required List<String> times,
    String frequency = 'daily',
  }) async {
    final HttpResponse<dynamic> res = await _apiClient.updateMedication(
      AiseeApiAuth.bearer(accessToken),
      userId,
      medId,
      <String, dynamic>{
        'name': name,
        'dosage': dosage,
        'times': times,
        'frequency': frequency,
      },
    );
    if (res.response.statusCode != 200) {
      throw _error(res, 'Không cập nhật được thuốc');
    }
    return DashboardMedication.fromJson(
      _decodeMap(res, 'Không cập nhật được thuốc'),
    );
  }

  Future<void> deleteMedication(
    String accessToken,
    String userId,
    String medId,
  ) async {
    final HttpResponse<dynamic> res = await _apiClient.deleteMedication(
      AiseeApiAuth.bearer(accessToken),
      userId,
      medId,
    );
    if (res.response.statusCode != 200 && res.response.statusCode != 204) {
      throw _error(res, 'Không xóa được thuốc');
    }
  }

  Future<List<AuditLogEntry>> getAuditLog(
    String accessToken,
    String userId, {
    int page = 1,
    int limit = 20,
  }) async {
    final HttpResponse<dynamic> res = await _apiClient.getAuditLog(
      AiseeApiAuth.bearer(accessToken),
      userId,
      <String, dynamic>{'page': page, 'limit': limit},
    );
    if (res.response.statusCode != 200) {
      throw _error(res, 'Không tải được lịch sử hoạt động');
    }
    final Map<String, dynamic> body = _decodeMap(
      res,
      'Không tải được lịch sử hoạt động',
    );
    final List<dynamic> list = body['logs'] as List<dynamic>? ?? [];
    return list
        .map((e) => AuditLogEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<UserLocation> getLocation(String accessToken, String userId) async {
    final HttpResponse<dynamic> res = await _apiClient.getLocation(
      AiseeApiAuth.bearer(accessToken),
      userId,
    );
    if (res.response.statusCode != 200) {
      throw _error(res, 'Không tải được vị trí');
    }
    return UserLocation.fromJson(_decodeMap(res, 'Không tải được vị trí'));
  }

  Map<String, dynamic> _decodeMap(HttpResponse<dynamic> res, String fallback) {
    final dynamic data = res.data;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw AiseeApiException(
      '$fallback (HTTP ${res.response.statusCode}, phản hồi không hợp lệ)',
    );
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
