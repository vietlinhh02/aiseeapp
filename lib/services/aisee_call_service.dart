import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_env.dart';
import '../models/aisee_api_models.dart';

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
    final Map<String, dynamic> map =
        jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    return (
      roomName: map['room_name'] as String,
      token: map['token'] as String,
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
}
