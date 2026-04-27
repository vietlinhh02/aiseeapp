import 'dart:async';

import 'package:aiseeapp/models/agent_state.dart';
import 'package:aiseeapp/services/aisee_ai_assistant_controller.dart';
import 'package:aiseeapp/services/aisee_ai_camera_streamer.dart';
import 'package:aiseeapp/services/aisee_ai_microphone_input.dart';
import 'package:aiseeapp/services/aisee_ai_session.dart';
import 'package:aiseeapp/services/aisee_audio_uplink_gate.dart';
import 'package:aiseeapp/services/aisee_assistant_device_command_handler.dart';
import 'package:aiseeapp/services/aisee_pcm_audio_player.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'enableAssistantMic streams pcm16 microphone frames to the AI session',
    () async {
      final _FakeAssistantSession session = _FakeAssistantSession();
      final _FakeMicrophoneInput microphone = _FakeMicrophoneInput();
      final _FakePcmPlayer player = _FakePcmPlayer();
      final _FakeDeviceCommandHandler commandHandler =
          _FakeDeviceCommandHandler();
      final AiseeAiAssistantController controller = AiseeAiAssistantController(
        session: session,
        microphoneInput: microphone,
        cameraStreamer: _FakeCameraStreamer(),
        audioPlayer: player,
        deviceCommandHandler: commandHandler,
      );

      await controller.connect('app-token');
      await controller.enableAssistantMic();
      microphone.emit(_pcmFrame(20));
      microphone.emit(_pcmFrame(3600));
      await pumpEventQueue();
      await controller.disableAssistantMic();

      expect(session.startedTokens, <String>['app-token']);
      expect(microphone.startCalls, 1);
      expect(microphone.stopCalls, 1);
      expect(session.sentControls, <String>['wake_greeting']);
      expect(session.stopAudioStreamCalls, 1);
      expect(session.sentAudioFrames, <Uint8List>[_pcmFrame(3600)]);

      await controller.dispose();
    },
  );

  test(
    'enableAssistantMic starts foreground service before microphone input',
    () async {
      final _FakeAssistantSession session = _FakeAssistantSession();
      final _FakeMicrophoneInput microphone = _FakeMicrophoneInput();
      final List<String> order = <String>[];
      microphone.onStart = () {
        order.add('mic-start');
      };
      final AiseeAiAssistantController controller = AiseeAiAssistantController(
        session: session,
        microphoneInput: microphone,
        cameraStreamer: _FakeCameraStreamer(),
        audioPlayer: _FakePcmPlayer(),
        deviceCommandHandler: _FakeDeviceCommandHandler(),
        startForeground: () async {
          order.add('foreground-start');
        },
        stopForeground: () async {
          order.add('foreground-stop');
        },
      );

      await controller.connect('app-token');
      await controller.enableAssistantMic();
      await controller.disableAssistantMic();

      expect(order, <String>[
        'foreground-start',
        'mic-start',
        'foreground-stop',
      ]);

      await controller.dispose();
    },
  );

  test(
    'enableAssistantMic rolls back foreground service when microphone start fails',
    () async {
      final _FakeMicrophoneInput microphone = _FakeMicrophoneInput()
        ..failStart = true;
      int foregroundStarts = 0;
      int foregroundStops = 0;
      final AiseeAiAssistantController controller = AiseeAiAssistantController(
        session: _FakeAssistantSession(),
        microphoneInput: microphone,
        cameraStreamer: _FakeCameraStreamer(),
        audioPlayer: _FakePcmPlayer(),
        deviceCommandHandler: _FakeDeviceCommandHandler(),
        startForeground: () async {
          foregroundStarts += 1;
        },
        stopForeground: () async {
          foregroundStops += 1;
        },
      );

      await controller.connect('app-token');

      await expectLater(controller.enableAssistantMic(), throwsStateError);

      expect(foregroundStarts, 1);
      expect(foregroundStops, 1);
      expect(microphone.stopCalls, 1);

      await controller.dispose();
    },
  );

  test('audio gate drops steady background noise before uplink', () {
    final AiseeAudioUplinkGate gate = AiseeAudioUplinkGate();

    for (int i = 0; i < 20; i += 1) {
      final AiseeAudioUplinkDecision decision = gate.process(
        _pcmFrame(18),
        assistantOutputActive: false,
      );
      expect(decision.frames, isEmpty);
      expect(decision.bargeIn, isFalse);
    }

    final AiseeAudioUplinkDecision speech = gate.process(
      _pcmFrame(3600),
      assistantOutputActive: false,
    );

    expect(speech.frames, <Uint8List>[_pcmFrame(3600)]);
    expect(speech.bargeIn, isFalse);
  });

  test(
    'loud user speech during assistant output barges in and stops playback',
    () async {
      final _FakeAssistantSession session = _FakeAssistantSession();
      final _FakeMicrophoneInput microphone = _FakeMicrophoneInput();
      final _FakePcmPlayer player = _FakePcmPlayer();
      final AiseeAiAssistantController controller = AiseeAiAssistantController(
        session: session,
        microphoneInput: microphone,
        cameraStreamer: _FakeCameraStreamer(),
        audioPlayer: player,
        deviceCommandHandler: _FakeDeviceCommandHandler(),
      );

      await controller.connect('app-token');
      await controller.enableAssistantMic();
      session.agentState.value = AgentState.speaking;
      session.emitAssistantAudio(_pcmFrame(1200));
      await pumpEventQueue();

      microphone.emit(_pcmFrame(80));
      await pumpEventQueue();
      expect(session.sentAudioFrames, isEmpty);

      microphone.emit(_pcmFrame(5200));
      await pumpEventQueue();

      expect(session.sentAudioFrames, <Uint8List>[_pcmFrame(5200)]);
      expect(session.sentControls, isNot(contains('interrupt')));
      expect(player.stopCalls, 1);
      expect(player.stopReasons, <String>['barge-in']);

      await controller.dispose();
    },
  );

  test(
    'barge-in suppresses stale assistant audio until user turn advances',
    () async {
      final _FakeAssistantSession session = _FakeAssistantSession();
      final _FakeMicrophoneInput microphone = _FakeMicrophoneInput();
      final _FakePcmPlayer player = _FakePcmPlayer();
      final AiseeAiAssistantController controller = AiseeAiAssistantController(
        session: session,
        microphoneInput: microphone,
        cameraStreamer: _FakeCameraStreamer(),
        audioPlayer: player,
        deviceCommandHandler: _FakeDeviceCommandHandler(),
      );

      await controller.connect('app-token');
      await controller.enableAssistantMic();
      session.agentState.value = AgentState.speaking;
      session.emitAssistantAudio(_pcmFrame(1200));
      await pumpEventQueue();

      microphone.emit(_pcmFrame(5200));
      await pumpEventQueue();

      session.emitAssistantAudio(_pcmFrame(1300));
      session.emitAssistantAudio(_pcmFrame(1400));
      await pumpEventQueue();

      expect(player.enqueuedChunks, <Uint8List>[_pcmFrame(1200)]);
      expect(player.stopReasons, <String>['barge-in']);

      session.agentState.value = AgentState.listening;
      session.agentState.value = AgentState.speaking;
      session.emitAssistantAudio(_pcmFrame(1500));
      await pumpEventQueue();

      expect(player.enqueuedChunks, <Uint8List>[
        _pcmFrame(1200),
        _pcmFrame(1500),
      ]);

      await controller.dispose();
    },
  );

  test(
    'low-level assistant echo after idle state does not stop playback',
    () async {
      final _FakeAssistantSession session = _FakeAssistantSession();
      final _FakeMicrophoneInput microphone = _FakeMicrophoneInput();
      final _FakePcmPlayer player = _FakePcmPlayer();
      final AiseeAiAssistantController controller = AiseeAiAssistantController(
        session: session,
        microphoneInput: microphone,
        cameraStreamer: _FakeCameraStreamer(),
        audioPlayer: player,
        deviceCommandHandler: _FakeDeviceCommandHandler(),
      );

      await controller.connect('app-token');
      await controller.enableAssistantMic();
      session.emitAssistantAudio(_pcmFrame(1200));
      await pumpEventQueue();
      session.agentState.value = AgentState.idle;

      microphone.emit(_pcmFrame(80));
      await pumpEventQueue();

      expect(player.stopCalls, 0);
      expect(session.sentControls, isNot(contains('interrupt')));
      expect(session.sentAudioFrames, isEmpty);

      await controller.dispose();
    },
  );

  test('server interrupted event clears assistant playback queue', () async {
    final _FakeAssistantSession session = _FakeAssistantSession();
    final _FakePcmPlayer player = _FakePcmPlayer();
    final AiseeAiAssistantController controller = AiseeAiAssistantController(
      session: session,
      microphoneInput: _FakeMicrophoneInput(),
      cameraStreamer: _FakeCameraStreamer(),
      audioPlayer: player,
      deviceCommandHandler: _FakeDeviceCommandHandler(),
    );

    await controller.connect('app-token');
    session.emitAssistantAudio(_pcmFrame(1200));
    session.emitAssistantAudioInterrupted();
    await pumpEventQueue();

    expect(player.enqueuedChunks, <Uint8List>[_pcmFrame(1200)]);
    expect(player.stopReasons, <String>['assistant-interrupted']);

    await controller.dispose();
  });

  test(
    'state churn during assistant output only interrupts on clear speech',
    () async {
      final _FakeAssistantSession session = _FakeAssistantSession();
      final _FakeMicrophoneInput microphone = _FakeMicrophoneInput();
      final _FakePcmPlayer player = _FakePcmPlayer();
      final AiseeAiAssistantController controller = AiseeAiAssistantController(
        session: session,
        microphoneInput: microphone,
        cameraStreamer: _FakeCameraStreamer(),
        audioPlayer: player,
        deviceCommandHandler: _FakeDeviceCommandHandler(),
      );

      await controller.connect('app-token');
      await controller.enableAssistantMic();

      for (int i = 0; i < 4; i += 1) {
        session.agentState.value = AgentState.speaking;
        session.emitAssistantAudio(_pcmFrame(1200 + i));
        await pumpEventQueue();
        microphone.emit(_pcmFrame(80));
        await pumpEventQueue();

        session.agentState.value = AgentState.idle;
        microphone.emit(_pcmFrame(80));
        await pumpEventQueue();
      }

      expect(player.enqueuedChunks.length, 4);
      expect(player.stopCalls, 0);
      expect(session.sentControls, isNot(contains('interrupt')));
      expect(session.sentAudioFrames, isEmpty);

      await controller.dispose();
    },
  );

  test('echo-only gate passes normal speech and drops assistant echo', () {
    final AiseeAudioUplinkGate gate = AiseeAudioUplinkGate.echoOnly();

    final AiseeAudioUplinkDecision normalSpeech = gate.process(
      _pcmFrame(600),
      assistantOutputActive: false,
    );
    expect(normalSpeech.frames, <Uint8List>[_pcmFrame(600)]);
    expect(normalSpeech.bargeIn, isFalse);

    final AiseeAudioUplinkDecision assistantEcho = gate.process(
      _pcmFrame(900),
      assistantOutputActive: true,
    );
    expect(assistantEcho.frames, isEmpty);
    expect(assistantEcho.bargeIn, isFalse);

    final AiseeAudioUplinkDecision userInterrupt = gate.process(
      _pcmFrame(5200),
      assistantOutputActive: true,
    );
    expect(userInterrupt.frames, <Uint8List>[_pcmFrame(5200)]);
    expect(userInterrupt.bargeIn, isTrue);
  });

  test(
    'assistant audio and device commands are routed through the controller',
    () async {
      final _FakeAssistantSession session = _FakeAssistantSession();
      final _FakeMicrophoneInput microphone = _FakeMicrophoneInput();
      final _FakePcmPlayer player = _FakePcmPlayer();
      final _FakeDeviceCommandHandler commandHandler =
          _FakeDeviceCommandHandler(
            responses: <String, Map<String, Object?>>{
              'play_audio': <String, Object?>{
                'status': 'ok',
                'title': 'Lullaby',
              },
            },
          );
      final AiseeAiAssistantController controller = AiseeAiAssistantController(
        session: session,
        microphoneInput: microphone,
        cameraStreamer: _FakeCameraStreamer(),
        audioPlayer: player,
        deviceCommandHandler: commandHandler,
      );

      await controller.connect('app-token');
      session.emitAssistantAudio(Uint8List.fromList(<int>[9, 8, 7, 6]));
      session.emitDeviceCommand(
        const AiseeAiDeviceCommandRequest(
          requestId: 'tool-1',
          name: 'play_audio',
          params: <String, dynamic>{'url': 'https://example.test/song.mp3'},
        ),
      );
      await pumpEventQueue();

      expect(player.enqueuedChunks, <Uint8List>[
        Uint8List.fromList(<int>[9, 8, 7, 6]),
      ]);
      expect(player.stopCalls, 1);
      expect(player.stopReasons, <String>['play-audio-command']);
      expect(commandHandler.handledCommands.single.name, 'play_audio');
      expect(session.toolResults.single.requestId, 'tool-1');
      expect(session.toolResults.single.result, <String, Object?>{
        'status': 'ok',
        'title': 'Lullaby',
      });

      await controller.dispose();
    },
  );

  test('play_audio stops assistant microphone before music playback', () async {
    final _FakeAssistantSession session = _FakeAssistantSession();
    final _FakeMicrophoneInput microphone = _FakeMicrophoneInput();
    final _FakePcmPlayer player = _FakePcmPlayer();
    final _FakeDeviceCommandHandler commandHandler = _FakeDeviceCommandHandler(
      responses: <String, Map<String, Object?>>{
        'play_audio': <String, Object?>{'status': 'ok'},
      },
    );
    final AiseeAiAssistantController controller = AiseeAiAssistantController(
      session: session,
      microphoneInput: microphone,
      cameraStreamer: _FakeCameraStreamer(),
      audioPlayer: player,
      deviceCommandHandler: commandHandler,
    );

    await controller.connect('app-token');
    await controller.enableAssistantMic();
    session.emitDeviceCommand(
      const AiseeAiDeviceCommandRequest(
        requestId: 'tool-music',
        name: 'play_audio',
        params: <String, dynamic>{'url': 'https://example.test/song.mp3'},
      ),
    );
    await pumpEventQueue();

    expect(microphone.stopCalls, 1);
    expect(session.stopAudioStreamCalls, 1);
    expect(player.stopCalls, 1);
    expect(player.stopReasons, <String>['play-audio-command']);
    expect(commandHandler.handledCommands.single.name, 'play_audio');

    microphone.emit(Uint8List.fromList(<int>[1, 2]));
    await pumpEventQueue();
    expect(session.sentAudioFrames, isEmpty);

    await controller.dispose();
  });

  test('play_audio returns tool result before resuming wake mode', () async {
    final _FakeAssistantSession session = _FakeAssistantSession();
    final _FakeMicrophoneInput microphone = _FakeMicrophoneInput();
    final _FakePcmPlayer player = _FakePcmPlayer();
    final List<String> order = <String>[];
    session.onToolResult = () {
      order.add('tool-result');
    };
    final _FakeDeviceCommandHandler commandHandler = _FakeDeviceCommandHandler(
      responses: <String, Map<String, Object?>>{
        'play_audio': <String, Object?>{'status': 'ok'},
      },
      onHandled: (AiseeAiDeviceCommandRequest request) {
        order.add('handled:${request.name}');
      },
    );
    final AiseeAiAssistantController controller = AiseeAiAssistantController(
      session: session,
      microphoneInput: microphone,
      cameraStreamer: _FakeCameraStreamer(),
      audioPlayer: player,
      deviceCommandHandler: commandHandler,
      onMusicPlaybackStarted: () async {
        order.add('wake-resumed');
      },
    );

    await controller.connect('app-token');
    await controller.enableAssistantMic();
    session.emitDeviceCommand(
      const AiseeAiDeviceCommandRequest(
        requestId: 'tool-music',
        name: 'play_audio',
        params: <String, dynamic>{'url': 'https://example.test/song.mp3'},
      ),
    );
    await pumpEventQueue();

    expect(order, <String>[
      'handled:play_audio',
      'tool-result',
      'wake-resumed',
    ]);
    expect(session.toolResults.single.requestId, 'tool-music');
    expect(microphone.stopCalls, 1);
    expect(session.stopAudioStreamCalls, 1);

    await controller.dispose();
  });

  test('wake reconnects AI websocket when previous session closed', () async {
    final _FakeAssistantSession session = _FakeAssistantSession();
    final _FakeMicrophoneInput microphone = _FakeMicrophoneInput();
    final AiseeAiAssistantController controller = AiseeAiAssistantController(
      session: session,
      microphoneInput: microphone,
      cameraStreamer: _FakeCameraStreamer(),
      audioPlayer: _FakePcmPlayer(),
      deviceCommandHandler: _FakeDeviceCommandHandler(),
    );

    await controller.connect('app-token');
    session.connectionStatus.value =
        AiseeAiSessionConnectionStatus.disconnected;
    await controller.enableAssistantMic();

    expect(session.startedTokens, <String>['app-token', 'app-token']);
    expect(microphone.startCalls, 1);
    expect(session.sentControls, <String>['wake_greeting']);

    await controller.dispose();
  });

  test('assistant audio gates low-level echo during playback', () async {
    final _FakeAssistantSession session = _FakeAssistantSession();
    final _FakeMicrophoneInput microphone = _FakeMicrophoneInput();
    final AiseeAiAssistantController controller = AiseeAiAssistantController(
      session: session,
      microphoneInput: microphone,
      cameraStreamer: _FakeCameraStreamer(),
      audioPlayer: _FakePcmPlayer(),
      deviceCommandHandler: _FakeDeviceCommandHandler(),
      micResumeDelayAfterAssistantAudio: const Duration(milliseconds: 20),
    );

    await controller.connect('app-token');
    await controller.enableAssistantMic();
    session.emitAssistantAudio(Uint8List.fromList(<int>[9, 8, 7, 6]));
    await pumpEventQueue();

    expect(session.stopAudioStreamCalls, 0);

    microphone.emit(_pcmFrame(80));
    await pumpEventQueue();
    expect(session.sentAudioFrames, isEmpty);

    await Future<void>.delayed(const Duration(milliseconds: 30));
    microphone.emit(_pcmFrame(3600));
    await pumpEventQueue();
    expect(session.sentAudioFrames, <Uint8List>[_pcmFrame(3600)]);

    await controller.dispose();
  });

  test('speaking state gates echo but allows clear user barge-in', () async {
    final _FakeAssistantSession session = _FakeAssistantSession();
    final _FakeMicrophoneInput microphone = _FakeMicrophoneInput();
    final _FakePcmPlayer player = _FakePcmPlayer();
    final AiseeAiAssistantController controller = AiseeAiAssistantController(
      session: session,
      microphoneInput: microphone,
      cameraStreamer: _FakeCameraStreamer(),
      audioPlayer: player,
      deviceCommandHandler: _FakeDeviceCommandHandler(),
      micResumeDelayAfterAssistantAudio: const Duration(milliseconds: 20),
    );

    await controller.connect('app-token');
    await controller.enableAssistantMic();
    session.agentState.value = AgentState.speaking;
    await Future<void>.delayed(const Duration(milliseconds: 30));
    microphone.emit(_pcmFrame(80));
    await pumpEventQueue();
    expect(session.sentAudioFrames, isEmpty);

    microphone.emit(_pcmFrame(3600));
    await pumpEventQueue();
    expect(session.sentAudioFrames, <Uint8List>[_pcmFrame(3600)]);
    expect(player.stopReasons, <String>['barge-in']);

    await controller.dispose();
  });

  test('device command failures return tool_result error payloads', () async {
    final _FakeAssistantSession session = _FakeAssistantSession();
    final AiseeAiAssistantController controller = AiseeAiAssistantController(
      session: session,
      microphoneInput: _FakeMicrophoneInput(),
      cameraStreamer: _FakeCameraStreamer(),
      audioPlayer: _FakePcmPlayer(),
      deviceCommandHandler: _FakeDeviceCommandHandler(
        failingCommands: <String>{'open_maps'},
      ),
    );

    await controller.connect('app-token');
    session.emitDeviceCommand(
      const AiseeAiDeviceCommandRequest(
        requestId: 'tool-2',
        name: 'open_maps',
        params: <String, dynamic>{'destination': 'Clinic'},
      ),
    );
    await pumpEventQueue();

    expect(session.toolResults.single.requestId, 'tool-2');
    expect(session.toolResults.single.result, <String, Object?>{
      'status': 'error',
      'message': 'cannot open maps',
    });

    await controller.dispose();
  });

  test('camera command streams jpeg frames through the AI session', () async {
    final _FakeAssistantSession session = _FakeAssistantSession();
    final _FakeCameraStreamer camera = _FakeCameraStreamer();
    final AiseeAiAssistantController controller = AiseeAiAssistantController(
      session: session,
      microphoneInput: _FakeMicrophoneInput(),
      cameraStreamer: camera,
      audioPlayer: _FakePcmPlayer(),
      deviceCommandHandler: _FakeDeviceCommandHandler(),
    );

    await controller.connect('app-token');
    final Map<String, Object?> result = await controller.enableCamera(
      const <String, dynamic>{},
    );
    camera.emit(Uint8List.fromList(<int>[0xFF, 0xD8, 0xFF]));
    await controller.disableCamera(const <String, dynamic>{});

    expect(result, const <String, Object?>{'status': 'ok'});
    expect(camera.startCalls, 1);
    expect(camera.stopCalls, 1);
    expect(session.sentCameraFrames, <Uint8List>[
      Uint8List.fromList(<int>[0xFF, 0xD8, 0xFF]),
    ]);

    await controller.dispose();
  });
}

