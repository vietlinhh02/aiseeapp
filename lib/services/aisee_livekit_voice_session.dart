import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:livekit_client/livekit_client.dart' hide AgentState;
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_env.dart';
import '../debug/aisee_performance_debug.dart';
import '../models/aisee_api_models.dart';
import '../models/livekit_join_credentials.dart';
import '../services/aisee_auth_service.dart';
import '../services/aisee_session_store.dart';
import '../services/aisee_voice_foreground.dart';
import '../models/agent_state.dart';
import '../models/aisee_reminder.dart';
import '../services/aisee_location_service.dart';
import '../services/aisee_reminder_service.dart';

class AiseeCallsTokenUnauthorized implements Exception {
  @override
  String toString() => 'AiseeCallsTokenUnauthorized';
}

/// Console log có tag cho debug terminal (`flutter run`).
void _log(String tag, String message) {
  debugPrint('[AiSee:$tag] $message');
}

/// Log nhiều dòng (payload dài, trạng thái nhiều field).
void _logBlock(String tag, String title, Map<String, Object?> fields) {
  final StringBuffer buf = StringBuffer()
    ..writeln('[AiSee:$tag] $title');
  for (final MapEntry<String, Object?> e in fields.entries) {
    buf.writeln('  ${e.key}: ${e.value}');
  }
  debugPrint(buf.toString().trimRight());
}

/// Gọi backend lấy token phòng + kết nối LiveKit, bật mic (trợ lý giọng nói).
/// Xin quyền micro + camera trước khi kết nối (sẵn sàng cho video / lệnh từ agent).
class AiseeLiveKitVoiceSession {
  AiseeLiveKitVoiceSession({http.Client? httpClient})
    : _http = httpClient ?? http.Client(),
        _ownsClient = httpClient == null;

  final http.Client _http;
  final bool _ownsClient;

  Room? _room;
  EventsListener<RoomEvent>? _roomListener;

  AudioPlayer? _musicPlayer;
  StreamSubscription<PlayerState>? _musicPlayingSub;
  String? _nowPlayingTitle;
  Timer? _waveDecayTimer;

  /// 0–1 từ LiveKit active speakers (bạn + agent trong phòng).
  final ValueNotifier<double> assistantWaveEnergy = ValueNotifier<double>(0);

  /// true khi [just_audio] đang phát (sóng nhạc trên UI).
  final ValueNotifier<bool> assistantMusicActive = ValueNotifier<bool>(false);

  final ValueNotifier<AgentState> agentState =
      ValueNotifier<AgentState>(AgentState.connecting);

  /// Track video camera local khi agent bật camera — dùng cho preview tab Trợ lý.
  final ValueNotifier<LocalVideoTrack?> localCameraPreviewTrack =
      ValueNotifier<LocalVideoTrack?>(null);

  /// Gọi sau khi đổi trạng thái phát nhạc (tiêu đề / dừng) để UI rebuild.
  VoidCallback? onMusicUiChanged;

  String? get nowPlayingTitle => _nowPlayingTitle;

  void _setLocalCameraPreviewTrack(LocalVideoTrack? track) {
    if (localCameraPreviewTrack.value == track) return;
    localCameraPreviewTrack.value = track;
  }

  /// Đồng bộ preview: chỉ khi camera đang bật (không mute). Khi tắt, LiveKit vẫn
  /// giữ publication/track nên phải dựa vào [LocalParticipant.isCameraEnabled]
  /// để tránh frame video bị kẹt trên UI.
  void syncLocalCameraPreviewTrack() {
    final LocalParticipant? lp = _room?.localParticipant;
    if (lp == null || !lp.isCameraEnabled()) {
      _log('Camera', 'syncPreview: camera OFF hoac chua co participant -> null');
      _setLocalCameraPreviewTrack(null);
      return;
    }
    final LocalTrackPublication? pub =
        lp.getTrackPublicationBySource(TrackSource.camera);
    final LocalTrack? t = pub?.track;
    if (t is LocalVideoTrack) {
      _log('Camera', 'syncPreview: co LocalVideoTrack -> hien preview');
      _setLocalCameraPreviewTrack(t);
    } else {
      _log('Camera', 'syncPreview: khong co video track -> null');
      _setLocalCameraPreviewTrack(null);
    }
  }

