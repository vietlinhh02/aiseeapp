import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_env.dart';
import '../models/aisee_api_models.dart';
import '../models/aisee_family_member.dart';

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
    final List<dynamic> list =
        jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
    return list
        .cast<Map<String, dynamic>>()
        .map(AiseeFamilyMember.fromJson)
        .toList();
  }

  Future<String> createInvite(
    String accessToken,
    String relationship,
  ) async {
    final http.Response res = await _http.post(
      _uri('/api/v1/users/family-link'),
      headers: _authHeaders(accessToken),
      body: jsonEncode({'relationship': relationship}),
    );
    if (res.statusCode != 200) {
      throw _error(res, 'Không tạo được mã mời');
    }
    final Map<String, dynamic> map =
        jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    return map['invite_code'] as String;
  }

  Future<void> joinFamily(String accessToken, String inviteCode) async {
    final http.Response res = await _http.post(
      _uri('/api/v1/users/join-family'),
      headers: _authHeaders(accessToken),
      body: jsonEncode({'invite_code': inviteCode}),
    );
    if (res.statusCode != 200) {
      throw _error(res, 'Không tham gia được gia đình');
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
