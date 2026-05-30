import 'package:flutter/foundation.dart';

import 'aisee_audio_route_service.dart';

/// Configure audio session for Agent voice mode.
///
/// Delegates to [AiseeAudioRouteService] for centralized audio routing.
Future<void> configureAiseeVoiceAudioSession() async {
  if (kIsWeb) return;
  await AiseeAudioRouteService.instance.enterAgentMode();
}