class _FakeAssistantSession implements AiseeAiAssistantSessionClient {
  @override
  final ValueNotifier<AgentState> agentState = ValueNotifier<AgentState>(
    AgentState.connecting,
  );
  @override
  final ValueNotifier<AiseeAiSessionConnectionStatus> connectionStatus =
      ValueNotifier<AiseeAiSessionConnectionStatus>(
        AiseeAiSessionConnectionStatus.disconnected,
      );

  final StreamController<Uint8List> _assistantAudioController =
      StreamController<Uint8List>.broadcast();
  final StreamController<void> _assistantAudioInterruptedController =
      StreamController<void>.broadcast();
  final StreamController<AiseeAiDeviceCommandRequest> _deviceCommandController =
      StreamController<AiseeAiDeviceCommandRequest>.broadcast();

  final List<String> startedTokens = <String>[];
  final List<Uint8List> sentAudioFrames = <Uint8List>[];
  final List<Uint8List> sentCameraFrames = <Uint8List>[];
  final List<String> sentControls = <String>[];
  int stopAudioStreamCalls = 0;
  VoidCallback? onToolResult;
  final List<({String requestId, Map<String, Object?> result})> toolResults =
      <({String requestId, Map<String, Object?> result})>[];

  @override
  Stream<Uint8List> get assistantAudioBytes => _assistantAudioController.stream;

