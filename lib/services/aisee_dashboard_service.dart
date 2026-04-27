import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_env.dart';
import '../models/aisee_api_models.dart';
import '../models/aisee_dashboard_models.dart';

class AiseeDashboardService {
  AiseeDashboardService({http.Client? httpClient})
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
    try {
      final Map<String, dynamic> map =
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final String? msg = map['message'] as String?;
      final String? code = map['error'] as String?;
      return AiseeApiException(msg ?? fallback, code: code);
    } catch (_) {
      return AiseeApiException(fallback);
    }
  }

  Future<DashboardHealth> getHealth(String accessToken, String userId) async {
    final res = await _http.get(
      _uri('/api/v1/dashboard/$userId/health'),
      headers: _authHeaders(accessToken),
    );
    if (res.statusCode != 200) {
      throw _error(res, 'Không tải được dữ liệu sức khỏe');
    }
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    return DashboardHealth.fromJson(body);
  }

  Future<List<MedStatus>> getMedications(
    String accessToken,
    String userId,
  ) async {
    final res = await _http.get(
      _uri('/api/v1/dashboard/$userId/medications'),
      headers: _authHeaders(accessToken),
    );
    if (res.statusCode != 200) {
      throw _error(res, 'Không tải được danh sách thuốc');
    }
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final list = body['medications'] as List<dynamic>? ?? [];
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
    final res = await _http.post(
      _uri('/api/v1/dashboard/$userId/medications'),
      headers: _authHeaders(accessToken),
      body: jsonEncode({
        'name': name,
        'dosage': dosage,
        'times': times,
        'frequency': frequency,
      }),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw _error(res, 'Không thêm được thuốc');
    }
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    return DashboardMedication.fromJson(body);
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
    final res = await _http.put(
      _uri('/api/v1/dashboard/$userId/medications/$medId'),
      headers: _authHeaders(accessToken),
      body: jsonEncode({
        'name': name,
        'dosage': dosage,
        'times': times,
        'frequency': frequency,
      }),
    );
    if (res.statusCode != 200) {
      throw _error(res, 'Không cập nhật được thuốc');
    }
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    return DashboardMedication.fromJson(body);
  }

  Future<void> deleteMedication(
    String accessToken,
    String userId,
    String medId,
  ) async {
    final res = await _http.delete(
      _uri('/api/v1/dashboard/$userId/medications/$medId'),
      headers: _authHeaders(accessToken),
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw _error(res, 'Không xóa được thuốc');
    }
  }

  Future<List<AuditLogEntry>> getAuditLog(
    String accessToken,
    String userId, {
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _http.get(
      _uri(
        '/api/v1/dashboard/$userId/audit-log'
        '?page=$page&limit=$limit',
      ),
      headers: _authHeaders(accessToken),
    );
    if (res.statusCode != 200) {
      throw _error(res, 'Không tải được lịch sử hoạt động');
    }
    final list = jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
    return list
        .map((e) => AuditLogEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<UserLocation> getLocation(String accessToken, String userId) async {
    final res = await _http.get(
      _uri('/api/v1/dashboard/$userId/location'),
      headers: _authHeaders(accessToken),
    );
    if (res.statusCode != 200) {
      throw _error(res, 'Không tải được vị trí');
    }
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    return UserLocation.fromJson(body);
  }
}
