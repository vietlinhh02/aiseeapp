import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_env.dart';
import '../models/aisee_api_models.dart';
import '../models/aisee_family_member.dart';
import '../models/aisee_family_group.dart';
import '../utils/aisee_api_error_parse.dart';

class AiseeFamilyService {
  AiseeFamilyService({http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  final http.Client _http;

  void close() => _http.close();

  Uri _uri(String path) => Uri.parse('${AppEnv.apiBaseUrl}$path');

  Map<String, String> _authHeaders(String accessToken) => {
    'Authorization': 'Bearer $accessToken',
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': 'application/json',
  };

  Future<List<AiseeFamilyMember>> fetchFamily(String accessToken) async {
    final http.Response res = await _http.get(
      _uri('/api/v1/users/me/family'),
      headers: _authHeaders(accessToken),
    );
    if (res.statusCode != 200) {
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
    final http.Response res = await _http.post(
      _uri('/api/v1/users/family-link'),
      headers: _authHeaders(accessToken),
      body: jsonEncode({'relationship': relationship}),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
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
    final http.Response res = await _http.get(
      _uri('/api/v1/users/me/group'),
      headers: _authHeaders(accessToken),
    );
    if (res.statusCode == 404) {
      final AiseeApiException error = _error(
        res,
        'Không tải được nhóm chăm sóc',
      );
      if (error.code == 'no_active_group') {
        return null;
      }
    }
    if (res.statusCode != 200) {
      throw _error(res, 'Không tải được nhóm chăm sóc');
    }
    final Object? decoded = _decodeJson(res, 'Không tải được nhóm chăm sóc');
    if (decoded is! Map<String, dynamic>) {
      throw AiseeApiException('Phản hồi nhóm chăm sóc không hợp lệ');
    }
    return AiseeCurrentGroup.fromJson(decoded);
  }

  Future<void> joinFamily(String accessToken, String inviteCode) async {
    final http.Response res = await _http.post(
      _uri('/api/v1/users/join-family'),
      headers: _authHeaders(accessToken),
      body: jsonEncode({'invite_code': inviteCode}),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw _error(res, 'Không tham gia được gia đình');
    }
    // Backend có thể trả {"status":"joined"} — không bắt buộc parse cho luồng UI.
  }

  Future<void> revokeInvite(String accessToken, String inviteCode) async {
    final http.Response res = await _http.delete(
      _uri('/api/v1/users/family-invite/$inviteCode'),
      headers: _authHeaders(accessToken),
    );
    if (res.statusCode != 200) {
      throw _error(res, 'Không thu hồi được mã mời');
    }
  }

  Future<void> leaveGroup(String accessToken) async {
    final http.Response res = await _http.post(
      _uri('/api/v1/users/leave-group'),
      headers: _authHeaders(accessToken),
      body: jsonEncode(<String, dynamic>{}),
    );
    if (res.statusCode != 200) {
      throw _error(res, 'Không rời được nhóm chăm sóc');
    }
  }

  Future<void> transferGroupOwnership(
    String accessToken,
    String targetUserId,
  ) async {
    final http.Response res = await _http.post(
      _uri('/api/v1/users/transfer-group-ownership'),
      headers: _authHeaders(accessToken),
      body: jsonEncode(<String, dynamic>{'target_user_id': targetUserId}),
    );
    if (res.statusCode != 200) {
      throw _error(res, 'Không chuyển được quyền chủ nhóm');
    }
  }

  Future<void> deleteLink(String accessToken, String linkId) async {
    final http.Response res = await _http.delete(
      _uri('/api/v1/users/family-link/$linkId'),
      headers: _authHeaders(accessToken),
    );
    if (res.statusCode != 200) {
      throw _error(res, 'Không xoá được liên kết');
    }
  }

  Future<void> updateProfile(
    String accessToken,
    Map<String, dynamic> fields,
  ) async {
    final http.Response res = await _http.put(
      _uri('/api/v1/users/me'),
      headers: _authHeaders(accessToken),
      body: jsonEncode(fields),
    );
    if (res.statusCode != 200) {
      throw _error(res, 'Không cập nhật được hồ sơ');
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
      final String preview = raw.length > 80 ? '${raw.substring(0, 80)}…' : raw;
      throw AiseeApiException('$fallback (HTTP ${res.statusCode}): $preview');
    }
  }

  AiseeApiException _error(http.Response res, String fallback) {
    final AiseeApiException parsed = aiseeApiExceptionFromResponse(
      res,
      fallback,
    );
    return AiseeApiException(
      'HTTP ${res.statusCode}: ${parsed.message}',
      code: parsed.code,
    );
  }
}
