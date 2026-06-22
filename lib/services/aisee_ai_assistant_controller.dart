import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../models/agent_state.dart';
import '../models/aisee_incoming_call.dart';
import '../screens/aisee_navigation_screen.dart';
import 'aisee_ai_camera_streamer.dart';
import 'aisee_ai_microphone_input.dart';
import 'aisee_ai_session.dart';
import 'aisee_assistant_device_command_handler.dart';
import 'aisee_device_command_contract.dart';
import 'aisee_assistant_incoming_call_bridge.dart';
import 'aisee_audio_uplink_gate.dart';
import 'aisee_pcm_audio_player.dart';
import 'aisee_voice_audio_session.dart';
import 'aisee_voice_foreground.dart';
import 'aisee_wake_word_service.dart';

typedef AiseeMusicPlaybackStartedCallback = Future<void> Function();
typedef AiseeAssistantForegroundAction = Future<void> Function();

abstract interface class AiseeAiAssistantSessionClient {
  ValueListenable<AgentState> get agentState;
  ValueListenable<AiseeAiSessionConnectionStatus> get connectionStatus;
  ValueListenable<int> get reconnectAttempt;

  Stream<Uint8List> get assistantAudioBytes;
  Stream<void> get assistantAudioInterrupted;
  Stream<AiseeAiDeviceCommandRequest> get deviceCommands;

  Future<AiseeAiSessionConfig> start(String accessToken);
  Future<void> sendAudioFrame(Uint8List bytes);
  Future<void> sendCameraFrame(Uint8List bytes);
  Future<void> sendNsfwDetected();
  Future<void> sendControl(String action, {Map<String, Object?> payload});
  Future<void> stopAudioStream();
  Future<void> sendToolResult(String requestId, Object? result);
  Future<void> stop({bool resetState, int? closeCode, String? reason});
  void dispose();
}

class AiseeAiSessionClientAdapter implements AiseeAiAssistantSessionClient {
  AiseeAiSessionClientAdapter(this._session);

  final AiseeAiSession _session;

  @override
  ValueListenable<AgentState> get agentState => _session.agentState;

  @override
  Stream<Uint8List> get assistantAudioBytes => _session.assistantAudioBytes;

  @override
  Stream<void> get assistantAudioInterrupted =>
      _session.assistantAudioInterrupted;

  @override
  ValueListenable<AiseeAiSessionConnectionStatus> get connectionStatus =>
      _session.connectionStatus;

  @override
  ValueListenable<int> get reconnectAttempt => _session.reconnectAttempt;

  @override
  Stream<AiseeAiDeviceCommandRequest> get deviceCommands =>
      _session.deviceCommands;

  @override
  void dispose() {
    _session.dispose();
  }

  @override
  Future<void> sendAudioFrame(Uint8List bytes) {
    return _session.sendAudioFrame(bytes);
  }

  @override
  Future<void> sendCameraFrame(Uint8List bytes) {
    return _session.sendCameraFrame(bytes);
  }

  @override
  Future<void> sendControl(
    String action, {
    Map<String, Object?> payload = const <String, Object?>{},
  }) {
    return _session.sendControl(action, payload: payload);
  }

  @override
  Future<void> sendNsfwDetected() {
    return _session.sendNsfwDetected();
  }

  @override
  Future<void> stopAudioStream() {
    return _session.stopAudioStream();
  }

  @override
  Future<void> sendToolResult(String requestId, Object? result) {
    return _session.sendToolResult(requestId, result);
  }

  @override
  Future<AiseeAiSessionConfig> start(String accessToken) {
    return _session.start(accessToken);
  }

  @override
  Future<void> stop({bool resetState = true, int? closeCode, String? reason}) {
    return _session.stop(
      resetState: resetState,
      closeCode: closeCode,
      reason: reason,
    );
  }
}

class AiseeAiAssistantController {
  AiseeAiAssistantController({
    required AiseeAiAssistantSessionClient session,
    required AiseeAiMicrophoneInput microphoneInput,
    required AiseeAiCameraStreamer cameraStreamer,
    required AiseeAiPcmPlayer audioPlayer,
    required AiseeAssistantDeviceCommandHandler deviceCommandHandler,
    AiseeMusicPlaybackStartedCallback? onMusicPlaybackStarted,
    AiseeAssistantForegroundAction? startForeground,
    AiseeAssistantForegroundAction? stopForeground,
    AiseeAudioUplinkGate? audioUplinkGate,
  }) : _session = session,
       _microphoneInput = microphoneInput,
       _cameraStreamer = cameraStreamer,
       _audioPlayer = audioPlayer,
       _deviceCommandHandler = deviceCommandHandler,
       _onMusicPlaybackStarted = onMusicPlaybackStarted,
        _startForeground =
            startForeground ??
            AiseeVoiceAssistantForeground.ensureStartedAfterConnected,
        _stopForeground =
            stopForeground ?? AiseeVoiceAssistantForeground.ensureStopped,
        _audioUplinkGate = audioUplinkGate ?? AiseeAudioUplinkGate();

