import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_env.dart';
import '../models/aisee_api_models.dart';
import '../models/aisee_family_member.dart';

class AiseeFamilyService {
  AiseeFamilyService({http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  final http.Client _http;

  void close() => _http.close();

  Uri _uri(String path) => Uri.parse('${AppEnv.apiBaseUrl}$path');

  Map<String, String> _authHeaders(String accessToken) => {
    'Authorization': 'Bearer $accessToken',
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': 'application/json',
  };

  Future<List<AiseeFamilyMember>> fetchFamily(String accessToken) async {
    final http.Response res = await _http.get(
      _uri('/api/v1/users/me/family'),
      headers: _authHeaders(accessToken),
    );
    if (res.statusCode != 200) {
      throw _error(res, 'Không tải được danh sách người thân');
    }
    final Object? decoded = _decodeJson(
      res,
      'Không tải được danh sách người thân',
    );
    if (decoded is! List) {
      throw AiseeApiException('Phản hồi không hợp lệ (không phải danh sách)');
    }
    return decoded
        .cast<Map<String, dynamic>>()
        .map(AiseeFamilyMember.fromJson)
        .toList();
  }

  Future<String> createInvite(
    String accessToken,
    String relationship,
  ) async {
    final http.Response res = await _http.post(
      _uri('/api/v1/users/family-link'),
      headers: _authHeaders(accessToken),
      body: jsonEncode({'relationship': relationship}),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw _error(res, 'Không tạo được mã mời');
    }
    final Object? decoded = _decodeJson(res, 'Không tạo được mã mời');
    if (decoded is! Map<String, dynamic>) {
      throw AiseeApiException('Phản hồi không hợp lệ');
    }
    final Object? code = decoded['invite_code'];
    if (code is! String || code.isEmpty) {
      throw AiseeApiException('Phản hồi thiếu invite_code');
    }
    return code;
  }

  Future<void> joinFamily(String accessToken, String inviteCode) async {
    final http.Response res = await _http.post(
      _uri('/api/v1/users/join-family'),
      headers: _authHeaders(accessToken),
      body: jsonEncode({'invite_code': inviteCode}),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw _error(res, 'Không tham gia được gia đình');
    }
    // Backend có thể trả {"status":"joined"} — không bắt buộc parse cho luồng UI.
  }

  Future<void> deleteLink(String accessToken, String linkId) async {
    final http.Response res = await _http.delete(
      _uri('/api/v1/users/family-link/$linkId'),
      headers: _authHeaders(accessToken),
    );
    if (res.statusCode != 200) {
      throw _error(res, 'Không xoá được liên kết');
    }
  }

  Future<void> updateProfile(
    String accessToken,
    Map<String, dynamic> fields,
  ) async {
    final http.Response res = await _http.put(
      _uri('/api/v1/users/me'),
      headers: _authHeaders(accessToken),
      body: jsonEncode(fields),
    );
    if (res.statusCode != 200) {
      throw _error(res, 'Không cập nhật được hồ sơ');
    }
  }

  Object? _decodeJson(http.Response res, String fallback) {
    final String raw = utf8.decode(res.bodyBytes).trim();
    if (raw.isEmpty) {
      throw AiseeApiException('$fallback (phản hồi trống)');
    }
    try {
      return jsonDecode(raw);
    } on FormatException {
      final String preview =
          raw.length > 80 ? '${raw.substring(0, 80)}…' : raw;
      throw AiseeApiException(
        '$fallback (HTTP ${res.statusCode}): $preview',
      );
    }
  }

  AiseeApiException _error(http.Response res, String fallback) {
    final String prefix = 'HTTP ${res.statusCode}';
    try {
      final String raw = utf8.decode(res.bodyBytes).trim();
      if (raw.isEmpty) {
        return AiseeApiException('$prefix: $fallback');
      }
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return AiseeApiException(
          raw.length > 120 ? '$prefix: ${raw.substring(0, 120)}…' : '$prefix: $raw',
        );
      }
      final String? extracted = _extractApiErrorMessage(decoded);
      final String? errCode = _extractApiErrorCode(decoded);
      return AiseeApiException(
        extracted != null && extracted.isNotEmpty
            ? '$prefix: $extracted'
            : '$prefix: $fallback',
        code: errCode,
      );
    } catch (_) {
      return AiseeApiException('$prefix: $fallback');
    }
  }

  /// Gin/Go thường trả `{"error":"..."}` — phải đưa vào message, không chỉ `code`.
  static String? _extractApiErrorMessage(Map<String, dynamic> map) {
    final Object? msg = map['message'];
    if (msg is String && msg.isNotEmpty) return msg;

    final Object? err = map['error'];
    if (err is String && err.isNotEmpty) return err;
    if (err is Map<String, dynamic>) {
      final m = err['message'] as String?;
      if (m != null && m.isNotEmpty) return m;
    }

    final Object? detail = map['detail'];
    if (detail is String && detail.isNotEmpty) return detail;
    if (detail is List && detail.isNotEmpty) {
      final Object? first = detail.first;
      if (first is Map<String, dynamic>) {
        final m = first['msg'] as String? ?? first['message'] as String?;
        if (m != null && m.isNotEmpty) return m;
      }
    }
    return null;
  }

  static String? _extractApiErrorCode(Map<String, dynamic> map) {
    final Object? c = map['code'];
    if (c is String && c.isNotEmpty) return c;
    final Object? err = map['error'];
    if (err is Map<String, dynamic>) {
      final x = err['code'] as String?;
      if (x != null && x.isNotEmpty) return x;
    }
    return null;
  }
}
