import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:volume_controller/volume_controller.dart';

import '../models/aisee_incoming_call.dart';
import '../models/aisee_reminder.dart';
import '../services/aisee_location_service.dart';
import '../services/aisee_reminder_service.dart';
import 'aisee_ai_session.dart';
import 'aisee_assistant_incoming_call_bridge.dart';
import 'aisee_audio_route_service.dart';
import 'aisee_device_command_contract.dart';

typedef AiseeAssistantCameraCommand =
    Future<Map<String, Object?>> Function(Map<String, dynamic> params);
typedef AiseeAssistantCameraFpsCommand =
    Future<Map<String, Object?>> Function(Duration interval);
typedef AiseeAssistantNavigationScreenCommand =
    Future<Map<String, Object?>> Function(Map<String, dynamic> params);
typedef AiseeAssistantStartCallCommand =
    Future<Map<String, Object?>> Function(Map<String, dynamic> params);
typedef AiseeAssistantAnswerIncomingCommand =
    Future<Map<String, Object?>> Function(Map<String, dynamic> params);
typedef AiseeAssistantDeclineIncomingCommand =
    Future<Map<String, Object?>> Function(Map<String, dynamic> params);

class AiseeAssistantDeviceCommandException implements Exception {
  const AiseeAssistantDeviceCommandException({
    required this.message,
    this.rpcCode,
  });

  final String message;
  final int? rpcCode;

  @override
  String toString() {
    return 'AiseeAssistantDeviceCommandException('
        'message: $message, rpcCode: $rpcCode)';
  }
}

abstract interface class AiseeAssistantDeviceCommandHandler {
  ValueListenable<String?> get nowPlayingTitle;

  Future<Map<String, Object?>> handle(AiseeAiDeviceCommandRequest request);

  Future<void> dispose();
}