  void _startWaveDecayTimer() {
    if (_waveDecayTimer != null) return;
    _waveDecayTimer = Timer.periodic(
      const Duration(milliseconds: 50),
      (_) => _decayWaveEnergy(),
    );
  }

  void _stopWaveDecayTimer() {
    _waveDecayTimer?.cancel();
    _waveDecayTimer = null;
    assistantWaveEnergy.value = 0;
    _lastPeak = 0;
  }

  final AiseeAiAssistantSessionClient _session;
  final AiseeAiMicrophoneInput _microphoneInput;
  final AiseeAiCameraStreamer _cameraStreamer;
  final AiseeAiPcmPlayer _audioPlayer;
  final AiseeAssistantDeviceCommandHandler _deviceCommandHandler;
  final AiseeMusicPlaybackStartedCallback? _onMusicPlaybackStarted;
  final AiseeAssistantForegroundAction _startForeground;
  final AiseeAssistantForegroundAction _stopForeground;
  final AiseeAudioUplinkGate _audioUplinkGate;

  final ValueNotifier<double> assistantWaveEnergy = ValueNotifier<double>(0);

  StreamSubscription<Uint8List>? _assistantAudioSub;
  StreamSubscription<void>? _assistantAudioInterruptedSub;
  StreamSubscription<AiseeAiDeviceCommandRequest>? _deviceCommandSub;
  Timer? _waveDecayTimer;

  bool _micEnabled = false;
  bool _agentStateListenerAttached = false;
  bool _disposed = false;
  double _lastPeak = 0;
  String? _lastAccessToken;

  ValueListenable<AgentState> get agentState => _session.agentState;

  ValueListenable<AiseeAiSessionConnectionStatus> get connectionStatus =>
      _session.connectionStatus;

  ValueListenable<int> get reconnectAttempt => _session.reconnectAttempt;

  ValueListenable<String?> get nowPlayingTitle =>
      _deviceCommandHandler.nowPlayingTitle;

  ValueListenable<Widget?> get cameraPreview => _cameraStreamer.preview;

  bool get isConnected {
    final AiseeAiSessionConnectionStatus status =
        _session.connectionStatus.value;
    return status == AiseeAiSessionConnectionStatus.connected ||
        status == AiseeAiSessionConnectionStatus.ready ||
        status == AiseeAiSessionConnectionStatus.reconnecting;
  }

  Future<void> connect(String accessToken) async {
    _ensureNotDisposed();
    _lastAccessToken = accessToken;
    await _session.start(accessToken);
    if (!_agentStateListenerAttached) {
      _session.agentState.addListener(_handleAgentStateChanged);
      _agentStateListenerAttached = true;
    }
    _assistantAudioSub ??= _session.assistantAudioBytes.listen(
      _handleAssistantAudio,
    );
    _assistantAudioInterruptedSub ??= _session.assistantAudioInterrupted.listen(
      (_) {
        unawaited(_handleAssistantAudioInterrupted());
      },
    );
    _deviceCommandSub ??= _session.deviceCommands.listen((
      AiseeAiDeviceCommandRequest request,
    ) {
      unawaited(_handleDeviceCommand(request));
    });
    AiseeAssistantIncomingCallBridge.instance.registerHandlers(
      announce: _announceIncomingCallToAgent,
      clear: _announceIncomingCallClearedToAgent,
    );
    final AiseeIncomingCall? pending =
        AiseeAssistantIncomingCallBridge.instance.pendingCall;
    if (pending != null) {
      unawaited(_announceIncomingCallToAgent(pending));
    }
  }

