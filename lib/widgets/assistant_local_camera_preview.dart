import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

import '../theme/style_tokens.dart';

/// Video camera gần full khung cha, bo góc + viền (dùng trong Stack Positioned.fill).
class AssistantLiveCameraBackdrop extends StatelessWidget {
  const AssistantLiveCameraBackdrop({super.key, required this.track});

  final LocalVideoTrack track;

  static const double _radius = 28;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 2, 0, 6),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(_radius),
          border: Border.all(
            color: StyleTokens.navGlassBorder,
            width: 1.5,
          ),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: KeyedSubtree(
          key: ValueKey<String>(track.mediaStreamTrack.id ?? 'local_video'),
          child: VideoTrackRenderer(
            track,
            fit: VideoViewFit.cover,
            mirrorMode: VideoViewMirrorMode.auto,
            autoCenter: false,
          ),
        ),
      ),
    );
  }
}
