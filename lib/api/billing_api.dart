import 'package:dio/dio.dart';
import 'package:retrofit/dio.dart';

class AiseeBillingApiClient {
  AiseeBillingApiClient(this._dio);

  final Dio _dio;

  Future<HttpResponse<dynamic>> fetchBillingOverview(
    String authorization,
    Map<String, dynamic> query,
  ) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      '/api/v1/me/billing-overview',
      queryParameters: query,
      options: Options(
        headers: <String, Object?>{'Authorization': authorization},
      ),
    );
    return HttpResponse<dynamic>(response.data, response);
  }

  Future<HttpResponse<dynamic>> fetchUsage(
    String authorization,
    Map<String, dynamic> query,
  ) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      '/api/v1/me/usage',
      queryParameters: query,
      options: Options(
        headers: <String, Object?>{'Authorization': authorization},
      ),
    );
    return HttpResponse<dynamic>(response.data, response);
  }
}
