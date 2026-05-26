import 'package:dio/dio.dart';
import 'package:retrofit/dio.dart';

import '../api/aisee_api_auth.dart';
import '../api/aisee_api_dio.dart';
import '../api/volunteer_api.dart';
import '../models/aisee_api_models.dart';
import '../models/aisee_volunteer_status.dart';

class AiseeVolunteerService {
  AiseeVolunteerService({AiseeVolunteerApiClient? apiClient, Dio? dio})
    : this._(dio: dio ?? AiseeApiDioFactory.create(), apiClient: apiClient);

  AiseeVolunteerService._({
    required Dio dio,
    AiseeVolunteerApiClient? apiClient,
  }) : _dio = dio,
       _ownsDio = apiClient == null,
       _apiClient = apiClient ?? AiseeVolunteerApiClient(dio);

  final Dio _dio;
  final bool _ownsDio;
  final AiseeVolunteerApiClient _apiClient;

  void close() {
    if (_ownsDio) {
      _dio.close(force: true);
    }
  }

  AiseeApiException _error(HttpResponse<dynamic> res, String fallback) {
    final int statusCode = res.response.statusCode ?? 0;
    final String prefix = 'HTTP $statusCode';
    try {
      final Map<String, dynamic>? decoded = _asMap(res.data);
      if (decoded == null) {
        return AiseeApiException('$prefix: $fallback');
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

  Map<String, dynamic>? _asMap(Object? data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return null;
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
    final HttpResponse<dynamic> res = await _apiClient.fetchStatus(
      AiseeApiAuth.bearer(accessToken),
    );
    if (res.response.statusCode != 200) {
      throw _error(res, 'Không tải được trạng thái tình nguyện viên');
    }
    final Map<String, dynamic>? decoded = _asMap(res.data);
    if (decoded == null) {
      throw AiseeApiException('Phản hồi trống');
    }
    return AiseeVolunteerStatus.fromJson(decoded);
  }

  Future<void> register(
    String accessToken, {
    List<String> languages = const <String>['vi'],
  }) async {
    final HttpResponse<dynamic> res = await _apiClient.register(
      AiseeApiAuth.bearer(accessToken),
      <String, dynamic>{'languages': languages},
    );
    final int statusCode = res.response.statusCode ?? 0;
    if (_registerOk(statusCode)) {
      return;
    }
    // Đã là tình nguyện viên — coi như thành công để đồng bộ UI.
    if (statusCode == 409) {
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
    final HttpResponse<dynamic> res = await _apiClient.setAvailability(
      AiseeApiAuth.bearer(accessToken),
      <String, dynamic>{'available': available},
    );
    final int statusCode = res.response.statusCode ?? 0;
    if (statusCode == 200 || statusCode == 204) {
      return;
    }
    throw _error(res, 'Không cập nhật trạng thái sẵn sàng được.');
  }
}
