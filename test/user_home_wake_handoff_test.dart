import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aiseeapp/models/agent_state.dart';
import 'package:aiseeapp/models/aisee_api_models.dart';
import 'package:aiseeapp/services/assistant_audio_coordinator.dart';
import 'package:aiseeapp/services/aisee_livekit_voice_session.dart';
import 'package:aiseeapp/services/aisee_wake_word_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel nativePlatformChannel = MethodChannel(
    'com.aisee.aiseeapp/platform',
  );

  test('live session keeps mic disabled until explicitly enabled', () async {
    final _RecordingVoiceSession session = _RecordingVoiceSession()
      ..connectedForMic = true;
    session.onAfterMicEnabledForRoom = () async {
      session.pauseHookCalls += 1;
    };
    session.onAfterRoomDisconnected = () async {
      session.resumeHookCalls += 1;
    };

    await session.connect(userName: 'user', userId: 'id');

    expect(session.connectCalled, isTrue);
    expect(session.isAssistantMicEnabled, isFalse);

    await session.enableAssistantMic();

    expect(session.isAssistantMicEnabled, isTrue);
    expect(session.micTransitions, <bool>[true]);
    expect(session.pauseHookCalls, 1);
    expect(session.resumeHookCalls, 0);
    expect(session.foregroundStarted, isTrue);

    await session.disableAssistantMic();

    expect(session.isAssistantMicEnabled, isFalse);
    expect(session.micTransitions, <bool>[true, false]);
    expect(session.resumeHookCalls, 1);
    expect(session.foregroundStopped, isTrue);
  });

  test(
    'explicit mic toggle updates state after foreground lifecycle',
    () async {
      final Completer<void> startForegroundCompleter = Completer<void>();
      final Completer<void> stopForegroundCompleter = Completer<void>();
      final _RecordingVoiceSession session = _RecordingVoiceSession(
        startForegroundCompleter: startForegroundCompleter,
        stopForegroundCompleter: stopForegroundCompleter,
      )..connectedForMic = true;

      final Future<void> enableFuture = session.enableAssistantMic();
      await Future<void>.delayed(Duration.zero);

      expect(session.isAssistantMicEnabled, isFalse);

      startForegroundCompleter.complete();
      await enableFuture;

      expect(session.isAssistantMicEnabled, isTrue);
      expect(session.audioSessionConfigs, 1);
      expect(session.micTransitions, <bool>[true]);
      expect(session.foregroundStartCalls, 1);
      expect(session.foregroundStopCalls, 0);

      final Future<void> disableFuture = session.disableAssistantMic();
      await Future<void>.delayed(Duration.zero);

      expect(session.isAssistantMicEnabled, isTrue);

      stopForegroundCompleter.complete();
      await disableFuture;

      expect(session.isAssistantMicEnabled, isFalse);
      expect(session.micTransitions, <bool>[true, false]);
      expect(session.foregroundStartCalls, 1);
      expect(session.foregroundStopCalls, 1);
    },
  );

  test('enableAssistantMic fails when room is not connected', () async {
    final AiseeLiveKitVoiceSession session = _RecordingVoiceSession();

    await expectLater(
      session.enableAssistantMic(),
      throwsA(isA<AiseeApiException>()),
    );

    expect(session.isAssistantMicEnabled, isFalse);
    session.disposeHttp();
  });

  test(
    'disableAssistantMic without active mic does not resume wake word',
    () async {
      final _RecordingVoiceSession session = _RecordingVoiceSession()
        ..connectedForMic = true;
      session.onAfterRoomDisconnected = () async {
        session.resumeHookCalls += 1;
      };

      await session.disableAssistantMic();

      expect(session.isAssistantMicEnabled, isFalse);
      expect(session.resumeHookCalls, 0);
      session.disposeHttp();
    },
  );

  test(
    'enableAssistantMic rolls back mic when foreground start fails',
    () async {
      final _RecordingVoiceSession session = _RecordingVoiceSession(
        failStartForeground: true,
      )..connectedForMic = true;

      await expectLater(session.enableAssistantMic(), throwsStateError);

      expect(session.isAssistantMicEnabled, isFalse);
      expect(session.micTransitions, <bool>[true, false]);
      expect(session.foregroundStartCalls, 1);
      expect(session.foregroundStopCalls, 0);
    },
  );

  test('disableAssistantMic restores mic when foreground stop fails', () async {
    final _RecordingVoiceSession session = _RecordingVoiceSession(
      failStopForeground: true,
    )..connectedForMic = true;

    await session.enableAssistantMic();
    expect(session.isAssistantMicEnabled, isTrue);

    await expectLater(session.disableAssistantMic(), throwsStateError);

    expect(session.isAssistantMicEnabled, isTrue);
    expect(session.micTransitions, <bool>[true, false, true]);
    expect(session.foregroundStartCalls, 1);
    expect(session.foregroundStopCalls, 1);
  });

  test(
    'disconnect stops foreground service through mic lifecycle seam',
    () async {
      final _RecordingVoiceSession session = _RecordingVoiceSession();

      await session.disconnect();

      expect(session.foregroundStopCalls, 1);
      expect(session.isAssistantMicEnabled, isFalse);
    },
  );

  test(
    'disconnect swallows foreground stop failures during teardown',
    () async {
      final _RecordingVoiceSession session = _RecordingVoiceSession(
        failStopForeground: true,
      );

      await session.disconnect();

      expect(session.foregroundStopCalls, 1);
      expect(session.isAssistantMicEnabled, isFalse);
    },
  );

  test('wake word can stop for live session and resume later', () async {
    final _FakeWakeWordBackend backend = _FakeWakeWordBackend();
    final AiseeWakeWordService service = AiseeWakeWordService.test(
      wakeModel: backend,
      started: true,
      listening: true,
    );

    expect(service.isConfiguredAndStarted, isTrue);
    expect(service.isListening, isTrue);

    await service.stopForLiveSession();
    expect(service.isListening, isFalse);
    expect(backend.stopListeningCalls, 1);

    await service.startIdleListening();
    expect(service.isListening, isTrue);
    expect(backend.startListeningCalls, 1);
  });

  test('failed wake start cleans up stale native instance for retry', () async {
    final _FakeWakeWordBackend backend = _FakeWakeWordBackend()
      ..failAddInstanceCount = 1;
    final AiseeWakeWordService service = AiseeWakeWordService.test(
      wakeModel: backend,
      isSupportedPlatform: true,
      microphoneGranted: true,
      license: 'valid-license',
      modelNames: const <String>['hey_lookdeep.onnx'],
    );

    await service.startIfConfigured();

    expect(service.isConfiguredAndStarted, isFalse);
    expect(service.isListening, isFalse);
    expect(backend.removeInstanceCalls, 1);

    await service.startIfConfigured();

    expect(service.isConfiguredAndStarted, isTrue);
    expect(service.isListening, isTrue);
    expect(backend.addInstanceMultiCalls, 2);
  });

  test(
    'wake start skips unsupported native runtime without touching backend',
    () async {
      final _FakeWakeWordBackend backend = _FakeWakeWordBackend();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(nativePlatformChannel, (
            MethodCall call,
          ) async {
            if (call.method == 'getWakeWordRuntimeSupport') {
              return <String, Object?>{
                'isSupported': false,
                'reason': 'abi x86_64 has no bundled wake-word JNI libs',
              };
            }
            return null;
          });

      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(nativePlatformChannel, null);
      });

      final AiseeWakeWordService service = AiseeWakeWordService.test(
        wakeModel: backend,
        isSupportedPlatform: true,
        microphoneGranted: true,
        license: 'valid-license',
        modelNames: const <String>['hey_lookdeep.onnx'],
      );

      await service.startIfConfigured();

      expect(service.isConfiguredAndStarted, isFalse);
      expect(service.isListening, isFalse);
      expect(backend.addInstanceMultiCalls, 0);
      expect(backend.setLicenseCalls, 0);
    },
  );

  test(
    'wake start skips translated android abi even if probe reports supported',
    () async {
      final _FakeWakeWordBackend backend = _FakeWakeWordBackend();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(nativePlatformChannel, (
            MethodCall call,
          ) async {
            if (call.method == 'getWakeWordRuntimeSupport') {
              return <String, Object?>{
                'isSupported': true,
                'reason': 'legacy any-abi probe allowed arm64 fallback',
                'supportedAbis': <String>['x86_64', 'arm64-v8a'],
                'requiredAbis': <String>['arm64-v8a'],
                'isEmulator': true,
              };
            }
            return null;
          });

      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(nativePlatformChannel, null);
      });

      final AiseeWakeWordService service = AiseeWakeWordService.test(
        wakeModel: backend,
        isSupportedPlatform: true,
        microphoneGranted: true,
        license: 'valid-license',
        modelNames: const <String>['hey_lookdeep.onnx'],
      );

      await service.startIfConfigured();

      expect(service.isConfiguredAndStarted, isFalse);
      expect(service.isListening, isFalse);
      expect(backend.addInstanceMultiCalls, 0);
      expect(backend.setLicenseCalls, 0);
    },
  );

  test('wake feature is disabled when config is missing', () {
    final AiseeWakeWordService service = AiseeWakeWordService.test(
      wakeModel: _FakeWakeWordBackend(),
      isSupportedPlatform: true,
      microphoneGranted: true,
      license: '',
      modelNames: const <String>[],
    );

    expect(service.isFeatureEnabledByConfig, isFalse);
  });

  test('wake feature is enabled when license and model exist', () {
    final AiseeWakeWordService service = AiseeWakeWordService.test(
      wakeModel: _FakeWakeWordBackend(),
      isSupportedPlatform: true,
      microphoneGranted: true,
      license: 'valid-license',
      modelNames: const <String>['hey_lookdeep.onnx'],
    );

    expect(service.isFeatureEnabledByConfig, isTrue);
  });

  test('wake detection enables mic and stops wake listening', () async {
    final _RecordingCoordinatorOps ops = _RecordingCoordinatorOps();
    final AssistantAudioCoordinator controller = AssistantAudioCoordinator(
      startWakeListening: ops.startWakeListening,
      stopWakeListening: ops.stopWakeListening,
      enableAssistantMic: ops.enableAssistantMic,
      disableAssistantMic: ops.disableAssistantMic,
      switchToAssistantTab: ops.switchToAssistantTab,
      gracePeriod: const Duration(milliseconds: 20),
    );

    await controller.onWakeDetected();

    expect(controller.state, AssistantAudioState.conversationActive);
    expect(ops.wakeListening, isFalse);
    expect(ops.liveMicEnabled, isTrue);
    expect(ops.enableMicCalls, 1);
    expect(ops.switchTabCalls, 1);
  });

  test('default conversation grace period keeps session open longer', () {
    final _RecordingCoordinatorOps ops = _RecordingCoordinatorOps();
    final AssistantAudioCoordinator controller = AssistantAudioCoordinator(
      startWakeListening: ops.startWakeListening,
      stopWakeListening: ops.stopWakeListening,
      enableAssistantMic: ops.enableAssistantMic,
      disableAssistantMic: ops.disableAssistantMic,
      switchToAssistantTab: ops.switchToAssistantTab,
    );

    expect(controller.gracePeriod, const Duration(seconds: 90));
  });

  test('agent idle starts grace period and timeout returns to wake', () async {
    final _RecordingCoordinatorOps ops = _RecordingCoordinatorOps();
    final List<String> idleReasons = <String>[];
    final AssistantAudioCoordinator controller = AssistantAudioCoordinator(
      startWakeListening: ops.startWakeListening,
      stopWakeListening: ops.stopWakeListening,
      enableAssistantMic: ops.enableAssistantMic,
      disableAssistantMic: ops.disableAssistantMic,
      switchToAssistantTab: ops.switchToAssistantTab,
      gracePeriod: const Duration(milliseconds: 20),
      onReturnedToIdleWake: idleReasons.add,
    );

    await controller.onWakeDetected();
    controller.onAgentStateChanged(AgentState.idle);
    await Future<void>.delayed(const Duration(milliseconds: 40));

    expect(controller.state, AssistantAudioState.idleListeningWake);
    expect(ops.wakeListening, isTrue);
    expect(ops.liveMicEnabled, isFalse);
    expect(idleReasons, <String>['grace-expired']);
  });

  test(
    'new activity during grace period restores active conversation',
    () async {
      final _RecordingCoordinatorOps ops = _RecordingCoordinatorOps();
      final AssistantAudioCoordinator controller = AssistantAudioCoordinator(
        startWakeListening: ops.startWakeListening,
        stopWakeListening: ops.stopWakeListening,
        enableAssistantMic: ops.enableAssistantMic,
        disableAssistantMic: ops.disableAssistantMic,
        switchToAssistantTab: ops.switchToAssistantTab,
        gracePeriod: const Duration(milliseconds: 40),
      );

      await controller.onWakeDetected();
      controller.onAgentStateChanged(AgentState.idle);
      controller.onAgentStateChanged(AgentState.speaking);
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(controller.state, AssistantAudioState.conversationActive);
      expect(ops.liveMicEnabled, isTrue);
      expect(ops.wakeListening, isFalse);
    },
  );

  test('duplicate wake event during active conversation is ignored', () async {
    final _RecordingCoordinatorOps ops = _RecordingCoordinatorOps();
    final AssistantAudioCoordinator controller = AssistantAudioCoordinator(
      startWakeListening: ops.startWakeListening,
      stopWakeListening: ops.stopWakeListening,
      enableAssistantMic: ops.enableAssistantMic,
      disableAssistantMic: ops.disableAssistantMic,
      switchToAssistantTab: ops.switchToAssistantTab,
      gracePeriod: const Duration(milliseconds: 20),
    );

    await controller.onWakeDetected();
    await controller.onWakeDetected();

    expect(controller.state, AssistantAudioState.conversationActive);
    expect(ops.enableMicCalls, 1);
  });

  test('mic enable failure restores idle wake mode', () async {
    final _RecordingCoordinatorOps ops = _RecordingCoordinatorOps(
      failEnableMic: true,
    );
    final AssistantAudioCoordinator controller = AssistantAudioCoordinator(
      startWakeListening: ops.startWakeListening,
      stopWakeListening: ops.stopWakeListening,
      enableAssistantMic: ops.enableAssistantMic,
      disableAssistantMic: ops.disableAssistantMic,
      switchToAssistantTab: ops.switchToAssistantTab,
      gracePeriod: const Duration(milliseconds: 20),
    );

    await controller.onWakeDetected();

    expect(controller.state, AssistantAudioState.idleListeningWake);
    expect(ops.wakeListening, isTrue);
    expect(ops.liveMicEnabled, isFalse);
  });

  test(
    'pause during active conversation keeps live mic for background screen-off use',
    () async {
      final _RecordingCoordinatorOps ops = _RecordingCoordinatorOps();
      final AssistantAudioCoordinator controller = AssistantAudioCoordinator(
        startWakeListening: ops.startWakeListening,
        stopWakeListening: ops.stopWakeListening,
        enableAssistantMic: ops.enableAssistantMic,
        disableAssistantMic: ops.disableAssistantMic,
        switchToAssistantTab: ops.switchToAssistantTab,
        gracePeriod: const Duration(milliseconds: 20),
      );

      await controller.onWakeDetected();
      await controller.onAppPaused();

      expect(controller.state, AssistantAudioState.conversationActive);
      expect(ops.liveMicEnabled, isTrue);
      expect(ops.wakeListening, isFalse);
      expect(ops.startWakeListeningCalls, 0);
      expect(ops.disableMicCalls, 0);

      await controller.onAppResumed(liveKitConnected: true);

      expect(controller.state, AssistantAudioState.conversationActive);
      expect(ops.liveMicEnabled, isTrue);
      expect(ops.wakeListening, isFalse);
      expect(ops.startWakeListeningCalls, 0);
    },
  );

  test(
    'pause while idle keeps wake listening without touching live mic',
    () async {
      final _RecordingCoordinatorOps ops = _RecordingCoordinatorOps();
      final AssistantAudioCoordinator controller = AssistantAudioCoordinator(
        startWakeListening: ops.startWakeListening,
        stopWakeListening: ops.stopWakeListening,
        enableAssistantMic: ops.enableAssistantMic,
        disableAssistantMic: ops.disableAssistantMic,
        switchToAssistantTab: ops.switchToAssistantTab,
        gracePeriod: const Duration(milliseconds: 20),
      );

      await controller.onAppPaused();

      expect(controller.state, AssistantAudioState.idleListeningWake);
      expect(ops.liveMicEnabled, isFalse);
      expect(ops.wakeListening, isTrue);
      expect(ops.startWakeListeningCalls, 0);
      expect(ops.disableMicCalls, 0);
    },
  );
}

