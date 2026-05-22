import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_env.dart';
import '../models/aisee_api_models.dart';
import '../models/aisee_billing_models.dart';
import '../utils/aisee_api_error_parse.dart';

class AiseeBillingService {
  AiseeBillingService({http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  final http.Client _http;

  void close() => _http.close();

  Uri _uri(String path) => Uri.parse('${AppEnv.apiBaseUrl}$path');

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
    final Uri uri = _buildBillingUri(
      path,
      careGroupId: normalizedCareGroupId,
      caredUserId: normalizedCaredUserId,
    );
    final http.Response res = await _http.get(
      uri,
      headers: _headers(accessToken),
    );
    final Map<String, dynamic> body = _parseJsonBody(res, fallback: fallback);
    if (res.statusCode == 200) {
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

  Uri _buildBillingUri(
    String path, {
    String? careGroupId,
    String? caredUserId,
  }) {
    final Map<String, String> query = <String, String>{};
    if (careGroupId != null) {
      query['care_group_id'] = careGroupId;
    }
    if (caredUserId != null) {
      query['cared_user_id'] = caredUserId;
    }
    final Uri uri = query.isEmpty
        ? _uri(path)
        : _uri(path).replace(queryParameters: query);
    return uri;
  }

  Map<String, String> _headers(String accessToken) {
    return <String, String>{
      'Authorization': 'Bearer $accessToken',
      'Accept': 'application/json',
    };
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
    http.Response res, {
    required String fallback,
  }) {
    final String raw = utf8.decode(res.bodyBytes).trim();
    if (raw.isEmpty) {
      throw AiseeApiException(
        '$fallback (HTTP ${res.statusCode}, phản hồi trống)',
      );
    }
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      throw AiseeApiException(
        '$fallback (HTTP ${res.statusCode}, phản hồi không hợp lệ)',
      );
    } on FormatException {
      final String preview = raw.length > 80 ? '${raw.substring(0, 80)}…' : raw;
      throw AiseeApiException('$fallback (HTTP ${res.statusCode}): $preview');
    }
  }

  AiseeApiException _errorFromBody(
    Map<String, dynamic> map, {
    required String fallback,
  }) {
    return aiseeApiExceptionFromJsonMap(map, fallback);
  }
}
