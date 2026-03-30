import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_env.dart';
import '../models/aisee_api_models.dart';

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

  Future<void> register(String accessToken) async {
    final res = await _http.post(
      _uri('/api/v1/volunteers/register'),
      headers: _authHeaders(accessToken),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw _error(res, 'Khong dang ky tinh nguyen vien duoc');
    }
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
    if (res.statusCode != 200) {
      throw _error(res, 'Khong cap nhat trang thai duoc');
    }
  }
}