  Future<void> enableAssistantMic() async {
    _ensureNotDisposed();
    if (_micEnabled) {
      return;
    }
    await _ensureSessionConnectedForWake();

    final Uint8List? capturedAudio =
        AiseeWakeWordService.instance.consumeCapturedAudio();
    if (capturedAudio != null && capturedAudio.isNotEmpty) {
      debugPrint(
        '[AiSee:WakeFlow] Injecting ${capturedAudio.length} bytes '
        'of post-wake audio (~${capturedAudio.length ~/ 32}ms)',
      );
      await _session.sendAudioFrame(capturedAudio);
    }

    await configureAiseeVoiceAudioSession();
    await _startForeground();
    try {
      await _microphoneInput.start(
        onFrame: (Uint8List bytes) {
          _handleMicrophoneFrame(bytes);
        },
      );
      await _session.sendControl(AiControlActions.wakeGreeting);
      _micEnabled = true;
      _startWaveDecayTimer();
    } catch (_) {
      await _microphoneInput.stop();
      await _session.stopAudioStream();
      await _stopForeground();
      _audioUplinkGate.reset();
      _micEnabled = false;
      rethrow;
    }
  }

  Future<void> disableAssistantMic() async {
    if (!_micEnabled) {
      return;
    }

    await _microphoneInput.stop();
    await _session.stopAudioStream();
    _audioUplinkGate.reset();
    _micEnabled = false;
    _stopWaveDecayTimer();
    await _stopForeground();
  }

  Future<void> audioPlayerStop() async {
    await _audioPlayer.stop(reason: 'incoming-call-accepted');
  }

  Future<Map<String, Object?>> enableCamera(Map<String, dynamic> params) async {
    _ensureNotDisposed();
    await _cameraStreamer.start(
      onFrame: (Uint8List jpeg) {
        unawaited(_session.sendCameraFrame(jpeg));
      },
    );
    return const <String, Object?>{'status': 'ok'};
  }

  Future<Map<String, Object?>> disableCamera(
    Map<String, dynamic> params,
  ) async {
    await _cameraStreamer.stop();
    return const <String, Object?>{'status': 'ok'};
  }

  /// Tăng FPS camera cho walking navigation (mặc định 1.0 → 1.67 fps trong nav).
  /// No-op khi camera chưa bật.
  Future<void> setNavigationFps({bool active = true}) async {
    await _cameraStreamer.setFrameInterval(
      active
          ? const Duration(milliseconds: 600)
          : const Duration(seconds: 1),
    );
  }

  /// Generic set camera FPS interval (used by Python's set_camera_fps device command).
  Future<Map<String, Object?>> setCameraFps(Duration interval) async {
    await _cameraStreamer.setFrameInterval(interval);
    return <String, Object?>{
      'status': 'ok',
      'interval_ms': interval.inMilliseconds,
    };
  }

  // ── In-app walking navigation (Mapbox) ──

  /// Notifier cho NavigationScreenData hiện tại. Null = không có nav active.
  final ValueNotifier<NavigationScreenData?> navigationScreenData =
      ValueNotifier<NavigationScreenData?>(null);

  /// Khởi tạo navigation screen từ device command `show_navigation_screen`.
  /// Lưu state và emit qua [navigationScreenData] để UI overlay subscribe.
  Future<Map<String, Object?>> showNavigationScreen(
    Map<String, dynamic> params,
  ) async {
    final NavigationScreenData data = NavigationScreenData(
      destinationName: (params['destination_name'] as String?) ?? '',
      destinationQuery: (params['destination_query'] as String?) ?? '',
      totalDistanceM: (params['total_distance_m'] as num?)?.toDouble() ?? 0,
      totalDurationS: (params['total_duration_s'] as num?)?.toDouble() ?? 0,
      totalSteps: (params['total_steps'] as int?) ?? 0,
      currentStepIndex: 1,
      currentStepName: (params['first_step_name'] as String?) ?? '',
      currentStepVoiceVi:
          (params['first_step_voice_english'] as String?) ?? '',
      remainingDistanceM: (params['total_distance_m'] as num?)?.toDouble() ?? 0,
      progressPct: 0,
      isDeviated: false,
      isCompleted: false,
      outcome: 'in_progress',
    );
    navigationScreenData.value = data;
    return <String, Object?>{'status': 'ok'};
  }