class _RecordingVoiceSession extends AiseeLiveKitVoiceSession {
  _RecordingVoiceSession({
    this.startForegroundCompleter,
    this.stopForegroundCompleter,
    this.failStartForeground = false,
    this.failStopForeground = false,
  });

  final Completer<void>? startForegroundCompleter;
  final Completer<void>? stopForegroundCompleter;
  final bool failStartForeground;
  final bool failStopForeground;

  bool connectCalled = false;
  bool connectedForMic = false;
  bool foregroundStarted = false;
  bool foregroundStopped = false;
  int foregroundStartCalls = 0;
  int foregroundStopCalls = 0;
  int audioSessionConfigs = 0;
  int pauseHookCalls = 0;
  int resumeHookCalls = 0;
  final List<bool> micTransitions = <bool>[];

  @override
  Future<void> connect({
    required String userName,
    required String userId,
    Future<bool>? resolveHasFamilyLink,
  }) async {
    connectCalled = true;
    await completeConnectedSetup();
  }

  @override
  bool get hasConnectedLocalParticipant => connectedForMic;

  @override
  Future<void> setRoomMicrophoneEnabled(bool enabled) async {
    if (!connectedForMic) {
      throw AiseeApiException('LiveKit chưa sẵn sàng để bật micro.');
    }
    micTransitions.add(enabled);
  }

