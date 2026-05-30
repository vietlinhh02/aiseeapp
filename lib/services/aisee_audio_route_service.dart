import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';

/// Audio context modes for the app.
enum AudioContext {
  /// Agent voice conversation (speaker, voiceChat).
  agentVoice,

  /// Music playback (media).
  music,

  /// Phone/video call (LiveKit manages its own audio route).
  phoneCall,
}

/// Centralized audio routing service.
///
/// Ensures the audio session is configured correctly when switching between
/// Agent voice mode, music mode, and phone call mode.
class AiseeAudioRouteService {
  AiseeAudioRouteService._();

  static final AiseeAudioRouteService instance = AiseeAudioRouteService._();

  AudioContext? _currentContext;

  AudioContext? get currentContext => _currentContext;

  /// Configure audio session for Agent voice mode.
  ///
  /// Uses playAndRecord with defaultToSpeaker so Agent audio comes through
  /// the loudspeaker, not the earpiece.
  Future<void> enterAgentMode() async {
    if (_currentContext == AudioContext.agentVoice) return;
    if (kIsWeb) return;

    try {
      final AudioSession session = await AudioSession.instance;
      await session.configure(
        AudioSessionConfiguration(
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
        ),
      );
      _currentContext = AudioContext.agentVoice;
      debugPrint('[AiSee:Audio] Entered Agent voice mode (speaker)');
    } catch (e) {
      debugPrint('[AiSee:Audio] Failed to enter Agent mode: $e');
    }
  }

  /// Configure audio session for music playback.
  Future<void> enterMusicMode() async {
    if (_currentContext == AudioContext.music) return;
    if (kIsWeb) return;

    try {
      final AudioSession session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      _currentContext = AudioContext.music;
      debugPrint('[AiSee:Audio] Entered Music mode');
    } catch (e) {
      debugPrint('[AiSee:Audio] Failed to enter Music mode: $e');
    }
  }

  /// Mark that a phone call is active (LiveKit manages its own audio route).
  Future<void> enterPhoneCallMode() async {
    _currentContext = AudioContext.phoneCall;
    debugPrint('[AiSee:Audio] Entered Phone call mode');
  }

  /// Restore Agent voice mode after a call or music session ends.
  ///
  /// This is the key method to call after family/support call ends to prevent
  /// audio from being stuck on earpiece.
  Future<void> restoreAgentMode() async {
    debugPrint('[AiSee:Audio] Restoring Agent mode (was: $_currentContext)');
    _currentContext = null; // Force reconfigure.
    await enterAgentMode();
  }
}