  /// Cập nhật step hiện tại (gọi từ announce_navigation_step mỗi 5-10s).
  /// Nếu không có nav active, ignore.
  void updateNavigationStep({
    int? currentStepIndex,
    String? currentStepName,
    String? currentStepVoiceVi,
    double? remainingDistanceM,
    double? progressPct,
    bool? isDeviated,
    bool? isCompleted,
  }) {
    final NavigationScreenData? prev = navigationScreenData.value;
    if (prev == null) return;
    navigationScreenData.value = NavigationScreenData(
      destinationName: prev.destinationName,
      destinationQuery: prev.destinationQuery,
      totalDistanceM: prev.totalDistanceM,
      totalDurationS: prev.totalDurationS,
      totalSteps: prev.totalSteps,
      currentStepIndex: currentStepIndex ?? prev.currentStepIndex,
      currentStepName: currentStepName ?? prev.currentStepName,
      currentStepVoiceVi: currentStepVoiceVi ?? prev.currentStepVoiceVi,
      remainingDistanceM: remainingDistanceM ?? prev.remainingDistanceM,
      progressPct: progressPct ?? prev.progressPct,
      isDeviated: isDeviated ?? prev.isDeviated,
      isCompleted: isCompleted ?? prev.isCompleted,
      outcome: isCompleted == true ? 'completed' : prev.outcome,
    );
  }

  /// Ẩn nav screen từ device command `hide_navigation_screen`.
  Future<Map<String, Object?>> hideNavigationScreen(
    Map<String, dynamic> params,
  ) async {
    navigationScreenData.value = null;
    return <String, Object?>{'status': 'ok'};
  }

  /// User bấm nút "Dừng chỉ đường" trên UI.
  /// Gửi control action stop_navigation lên Python agent qua WS,
  /// agent sẽ tự gọi stop_navigation tool + ghi DB + return summary.
  Future<void> requestStopNavigation() async {
    navigationScreenData.value = null;
    try {
      await _session.sendControl(
        AiControlActions.stopNavigation,
        payload: <String, Object?>{'outcome': 'cancelled'},
      );
    } catch (e) {
      debugPrint('[AiSee:Nav] requestStopNavigation: $e');
    }
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;

    AiseeAssistantIncomingCallBridge.instance.unregisterHandlers();
    await disableAssistantMic();
    await _assistantAudioSub?.cancel();
    await _assistantAudioInterruptedSub?.cancel();
    await _deviceCommandSub?.cancel();
    _assistantAudioSub = null;
    _assistantAudioInterruptedSub = null;
    _deviceCommandSub = null;
    if (_agentStateListenerAttached) {
      _session.agentState.removeListener(_handleAgentStateChanged);
      _agentStateListenerAttached = false;
    }
    _stopWaveDecayTimer();
    assistantWaveEnergy.dispose();
    await _microphoneInput.dispose();
    await _cameraStreamer.dispose();
    await _audioPlayer.dispose();
    await _deviceCommandHandler.dispose();
    await _session.stop();
    _session.dispose();
  }

  Future<void> _handleAssistantAudio(Uint8List bytes) async {
    await _audioPlayer.enqueuePcm16(bytes);
    _boostWaveEnergy(_pcmPeak(bytes));
  }

  Future<void> _handleAssistantAudioInterrupted() async {
    _audioUplinkGate.reset();
    await _audioPlayer.stop(reason: 'assistant-interrupted');
  }

  void _handleAgentStateChanged() {}

  void _handleMicrophoneFrame(Uint8List bytes) {
    final bool assistantOutputActive =
        _audioPlayer.hasPendingAudio ||
        _session.agentState.value == AgentState.speaking;

    // Để uplink gate quyết định: nếu assistant đang nói, gate sẽ drop
    // nhưng vẫn cho phép barge-in nếu user nói to (energy threshold)
    final AiseeAudioUplinkDecision decision = _audioUplinkGate.process(
      bytes,
      assistantOutputActive: assistantOutputActive,
    );

    for (final Uint8List frame in decision.frames) {
      unawaited(_session.sendAudioFrame(frame));
      _boostWaveEnergy(_pcmPeak(frame));
    }
  }