  @override
  Stream<void> get assistantAudioInterrupted =>
      _assistantAudioInterruptedController.stream;

  @override
  Stream<AiseeAiDeviceCommandRequest> get deviceCommands =>
      _deviceCommandController.stream;

  void emitAssistantAudio(Uint8List bytes) {
    _assistantAudioController.add(bytes);
  }

  void emitAssistantAudioInterrupted() {
    _assistantAudioInterruptedController.add(null);
  }

  void emitDeviceCommand(AiseeAiDeviceCommandRequest request) {
    _deviceCommandController.add(request);
  }

  @override
  Future<AiseeAiSessionConfig> start(String accessToken) async {
    startedTokens.add(accessToken);
    connectionStatus.value = AiseeAiSessionConnectionStatus.ready;
    agentState.value = AgentState.idle;
    return const AiseeAiSessionConfig(
      sessionId: 'ai-session',
      wsUrl: 'wss://example.test/ws',
      audioInput: AiseeAiAudioFormat(
        encoding: 'pcm_s16le',
        sampleRate: 16000,
        channels: 1,
      ),
      audioOutput: AiseeAiAudioFormat(
        encoding: 'pcm_s16le',
        sampleRate: 24000,
        channels: 1,
      ),
      camera: AiseeAiCameraConfig(encoding: 'jpeg', maxFps: 1),
    );
  }

