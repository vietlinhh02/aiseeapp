import 'package:dio/dio.dart';
import 'package:retrofit/dio.dart';

import '../api/aisee_api_auth.dart';
import '../api/aisee_api_dio.dart';
import '../api/call_api.dart';
import '../models/aisee_api_models.dart';

class AiseeCallService {
  AiseeCallService({AiseeCallApiClient? apiClient, Dio? dio})
    : this._(dio: dio ?? AiseeApiDioFactory.create(), apiClient: apiClient);

  AiseeCallService._({required Dio dio, AiseeCallApiClient? apiClient})
    : _dio = dio,
      _ownsDio = apiClient == null,
      _apiClient = apiClient ?? AiseeCallApiClient(dio);

  final Dio _dio;
  final bool _ownsDio;
  final AiseeCallApiClient _apiClient;

  void close() {
    if (_ownsDio) {
      _dio.close(force: true);
    }
  }

  Future<({String roomName, String token})> createRoom(
    String accessToken,
    String calleeId,
    String callType,
  ) async {
    final HttpResponse<dynamic> res = await _apiClient.createRoom(
      AiseeApiAuth.bearer(accessToken),
      <String, dynamic>{'callee_id': calleeId, 'call_type': callType},
    );
    if (res.response.statusCode != 200) {
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
    final HttpResponse<dynamic> res = await _apiClient.endRoom(
      AiseeApiAuth.bearer(accessToken),
      <String, dynamic>{'room_name': roomName},
    );
    if (res.response.statusCode != 200) {
      throw _error(res, 'Không kết thúc được cuộc gọi');
    }
  }

  Object? _decodeJson(HttpResponse<dynamic> res, String fallback) {
    final dynamic data = res.data;
    if (data == null) {
      throw AiseeApiException('$fallback (phản hồi trống)');
    }
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    throw AiseeApiException(
      '$fallback (HTTP ${res.response.statusCode}): phản hồi không hợp lệ',
    );
  }

  AiseeApiException _error(HttpResponse<dynamic> res, String fallback) {
    final dynamic data = res.data;
    final Map<String, dynamic>? body = switch (data) {
      Map<String, dynamic> value => value,
      Map value => Map<String, dynamic>.from(value),
      _ => null,
    };
    final Map<String, dynamic>? error = body?['error'] as Map<String, dynamic>?;
    return AiseeApiException(
      error?['message'] as String? ?? body?['message'] as String? ?? fallback,
      code: error?['code'] as String?,
    );
  }
}
