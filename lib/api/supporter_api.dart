import 'package:dio/dio.dart';
import 'package:retrofit/dio.dart';

class AiseeSupporterApiClient {
  AiseeSupporterApiClient(this._dio);

  final Dio _dio;

  Options _auth(String authorization) => Options(
    headers: <String, Object?>{
      'Authorization': authorization,
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
    },
  );

  Future<HttpResponse<dynamic>> getOverview(String authorization) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      '/api/v1/me/supporter/overview',
      options: _auth(authorization),
    );
    return HttpResponse<dynamic>(response.data, response);
  }

  Future<HttpResponse<dynamic>> watchAd(String authorization) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      '/api/v1/me/supporter/watch-ad',
      options: _auth(authorization),
    );
    return HttpResponse<dynamic>(response.data, response);
  }

  Future<HttpResponse<dynamic>> redeem(
    String authorization,
    Map<String, dynamic> body,
  ) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      '/api/v1/me/supporter/redeem',
      data: body,
      options: _auth(authorization),
    );
    return HttpResponse<dynamic>(response.data, response);
  }
}
