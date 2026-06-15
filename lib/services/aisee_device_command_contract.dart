/// Single source of truth for all device command and protocol constants
/// on the Flutter side.
///
/// These values MUST match the wire values in Python's contracts.py.
/// Do NOT change wire values without coordinated migration.
library;

/// Device command names received from Python agent via WS tool_request.
/// These match DeviceCommand enum in Python contracts.py.
abstract final class DeviceCommandNames {
  static const String enableCamera = 'enable_camera';
  static const String disableCamera = 'disable_camera';
  static const String setCameraFps = 'set_camera_fps';
  static const String showNavigationScreen = 'show_navigation_screen';
  static const String hideNavigationScreen = 'hide_navigation_screen';
  static const String startCall = 'start_call';
  static const String scheduleReminder = 'schedule_reminder';
  static const String getLocation = 'get_location';
  static const String openMaps = 'open_maps';
  static const String answerIncomingCall = 'answer_incoming_call';
  static const String declineIncomingCall = 'decline_incoming_call';
  static const String playAudio = 'play_audio';
  static const String controlAudio = 'control_audio';

  /// All known device command names — for validation.
  static const Set<String> all = <String>{
    enableCamera,
    disableCamera,
    setCameraFps,
    showNavigationScreen,
    hideNavigationScreen,
    startCall,
    scheduleReminder,
    getLocation,
    openMaps,
    answerIncomingCall,
    declineIncomingCall,
    playAudio,
    controlAudio,
  };
}

/// Audio control sub-commands sent inside control_audio params.
/// These match AudioControlAction enum in Python contracts.py.
abstract final class AudioControlActions {
  static const String pause = 'pause';
  static const String resume = 'resume';
  static const String play = 'play';
  static const String stop = 'stop';
  static const String next = 'next';
  static const String previous = 'previous';
  static const String volumeUp = 'volume_up';
  static const String volumeDown = 'volume_down';
}

/// WS message types Flutter sends to Python agent.
/// These match WsInboundType in Python contracts.py.
abstract final class AiWsOutboundTypes {
  static const String audioStart = 'audio_start';
  static const String audioStop = 'audio_stop';
  static const String mediaMode = 'media_mode';
  static const String nsfwDetected = 'nsfw_detected';
  static const String toolResult = 'tool_result';
  static const String interrupt = 'interrupt';
  static const String control = 'control';
  static const String pong = 'pong';
}

/// WS message types Python agent sends to Flutter.
/// These match WsOutboundType in Python contracts.py.
abstract final class AiWsInboundTypes {
  static const String ready = 'ready';
  static const String agentState = 'agent_state';
  static const String toolRequest = 'tool_request';
  static const String deviceCommand = 'device_command';
  static const String assistantAudioInterrupted = 'assistant_audio_interrupted';
  static const String ping = 'ping';
  static const String error = 'error';
}

/// Control actions sent inside WS "control" messages.
/// These match ControlAction in Python contracts.py.
abstract final class AiControlActions {
  static const String wake = 'wake';
  static const String wakeGreeting = 'wake_greeting';
  static const String incomingCall = 'incoming_call';
  static const String incomingCallCleared = 'incoming_call_cleared';
  static const String interrupt = 'interrupt';
  static const String nsfwDetected = 'nsfw_detected';
  static const String stopNavigation = 'stop_navigation';
}

/// Media mode wire values.
/// These match the Flutter-facing values in Python contracts.py.
abstract final class AiMediaModes {
  static const String audioPcm = 'audio_pcm';
  static const String cameraJpeg = 'camera_jpeg';
}

/// Tool error codes for structured error responses.
/// These match ToolErrorCode in Python contracts.py.
abstract final class ToolErrorCodes {
  static const String permissionDenied = 'PERMISSION_DENIED';
  static const String timeout = 'TIMEOUT';
  static const String safetyBlocked = 'SAFETY_BLOCKED';
  static const String cancelled = 'CANCELLED';
  static const String unknownTool = 'UNKNOWN_TOOL';
  static const String unknown = 'UNKNOWN';
}

/// Helpers to determine device command behavior without string literals.
abstract final class DeviceCommandContract {
  /// Commands that require the assistant microphone to be paused
  /// before execution (to avoid audio conflict).
  /// Matches AUDIO_INTERRUPT_COMMANDS in Python contracts.py.
  static bool requiresMicPause(String commandName) {
    return commandName == DeviceCommandNames.playAudio ||
        commandName == DeviceCommandNames.startCall;
  }

  /// Commands that require stopping assistant audio playback.
  static bool requiresAudioStop(String commandName) {
    return commandName == DeviceCommandNames.playAudio;
  }

  /// Commands that require resuming mic after completion.
  static bool shouldResumeMicAfter(String commandName) {
    return commandName == DeviceCommandNames.startCall;
  }
}
