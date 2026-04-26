class AiseeMessage {
  const AiseeMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    this.contentText = '',
    this.voiceUrl,
    this.imageUrl,
    this.senderName,
    this.senderAvatarUrl,
    this.isRead = false,
    required this.createdAt,
  });

  final String id;
  final String senderId;
  final String receiverId;
  final String contentText;
  final String? voiceUrl;
  final String? imageUrl;
  final String? senderName;
  final String? senderAvatarUrl;
  final bool isRead;
  final DateTime createdAt;

  /// Chuỗi rỗng từ API → null (tránh đưa "" vào player). URL dùng nguyên từ backend (https://...).
  static String? _optionalUrlField(dynamic v) {
    if (v == null) return null;
    if (v is! String) return null;
    final String s = v.trim();
    return s.isEmpty ? null : s;
  }

  factory AiseeMessage.fromJson(Map<String, dynamic> j) {
    return AiseeMessage(
      id: j['id'] as String,
      senderId: j['sender_id'] as String,
      receiverId: j['receiver_id'] as String,
      contentText: j['content_text'] as String? ?? '',
      voiceUrl: _optionalUrlField(j['voice_url']),
      imageUrl: _optionalUrlField(j['image_url']),
      senderName: _optionalUrlField(j['sender_name']),
      senderAvatarUrl: _optionalUrlField(j['sender_avatar_url']),
      isRead: j['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
    );
  }
}
