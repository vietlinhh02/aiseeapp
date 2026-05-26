import 'package:dio/dio.dart';
import 'package:retrofit/dio.dart';

class AiseeCallApiClient {
  AiseeCallApiClient(this._dio);

  final Dio _dio;

  Future<HttpResponse<dynamic>> createRoom(
    String authorization,
    Map<String, dynamic> body,
  ) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      '/api/v1/calls/create-room',
      data: body,
      options: Options(
        headers: <String, Object?>{'Authorization': authorization},
      ),
    );
    return HttpResponse<dynamic>(response.data, response);
  }

  Future<HttpResponse<dynamic>> endRoom(
    String authorization,
    Map<String, dynamic> body,
  ) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      '/api/v1/calls/end-room',
      data: body,
      options: Options(
        headers: <String, Object?>{'Authorization': authorization},
      ),
    );
    return HttpResponse<dynamic>(response.data, response);
  }
}
