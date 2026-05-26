import 'package:dio/dio.dart';
import 'package:retrofit/dio.dart';

import '../api/aisee_api_auth.dart';
import '../api/aisee_api_dio.dart';
import '../api/chat_api.dart';
import '../models/aisee_api_models.dart';
import '../models/aisee_message.dart';

class AiseeChatService {
  AiseeChatService({AiseeChatApiClient? apiClient, Dio? dio})
    : this._(dio: dio ?? AiseeApiDioFactory.create(), apiClient: apiClient);

  AiseeChatService._({required Dio dio, AiseeChatApiClient? apiClient})
    : _dio = dio,
      _ownsDio = apiClient == null,
      _apiClient = apiClient ?? AiseeChatApiClient(dio);

  final Dio _dio;
  final bool _ownsDio;
  final AiseeChatApiClient _apiClient;

  void close() {
    if (_ownsDio) {
      _dio.close(force: true);
    }
  }

  Future<List<AiseeMessage>> fetchMessages(
    String accessToken,
    String contactId, {
    int limit = 50,
    String? before,
  }) async {
    final Map<String, dynamic> query = <String, dynamic>{'limit': limit};
    if (before != null) {
      query['before'] = before;
    }
    final HttpResponse<dynamic> res = await _apiClient.fetchMessages(
      AiseeApiAuth.bearer(accessToken),
      contactId,
      query,
    );
    if (res.response.statusCode != 200) {
      throw _error(res, 'Không tải được tin nhắn');
    }
    final Object? decoded = _decodeJson(res, 'Không tải được tin nhắn');
    if (decoded is Map<String, dynamic>) {
      final Object? msgs = decoded['messages'];
      if (msgs is List) {
        return msgs
            .cast<Map<String, dynamic>>()
            .map(AiseeMessage.fromJson)
            .toList();
      }
    }
    if (decoded is List) {
      return decoded
          .cast<Map<String, dynamic>>()
          .map(AiseeMessage.fromJson)
          .toList();
    }
    return <AiseeMessage>[];
  }

  Future<AiseeMessage> sendMessage(
    String accessToken,
    String receiverId,
    String text, {
    String? voiceUrl,
    String? imageUrl,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'receiver_id': receiverId,
      'content_text': text,
    };
    final String? v = voiceUrl?.trim();
    final String? img = imageUrl?.trim();
    if (v != null && v.isNotEmpty) {
      body['voice_url'] = v;
    }
    if (img != null && img.isNotEmpty) {
      body['image_url'] = img;
    }

    final HttpResponse<dynamic> res = await _apiClient.sendMessage(
      AiseeApiAuth.bearer(accessToken),
      body,
    );
    if (res.response.statusCode != 200 && res.response.statusCode != 201) {
      throw _error(res, 'Không gửi được tin nhắn');
    }
    final Object? decoded = _decodeJson(res, 'Không gửi được tin nhắn');
    if (decoded is! Map<String, dynamic>) {
      throw AiseeApiException('Phản hồi không hợp lệ');
    }
    return AiseeMessage.fromJson(decoded);
  }

  Future<void> markRead(String accessToken, String messageId) async {
    final HttpResponse<dynamic> res = await _apiClient.markRead(
      AiseeApiAuth.bearer(accessToken),
      messageId,
    );
    if (res.response.statusCode != 200) {
      throw _error(res, 'Không đánh dấu đã đọc');
    }
  }

  Future<int> fetchUnreadCount(String accessToken) async {
    final HttpResponse<dynamic> res = await _apiClient.fetchUnreadCount(
      AiseeApiAuth.bearer(accessToken),
    );
    if (res.response.statusCode != 200) {
      throw _error(res, 'Không lấy được số tin chưa đọc');
    }
    final Object? decoded = _decodeJson(res, 'Không lấy được số tin chưa đọc');
    if (decoded is Map<String, dynamic>) {
      return decoded['count'] as int? ?? 0;
    }
    return 0;
  }

  Object? _decodeJson(HttpResponse<dynamic> res, String fallback) {
    final dynamic data = res.data;
    if (data == null) {
      throw AiseeApiException('$fallback (phản hồi trống)');
    }
    if (data is Map<String, dynamic> || data is List) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    throw AiseeApiException(
      '$fallback (HTTP ${res.response.statusCode}): phản hồi không hợp lệ',
    );
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
}
