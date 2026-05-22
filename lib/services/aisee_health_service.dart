import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_env.dart';
import '../models/aisee_api_models.dart';
import '../utils/aisee_api_error_parse.dart';

class AiseeHealthService {
  AiseeHealthService({http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  final http.Client _http;

  void close() => _http.close();

  Uri _uri(String path) => Uri.parse('${AppEnv.apiBaseUrl}$path');

  Map<String, String> _authHeaders(String accessToken) => {
    'Authorization': 'Bearer $accessToken',
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': 'application/json',
  };

  Future<void> markMedicationTaken(
    String accessToken,
    Map<String, dynamic> data,
  ) async {
    final http.Response res = await _http.post(
      _uri('/api/v1/health/medication/taken'),
      headers: _authHeaders(accessToken),
      body: jsonEncode(data),
    );
    if (res.statusCode != 200) {
      throw _error(res, 'Không ghi nhận uống thuốc được');
    }
  }

  Future<void> markMedicationSkipped(
    String accessToken,
    Map<String, dynamic> data,
  ) async {
    final http.Response res = await _http.post(
      _uri('/api/v1/health/medication/skipped'),
      headers: _authHeaders(accessToken),
      body: jsonEncode(data),
    );
    if (res.statusCode != 200) {
      throw _error(res, 'Không ghi nhận bỏ thuốc được');
    }
  }

  Future<void> logSymptom(String accessToken, Map<String, dynamic> data) async {
    final http.Response res = await _http.post(
      _uri('/api/v1/health/symptoms'),
      headers: _authHeaders(accessToken),
      body: jsonEncode(data),
    );
    if (res.statusCode != 200) {
      throw _error(res, 'Không ghi triệu chứng được');
    }
  }

  Future<void> logMetric(String accessToken, Map<String, dynamic> data) async {
    final http.Response res = await _http.post(
      _uri('/api/v1/health/metrics'),
      headers: _authHeaders(accessToken),
      body: jsonEncode(data),
    );
    if (res.statusCode != 200) {
      throw _error(res, 'Không ghi chỉ số sức khoẻ được');
    }
  }

  Future<Map<String, dynamic>> sendEmergencyAlert(
    String accessToken,
    Map<String, dynamic> data,
  ) async {
    final http.Response res = await _http.post(
      _uri('/api/v1/emergency/alert'),
      headers: _authHeaders(accessToken),
      body: jsonEncode(data),
    );
    if (res.statusCode != 200) {
      throw _error(res, 'Không gửi được cảnh báo khẩn cấp');
    }
    final String raw = utf8.decode(res.bodyBytes).trim();
    if (raw.isEmpty) return <String, dynamic>{};
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return <String, dynamic>{};
  }

  Future<void> rateVolunteer(
    String accessToken,
    Map<String, dynamic> data,
  ) async {
    final http.Response res = await _http.post(
      _uri('/api/v1/volunteers/rate'),
      headers: _authHeaders(accessToken),
      body: jsonEncode(data),
    );
    if (res.statusCode != 200) {
      throw _error(res, 'Không đánh giá được tình nguyện viên');
    }
  }

  /// GET /api/v1/me/medications
  /// Response: {medications: [{medication: {...}, taken, skipped}], count}
  /// Returns flattened list: [{id, name, dosage, times, frequency,
  ///   active, taken, skipped, created_at}]
  Future<List<Map<String, dynamic>>> fetchMedications(
    String accessToken,
  ) async {
    final http.Response res = await _http.get(
      _uri('/api/v1/me/medications'),
      headers: _authHeaders(accessToken),
    );
    if (res.statusCode != 200) {
      throw _error(res, 'Không tải được lịch thuốc');
    }
    final Map<String, dynamic> body = _decodeMap(res);
    final List<dynamic> items =
        body['medications'] as List<dynamic>? ?? <dynamic>[];
    return items.map((dynamic e) {
      final Map<String, dynamic> entry = e as Map<String, dynamic>;
      final Map<String, dynamic> med =
          entry['medication'] as Map<String, dynamic>? ?? <String, dynamic>{};
      return <String, dynamic>{
        ...med,
        'taken': entry['taken'] ?? false,
        'skipped': entry['skipped'] ?? false,
      };
    }).toList();
  }

  /// GET /api/v1/me/appointments
  /// Response: {appointments: [{id, title, location, datetime,
  ///   notes, ...}], count}
  Future<List<Map<String, dynamic>>> fetchAppointments(
    String accessToken,
  ) async {
    final http.Response res = await _http.get(
      _uri('/api/v1/me/appointments'),
      headers: _authHeaders(accessToken),
    );
    if (res.statusCode != 200) {
      throw _error(res, 'Không tải được lịch hẹn');
    }
    final Map<String, dynamic> body = _decodeMap(res);
    final List<dynamic> items =
        body['appointments'] as List<dynamic>? ?? <dynamic>[];
    return items.cast<Map<String, dynamic>>();
  }

  /// GET /api/v1/me/health
  /// Response: {medications: [...], recent_symptoms: [...],
  ///   recent_metrics: [...]}
  /// Returns merged list with a `_kind` field (symptom / metric).
  Future<List<Map<String, dynamic>>> fetchHealthLogs(String accessToken) async {
    final http.Response res = await _http.get(
      _uri('/api/v1/me/health'),
      headers: _authHeaders(accessToken),
    );
    if (res.statusCode != 200) {
      throw _error(res, 'Không tải được nhật ký sức khỏe');
    }
    final Map<String, dynamic> body = _decodeMap(res);
    final List<Map<String, dynamic>> result = <Map<String, dynamic>>[];
    final List<dynamic> symptoms =
        body['recent_symptoms'] as List<dynamic>? ?? <dynamic>[];
    for (final dynamic s in symptoms) {
      final Map<String, dynamic> m = s as Map<String, dynamic>;
      result.add(<String, dynamic>{...m, '_kind': 'symptom'});
    }
    final List<dynamic> metrics =
        body['recent_metrics'] as List<dynamic>? ?? <dynamic>[];
    for (final dynamic s in metrics) {
      final Map<String, dynamic> m = s as Map<String, dynamic>;
      result.add(<String, dynamic>{...m, '_kind': 'metric'});
    }
    return result;
  }

  Map<String, dynamic> _decodeMap(http.Response res) {
    final String raw = utf8.decode(res.bodyBytes).trim();
    if (raw.isEmpty) return <String, dynamic>{};
    final Object? decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    return <String, dynamic>{};
  }

  AiseeApiException _error(http.Response res, String fallback) {
    return aiseeApiExceptionFromResponse(res, fallback);
  }
}
