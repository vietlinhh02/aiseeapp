import 'dart:convert';
import 'dart:io';

import 'package:aiseeapp/services/aisee_upload_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test('uploadFile sends m4a with audio/mp4 content type', () async {
    final _RecordingMultipartClient client = _RecordingMultipartClient();
    final AiseeUploadService service = AiseeUploadService(httpClient: client);
    final File file = await _createTempFile('.m4a');

    addTearDown(() async {
      service.close();
      if (await file.exists()) {
        await file.delete();
      }
    });

    await service.uploadFile('token', file);

    expect(client.lastRequest, isA<http.MultipartRequest>());
    final http.MultipartRequest request =
        client.lastRequest! as http.MultipartRequest;
    expect(request.files, hasLength(1));
    expect(request.files.single.contentType.mimeType, 'audio/mp4');
  });
}

Future<File> _createTempFile(String extension) async {
  final Directory dir = await Directory.systemTemp.createTemp('aisee-upload-');
  final File file = File('${dir.path}/sample$extension');
  await file.writeAsBytes(utf8.encode('voice'));
  return file;
}

class _RecordingMultipartClient extends http.BaseClient {
  http.BaseRequest? lastRequest;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastRequest = request;
    return http.StreamedResponse(
      Stream<List<int>>.value(
        utf8.encode('{"url":"https://example.com/f.m4a"}'),
      ),
      200,
      headers: const <String, String>{'content-type': 'application/json'},
    );
  }
}
