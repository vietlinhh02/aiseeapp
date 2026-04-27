import 'dart:async';
import 'dart:io' show Platform;

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:volume_controller/volume_controller.dart';

import '../services/aisee_location_service.dart';
import 'aisee_ai_session.dart';

typedef AiseeAssistantCameraCommand =
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
  }) : _onEnableCamera = onEnableCamera,
       _onDisableCamera = onDisableCamera;

  final AiseeAssistantCameraCommand? _onEnableCamera;
  final AiseeAssistantCameraCommand? _onDisableCamera;

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
      'enable_camera' => _handleEnableCamera(request.params),
      'disable_camera' => _handleDisableCamera(request.params),
      'play_audio' => _handlePlayAudio(request.params),
      'control_audio' => _handleControlAudio(request.params),
      'get_location' => _handleGetLocation(),
      'open_maps' => _handleOpenMaps(request.params),
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
    if (command == 'volume_up' || command == 'volume_down') {
      final VolumeController controller = VolumeController.instance;
      controller.showSystemUI = true;
      final double current = await controller.getVolume();
      const double step = 0.1;
      final double next = command == 'volume_up'
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
      case 'pause':
        await player.pause();
      case 'resume':
      case 'play':
        await player.play();
      case 'stop':
        await player.stop();
        _nowPlayingTitle.value = null;
      case 'next':
      case 'previous':
        await player.stop();
        _nowPlayingTitle.value = null;
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
      }
    });
    return player;
  }

  Future<void> _configureMusicAudioSession() async {
    if (kIsWeb) {
      return;
    }

    final AudioSession session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
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
