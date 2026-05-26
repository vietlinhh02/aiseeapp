import 'package:dio/dio.dart';
import 'package:retrofit/dio.dart';

import '../api/aisee_api_auth.dart';
import '../api/aisee_api_dio.dart';
import '../api/supporter_api.dart';
import '../models/aisee_api_models.dart';
import '../models/aisee_supporter_models.dart';

class AiseeSupporterService {
  AiseeSupporterService({AiseeSupporterApiClient? apiClient, Dio? dio})
    : this._(dio: dio ?? AiseeApiDioFactory.create(), apiClient: apiClient);

  AiseeSupporterService._({
    required Dio dio,
    AiseeSupporterApiClient? apiClient,
  }) : _dio = dio,
       _ownsDio = apiClient == null,
       _apiClient = apiClient ?? AiseeSupporterApiClient(dio);

  final Dio _dio;
  final bool _ownsDio;
  final AiseeSupporterApiClient _apiClient;

  void close() {
    if (_ownsDio) {
      _dio.close(force: true);
    }
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

  Map<String, dynamic> _decodeMap(HttpResponse<dynamic> res, String fallback) {
    final dynamic data = res.data;
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    if (data == null) {
      throw AiseeApiException('$fallback (phản hồi trống)');
    }
    throw AiseeApiException('$fallback (JSON không hợp lệ)');
  }

  Future<SupporterOverviewResponse> getOverview(String accessToken) async {
    final HttpResponse<dynamic> res = await _apiClient.getOverview(
      AiseeApiAuth.bearer(accessToken),
    );
    if (res.response.statusCode != 200) {
      throw _error(res, 'Không tải được tổng quan hỗ trợ');
    }
    return SupporterOverviewResponse.fromJson(
      _decodeMap(res, 'supporter overview'),
    );
  }

  Future<WatchAdResponse> watchAd(String accessToken) async {
    final HttpResponse<dynamic> res = await _apiClient.watchAd(
      AiseeApiAuth.bearer(accessToken),
    );
    if (res.response.statusCode != 200) {
      throw _error(res, 'Không xem được quảng cáo');
    }
    return WatchAdResponse.fromJson(_decodeMap(res, 'watch ad'));
  }

  Future<RedeemResponse> redeem(
    String accessToken,
    int amount,
    String? recipientUserId,
  ) async {
    final Map<String, dynamic> body = <String, dynamic>{'amount': amount};
    if (recipientUserId != null) {
      body['recipient_user_id'] = recipientUserId;
    }

    final HttpResponse<dynamic> res = await _apiClient.redeem(
      AiseeApiAuth.bearer(accessToken),
      body,
    );
    if (res.response.statusCode != 200) {
      throw _error(res, 'Không đổi được xu');
    }
    return RedeemResponse.fromJson(_decodeMap(res, 'redeem'));
  }
}
