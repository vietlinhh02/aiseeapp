import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:retrofit/dio.dart';

import '../api/aisee_api_auth.dart';
import '../api/aisee_api_dio.dart';
import '../api/auth_api.dart';
import '../models/aisee_api_models.dart';

class AiseeAuthService {
  AiseeAuthService({AiseeAuthApiClient? apiClient, Dio? dio})
    : this._(dio: dio ?? AiseeApiDioFactory.create(), apiClient: apiClient);

  AiseeAuthService._({required Dio dio, AiseeAuthApiClient? apiClient})
    : _dio = dio,
      _ownsDio = apiClient == null,
      _apiClient = apiClient ?? AiseeAuthApiClient(dio);

  final Dio _dio;
  final bool _ownsDio;
  final AiseeAuthApiClient _apiClient;

  void close() {
    if (_ownsDio) {
      _dio.close(force: true);
    }
  }

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
    final HttpResponse<dynamic> res = await _apiClient.signInWithGoogle(
      <String, dynamic>{'id_token': idToken, 'role': role},
    );
    final Map<String, dynamic> map = _parseJsonBody(
      res,
      fallback: 'Đăng nhập máy chủ thất bại',
    );
    if (res.response.statusCode != 200) {
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
    final HttpResponse<dynamic> res = await _apiClient.fetchCurrentUser(
      AiseeApiAuth.bearer(accessToken),
    );
    final Map<String, dynamic> map = _parseJsonBody(
      res,
      fallback: 'Không tải được hồ sơ',
    );
    if (res.response.statusCode != 200) {
      throw _errorFromBody(map, fallback: 'Không tải được hồ sơ');
    }
    return AiseeUserProfile.fromJson(_unwrapPayload(map));
  }

  Future<AiseeAuthTokens> refreshTokens(String refreshToken) async {
    final HttpResponse<dynamic> res = await _apiClient.refreshTokens(
      <String, dynamic>{'refresh_token': refreshToken},
    );
    final Map<String, dynamic> map = _parseJsonBody(
      res,
      fallback: 'Phiên hết hạn, vui lòng đăng nhập lại',
    );
    if (res.response.statusCode != 200) {
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
    HttpResponse<dynamic> res = await _apiClient.fetchCurrentUser(
      AiseeApiAuth.bearer(access),
    );
    if (res.response.statusCode == 401) {
      developer.log(
        'resumeSession: access token expired, attempting refresh',
        name: 'AiSeeAuth',
      );
      try {
        final AiseeAuthTokens rotated = await refreshTokens(refresh);
        access = rotated.accessToken;
        refresh = rotated.refreshToken;
        developer.log('resumeSession: refresh succeeded', name: 'AiSeeAuth');
        res = await _apiClient.fetchCurrentUser(AiseeApiAuth.bearer(access));
      } catch (_) {
        developer.log('resumeSession: refresh failed', name: 'AiSeeAuth');
        return null;
      }
    }
    if (res.response.statusCode != 200) {
      return null;
    }
    Map<String, dynamic> map;
    try {
      map = _parseJsonBody(res, fallback: 'Không tải được hồ sơ');
    } catch (_) {
      return null;
    }
    final AiseeUserProfile profile = AiseeUserProfile.fromJson(
      _unwrapPayload(map),
    );
    return (
      profile: profile,
      tokens: AiseeAuthTokens(accessToken: access, refreshToken: refresh),
    );
  }

  /// Parse response body as JSON map. Throws [AiseeApiException] with
  /// [fallback] if body is empty or not valid JSON (e.g. `404 page not found`).
  Map<String, dynamic> _parseJsonBody(
    HttpResponse<dynamic> res, {
    required String fallback,
  }) {
    final dynamic data = res.data;
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    if (data == null) {
      throw AiseeApiException(
        '$fallback (HTTP ${res.response.statusCode}, phản hồi trống)',
      );
    }
    throw AiseeApiException(
      '$fallback (HTTP ${res.response.statusCode}, phản hồi không phải JSON object)',
    );
  }

  AiseeApiException _errorFromBody(
    Map<String, dynamic> map, {
    required String fallback,
  }) {
    final Map<String, dynamic>? error = map['error'] as Map<String, dynamic>?;
    if (error != null) {
      return AiseeApiException(
        error['message'] as String? ?? fallback,
        code: error['code'] as String?,
      );
    }
    return AiseeApiException(map['message'] as String? ?? fallback);
  }
}
