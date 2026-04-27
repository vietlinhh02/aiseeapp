import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../models/agent_state.dart';
import 'aisee_ai_camera_streamer.dart';
import 'aisee_ai_microphone_input.dart';
import 'aisee_ai_session.dart';
import 'aisee_audio_uplink_gate.dart';
import 'aisee_assistant_device_command_handler.dart';
import 'aisee_pcm_audio_player.dart';
import 'aisee_voice_audio_session.dart';
import 'aisee_voice_foreground.dart';

typedef AiseeMusicPlaybackStartedCallback = Future<void> Function();
typedef AiseeAssistantForegroundAction = Future<void> Function();

abstract interface class AiseeAiAssistantSessionClient {
  ValueListenable<AgentState> get agentState;
  ValueListenable<AiseeAiSessionConnectionStatus> get connectionStatus;

  Stream<Uint8List> get assistantAudioBytes;
  Stream<void> get assistantAudioInterrupted;
  Stream<AiseeAiDeviceCommandRequest> get deviceCommands;

  Future<AiseeAiSessionConfig> start(String accessToken);
  Future<void> sendAudioFrame(Uint8List bytes);
  Future<void> sendCameraFrame(Uint8List bytes);
  Future<void> sendControl(String action);
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
  Future<void> sendControl(String action) {
    return _session.sendControl(action);
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
    Duration micResumeDelayAfterAssistantAudio = const Duration(
      milliseconds: 900,
    ),
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
       _audioUplinkGate = audioUplinkGate ?? AiseeAudioUplinkGate(),
       _micResumeDelayAfterAssistantAudio = micResumeDelayAfterAssistantAudio {
    _waveDecayTimer = Timer.periodic(
      const Duration(milliseconds: 50),
      (_) => _decayWaveEnergy(),
    );
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
  final Duration _micResumeDelayAfterAssistantAudio;

  final ValueNotifier<double> assistantWaveEnergy = ValueNotifier<double>(0);

  StreamSubscription<Uint8List>? _assistantAudioSub;
  StreamSubscription<void>? _assistantAudioInterruptedSub;
  StreamSubscription<AiseeAiDeviceCommandRequest>? _deviceCommandSub;
  Timer? _waveDecayTimer;
  Timer? _micUplinkResumeTimer;

  bool _micEnabled = false;
  bool _assistantOutputActive = false;
  bool _agentStateListenerAttached = false;
  bool _disposed = false;
  double _lastPeak = 0;
  String? _lastAccessToken;

  ValueListenable<AgentState> get agentState => _session.agentState;

  ValueListenable<String?> get nowPlayingTitle =>
      _deviceCommandHandler.nowPlayingTitle;

  ValueListenable<Widget?> get cameraPreview => _cameraStreamer.preview;

  bool get isConnected {
    final AiseeAiSessionConnectionStatus status =
        _session.connectionStatus.value;
    return status == AiseeAiSessionConnectionStatus.connected ||
        status == AiseeAiSessionConnectionStatus.ready;
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
  }

  Future<void> enableAssistantMic() async {
    _ensureNotDisposed();
    if (_micEnabled) {
      return;
    }
    await _ensureSessionConnectedForWake();

    await configureAiseeVoiceAudioSession();
    await _startForeground();
    try {
      await _microphoneInput.start(
        onFrame: (Uint8List bytes) {
          _handleMicrophoneFrame(bytes);
        },
      );
      await _session.sendControl('wake_greeting');
      _micEnabled = true;
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
    await _stopForeground();
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

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;

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
    _micUplinkResumeTimer?.cancel();
    _micUplinkResumeTimer = null;
    _waveDecayTimer?.cancel();
    _waveDecayTimer = null;
    assistantWaveEnergy.value = 0;
    assistantWaveEnergy.dispose();
    await _microphoneInput.dispose();
    await _cameraStreamer.dispose();
    await _audioPlayer.dispose();
    await _deviceCommandHandler.dispose();
    await _session.stop();
    _session.dispose();
  }

  Future<void> _handleAssistantAudio(Uint8List bytes) async {
    _markAssistantOutputActive();
    await _audioPlayer.enqueuePcm16(bytes);
    _boostWaveEnergy(_pcmPeak(bytes));
  }

  Future<void> _handleAssistantAudioInterrupted() async {
    _assistantOutputActive = false;
    _micUplinkResumeTimer?.cancel();
    _micUplinkResumeTimer = null;
    _audioUplinkGate.reset();
    await _audioPlayer.stop(reason: 'assistant-interrupted');
  }

  void _handleAgentStateChanged() {
    if (_session.agentState.value == AgentState.speaking) {
      _markAssistantOutputActive();
    }
  }

  void _handleMicrophoneFrame(Uint8List bytes) {
    final AiseeAudioUplinkDecision decision = _audioUplinkGate.process(
      bytes,
      assistantOutputActive: _assistantOutputActive,
    );
    if (decision.bargeIn) {
      _assistantOutputActive = false;
      _micUplinkResumeTimer?.cancel();
      _micUplinkResumeTimer = null;
      unawaited(_audioPlayer.stop(reason: 'barge-in'));
    }
    for (final Uint8List frame in decision.frames) {
      unawaited(_session.sendAudioFrame(frame));
      _boostWaveEnergy(_pcmPeak(frame));
    }
  }

  void _markAssistantOutputActive() {
    _assistantOutputActive = true;
    _micUplinkResumeTimer?.cancel();
    _micUplinkResumeTimer = Timer(_micResumeDelayAfterAssistantAudio, () {
      if (_session.agentState.value == AgentState.speaking) {
        _markAssistantOutputActive();
        return;
      }
      _assistantOutputActive = false;
      _micUplinkResumeTimer = null;
    });
  }

  Future<void> _handleDeviceCommand(AiseeAiDeviceCommandRequest request) async {
    final bool isMusicPlaybackCommand = request.name == 'play_audio';
    Map<String, Object?> result;
    try {
      if (isMusicPlaybackCommand) {
        await disableAssistantMic();
        await _audioPlayer.stop(reason: 'play-audio-command');
      }
      result = await _deviceCommandHandler.handle(request);
    } on AiseeAssistantDeviceCommandException catch (error) {
      result = <String, Object?>{
        'status': 'error',
        'message': error.message,
        if (error.rpcCode != null) 'code': error.rpcCode,
      };
    } catch (error) {
      result = <String, Object?>{
        'status': 'error',
        'message': error.toString(),
      };
    }

    try {
      await _session.sendToolResult(request.requestId, result);
    } finally {
      if (isMusicPlaybackCommand) {
        await _resumeWakeAfterMusicPlayback();
      }
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
