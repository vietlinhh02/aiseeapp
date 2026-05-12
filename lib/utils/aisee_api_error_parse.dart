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
      return aiseeApiExceptionFromJsonMap(decoded, fallback);
    }
  } catch (_) {}
  return AiseeApiException(fallback);
}
