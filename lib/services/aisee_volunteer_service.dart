import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_env.dart';
import '../models/aisee_api_models.dart';
import '../models/aisee_volunteer_status.dart';

class AiseeVolunteerService {
  AiseeVolunteerService({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final http.Client _http;
  void close() => _http.close();

  Uri _uri(String path) => Uri.parse('${AppEnv.apiBaseUrl}$path');

  Map<String, String> _authHeaders(String accessToken) => {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json',
      };

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
          raw.length > 160 ? '$prefix: ${raw.substring(0, 160)}…' : '$prefix: $raw',
        );
      }
      final String? extracted = _extractErrorMessage(decoded);
      final String? code = _extractErrorCode(decoded);
      return AiseeApiException(
        extracted != null && extracted.isNotEmpty
            ? '$prefix: $extracted'
            : '$prefix: $fallback',
        code: code,
      );
    } catch (_) {
      return AiseeApiException('$prefix: $fallback');
    }
  }

  /// Thông điệp lỗi — hỗ trợ nhiều kiểu JSON (Gin, chi tiết chuỗi, v.v.).
  static String? _extractErrorMessage(Map<String, dynamic> map) {
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

  static String? _extractErrorCode(Map<String, dynamic> map) {
    final Object? err = map['error'];
    if (err is String) return err;
    if (err is Map<String, dynamic>) {
      final c = err['code'] as String?;
      if (c != null && c.isNotEmpty) return c;
    }
    return null;
  }

  static bool _registerOk(int code) =>
      code == 200 || code == 201 || code == 202 || code == 204;

  /// Trạng thái đăng ký + `available` từ server (sau khi đăng nhập lại vẫn đúng).
  Future<AiseeVolunteerStatus> fetchStatus(String accessToken) async {
    final http.Response res = await _http.get(
      _uri('/api/v1/volunteers/status'),
      headers: _authHeaders(accessToken),
    );
    if (res.statusCode != 200) {
      throw _error(res, 'Không tải được trạng thái tình nguyện viên');
    }
    final String raw = utf8.decode(res.bodyBytes).trim();
    if (raw.isEmpty) {
      throw AiseeApiException('Phản hồi trống');
    }
    final Object? decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw AiseeApiException('Phản hồi không hợp lệ');
    }
    return AiseeVolunteerStatus.fromJson(decoded);
  }

  Future<void> register(
    String accessToken, {
    List<String> languages = const <String>['vi'],
  }) async {
    final res = await _http.post(
      _uri('/api/v1/volunteers/register'),
      headers: _authHeaders(accessToken),
      body: jsonEncode(<String, dynamic>{'languages': languages}),
    );
    if (_registerOk(res.statusCode)) {
      return;
    }
    // Đã là tình nguyện viên — coi như thành công để đồng bộ UI.
    if (res.statusCode == 409) {
      return;
    }
    throw _error(
      res,
      'Không đăng ký tình nguyện viên được. Kiểm tra quyền tài khoản và BACKEND_URL.',
    );
  }

  Future<void> setAvailability(
    String accessToken, {
    required bool available,
  }) async {
    final res = await _http.put(
      _uri('/api/v1/volunteers/availability'),
      headers: _authHeaders(accessToken),
      body: jsonEncode({'available': available}),
    );
    if (res.statusCode == 200 || res.statusCode == 204) {
      return;
    }
    throw _error(
      res,
      'Không cập nhật trạng thái sẵn sàng được.',
    );
  }
}