  Future<void> _handleDeviceCommand(AiseeAiDeviceCommandRequest request) async {
    final String name = request.name;
    final bool needsMicPause = DeviceCommandContract.requiresMicPause(name);
    final bool needsAudioStop = DeviceCommandContract.requiresAudioStop(name);
    final bool micWasEnabledBeforeCall =
        DeviceCommandContract.shouldResumeMicAfter(name) && _micEnabled;
    Map<String, Object?> result;
    try {
      if (needsAudioStop) {
        await disableAssistantMic();
        await _audioPlayer.stop(reason: 'play-audio-command');
      } else if (needsMicPause) {
        await disableAssistantMic();
        await _audioPlayer.stop(reason: 'start-call-command');
      }
      debugPrint(
        '[AiSee:ToolCall] dispatching name=${request.name} requestId=${request.requestId}',
      );
      result = await _deviceCommandHandler.handle(request);
      debugPrint(
        '[AiSee:ToolCall] result name=${request.name} status=${result['status']}',
      );
    } on AiseeAssistantDeviceCommandException catch (error) {
      result = <String, Object?>{
        'status': 'error',
        'message': error.message,
        if (error.rpcCode != null) 'code': error.rpcCode,
        'recoverable': true,
      };
    } catch (error) {
      final String errorString = error.toString();
      final bool isPermissionError =
          errorString.contains('permission') ||
          errorString.contains('Permission') ||
          errorString.contains('Cần quyền');
      result = <String, Object?>{
        'status': 'error',
        'message': errorString,
        'recoverable': !isPermissionError,
      };
    }

    try {
      await _session.sendToolResult(request.requestId, result);
    } catch (sendError) {
      debugPrint(
        '[AiSee:ToolCall] failed to send tool_result '
        'name=${request.name} requestId=${request.requestId} error=$sendError',
      );
    } finally {
      if (needsAudioStop) {
        await _resumeWakeAfterMusicPlayback();
      }
      if (DeviceCommandContract.shouldResumeMicAfter(name) && micWasEnabledBeforeCall) {
        await _resumeAssistantAfterCall();
      }
    }
  }

  Future<void> _resumeAssistantAfterCall() async {
    try {
      await enableAssistantMic();
    } catch (error, stackTrace) {
      debugPrint(
        '[AiSee:Call] Failed to resume assistant mic after call: $error\n$stackTrace',
      );
    }
  }

  Future<void> _announceIncomingCallToAgent(AiseeIncomingCall call) async {
    if (!isConnected) {
      debugPrint(
        '[AiSee:IncomingBridge] Session not connected; '
        'skip announce for room=${call.roomName}',
      );
      return;
    }
    try {
      await _session.sendControl(
        AiControlActions.incomingCall,
        payload: <String, Object?>{
          'room_name': call.roomName,
          'caller_name': call.callerName,
          'caller_id': call.callerId,
          'call_type': call.callType,
        },
      );
    } catch (error, stack) {
      debugPrint(
        '[AiSee:IncomingBridge] sendControl incoming_call failed: $error\n$stack',
      );
    }
  }

  Future<void> _announceIncomingCallClearedToAgent(String roomName) async {
    if (!isConnected) {
      return;
    }
    try {
      await _session.sendControl(
        AiControlActions.incomingCallCleared,
        payload: <String, Object?>{'room_name': roomName},
      );
    } catch (error, stack) {
      debugPrint(
        '[AiSee:IncomingBridge] sendControl incoming_call_cleared failed: $error\n$stack',
      );
    }
  }

  Future<void> _resumeWakeAfterMusicPlayback() async {
    final AiseeMusicPlaybackStartedCallback? callback = _onMusicPlaybackStarted;
    if (callback == null) {
      return;
    }
    try {
      await callback();
    } catch (error, stackTrace) {
      debugPrint(
        '[AiSee:Music] Failed to resume wake after playback: $error\n$stackTrace',
      );
    }
  }

  void _boostWaveEnergy(double peak) {
    if (peak > _lastPeak) {
      _lastPeak = peak;
    }
    if (assistantWaveEnergy.value < peak) {
      assistantWaveEnergy.value = peak;
    }
  }

  void _decayWaveEnergy() {
    final double current = assistantWaveEnergy.value;
    if (current <= 0.02) {
      if (current != 0) {
        assistantWaveEnergy.value = 0;
      }
      _lastPeak = 0;
      return;
    }
    assistantWaveEnergy.value = current * 0.88;
  }

  double _pcmPeak(Uint8List bytes) {
    if (bytes.length < 2) {
      return 0;
    }

    final ByteData data = ByteData.sublistView(bytes);
    int peak = 0;
    for (int index = 0; index + 1 < bytes.length; index += 2) {
      final int sample = data.getInt16(index, Endian.little).abs();
      if (sample > peak) {
        peak = sample;
      }
    }
    return (peak / 32768).clamp(0.0, 1.0);
  }

  void _ensureNotDisposed() {
    if (_disposed) {
      throw StateError('AI assistant controller has been disposed.');
    }
  }

  Future<void> _ensureSessionConnectedForWake() async {
    if (isConnected) {
      return;
    }

    final String? token = _lastAccessToken;
    if (token == null || token.isEmpty) {
      throw StateError(
        'AI session is not connected and no token is available.',
      );
    }
    await connect(token);
  }
}
