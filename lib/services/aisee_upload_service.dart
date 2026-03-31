import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../config/app_env.dart';
import '../models/aisee_api_models.dart';

class AiseeUploadService {
  AiseeUploadService({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final http.Client _http;

  static const int _maxSizeBytes = 10 * 1024 * 1024;

  static const Set<String> _allowedMimeTypes = <String>{
    'image/jpeg',
    'image/png',
    'image/webp',
  };

  void close() => _http.close();

  /// Upload a file to the backend. Trả về đúng chuỗi `url` trong JSON (URL tuyệt đối https://…),
  /// không nối thêm base storage ở app.
  Future<String> uploadFile(
    String accessToken,
    File file,
  ) async {
    final int fileSize = await file.length();
    if (fileSize > _maxSizeBytes) {
      throw AiseeApiException('File quá lớn, tối đa 10MB');
    }

    final String mimeType = _guessMimeType(file.path);
    if (!_isAllowedMime(mimeType)) {
      throw AiseeApiException(
        'Định dạng không được hỗ trợ: $mimeType',
      );
    }

    final Uri uri = Uri.parse('${AppEnv.apiBaseUrl}/api/v1/upload');
    final http.MultipartRequest request =
        http.MultipartRequest('POST', uri)
          ..headers['Authorization'] = 'Bearer $accessToken'
          ..files.add(
            await http.MultipartFile.fromPath('file', file.path),
          );

    final http.StreamedResponse streamedRes = await _http.send(request);
    final String bodyStr = await streamedRes.stream.bytesToString();

    if (streamedRes.statusCode != 200) {
      throw _parseError(bodyStr, streamedRes.statusCode);
    }

    final Map<String, dynamic> body =
        jsonDecode(bodyStr) as Map<String, dynamic>;
    final String? url = body['url'] as String?;
    if (url == null || url.isEmpty) {
      throw AiseeApiException('Upload thành công nhưng không có URL');
    }
    debugPrint('[AiSee:Upload] Uploaded: $url');
    return url;
  }

  static String _guessMimeType(String path) {
    final String ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'aac':
        return 'audio/aac';
      case 'm4a':
        return 'audio/mp4';
      case 'wav':
        return 'audio/wav';
      case 'mp3':
        return 'audio/mpeg';
      default:
        return 'application/octet-stream';
    }
  }

  static bool _isAllowedMime(String mime) {
    if (mime.startsWith('audio/')) return true;
    return _allowedMimeTypes.contains(mime);
  }

  AiseeApiException _parseError(String body, int statusCode) {
    try {
      final Map<String, dynamic> json =
          jsonDecode(body) as Map<String, dynamic>;
      final Map<String, dynamic>? error =
          json['error'] as Map<String, dynamic>?;
      if (error != null) {
        return AiseeApiException(
          error['message'] as String? ?? 'Upload thất bại',
          code: error['code'] as String?,
        );
      }
      return AiseeApiException(
        json['message'] as String? ?? 'Upload thất bại (HTTP $statusCode)',
      );
    } catch (_) {
      return AiseeApiException('Upload thất bại (HTTP $statusCode)');
    }
  }
}
