/// Phản hồi [POST /api/v1/calls/token] — dùng kết nối LiveKit.
class LiveKitJoinCredentials {
  const LiveKitJoinCredentials({
    required this.token,
    required this.url,
    this.roomName,
  });

  final String token;

  /// WebSocket URL (ví dụ `wss://...`).
  final String url;
  final String? roomName;
}
