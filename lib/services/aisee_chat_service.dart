import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_env.dart';
import '../models/aisee_api_models.dart';
import '../models/aisee_message.dart';

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
    final Map<String, dynamic> map =
        jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final List<dynamic> list = map['messages'] as List<dynamic>;
    return list
        .cast<Map<String, dynamic>>()
        .map(AiseeMessage.fromJson)
        .toList();
  }

  Future<AiseeMessage> sendMessage(
    String accessToken,
    String receiverId,
    String text,
  ) async {
    final http.Response res = await _http.post(
      _uri('/api/v1/messages/send'),
      headers: _authHeaders(accessToken),
      body: jsonEncode({
        'receiver_id': receiverId,
        'content_text': text,
        'voice_url': '',
      }),
    );
    if (res.statusCode != 200) {
      throw _error(res, 'Không gửi được tin nhắn');
    }
    final Map<String, dynamic> map =
        jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    return AiseeMessage.fromJson(map);
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
    final Map<String, dynamic> map =
        jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    return map['count'] as int;
  }

  AiseeApiException _error(http.Response res, String fallback) {
    try {
      final Map<String, dynamic> map =
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final String? msg = map['message'] as String?;
      final String? code = map['error'] as String?;
      return AiseeApiException(msg ?? fallback, code: code);
    } catch (_) {
      return AiseeApiException(fallback);
    }
  }
}