  @override
  void syncLocalCameraPreviewTrack() {}

  @override
  void startWaveDecayTimer() {}

  @override
  Future<void> ensureForegroundStartedAfterConnected() async {
    foregroundStartCalls += 1;
    foregroundStarted = true;
    if (failStartForeground) {
      throw StateError('foreground start failed');
    }
    await startForegroundCompleter?.future;
  }

  @override
  Future<void> ensureForegroundStopped() async {
    foregroundStopCalls += 1;
    foregroundStopped = true;
    if (failStopForeground) {
      throw StateError('foreground stop failed');
    }
    await stopForegroundCompleter?.future;
  }

  @override
  Future<void> configureAudioSession() async {
    audioSessionConfigs += 1;
  }
}

class _FakeWakeWordBackend implements AiseeWakeWordBackend {
  int addInstanceMultiCalls = 0;
  int removeInstanceCalls = 0;
  int setLicenseCalls = 0;
  int startListeningCalls = 0;
  int stopListeningCalls = 0;
  int failAddInstanceCount = 0;

  @override
  Future<void> addInstanceMulti(
    Object config,
    void Function(Map<String, dynamic> event) onDetectionEvent,
  ) async {
    addInstanceMultiCalls += 1;
    if (failAddInstanceCount > 0) {
      failAddInstanceCount -= 1;
      throw Exception('INSTANCE_EXISTS');
    }
  }

