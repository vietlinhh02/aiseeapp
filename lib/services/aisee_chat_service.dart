import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_env.dart';
import '../models/aisee_api_models.dart';
import '../models/aisee_message.dart';
import '../utils/aisee_api_error_parse.dart';

class AiseeChatService {
  AiseeChatService({http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  final http.Client _http;

  void close() => _http.close();

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('${AppEnv.apiBaseUrl}$path').replace(queryParameters: query);

  Map<String, String> _authHeaders(String accessToken) => {
    'Authorization': 'Bearer $accessToken',
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': 'application/json',
  };

  Future<List<AiseeMessage>> fetchMessages(
    String accessToken,
    String contactId, {
    int limit = 50,
    String? before,
  }) async {
    final Map<String, String> query = {'limit': '$limit'};
    if (before != null) query['before'] = before;
    final http.Response res = await _http.get(
      _uri('/api/v1/messages/$contactId', query),
      headers: _authHeaders(accessToken),
    );
    if (res.statusCode != 200) {
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

    final http.Response res = await _http.post(
      _uri('/api/v1/messages/send'),
      headers: _authHeaders(accessToken),
      body: jsonEncode(body),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw _error(res, 'Không gửi được tin nhắn');
    }
    final Object? decoded = _decodeJson(res, 'Không gửi được tin nhắn');
    if (decoded is! Map<String, dynamic>) {
      throw AiseeApiException('Phản hồi không hợp lệ');
    }
    return AiseeMessage.fromJson(decoded);
  }

  Future<void> markRead(String accessToken, String messageId) async {
    final http.Response res = await _http.put(
      _uri('/api/v1/messages/$messageId/read'),
      headers: _authHeaders(accessToken),
    );
    if (res.statusCode != 200) {
      throw _error(res, 'Không đánh dấu đã đọc');
    }
  }

  Future<int> fetchUnreadCount(String accessToken) async {
    final http.Response res = await _http.get(
      _uri('/api/v1/messages/unread-count'),
      headers: _authHeaders(accessToken),
    );
    if (res.statusCode != 200) {
      throw _error(res, 'Không lấy được số tin chưa đọc');
    }
    final Object? decoded = _decodeJson(
      res,
      'Không lấy được số tin chưa đọc',
    );
    if (decoded is Map<String, dynamic>) {
      return decoded['count'] as int? ?? 0;
    }
    return 0;
  }

  Object? _decodeJson(http.Response res, String fallback) {
    final String raw = utf8.decode(res.bodyBytes).trim();
    if (raw.isEmpty) {
      throw AiseeApiException('$fallback (phản hồi trống)');
    }
    try {
      return jsonDecode(raw);
    } on FormatException {
      final String preview =
          raw.length > 80 ? '${raw.substring(0, 80)}…' : raw;
      throw AiseeApiException(
        '$fallback (HTTP ${res.statusCode}): $preview',
      );
    }
  }

  AiseeApiException _error(http.Response res, String fallback) {
    return aiseeApiExceptionFromResponse(res, fallback);
  }
}
