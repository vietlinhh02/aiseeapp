import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/aisee_api_models.dart';

/// Khớp `pkg/response.Err`: `{"error":{"code","message"}}`.
/// Hỗ trợ thêm `{"error":"code_string","message":"..."}`.
AiseeApiException aiseeApiExceptionFromJsonMap(
  Map<String, dynamic> map,
  String fallback,
) {
  final Object? errObj = map['error'];
  if (errObj is Map<String, dynamic>) {
    final String? msg = errObj['message'] as String?;
    final String? code = errObj['code'] as String?;
    return AiseeApiException(msg ?? fallback, code: code);
  }
  final String? msg = map['message'] as String?;
  final String? code = errObj is String ? errObj : null;
  if (msg != null && msg.isNotEmpty) {
    return AiseeApiException(msg, code: code);
  }
  return AiseeApiException(fallback);
}

AiseeApiException aiseeApiExceptionFromResponse(
  http.Response res,
  String fallback,
) {
  try {
    final Object? decoded = jsonDecode(utf8.decode(res.bodyBytes));
    if (decoded is Map<String, dynamic>) {
      if (res.statusCode == 402) {
        final AiseeQuotaApiException? quota = aiseeQuotaExceptionFromJsonMap(
          decoded,
        );
        if (quota != null) {
          return quota;
        }
      }
      return aiseeApiExceptionFromJsonMap(decoded, fallback);
    }
  } catch (_) {}
  return AiseeApiException(fallback);
}

AiseeQuotaApiException? aiseeQuotaExceptionFromJsonMap(
  Map<String, dynamic> map,
) {
  final Object? errObj = map['error'];
  if (errObj is! Map<String, dynamic>) {
    return null;
  }
  final String? usageType = errObj['usage_type'] as String?;
  if (usageType == null && errObj['code'] != 'quota_exceeded') {
    return null;
  }
  final String msg = errObj['message'] as String? ?? 'Quota exceeded';
  final String? code = errObj['code'] as String?;
  return AiseeQuotaApiException(
    msg,
    code: code,
    usageType: usageType,
    requiredAmount: (errObj['required'] as num?)?.toDouble(),
    remaining: (errObj['remaining'] as num?)?.toDouble(),
    planCode: errObj['plan_code'] as String?,
    resetPeriod: errObj['reset_period'] as String?,
  );
}
