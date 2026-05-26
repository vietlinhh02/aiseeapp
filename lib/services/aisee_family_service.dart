import 'package:dio/dio.dart';
import 'package:retrofit/dio.dart';

import '../api/aisee_api_auth.dart';
import '../api/aisee_api_dio.dart';
import '../api/family_api.dart';
import '../models/aisee_api_models.dart';
import '../models/aisee_family_member.dart';
import '../models/aisee_family_group.dart';

class AiseeFamilyService {
  AiseeFamilyService({AiseeFamilyApiClient? apiClient, Dio? dio})
    : this._(dio: dio ?? AiseeApiDioFactory.create(), apiClient: apiClient);

  AiseeFamilyService._({required Dio dio, AiseeFamilyApiClient? apiClient})
    : _dio = dio,
      _ownsDio = apiClient == null,
      _apiClient = apiClient ?? AiseeFamilyApiClient(dio);

  final Dio _dio;
  final bool _ownsDio;
  final AiseeFamilyApiClient _apiClient;

  void close() {
    if (_ownsDio) {
      _dio.close(force: true);
    }
  }

  Future<List<AiseeFamilyMember>> fetchFamily(String accessToken) async {
    final HttpResponse<dynamic> res = await _apiClient.fetchFamily(
      AiseeApiAuth.bearer(accessToken),
    );
    if (res.response.statusCode != 200) {
      throw _error(res, 'Không tải được danh sách người thân');
    }
    final Object? decoded = _decodeJson(
      res,
      'Không tải được danh sách người thân',
    );
    if (decoded is! List) {
      throw AiseeApiException('Phản hồi không hợp lệ (không phải danh sách)');
    }
    return decoded
        .cast<Map<String, dynamic>>()
        .map(AiseeFamilyMember.fromJson)
        .toList();
  }

  Future<String> createInvite(String accessToken, String relationship) async {
    final HttpResponse<dynamic> res = await _apiClient.createInvite(
      AiseeApiAuth.bearer(accessToken),
      <String, dynamic>{'relationship': relationship},
    );
    if (res.response.statusCode != 200 && res.response.statusCode != 201) {
      throw _error(res, 'Không tạo được mã mời');
    }
    final Object? decoded = _decodeJson(res, 'Không tạo được mã mời');
    if (decoded is! Map<String, dynamic>) {
      throw AiseeApiException('Phản hồi không hợp lệ');
    }
    final Object? code = decoded['invite_code'];
    if (code is! String || code.isEmpty) {
      throw AiseeApiException('Phản hồi thiếu invite_code');
    }
    return code;
  }

  Future<AiseeCurrentGroup?> fetchCurrentGroup(String accessToken) async {
    final HttpResponse<dynamic> res = await _apiClient.fetchCurrentGroup(
      AiseeApiAuth.bearer(accessToken),
    );
    if (res.response.statusCode == 404) {
      final AiseeApiException error = _error(
        res,
        'Không tải được nhóm chăm sóc',
      );
      if (error.code == 'no_active_group') {
        return null;
      }
    }
    if (res.response.statusCode != 200) {
      throw _error(res, 'Không tải được nhóm chăm sóc');
    }
    final Object? decoded = _decodeJson(res, 'Không tải được nhóm chăm sóc');
    if (decoded is! Map<String, dynamic>) {
      throw AiseeApiException('Phản hồi nhóm chăm sóc không hợp lệ');
    }
    return AiseeCurrentGroup.fromJson(decoded);
  }

  Future<void> joinFamily(String accessToken, String inviteCode) async {
    final HttpResponse<dynamic> res = await _apiClient.joinFamily(
      AiseeApiAuth.bearer(accessToken),
      <String, dynamic>{'invite_code': inviteCode},
    );
    if (res.response.statusCode != 200 && res.response.statusCode != 201) {
      throw _error(res, 'Không tham gia được gia đình');
    }
    // Backend có thể trả {"status":"joined"} — không bắt buộc parse cho luồng UI.
  }

  Future<void> revokeInvite(String accessToken, String inviteCode) async {
    final HttpResponse<dynamic> res = await _apiClient.revokeInvite(
      AiseeApiAuth.bearer(accessToken),
      inviteCode,
    );
    if (res.response.statusCode != 200) {
      throw _error(res, 'Không thu hồi được mã mời');
    }
  }

  Future<void> leaveGroup(String accessToken) async {
    final HttpResponse<dynamic> res = await _apiClient.leaveGroup(
      AiseeApiAuth.bearer(accessToken),
      <String, dynamic>{},
    );
    if (res.response.statusCode != 200) {
      throw _error(res, 'Không rời được nhóm chăm sóc');
    }
  }

  Future<void> transferGroupOwnership(
    String accessToken,
    String targetUserId,
  ) async {
    final HttpResponse<dynamic> res = await _apiClient.transferGroupOwnership(
      AiseeApiAuth.bearer(accessToken),
      <String, dynamic>{'target_user_id': targetUserId},
    );
    if (res.response.statusCode != 200) {
      throw _error(res, 'Không chuyển được quyền chủ nhóm');
    }
  }

  Future<void> deleteLink(String accessToken, String linkId) async {
    final HttpResponse<dynamic> res = await _apiClient.deleteLink(
      AiseeApiAuth.bearer(accessToken),
      linkId,
    );
    if (res.response.statusCode != 200) {
      throw _error(res, 'Không xoá được liên kết');
    }
  }

  Future<void> updateProfile(
    String accessToken,
    Map<String, dynamic> fields,
  ) async {
    final HttpResponse<dynamic> res = await _apiClient.updateProfile(
      AiseeApiAuth.bearer(accessToken),
      fields,
    );
    if (res.response.statusCode != 200) {
      throw _error(res, 'Không cập nhật được hồ sơ');
    }
  }

  Object? _decodeJson(HttpResponse<dynamic> res, String fallback) {
    final dynamic data = res.data;
    if (data == null) {
      throw AiseeApiException('$fallback (phản hồi trống)');
    }
    if (data is Map<String, dynamic> || data is List) {
      return data;
    }
    if (data is Map) return Map<String, dynamic>.from(data);
    throw AiseeApiException(
      '$fallback (HTTP ${res.response.statusCode}): phản hồi không hợp lệ',
    );
  }

  AiseeApiException _error(HttpResponse<dynamic> res, String fallback) {
    final dynamic decoded = res.data;
    final Map<String, dynamic>? body = switch (decoded) {
      Map<String, dynamic> value => value,
      Map value => Map<String, dynamic>.from(value),
      _ => null,
    };
    final Map<String, dynamic>? error = body?['error'] as Map<String, dynamic>?;
    final AiseeApiException parsed = AiseeApiException(
      error?['message'] as String? ?? body?['message'] as String? ?? fallback,
      code: error?['code'] as String?,
    );
    return AiseeApiException(
      'HTTP ${res.response.statusCode}: ${parsed.message}',
      code: parsed.code,
    );
  }
}
