import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_env.dart';
import '../models/aisee_api_models.dart';

class AiseeAuthService {
  AiseeAuthService({http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  final http.Client _http;

  void close() => _http.close();

  Uri _uri(String path) => Uri.parse('${AppEnv.apiBaseUrl}$path');

  /// Go backend trả JSON trần; docs cũ bọc trong `data` — hỗ trợ cả hai.
  Map<String, dynamic> _unwrapPayload(Map<String, dynamic> map) {
    final Object? data = map['data'];
    if (data is Map<String, dynamic>) return data;
    return map;
  }

  AiseeAuthTokens _parseTokenPair(Map<String, dynamic> map) {
    final Map<String, dynamic> p = _unwrapPayload(map);
    final Object? access = p['access_token'];
    final Object? refresh = p['refresh_token'];
    if (access is! String || refresh is! String) {
      throw AiseeApiException('Phản hồi máy chủ không hợp lệ (thiếu token)');
    }
    return AiseeAuthTokens(accessToken: access, refreshToken: refresh);
  }

  Future<AiseeAuthTokens> signInWithGoogle(
    String idToken, {
    String role = 'user',
  }) async {
    final http.Response res = await _http.post(
      _uri('/api/v1/auth/google'),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode({'id_token': idToken, 'role': role}),
    );
    final Map<String, dynamic> map =
        jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw _errorFromBody(map, fallback: 'Đăng nhập máy chủ thất bại');
    }
    final AiseeAuthTokens tokens = _parseTokenPair(map);
    final Map<String, dynamic> p = _unwrapPayload(map);
    final Object? userObj = p['user'];
    if (userObj is Map<String, dynamic>) {
      AiseeUserBrief.fromJson(userObj);
    }
    return tokens;
  }

  Future<AiseeUserProfile> fetchCurrentUser(String accessToken) async {
    final http.Response res = await _http.get(
      _uri('/api/v1/users/me'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      },
    );
    final Map<String, dynamic> map =
        jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw _errorFromBody(map, fallback: 'Không tải được hồ sơ');
    }
    return AiseeUserProfile.fromJson(_unwrapPayload(map));
  }

  Future<AiseeAuthTokens> refreshTokens(String refreshToken) async {
    final http.Response res = await _http.post(
      _uri('/api/v1/auth/refresh'),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode({'refresh_token': refreshToken}),
    );
    final Map<String, dynamic> map =
        jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw _errorFromBody(
        map,
        fallback: 'Phiên hết hạn, vui lòng đăng nhập lại',
      );
    }
    return _parseTokenPair(map);
  }

  /// Khôi phục phiên từ token đã lưu. Trả về `null` nếu không còn hợp lệ.
  Future<({AiseeUserProfile profile, AiseeAuthTokens tokens})?> resumeSession(
    AiseeAuthTokens initial,
  ) async {
    String access = initial.accessToken;
    String refresh = initial.refreshToken;
    http.Response res = await _http.get(
      _uri('/api/v1/users/me'),
      headers: {
        'Authorization': 'Bearer $access',
        'Accept': 'application/json',
      },
    );
    if (res.statusCode == 401) {
      try {
        final AiseeAuthTokens rotated = await refreshTokens(refresh);
        access = rotated.accessToken;
        refresh = rotated.refreshToken;
        res = await _http.get(
          _uri('/api/v1/users/me'),
          headers: {
            'Authorization': 'Bearer $access',
            'Accept': 'application/json',
          },
        );
      } catch (_) {
        return null;
      }
    }
    if (res.statusCode != 200) {
      return null;
    }
    final Map<String, dynamic> map =
        jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final AiseeUserProfile profile = AiseeUserProfile.fromJson(
      _unwrapPayload(map),
    );
    return (
      profile: profile,
      tokens: AiseeAuthTokens(accessToken: access, refreshToken: refresh),
    );
  }

  AiseeApiException _errorFromBody(
    Map<String, dynamic> map, {
    required String fallback,
  }) {
    final Object? errObj = map['error'];
    if (errObj is Map<String, dynamic>) {
      final String? msg = errObj['message'] as String?;
      final String? code = errObj['code'] as String?;
      return AiseeApiException(msg ?? fallback, code: code);
    }
    return AiseeApiException(fallback);
  }
}
