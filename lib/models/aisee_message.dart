class AiseeMessage {
  const AiseeMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    this.contentText = '',
    this.voiceUrl,
    this.imageUrl,
    this.isRead = false,
    required this.createdAt,
  });

  final String id;
  final String senderId;
  final String receiverId;
  final String contentText;
  final String? voiceUrl;
  final String? imageUrl;
  final bool isRead;
  final DateTime createdAt;

  factory AiseeMessage.fromJson(Map<String, dynamic> j) {
    return AiseeMessage(
      id: j['id'] as String,
      senderId: j['sender_id'] as String,
      receiverId: j['receiver_id'] as String,
      contentText: j['content_text'] as String? ?? '',
      voiceUrl: j['voice_url'] as String?,
      imageUrl: j['image_url'] as String?,
      isRead: j['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
    );
  }
}