  @override
  Future<void> sendAudioFrame(Uint8List bytes) async {
    sentAudioFrames.add(Uint8List.fromList(bytes));
  }

  @override
  Future<void> sendCameraFrame(Uint8List bytes) async {
    sentCameraFrames.add(Uint8List.fromList(bytes));
  }

  @override
  Future<void> sendControl(String action) async {
    sentControls.add(action);
  }

  @override
  Future<void> stopAudioStream() async {
    stopAudioStreamCalls += 1;
  }

  @override
  Future<void> sendToolResult(String requestId, Object? result) async {
    toolResults.add((
      requestId: requestId,
      result: Map<String, Object?>.from(result! as Map),
    ));
    onToolResult?.call();
  }

  @override
  Future<void> stop({
    bool resetState = true,
    int? closeCode,
    String? reason,
  }) async {
    connectionStatus.value = AiseeAiSessionConnectionStatus.disconnected;
    if (resetState) {
      agentState.value = AgentState.disconnected;
    }
  }

  @override
  void dispose() {
    _assistantAudioController.close();
    _assistantAudioInterruptedController.close();
    _deviceCommandController.close();
    agentState.dispose();
    connectionStatus.dispose();
  }
}

Uint8List _pcmFrame(int sample, {int samples = 800}) {
  final Uint8List bytes = Uint8List(samples * 2);
  final ByteData data = ByteData.sublistView(bytes);
  for (int index = 0; index < samples; index += 1) {
    data.setInt16(index * 2, sample, Endian.little);
  }
  return bytes;
}

