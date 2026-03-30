enum AgentState {
  connecting,
  initializing,
  idle,
  listening,
  thinking,
  speaking,
  disconnected,
  failed;

  factory AgentState.fromString(String? s) => switch (s) {
    'initializing' => AgentState.initializing,
    'idle' => AgentState.idle,
    'listening' => AgentState.listening,
    'thinking' => AgentState.thinking,
    'speaking' => AgentState.speaking,
    'disconnected' => AgentState.disconnected,
    'failed' => AgentState.failed,
    _ => AgentState.connecting,
  };

  bool get canListen =>
      this == listening || this == thinking || this == speaking;

  bool get isConnected =>
      this == listening || this == thinking || this == speaking;

  bool get isPending =>
      this == connecting || this == initializing || this == idle;

  bool get isFinished => this == disconnected || this == failed;

  String get displayTextVi => switch (this) {
    connecting || initializing => 'Đang kết nối...',
    idle => 'Sẵn sàng',
    listening => 'Đang nghe...',
    thinking => 'Đang xử lý...',
    speaking => 'Đang trả lời...',
    disconnected => 'Đã ngắt kết nối',
    failed => 'Lỗi kết nối',
  };
}
