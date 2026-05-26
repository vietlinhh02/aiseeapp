import 'dart:convert';
import 'dart:io';

import 'package:aiseeapp/api/upload_api.dart';
import 'package:aiseeapp/services/aisee_upload_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retrofit/dio.dart';

void main() {
  test('uploadFile sends m4a with audio/mp4 content type', () async {
    final _FakeUploadApiClient client = _FakeUploadApiClient();
    final AiseeUploadService service = AiseeUploadService(apiClient: client);
    final File file = await _createTempFile('.m4a');

    addTearDown(() async {
      service.close();
      if (await file.exists()) {
        await file.delete();
      }
    });

    await service.uploadFile('token', file);

    expect(client.lastPath, file.path);
    expect(client.lastMimeType, 'audio/mp4');
  });
}

Future<File> _createTempFile(String extension) async {
  final Directory dir = await Directory.systemTemp.createTemp('aisee-upload-');
  final File file = File('${dir.path}/sample$extension');
  await file.writeAsBytes(utf8.encode('voice'));
  return file;
}

class _FakeUploadApiClient extends AiseeUploadApiClient {
  _FakeUploadApiClient() : super(Dio());

  String? lastPath;
  String? lastMimeType;

  @override
  Future<HttpResponse<dynamic>> uploadFile(
    String authorization,
    String path,
    String mimeType,
  ) async {
    lastPath = path;
    lastMimeType = mimeType;
    final RequestOptions requestOptions = RequestOptions(
      path: '/api/v1/upload',
    );
    final Map<String, dynamic> data = <String, dynamic>{
      'url': 'https://example.com/f.m4a',
    };
    final Response<dynamic> response = Response<dynamic>(
      requestOptions: requestOptions,
      data: data,
      statusCode: 200,
    );
    return HttpResponse<dynamic>(data, response);
  }
}