  /// Camera đầu tiên trong danh sách thiết bị (index 0) — thường là camera sau trên Android.
  Future<CameraCaptureOptions> _agentCameraCaptureOptions() async {
    try {
      final List<MediaDevice> inputs = await Hardware.instance.videoInputs();
      if (inputs.isNotEmpty) {
        return CameraCaptureOptions(deviceId: inputs[0].deviceId);
      }
    } catch (e, st) {
      debugPrint('videoInputs: $e\n$st');
    }
    return const CameraCaptureOptions(cameraPosition: CameraPosition.back);
  }

  void disposeHttp() {
    if (_ownsClient) {
      _http.close();
    }
  }

  Future<LiveKitJoinCredentials> _fetchJoinCredentials(String accessToken) async {
    final Uri uri = Uri.parse('${AppEnv.apiBaseUrl}/api/v1/calls/token');
    _log('API', 'POST $uri');
    // Backend (chi) đăng ký POST — GET sẽ 404 body rỗng.
    final http.Response res = await _http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      },
    );

    final String raw = utf8.decode(res.bodyBytes).trim();
    _log('API', 'Response HTTP ${res.statusCode} (${raw.length} chars)');

    if (res.statusCode == 401) {
      throw AiseeCallsTokenUnauthorized();
    }

    Map<String, dynamic>? map;
    if (raw.isNotEmpty) {
      try {
        final Object? decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          map = decoded;
        }
      } on FormatException {
        throw AiseeApiException(
          'Máy chủ trả không phải JSON hợp lệ (HTTP ${res.statusCode}). '
          'Kiểm tra BACKEND_URL và route POST /api/v1/calls/token.',
        );
      }
    }

    if (res.statusCode != 200) {
      final String fb = 'Không lấy được token phòng (HTTP ${res.statusCode})';
      if (map != null) {
        throw AiseeApiException(_messageFromErrorBody(map, fallback: fb));
      }
      throw AiseeApiException(
        raw.isEmpty ? '$fb — phản hồi trống.' : '$fb — ${raw.length > 120 ? '${raw.substring(0, 120)}…' : raw}',
      );
    }

    if (map == null) {
      throw AiseeApiException(
        'API /api/v1/calls/token trả 200 nhưng thân phản hồi trống hoặc không phải JSON object. '
        'Kiểm tra handler backend (có gửi JSON chứa token không).',
      );
    }

    final Object? dataField = map['data'];
    final Map<String, dynamic> p =
        dataField is Map<String, dynamic> ? dataField : map;
    final String token = _pickString(p, const ['token', 'access_token']);
    String url = _pickString(p, const [
      'url',
      'ws_url',
      'livekit_url',
      'server_url',
    ]);
    if (url.isEmpty) {
      url = AppEnv.liveKitWsUrl;
    }
    final String? room =
        p['room_name'] as String? ?? p['room'] as String? ?? p['roomName'] as String?;
    if (token.isEmpty) {
      throw AiseeApiException('Phản hồi token LiveKit thiếu token');
    }
    if (url.isEmpty) {
      throw AiseeApiException(
        'Thiếu URL LiveKit: điền LIVEKIT_URL trong assets/app_config.env '
        'rồi chạy flutter clean && flutter run; hoặc '
        '--dart-define=LIVEKIT_URL=wss://...; hoặc để backend trả url trong JSON.',
      );
    }
    return LiveKitJoinCredentials(token: token, url: url, roomName: room);
  }

  String _pickString(Map<String, dynamic> p, List<String> keys) {
    for (final String k in keys) {
      final Object? v = p[k];
      if (v is String && v.isNotEmpty) return v;
    }
    return '';
  }

  String _paramString(Map<String, dynamic>? p, List<String> keys) {
    if (p == null) return '';
    return _pickString(p, keys);
  }

  void _setNowPlayingTitle(String? title) {
    if (_nowPlayingTitle == title) return;
    _nowPlayingTitle = title;
    onMusicUiChanged?.call();
  }

  Future<AudioPlayer> _musicPlayerOrCreate() async {
    if (_musicPlayer != null) {
      return _musicPlayer!;
    }
    final AudioPlayer p = AudioPlayer();
    _musicPlayer = p;
    _musicPlayingSub = p.playerStateStream.listen((PlayerState state) {
      final bool playing = state.playing;
      if (assistantMusicActive.value != playing) {
        assistantMusicActive.value = playing;
      }
    });
    return p;
  }

  void _startWaveDecayTimer() {
    _waveDecayTimer?.cancel();
    _waveDecayTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (AiseeDebugConfig.enabled) {
        AiseePerformanceDebug.instance.recordWaveTimerTick();
      }
      if (_room == null) {
        return;
      }
      final double v = assistantWaveEnergy.value;
      if (v <= 0.02) {
        if (v != 0) {
          assistantWaveEnergy.value = 0;
        }
        return;
      }
      assistantWaveEnergy.value = v * 0.88;
    });
  }

  void _stopWaveDecayTimer() {
    _waveDecayTimer?.cancel();
    _waveDecayTimer = null;
  }

  Future<void> _disposeMusicPlayer() async {
    await _musicPlayingSub?.cancel();
    _musicPlayingSub = null;
    assistantMusicActive.value = false;
    final AudioPlayer? p = _musicPlayer;
    _musicPlayer = null;
    _setNowPlayingTitle(null);
    if (p != null) {
      try {
        await p.dispose();
      } catch (e, st) {
        debugPrint('Music player dispose: $e\n$st');
      }
    }
  }

  String _messageFromErrorBody(Map<String, dynamic> map, {required String fallback}) {
    final Object? errObj = map['error'];
    if (errObj is Map<String, dynamic>) {
      final String? msg = errObj['message'] as String?;
      if (msg != null && msg.isNotEmpty) return msg;
    }
    return fallback;
  }

  /// Android/iOS: hộp thoại hệ thống. Web: trình duyệt tự hỏi khi bật thiết bị.
  Future<void> _ensurePermission(
    Permission permission, {
    required String nameVi,
  }) async {
    if (kIsWeb) {
      return;
    }
    final PermissionStatus current = await permission.status;
    if (current.isGranted) {
      return;
    }
    if (current.isPermanentlyDenied) {
      throw AiseeApiException(
        'Quyền $nameVi đã bị từ chối. Hãy bật trong Cài đặt cho AiSee.',
      );
    }
    final PermissionStatus next = await permission.request();
    if (next.isGranted) {
      return;
    }
    if (next.isPermanentlyDenied) {
      throw AiseeApiException(
        'Quyền $nameVi đã bị từ chối. Hãy bật trong Cài đặt cho AiSee.',
      );
    }
    throw AiseeApiException('Cần quyền $nameVi để dùng trợ lý.');
  }

  /// Cấu hình audio session hỗ trợ tai nghe có dây + Bluetooth.
  /// Gọi SAU khi LiveKit connect + bật mic để không bị LiveKit ghi đè.
  Future<void> _configureAudioSession() async {
    if (kIsWeb) return;
    try {
      final AudioSession session = await AudioSession.instance;
      await session.configure(AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.defaultToSpeaker |
            AVAudioSessionCategoryOptions.allowBluetooth |
            AVAudioSessionCategoryOptions.allowBluetoothA2dp,
        avAudioSessionMode: AVAudioSessionMode.voiceChat,
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      ));
      _log('Audio', 'Audio session configured (headphone + BT)');
    } catch (e) {
      _log('Audio', 'Audio session config failed: $e');
    }
  }

  Future<void> _ensureMediaPermissions() async {
    if (kIsWeb) {
      return;
    }
    await _ensurePermission(Permission.microphone, nameVi: 'micro');
    await _ensurePermission(Permission.camera, nameVi: 'camera');
    await _ensurePermission(Permission.location, nameVi: 'vị trí');
  }

  Future<LiveKitJoinCredentials> _fetchWithRefreshIfNeeded() async {
    final AiseeAuthTokens? stored = await AiseeSessionStore.instance.read();
    if (stored == null) {
      throw AiseeApiException('Chưa có phiên đăng nhập');
    }
    try {
      return await _fetchJoinCredentials(stored.accessToken);
    } on AiseeCallsTokenUnauthorized {
      final AiseeAuthService auth = AiseeAuthService();
      try {
        final AiseeAuthTokens rotated = await auth.refreshTokens(
          stored.refreshToken,
        );
        await AiseeSessionStore.instance.write(rotated);
        return await _fetchJoinCredentials(rotated.accessToken);
      } finally {
        auth.close();
      }
    }
  }

  void _registerRpcMethods() {
    final Room? room = _room;
    if (room == null) return;

    room.registerRpcMethod(
      'enable_camera',
      (RpcInvocationData data) async {
        _log('RPC', 'enable_camera called');
        final LocalParticipant? lp = _room?.localParticipant;
        if (lp == null) {
          throw RpcError(code: 2000, message: 'Not connected');
        }
        if (!kIsWeb) {
          await _ensurePermission(
            Permission.camera,
            nameVi: 'camera',
          );
        }
        final CameraCaptureOptions camOpts =
            await _agentCameraCaptureOptions();
        await lp.setCameraEnabled(
          true,
          cameraCaptureOptions: camOpts,
        );
        syncLocalCameraPreviewTrack();
        return jsonEncode({'status': 'ok'});
      },
    );

    room.registerRpcMethod(
      'disable_camera',
      (RpcInvocationData data) async {
        _log('RPC', 'disable_camera called');
        await _room?.localParticipant?.setCameraEnabled(false);
        syncLocalCameraPreviewTrack();
        return jsonEncode({'status': 'ok'});
      },
    );

    room.registerRpcMethod(
      'play_audio',
      (RpcInvocationData data) async {
        final Map<String, dynamic> params =
            jsonDecode(data.payload) as Map<String, dynamic>;
        final String url =
            _paramString(params, const ['url', 'audio_url', 'src']);
        final String titleRaw =
            _paramString(params, const ['title', 'name']);
        _log(
          'RPC',
          'play_audio url='
          '${url.length > 60 ? '${url.substring(0, 60)}...' : url}',
        );
        if (url.isEmpty) {
          throw RpcError(code: 2001, message: 'Missing url parameter');
        }
        final AudioPlayer player = await _musicPlayerOrCreate();
        await player.setUrl(url);
        _setNowPlayingTitle(titleRaw.isEmpty ? null : titleRaw);
        await player.play();
        return jsonEncode({'status': 'ok'});
      },
    );

    room.registerRpcMethod(
      'control_audio',
      (RpcInvocationData data) async {
        final Map<String, dynamic> params =
            jsonDecode(data.payload) as Map<String, dynamic>;
        final String cmd = _paramString(
          params,
          const ['command', 'action', 'op'],
        ).toLowerCase();
        _log('RPC', 'control_audio cmd=$cmd');
        final AudioPlayer? p = _musicPlayer;
        if (p == null) return jsonEncode({'status': 'ok'});
        switch (cmd) {
          case 'pause':
            await p.pause();
          case 'resume' || 'play':
            await p.play();
          case 'stop':
            await p.stop();
            _setNowPlayingTitle(null);
          default:
            throw RpcError(
              code: 2002,
              message: 'Unsupported command: $cmd',
            );
        }
        return jsonEncode({'status': 'ok'});
      },
    );

    room.registerRpcMethod(
      'get_location',
      (RpcInvocationData data) async {
        _log('RPC', 'get_location called');
        final AiseeLocationResult loc =
            await AiseeLocationService.getCurrentLocation();
        return jsonEncode({
          'status': 'ok',
          'lat': loc.lat,
          'lng': loc.lng,
          'address': loc.address,
        });
      },
    );

    room.registerRpcMethod(
      'open_maps',
      (RpcInvocationData data) async {
        final Map<String, dynamic> params =
            jsonDecode(data.payload) as Map<String, dynamic>;
        final String dest = _paramString(
          params,
          const ['destination', 'dest', 'query', 'q'],
        );
        final String latStr =
            _paramString(params, const ['lat', 'latitude']);
        final String lngStr =
            _paramString(params, const ['lng', 'longitude']);
        _log('RPC', 'open_maps dest="$dest" lat=$latStr lng=$lngStr');

        Uri? mapUri;
        if (dest.isNotEmpty) {
          if (!kIsWeb && Platform.isIOS) {
            mapUri = Uri.parse(
              'https://maps.apple.com/'
              '?daddr=${Uri.encodeComponent(dest)}',
            );
          } else {
            mapUri = Uri.parse(
              'google.navigation:'
              'q=${Uri.encodeComponent(dest)}',
            );
          }
        } else if (latStr.isNotEmpty && lngStr.isNotEmpty) {
          if (!kIsWeb && Platform.isIOS) {
            mapUri = Uri.parse(
              'https://maps.apple.com/?daddr=$latStr,$lngStr',
            );
          } else {
            mapUri = Uri.parse(
              'google.navigation:q=$latStr,$lngStr',
            );
          }
        }
        if (mapUri == null) {
          throw RpcError(
            code: 2003,
            message: 'Missing destination or lat/lng',
          );
        }
        final bool launched = await launchUrl(
          mapUri,
          mode: LaunchMode.externalApplication,
        );
        if (!launched) {
          throw RpcError(code: 2004, message: 'Cannot open maps');
        }
        return jsonEncode({'status': 'ok'});
      },
    );

    room.registerRpcMethod(
      'schedule_reminder',
      (RpcInvocationData data) async {
        final Map<String, dynamic> params =
            jsonDecode(data.payload) as Map<String, dynamic>;
        final String typeStr =
            _paramString(params, const ['type', 'reminder_type']);
        final String name =
            _paramString(params, const ['name', 'title']);
        final int baseId =
            DateTime.now().millisecondsSinceEpoch % 100000;
        _log('RPC', 'schedule_reminder type=$typeStr name=$name');

        if (typeStr == 'medication') {
          final List<String> times =
              (params['times'] as List<dynamic>?)?.cast<String>() ??
                  <String>[];
          final String freq =
              _paramString(params, const ['frequency', 'freq']);
          final AiseeReminder reminder = AiseeReminder(
            id: baseId,
            type: AiseeReminderType.medication,
            title: name,
            times: times,
            frequency: freq.isEmpty ? 'daily' : freq,
            createdAt: DateTime.now(),
          );
          await AiseeReminderService.instance
              .scheduleReminder(reminder);
        } else if (typeStr == 'appointment') {
          final String dt = _paramString(
            params,
            const ['datetime', 'date_time', 'time'],
          );
          final AiseeReminder reminder = AiseeReminder(
            id: baseId,
            type: AiseeReminderType.appointment,
            title: name,
            datetime: dt,
            createdAt: DateTime.now(),
          );
          await AiseeReminderService.instance
              .scheduleReminder(reminder);
        }
        return jsonEncode({'status': 'ok'});
      },
    );

    _log('RPC', '7 methods registered');
  }

  Future<void> connect({
    required String userName,
    required String userId,
    required bool hasFamilyLink,
  }) async {
    _log('Connect', 'Bat dau ket noi LiveKit...');
    await disconnect();
    _log('Connect', 'Xin quyen mic + camera + location...');
    await _ensureMediaPermissions();
    _log('Connect', 'Quyen OK. Lay token phong...');
    final LiveKitJoinCredentials creds = await _fetchWithRefreshIfNeeded();
    _logBlock('Connect', 'Credentials nhan duoc', {
      'url': creds.url,
      'room': creds.roomName ?? '(server tu gan)',
      'token': '${creds.token.substring(0, 20)}...${creds.token.substring(creds.token.length - 10)}',
    });
    final Room room = Room();
    _room = room;
    _roomListener = room.createListener()
      ..on<ActiveSpeakersChangedEvent>((ActiveSpeakersChangedEvent e) {
        if (AiseeDebugConfig.enabled) {
          AiseePerformanceDebug.instance.recordActiveSpeakerEvent();
        }
        double maxLevel = 0;
        for (final Participant p in e.speakers) {
          if (p.audioLevel > maxLevel) {
            maxLevel = p.audioLevel;
          }
        }
        final double next = maxLevel.clamp(0.0, 1.0);
        if (AiseeDebugConfig.enabled &&
            assistantWaveEnergy.value != next) {
          AiseePerformanceDebug.instance.recordAssistantEnergyChanged();
        }
        assistantWaveEnergy.value = next;
      })
      ..on<LocalTrackPublishedEvent>((LocalTrackPublishedEvent e) {
        _log('Camera', 'LocalTrackPublished source=${e.publication.source}');
        if (e.publication.source == TrackSource.camera) {
          syncLocalCameraPreviewTrack();
        }
      })
      ..on<LocalTrackUnpublishedEvent>((LocalTrackUnpublishedEvent e) {
        _log('Camera', 'LocalTrackUnpublished source=${e.publication.source}');
        if (e.publication.source == TrackSource.camera) {
          syncLocalCameraPreviewTrack();
        }
      })
      ..on<TrackMutedEvent>((TrackMutedEvent e) {
        _log('Camera', 'TrackMuted source=${e.publication.source} isLocal=${e.participant is LocalParticipant}');
        if (e.participant is LocalParticipant &&
            e.publication.source == TrackSource.camera) {
          syncLocalCameraPreviewTrack();
        }
      })
      ..on<TrackUnmutedEvent>((TrackUnmutedEvent e) {
        _log('Camera', 'TrackUnmuted source=${e.publication.source} isLocal=${e.participant is LocalParticipant}');
        if (e.participant is LocalParticipant &&
            e.publication.source == TrackSource.camera) {
          syncLocalCameraPreviewTrack();
        }
      })
      ..on<ParticipantAttributesChanged>((ParticipantAttributesChanged event) {
        if (event.participant is! RemoteParticipant) return;
        final String? raw = event.participant.attributes['lk.agent.state'];
        if (raw == null) return;
        final AgentState next = AgentState.fromString(raw);
        _log('AgentState', 'Agent state: $raw -> $next');
        agentState.value = next;
      });
    _log('Connect', 'Dang ket noi room...');
    await room.connect(creds.url, creds.token);
    _registerRpcMethods();
    await room.localParticipant?.setAttributes(<String, String>{
      'user_name': userName,
      'user_id': userId,
      'locale': Platform.localeName,
      'accessibility': 'low_vision',
      'has_family_link': hasFamilyLink ? 'true' : 'false',
    });
    _log('Connect', 'User attributes published: locale=${Platform.localeName}');
    _log('Connect', 'Room connected! Bat mic...');
    await room.localParticipant?.setMicrophoneEnabled(true);
    _log('Connect', 'Mic ON. Config audio session...');
    await _configureAudioSession();
    _log('Connect', 'Sync camera preview...');
    syncLocalCameraPreviewTrack();
    _startWaveDecayTimer();
    await AiseeVoiceAssistantForeground.ensureStartedAfterConnected();
    _log('Connect', 'Ket noi hoan tat. San sang nhan lenh tu agent.');
  }

  Future<void> disconnect() async {
    _log('Disconnect', 'Dang ngat ket noi...');
    _setLocalCameraPreviewTrack(null);
    agentState.value = AgentState.disconnected;
    await _disposeMusicPlayer();
    _stopWaveDecayTimer();
    assistantWaveEnergy.value = 0;
    await _roomListener?.dispose();
    _roomListener = null;
    final Room? r = _room;
    _room = null;
    if (r != null) {
      try {
        await r.disconnect();
        _log('Disconnect', 'Room disconnected OK');
      } catch (e, st) {
        debugPrint('LiveKit disconnect: $e\n$st');
      }
      try {
        await r.dispose();
      } catch (e, st) {
        debugPrint('LiveKit dispose: $e\n$st');
      }
    } else {
      _log('Disconnect', 'Khong co room dang ket noi');
    }
    await AiseeVoiceAssistantForeground.ensureStopped();
    _log('Disconnect', 'Da ngat xong.');
  }
}
