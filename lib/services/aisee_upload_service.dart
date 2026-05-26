import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:retrofit/dio.dart';

import '../api/aisee_api_auth.dart';
import '../api/aisee_api_dio.dart';
import '../api/upload_api.dart';
import '../models/aisee_api_models.dart';

class AiseeUploadService {
  AiseeUploadService({AiseeUploadApiClient? apiClient, Dio? dio})
    : this._(dio: dio ?? AiseeApiDioFactory.create(), apiClient: apiClient);

  AiseeUploadService._({required Dio dio, AiseeUploadApiClient? apiClient})
    : _dio = dio,
      _ownsDio = apiClient == null,
      _apiClient = apiClient ?? AiseeUploadApiClient(dio);

  final Dio _dio;
  final bool _ownsDio;
  final AiseeUploadApiClient _apiClient;

  static const int _maxSizeBytes = 10 * 1024 * 1024;

  static const Set<String> _allowedMimeTypes = <String>{
    'image/jpeg',
    'image/png',
    'image/webp',
  };

  void close() {
    if (_ownsDio) {
      _dio.close(force: true);
    }
  }

  /// Upload a file to the backend. Trả về đúng chuỗi `url` trong JSON (URL tuyệt đối https://…),
  /// không nối thêm base storage ở app.
  Future<String> uploadFile(String accessToken, File file) async {
    final int fileSize = await file.length();
    if (fileSize > _maxSizeBytes) {
      throw AiseeApiException('File quá lớn, tối đa 10MB');
    }

    final String mimeType = _guessMimeType(file.path);
    if (!_isAllowedMime(mimeType)) {
      throw AiseeApiException('Định dạng không được hỗ trợ: $mimeType');
    }

    final HttpResponse<dynamic> res = await _apiClient.uploadFile(
      AiseeApiAuth.bearer(accessToken),
      file.path,
      mimeType,
    );
    if (res.response.statusCode != 200) {
      throw _parseError(res, res.response.statusCode ?? 0);
    }

    final Map<String, dynamic> body = _decodeMap(res);
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

  Map<String, dynamic> _decodeMap(HttpResponse<dynamic> res) {
    final dynamic data = res.data;
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    throw AiseeApiException('Upload thành công nhưng phản hồi không hợp lệ');
  }

  AiseeApiException _parseError(HttpResponse<dynamic> res, int statusCode) {
    final dynamic data = res.data;
    try {
      final Map<String, dynamic> json = _decodeMap(res);
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
      if (data is String && data.isNotEmpty) {
        return AiseeApiException(data);
      }
      return AiseeApiException('Upload thất bại (HTTP $statusCode)');
    }
  }
}
