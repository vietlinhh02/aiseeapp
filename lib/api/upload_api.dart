import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:retrofit/dio.dart';

class AiseeUploadApiClient {
  AiseeUploadApiClient(this._dio);

  final Dio _dio;

  Future<HttpResponse<dynamic>> uploadFile(
    String authorization,
    String path,
    String mimeType,
  ) async {
    final FormData data = FormData.fromMap(<String, Object?>{
      'file': await MultipartFile.fromFile(
        path,
        contentType: _mediaTypeFromMime(mimeType),
      ),
    });
    final Response<dynamic> response = await _dio.post<dynamic>(
      '/api/v1/upload',
      data: data,
      options: Options(
        headers: <String, Object?>{
          'Authorization': authorization,
          'Accept': 'application/json',
        },
      ),
    );
    return HttpResponse<dynamic>(response.data, response);
  }

  MediaType _mediaTypeFromMime(String mimeType) {
    final List<String> parts = mimeType.split('/');
    if (parts.length == 2) {
      return MediaType(parts[0], parts[1]);
    }
    return MediaType('application', 'octet-stream');
  }
}
