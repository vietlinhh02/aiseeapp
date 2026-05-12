import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_env.dart';
import '../models/aisee_api_models.dart';
import '../utils/aisee_api_error_parse.dart';

class AiseeCallService {
  AiseeCallService({http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  final http.Client _http;

  void close() => _http.close();

  Uri _uri(String path) => Uri.parse('${AppEnv.apiBaseUrl}$path');

  Map<String, String> _authHeaders(String accessToken) => {
    'Authorization': 'Bearer $accessToken',
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': 'application/json',
  };

  Future<({String roomName, String token})> createRoom(
    String accessToken,
    String calleeId,
    String callType,
  ) async {
    final http.Response res = await _http.post(
      _uri('/api/v1/calls/create-room'),
      headers: _authHeaders(accessToken),
      body: jsonEncode({
        'callee_id': calleeId,
        'call_type': callType,
      }),
    );
    if (res.statusCode != 200) {
      throw _error(res, 'Không tạo được cuộc gọi');
    }
    final Object? decoded = _decodeJson(res, 'Không tạo được cuộc gọi');
    if (decoded is! Map<String, dynamic>) {
      throw AiseeApiException('Phản hồi không hợp lệ');
    }
    return (
      roomName: decoded['room_name'] as String,
      token: decoded['token'] as String,
    );
  }

  Future<void> endRoom(String accessToken, String roomName) async {
    final http.Response res = await _http.post(
      _uri('/api/v1/calls/end-room'),
      headers: _authHeaders(accessToken),
      body: jsonEncode({'room_name': roomName}),
    );
    if (res.statusCode != 200) {
      throw _error(res, 'Không kết thúc được cuộc gọi');
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
    return aiseeApiExceptionFromResponse(res, fallback);
  }
}