  @override
  Future<void> removeInstance(String id) async {
    removeInstanceCalls += 1;
  }

  @override
  Future<void> setKeywordDetectionLicense(String license) async {
    setLicenseCalls += 1;
  }

  @override
  Future<void> startListening() async {
    startListeningCalls += 1;
  }

  @override
  Future<void> stopListening() async {
    stopListeningCalls += 1;
  }
}

class _RecordingCoordinatorOps {
  _RecordingCoordinatorOps({this.failEnableMic = false});

  final bool failEnableMic;
  bool wakeListening = true;
  bool liveMicEnabled = false;
  int enableMicCalls = 0;
  int disableMicCalls = 0;
  int startWakeListeningCalls = 0;
  int switchTabCalls = 0;

  Future<void> startWakeListening() async {
    startWakeListeningCalls += 1;
    wakeListening = true;
  }

  Future<void> stopWakeListening() async {
    wakeListening = false;
  }

  Future<void> enableAssistantMic() async {
    enableMicCalls += 1;
    if (failEnableMic) {
      throw AiseeApiException('enable failed');
    }
    liveMicEnabled = true;
  }

  Future<void> disableAssistantMic() async {
    disableMicCalls += 1;
    liveMicEnabled = false;
  }

  void switchToAssistantTab() {
    switchTabCalls += 1;
  }
}
