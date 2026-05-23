import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_env.dart';
import '../models/aisee_api_models.dart';
import '../models/aisee_supporter_models.dart';
import '../utils/aisee_api_error_parse.dart';

class AiseeSupporterService {
  AiseeSupporterService({http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  final http.Client _http;

  void close() => _http.close();

  Uri _uri(String path) => Uri.parse('${AppEnv.apiBaseUrl}$path');

  Map<String, String> _headers(String accessToken) => <String, String>{
    'Authorization': 'Bearer $accessToken',
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': 'application/json',
  };

  AiseeApiException _error(http.Response res, String fallback) {
    return aiseeApiExceptionFromResponse(res, fallback);
  }

  Map<String, dynamic> _decodeMap(http.Response res, String fallback) {
    final String raw = utf8.decode(res.bodyBytes).trim();
    if (raw.isEmpty) {
      throw AiseeApiException('$fallback (phản hồi trống)');
    }
    final Object? decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    throw AiseeApiException('$fallback (JSON không hợp lệ)');
  }

  Future<SupporterOverviewResponse> getOverview(String accessToken) async {
    final http.Response res = await _http.get(
      _uri('/api/v1/me/supporter/overview'),
      headers: _headers(accessToken),
    );
    if (res.statusCode != 200) {
      throw _error(res, 'Không tải được tổng quan hỗ trợ');
    }
    return SupporterOverviewResponse.fromJson(
      _decodeMap(res, 'supporter overview'),
    );
  }

  Future<WatchAdResponse> watchAd(String accessToken) async {
    final http.Response res = await _http.post(
      _uri('/api/v1/me/supporter/watch-ad'),
      headers: _headers(accessToken),
    );
    if (res.statusCode != 200) {
      throw _error(res, 'Không xem được quảng cáo');
    }
    return WatchAdResponse.fromJson(_decodeMap(res, 'watch ad'));
  }

  Future<RedeemResponse> redeem(
    String accessToken,
    int amount,
    String? recipientUserId,
  ) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'amount': amount,
    };
    if (recipientUserId != null) {
      body['recipient_user_id'] = recipientUserId;
    }

    final http.Response res = await _http.post(
      _uri('/api/v1/me/supporter/redeem'),
      headers: _headers(accessToken),
      body: jsonEncode(body),
    );
    if (res.statusCode != 200) {
      throw _error(res, 'Không đổi được xu');
    }
    return RedeemResponse.fromJson(_decodeMap(res, 'redeem'));
  }
}