class _FakeMicrophoneInput implements AiseeAiMicrophoneInput {
  void Function(Uint8List bytes)? _onFrame;
  VoidCallback? onStart;
  int startCalls = 0;
  int stopCalls = 0;
  int disposeCalls = 0;
  bool failStart = false;

  void emit(Uint8List bytes) {
    _onFrame?.call(bytes);
  }

  @override
  Future<void> start({required void Function(Uint8List bytes) onFrame}) async {
    startCalls += 1;
    onStart?.call();
    if (failStart) {
      throw StateError('microphone start failed');
    }
    _onFrame = onFrame;
  }

  @override
  Future<void> stop() async {
    stopCalls += 1;
    _onFrame = null;
  }

  @override
  Future<void> dispose() async {
    disposeCalls += 1;
    _onFrame = null;
  }
}

class _FakeCameraStreamer implements AiseeAiCameraStreamer {
  final ValueNotifier<Widget?> _preview = ValueNotifier<Widget?>(null);
  void Function(Uint8List jpeg)? _onFrame;
  int startCalls = 0;
  int stopCalls = 0;
  int disposeCalls = 0;

  @override
  ValueListenable<Widget?> get preview => _preview;

  void emit(Uint8List bytes) {
    _onFrame?.call(bytes);
  }

  @override
  Future<void> start({required void Function(Uint8List jpeg) onFrame}) async {
    startCalls += 1;
    _onFrame = onFrame;
  }