class AiseeDefaultAssistantDeviceCommandHandler
    implements AiseeAssistantDeviceCommandHandler {
  AiseeDefaultAssistantDeviceCommandHandler({
    AiseeAssistantCameraCommand? onEnableCamera,
    AiseeAssistantCameraCommand? onDisableCamera,
    AiseeAssistantCameraFpsCommand? onSetCameraFps,
    AiseeAssistantNavigationScreenCommand? onShowNavigationScreen,
    AiseeAssistantNavigationScreenCommand? onHideNavigationScreen,
    AiseeAssistantStartCallCommand? onStartCall,
    AiseeAssistantAnswerIncomingCommand? onAnswerIncomingCall,
    AiseeAssistantDeclineIncomingCommand? onDeclineIncomingCall,
  }) : _onEnableCamera = onEnableCamera,
       _onDisableCamera = onDisableCamera,
       _onSetCameraFps = onSetCameraFps,
       _onShowNavigationScreen = onShowNavigationScreen,
       _onHideNavigationScreen = onHideNavigationScreen,
       _onStartCall = onStartCall,
       _onAnswerIncomingCall = onAnswerIncomingCall,
       _onDeclineIncomingCall = onDeclineIncomingCall;

  final AiseeAssistantCameraCommand? _onEnableCamera;
  final AiseeAssistantCameraCommand? _onDisableCamera;
  final AiseeAssistantCameraFpsCommand? _onSetCameraFps;
  final AiseeAssistantNavigationScreenCommand? _onShowNavigationScreen;
  final AiseeAssistantNavigationScreenCommand? _onHideNavigationScreen;
  final AiseeAssistantStartCallCommand? _onStartCall;
  final AiseeAssistantAnswerIncomingCommand? _onAnswerIncomingCall;
  final AiseeAssistantDeclineIncomingCommand? _onDeclineIncomingCall;

  final ValueNotifier<String?> _nowPlayingTitle = ValueNotifier<String?>(null);
  AudioPlayer? _musicPlayer;
  StreamSubscription<PlayerState>? _musicPlayingSub;

  @override
  ValueListenable<String?> get nowPlayingTitle => _nowPlayingTitle;

  @override
  Future<Map<String, Object?>> handle(
    AiseeAiDeviceCommandRequest request,
  ) async {
    return switch (request.name) {
      DeviceCommandNames.enableCamera => _handleEnableCamera(request.params),
      DeviceCommandNames.disableCamera => _handleDisableCamera(request.params),
      DeviceCommandNames.setCameraFps => _handleSetCameraFps(request.params),
      DeviceCommandNames.showNavigationScreen => _handleShowNavigationScreen(request.params),
      DeviceCommandNames.hideNavigationScreen => _handleHideNavigationScreen(request.params),
      DeviceCommandNames.startCall => _handleStartCall(request.params),
      DeviceCommandNames.answerIncomingCall => _handleAnswerIncomingCall(request.params),
      DeviceCommandNames.declineIncomingCall => _handleDeclineIncomingCall(request.params),
      DeviceCommandNames.playAudio => _handlePlayAudio(request.params),
      DeviceCommandNames.controlAudio => _handleControlAudio(request.params),
      DeviceCommandNames.getLocation => _handleGetLocation(),
      DeviceCommandNames.openMaps => _handleOpenMaps(request.params),
      // Bug fix #5: thêm case scheduleReminder để khi AI gọi qua WS
      // `device_command` (không phải LiveKit RPC) cũng hoạt động được.
      DeviceCommandNames.scheduleReminder => _handleScheduleReminder(
        request.params,
      ),
      _ => throw AiseeAssistantDeviceCommandException(
        message: 'Unsupported command: ${request.name}',
        rpcCode: 2002,
      ),
    };
  }

  @override
  Future<void> dispose() async {
    _nowPlayingTitle.dispose();
    await _musicPlayingSub?.cancel();
    _musicPlayingSub = null;
    final AudioPlayer? player = _musicPlayer;
    _musicPlayer = null;
    if (player != null) {
      await player.dispose();
    }
  }

  Future<Map<String, Object?>> _handleEnableCamera(
    Map<String, dynamic> params,
  ) async {
    final AiseeAssistantCameraCommand? callback = _onEnableCamera;
    if (callback == null) {
      return const <String, Object?>{
        'status': 'unavailable',
        'message': 'Camera streaming is not available in this assistant build.',
      };
    }
    return callback(params);
  }

  Future<Map<String, Object?>> _handleDisableCamera(
    Map<String, dynamic> params,
  ) async {
    final AiseeAssistantCameraCommand? callback = _onDisableCamera;
    if (callback == null) {
      return const <String, Object?>{'status': 'ok'};
    }
    return callback(params);
  }

  Future<Map<String, Object?>> _handleSetCameraFps(
    Map<String, dynamic> params,
  ) async {
    final AiseeAssistantCameraFpsCommand? callback = _onSetCameraFps;
    if (callback == null) {
      return const <String, Object?>{'status': 'ok'};
    }
    final Object? raw = params['interval_ms'];
    if (raw is! int) {
      return const <String, Object?>{
        'status': 'error',
        'message': 'set_camera_fps: missing interval_ms (int)',
      };
    }
    return callback(Duration(milliseconds: raw));
  }

  Future<Map<String, Object?>> _handleShowNavigationScreen(
    Map<String, dynamic> params,
  ) async {
    final AiseeAssistantNavigationScreenCommand? callback = _onShowNavigationScreen;
    if (callback == null) {
      return const <String, Object?>{'status': 'ok'};
    }
    return callback(params);
  }

  Future<Map<String, Object?>> _handleHideNavigationScreen(
    Map<String, dynamic> params,
  ) async {
    final AiseeAssistantNavigationScreenCommand? callback = _onHideNavigationScreen;
    if (callback == null) {
      return const <String, Object?>{'status': 'ok'};
    }
    return callback(params);
  }

  Future<Map<String, Object?>> _handleStartCall(
    Map<String, dynamic> params,
  ) async {
    final AiseeAssistantStartCallCommand? callback = _onStartCall;
    if (callback == null) {
      return const <String, Object?>{
        'status': 'unavailable',
        'message': 'Calling is not available in this assistant build.',
      };
    }
    return callback(params);
  }

  Future<Map<String, Object?>> _handleAnswerIncomingCall(
    Map<String, dynamic> params,
  ) async {
    final AiseeAssistantAnswerIncomingCommand? callback = _onAnswerIncomingCall;
    if (callback == null) {
      return const <String, Object?>{
        'status': 'unavailable',
        'message': 'Answering incoming calls is not wired in this build.',
      };
    }
    final Map<String, dynamic> merged = <String, dynamic>{...params};
    final AiseeIncomingCall? pending =
        AiseeAssistantIncomingCallBridge.instance.pendingCall;
    if (pending != null) {
      merged.putIfAbsent('room_name', () => pending.roomName);
      merged.putIfAbsent('token', () => pending.token);
      merged.putIfAbsent('caller_id', () => pending.callerId);
      merged.putIfAbsent('caller_name', () => pending.callerName);
      merged.putIfAbsent('call_type', () => pending.callType);
      if (pending.callerAvatarUrl != null) {
        merged.putIfAbsent('caller_avatar_url', () => pending.callerAvatarUrl);
      }
    }
    return callback(merged);
  }

  Future<Map<String, Object?>> _handleDeclineIncomingCall(
    Map<String, dynamic> params,
  ) async {
    final AiseeAssistantDeclineIncomingCommand? callback =
        _onDeclineIncomingCall;
    if (callback == null) {
      return const <String, Object?>{
        'status': 'unavailable',
        'message': 'Declining incoming calls is not wired in this build.',
      };
    }
    final Map<String, dynamic> merged = <String, dynamic>{...params};
    final AiseeIncomingCall? pending =
        AiseeAssistantIncomingCallBridge.instance.pendingCall;
    if (pending != null) {
      merged.putIfAbsent('room_name', () => pending.roomName);
      merged.putIfAbsent('caller_id', () => pending.callerId);
    }
    return callback(merged);
  }

  Future<Map<String, Object?>> _handlePlayAudio(
    Map<String, dynamic> params,
  ) async {
    final String url = _paramString(params, const <String>[
      'url',
      'audio_url',
      'src',
    ]);
    final String title = _paramString(params, const <String>['title', 'name']);
    if (url.isEmpty) {
      throw const AiseeAssistantDeviceCommandException(
        message: 'Missing url parameter',
        rpcCode: 2001,
      );
    }

    final AudioPlayer player = await _musicPlayerOrCreate();
    final Uri uri = Uri.parse(url);
    final bool needsYoutubeFriendlyHeaders =
        uri.host.contains('googlevideo.com') ||
        uri.host.contains('googlevideo.net') ||
        uri.host.contains('googleusercontent.com');
    try {
      debugPrint(
        '[AiSee:Music] play_audio start host=${uri.host} title=${title.isEmpty ? "(none)" : title}',
      );
      await _configureMusicAudioSession();
      await player.stop();
      final AudioSource source = needsYoutubeFriendlyHeaders
          ? AudioSource.uri(
              uri,
              headers: const <String, String>{
                'User-Agent':
                    'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 '
                    '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
                'Referer': 'https://www.youtube.com/',
              },
            )
          : AudioSource.uri(uri);
      await player.setAudioSource(source);
      _nowPlayingTitle.value = title.isEmpty ? null : title;
      final Future<bool> playbackStarted = player.playingStream.firstWhere(
        (bool playing) => playing,
      );
      await player.play();
      await playbackStarted.timeout(
        const Duration(seconds: 4),
        onTimeout: () => throw const AiseeAssistantDeviceCommandException(
          message: 'Playback did not start.',
          rpcCode: 2006,
        ),
      );
      debugPrint('[AiSee:Music] play_audio playing');
      return <String, Object?>{
        'status': 'ok',
        if (title.isNotEmpty) 'title': title,
      };
    } on PlayerException catch (error) {
      debugPrint('[AiSee:Music] play_audio PlayerException: $error');
      throw AiseeAssistantDeviceCommandException(
        message: 'Playback failed: ${error.message}',
        rpcCode: 2005,
      );
    } catch (error) {
      debugPrint('[AiSee:Music] play_audio failed: $error');
      throw AiseeAssistantDeviceCommandException(
        message: 'Playback failed: $error',
        rpcCode: 2006,
      );
    }
  }

  Future<Map<String, Object?>> _handleControlAudio(
    Map<String, dynamic> params,
  ) async {
    final String command = _paramString(params, const <String>[
      'command',
      'action',
      'op',
    ]).toLowerCase();
    if (command == AudioControlActions.volumeUp ||
        command == AudioControlActions.volumeDown) {
      final VolumeController controller = VolumeController.instance;
      controller.showSystemUI = true;
      final double current = await controller.getVolume();
      const double step = 0.1;
      final double next = command == AudioControlActions.volumeUp
          ? (current + step).clamp(0.0, 1.0)
          : (current - step).clamp(0.0, 1.0);
      await controller.setVolume(next);
      return <String, Object?>{'status': 'ok', 'volume': next};
    }

    final AudioPlayer? player = _musicPlayer;
    if (player == null) {
      return const <String, Object?>{'status': 'ok'};
    }

    switch (command) {
      case AudioControlActions.pause:
        await player.pause();
      case AudioControlActions.resume:
      case AudioControlActions.play:
        await player.play();
      case AudioControlActions.stop:
        await player.stop();
        _nowPlayingTitle.value = null;
        // Restore Agent voice mode when music is explicitly stopped.
        unawaited(AiseeAudioRouteService.instance.restoreAgentMode());
      case AudioControlActions.next:
      case AudioControlActions.previous:
        await player.stop();
        _nowPlayingTitle.value = null;
        // Restore Agent voice mode when music is stopped (next/prev).
        unawaited(AiseeAudioRouteService.instance.restoreAgentMode());
      default:
        throw AiseeAssistantDeviceCommandException(
          message: 'Unsupported command: $command',
          rpcCode: 2002,
        );
    }
    return const <String, Object?>{'status': 'ok'};
  }

  Future<Map<String, Object?>> _handleGetLocation() async {
    final AiseeLocationResult location =
        await AiseeLocationService.getCurrentLocation();
    return <String, Object?>{
      'status': 'ok',
      'lat': location.lat,
      'lng': location.lng,
      'address': location.address,
    };
  }

  Future<Map<String, Object?>> _handleOpenMaps(
    Map<String, dynamic> params,
  ) async {
    final String destination = _paramString(params, const <String>[
      'destination',
      'dest',
      'query',
      'q',
    ]);
    final String lat = _paramString(params, const <String>['lat', 'latitude']);
    final String lng = _paramString(params, const <String>['lng', 'longitude']);

    Uri? uri;
    if (destination.isNotEmpty) {
      if (!kIsWeb && Platform.isIOS) {
        uri = Uri.parse(
          'https://maps.apple.com/?daddr=${Uri.encodeComponent(destination)}',
        );
      } else {
        uri = Uri.parse(
          'google.navigation:q=${Uri.encodeComponent(destination)}',
        );
      }
    } else if (lat.isNotEmpty && lng.isNotEmpty) {
      if (!kIsWeb && Platform.isIOS) {
        uri = Uri.parse('https://maps.apple.com/?daddr=$lat,$lng');
      } else {
        uri = Uri.parse('google.navigation:q=$lat,$lng');
      }
    }

    if (uri == null) {
      throw const AiseeAssistantDeviceCommandException(
        message: 'Missing destination or lat/lng',
        rpcCode: 2003,
      );
    }

    final bool launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      throw const AiseeAssistantDeviceCommandException(
        message: 'Cannot open maps',
        rpcCode: 2004,
      );
    }
    return const <String, Object?>{'status': 'ok'};
  }

  Future<AudioPlayer> _musicPlayerOrCreate() async {
    if (_musicPlayer != null) {
      return _musicPlayer!;
    }

    final AudioPlayer player = AudioPlayer();
    _musicPlayer = player;
    _musicPlayingSub = player.playerStateStream.listen((PlayerState state) {
      if (!state.playing &&
          state.processingState == ProcessingState.completed) {
        _nowPlayingTitle.value = null;
        // Restore Agent voice mode after music finishes playing.
        unawaited(AiseeAudioRouteService.instance.restoreAgentMode());
      }
    });
    return player;
  }

  Future<void> _configureMusicAudioSession() async {
    if (kIsWeb) return;
    await AiseeAudioRouteService.instance.enterMusicMode();
  }

  Future<Map<String, Object?>> _handleScheduleReminder(
    Map<String, dynamic> params,
  ) async {
    // Bug fix #5: route `schedule_reminder` (WS device_command) tới
    // AiseeReminderService tương tự như LiveKit RPC. Param schema khớp
    // với Python agent (xem contracts.py: type/name + times cho
    // medication, datetime cho appointment).
    final String typeStr = _paramString(params, const <String>[
      'type',
      'reminder_type',
    ]);
    final String name = _paramString(params, const <String>['name', 'title']);
    if (name.isEmpty) {
      throw const AiseeAssistantDeviceCommandException(
        message: 'schedule_reminder: missing name/title',
        rpcCode: 2010,
      );
    }
    final int baseId = await AiseeReminderService.instance.nextReminderId();
    final AiseeReminder reminder;
    switch (typeStr) {
      case 'medication':
        final List<String> times =
            (params['times'] as List<dynamic>?)?.cast<String>() ??
                <String>[];
        final String freq = _paramString(params, const <String>[
          'frequency',
          'freq',
        ]);
        reminder = AiseeReminder(
          id: baseId,
          type: AiseeReminderType.medication,
          title: name,
          times: times,
          frequency: freq.isEmpty ? 'daily' : freq,
          createdAt: DateTime.now(),
        );
      case 'appointment':
        final String dt = _paramString(params, const <String>[
          'datetime',
          'date_time',
          'time',
        ]);
        reminder = AiseeReminder(
          id: baseId,
          type: AiseeReminderType.appointment,
          title: name,
          datetime: dt,
          createdAt: DateTime.now(),
        );
      default:
        throw AiseeAssistantDeviceCommandException(
          message: 'schedule_reminder: unsupported type "$typeStr"',
          rpcCode: 2011,
        );
    }
    await AiseeReminderService.instance.scheduleReminder(reminder);
    return <String, Object?>{
      'status': 'ok',
      'reminder_id': baseId,
      'type': reminder.type.name,
    };
  }

  String _paramString(Map<String, dynamic> params, List<String> keys) {
    for (final String key in keys) {
      final Object? value = params[key];
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }
    return '';
  }
}
