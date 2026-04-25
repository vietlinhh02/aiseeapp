import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';

/// Raw frame data captured from a video track.
typedef CapturedFrame = ({Uint8List pixels, int width, int height});

/// Abstraction over an NSFW classifier — allows faking in tests.
abstract interface class NsfwClassifier {
  Future<double> classify(Uint8List argbPixels, int width, int height);
  void dispose();
}

/// Periodically samples video frames and triggers [onUnsafeDetected] when
/// the classifier score exceeds [threshold].
class AiseeContentGuardService {
  AiseeContentGuardService({
    required this.classifier,
    this.threshold = 0.7,
    this.checkInterval = const Duration(milliseconds: 1500),
  });

  final NsfwClassifier classifier;
  final double threshold;
  final Duration checkInterval;

  Timer? _timer;
  bool _checking = false;

  void startWithFrameProvider({
    required Future<CapturedFrame?> Function() frameProvider,
    required VoidCallback onUnsafeDetected,
  }) {
    stop();
    _timer = Timer.periodic(checkInterval, (_) async {
      if (_checking) return;
      _checking = true;
      try {
        final frame = await frameProvider();
        if (frame == null) return;

        final score = await classifier.classify(
          frame.pixels,
          frame.width,
          frame.height,
        );

        if (score > threshold) {
          stop();
          onUnsafeDetected();
        }
      } catch (e, st) {
        dev.log(
          'AiseeContentGuardService: error during frame check: $e',
          stackTrace: st,
          level: 900,
        );
      } finally {
        _checking = false;
      }
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