  @override
  Future<void> stop() async {
    stopCalls += 1;
    _onFrame = null;
  }

  @override
  Future<void> dispose() async {
    disposeCalls += 1;
    await stop();
    _preview.dispose();
  }
}

class _FakePcmPlayer implements AiseeAiPcmPlayer {
  final List<Uint8List> enqueuedChunks = <Uint8List>[];
  final List<String> stopReasons = <String>[];
  int stopCalls = 0;

  @override
  Future<void> enqueuePcm16(Uint8List bytes) async {
    enqueuedChunks.add(Uint8List.fromList(bytes));
  }

  @override
  Future<void> stop({String reason = 'manual'}) async {
    stopCalls += 1;
    stopReasons.add(reason);
  }

  @override
  Future<void> dispose() async {}
}

class _FakeDeviceCommandHandler implements AiseeAssistantDeviceCommandHandler {
  _FakeDeviceCommandHandler({
    this.responses = const <String, Map<String, Object?>>{},
    this.failingCommands = const <String>{},
    this.onHandled,
  });

  final Map<String, Map<String, Object?>> responses;
  final Set<String> failingCommands;
  final void Function(AiseeAiDeviceCommandRequest request)? onHandled;
  final List<AiseeAiDeviceCommandRequest> handledCommands =
      <AiseeAiDeviceCommandRequest>[];

  @override
  ValueListenable<String?> get nowPlayingTitle => ValueNotifier<String?>(null);

  @override
  Future<Map<String, Object?>> handle(
    AiseeAiDeviceCommandRequest request,
  ) async {
    handledCommands.add(request);
    onHandled?.call(request);
    if (failingCommands.contains(request.name)) {
      throw const AiseeAssistantDeviceCommandException(
        message: 'cannot open maps',
      );
    }
    return responses[request.name] ?? const <String, Object?>{'status': 'ok'};
  }

  @override
  Future<void> dispose() async {}
}
