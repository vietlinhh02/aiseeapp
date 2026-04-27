import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_env.dart';
import '../models/aisee_api_models.dart';
import '../models/aisee_billing_models.dart';

class AiseeBillingService {
  AiseeBillingService({http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  final http.Client _http;

  void close() => _http.close();

  Uri _uri(String path) => Uri.parse('${AppEnv.apiBaseUrl}$path');

  Future<AiseeBillingOverview> fetchBillingOverview(String accessToken) async {
    final http.Response res = await _http.get(
      _uri('/api/v1/me/billing-overview'),
      headers: <String, String>{
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      },
    );
    final Map<String, dynamic> body = _parseJsonBody(
      res,
      fallback: 'Không tải được thông tin gói',
    );
    if (res.statusCode != 200) {
      throw _errorFromBody(body, fallback: 'Không tải được thông tin gói');
    }
    return AiseeBillingOverview.fromJson(body);
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
    final Object? errObj = map['error'];
    if (errObj is Map<String, dynamic>) {
      final String? msg = errObj['message'] as String?;
      final String? code = errObj['code'] as String?;
      return AiseeApiException(msg ?? fallback, code: code);
    }
    final String? msg = map['message'] as String?;
    final String? code = errObj is String ? errObj : null;
    return AiseeApiException(msg ?? fallback, code: code);
  }
}
