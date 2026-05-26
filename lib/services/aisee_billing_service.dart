import 'package:dio/dio.dart';
import 'package:retrofit/dio.dart';

import '../api/aisee_api_auth.dart';
import '../api/aisee_api_dio.dart';
import '../api/billing_api.dart';
import '../models/aisee_api_models.dart';
import '../models/aisee_billing_models.dart';

class AiseeBillingService {
  AiseeBillingService({AiseeBillingApiClient? apiClient, Dio? dio})
    : this._(dio: dio ?? AiseeApiDioFactory.create(), apiClient: apiClient);

  AiseeBillingService._({required Dio dio, AiseeBillingApiClient? apiClient})
    : _dio = dio,
      _ownsDio = apiClient == null,
      _apiClient = apiClient ?? AiseeBillingApiClient(dio);

  final Dio _dio;
  final bool _ownsDio;
  final AiseeBillingApiClient _apiClient;

  void close() {
    if (_ownsDio) {
      _dio.close(force: true);
    }
  }

  Future<AiseeBillingOverview> fetchBillingOverview(
    String accessToken, {
    String? careGroupId,
    String? caredUserId,
  }) async {
    final Map<String, dynamic> body = await _getJsonWithBillingFallback(
      '/api/v1/me/billing-overview',
      accessToken,
      careGroupId: careGroupId,
      caredUserId: caredUserId,
      fallback: 'Không tải được thông tin gói',
    );
    return AiseeBillingOverview.fromJson(body);
  }

  Future<AiseeMeUsageResponse> fetchUsage(
    String accessToken, {
    String? careGroupId,
    String? caredUserId,
  }) async {
    final Map<String, dynamic> body = await _getJsonWithBillingFallback(
      '/api/v1/me/usage',
      accessToken,
      careGroupId: careGroupId,
      caredUserId: caredUserId,
      fallback: 'Không tải được mức sử dụng',
    );
    return AiseeMeUsageResponse.fromJson(body);
  }

  Future<Map<String, dynamic>> _getJsonWithBillingFallback(
    String path,
    String accessToken, {
    String? careGroupId,
    String? caredUserId,
    required String fallback,
    bool allowRetryWithoutCaredUser = true,
  }) async {
    final String? normalizedCareGroupId = _normalizeQueryValue(careGroupId);
    final String? normalizedCaredUserId = _normalizeQueryValue(caredUserId);
    final Map<String, dynamic>? query = _buildBillingQuery(
      careGroupId: normalizedCareGroupId,
      caredUserId: normalizedCaredUserId,
    );
    final HttpResponse<dynamic> res = switch (path) {
      '/api/v1/me/billing-overview' => await _apiClient.fetchBillingOverview(
        AiseeApiAuth.bearer(accessToken),
        query ?? const <String, dynamic>{},
      ),
      '/api/v1/me/usage' => await _apiClient.fetchUsage(
        AiseeApiAuth.bearer(accessToken),
        query ?? const <String, dynamic>{},
      ),
      _ => throw StateError('Unsupported billing path: $path'),
    };
    final Map<String, dynamic> body = _parseJsonBody(res, fallback: fallback);
    if (res.response.statusCode == 200) {
      return body;
    }
    final AiseeApiException error = _errorFromBody(body, fallback: fallback);
    if (_shouldRetryWithoutCaredUser(error, normalizedCaredUserId) &&
        allowRetryWithoutCaredUser) {
      return _getJsonWithBillingFallback(
        path,
        accessToken,
        careGroupId: normalizedCareGroupId,
        fallback: fallback,
        allowRetryWithoutCaredUser: false,
      );
    }
    throw error;
  }

  Map<String, dynamic>? _buildBillingQuery({
    String? careGroupId,
    String? caredUserId,
  }) {
    final Map<String, dynamic> query = <String, dynamic>{};
    if (careGroupId != null) {
      query['care_group_id'] = careGroupId;
    }
    if (caredUserId != null) {
      query['cared_user_id'] = caredUserId;
    }
    return query.isEmpty ? null : query;
  }

  String? _normalizeQueryValue(String? value) {
    final String? trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  bool _shouldRetryWithoutCaredUser(
    AiseeApiException error,
    String? caredUserId,
  ) {
    return caredUserId != null && error.code == 'no_billing_care_group';
  }

  Map<String, dynamic> _parseJsonBody(
    HttpResponse<dynamic> res, {
    required String fallback,
  }) {
    final dynamic data = res.data;
    if (data == null) {
      throw AiseeApiException(
        '$fallback (HTTP ${res.response.statusCode}, phản hồi trống)',
      );
    }
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    throw AiseeApiException(
      '$fallback (HTTP ${res.response.statusCode}, phản hồi không hợp lệ)',
    );
  }

  AiseeApiException _errorFromBody(
    Map<String, dynamic> map, {
    required String fallback,
  }) {
    final Map<String, dynamic>? error = map['error'] as Map<String, dynamic>?;
    if (error != null) {
      return AiseeApiException(
        error['message'] as String? ?? fallback,
        code: error['code'] as String?,
      );
    }
    return AiseeApiException(map['message'] as String? ?? fallback);
  }
}
