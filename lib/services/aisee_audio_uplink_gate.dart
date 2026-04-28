import 'dart:collection';
import 'dart:math' as math;
import 'dart:typed_data';

class AiseeAudioUplinkDecision {
  const AiseeAudioUplinkDecision({required this.frames, required this.bargeIn});

  final List<Uint8List> frames;
  final bool bargeIn;
}

class AiseeAudioUplinkGate {
  AiseeAudioUplinkGate({
    this.enabled = true,
    this.initialNoiseFloor = 0.006,
    this.minSpeechRms = 0.018,
    this.minContinueRms = 0.010,
    this.minBargeInRms = 0.060,
    this.noiseMultiplier = 3.0,
    this.continueMultiplier = 1.7,
    this.bargeInMultiplier = 4.0,
    this.hangoverFrames = 10,
    this.preRollFrames = 3,
    this.preRollMinRms = 0.006,
    this.gateWhenAssistantInactive = true,
    int bargeInConsecutiveFrames = 3,
  }) : _noiseFloor = initialNoiseFloor.clamp(0.003, 0.040),
       _bargeInConsecutiveFrames = bargeInConsecutiveFrames;

  AiseeAudioUplinkGate.echoOnly({
    this.minBargeInRms = 0.08,
    this.bargeInMultiplier = 3.5,
    int bargeInConsecutiveFrames = 3,
  }) : enabled = true,
       initialNoiseFloor = 0.006,
       minSpeechRms = 0.0,
       minContinueRms = 0.0,
       noiseMultiplier = 3.0,
       continueMultiplier = 1.7,
       hangoverFrames = 0,
       preRollFrames = 0,
       preRollMinRms = 0,
       gateWhenAssistantInactive = false,
       _noiseFloor = 0.006,
       _bargeInConsecutiveFrames = bargeInConsecutiveFrames;

  AiseeAudioUplinkGate.disabled()
    : enabled = false,
      initialNoiseFloor = 0.006,
      minSpeechRms = 0,
      minContinueRms = 0,
      minBargeInRms = 0,
      noiseMultiplier = 1,
      continueMultiplier = 1,
      bargeInMultiplier = 1,
      hangoverFrames = 0,
      preRollFrames = 0,
      preRollMinRms = 0,
      gateWhenAssistantInactive = false,
      _noiseFloor = 0.006,
      _bargeInConsecutiveFrames = 0;

  final bool enabled;
  final double initialNoiseFloor;
  final double minSpeechRms;
  final double minContinueRms;
  final double minBargeInRms;
  final double noiseMultiplier;
  final double continueMultiplier;
  final double bargeInMultiplier;
  final int hangoverFrames;
  final int preRollFrames;
  final double preRollMinRms;
  final bool gateWhenAssistantInactive;
  final int _bargeInConsecutiveFrames;

  int get bargeInConsecutiveFrames => _bargeInConsecutiveFrames;

  final Queue<Uint8List> _preRoll = Queue<Uint8List>();
  double _noiseFloor;
  int _hangover = 0;
  int _consecutiveBargeInFrames = 0;
  bool _speechActive = false;

  AiseeAudioUplinkDecision process(
    Uint8List bytes, {
    required bool assistantOutputActive,
  }) {
    if (!enabled) {
      return AiseeAudioUplinkDecision(
        frames: <Uint8List>[Uint8List.fromList(bytes)],
        bargeIn: false,
      );
    }

    final double rms = _rms(bytes);
    if (!assistantOutputActive && !gateWhenAssistantInactive) {
      _adaptNoiseFloor(rms);
      return AiseeAudioUplinkDecision(
        frames: <Uint8List>[Uint8List.fromList(bytes)],
        bargeIn: false,
      );
    }

    if (assistantOutputActive && !gateWhenAssistantInactive) {
      final double bargeInThreshold = math.max(
        minBargeInRms,
        _noiseFloor * bargeInMultiplier,
      );
      if (rms < bargeInThreshold) {
        _consecutiveBargeInFrames = 0;
        _adaptNoiseFloor(rms);
        return const AiseeAudioUplinkDecision(
          frames: <Uint8List>[],
          bargeIn: false,
        );
      }
      _consecutiveBargeInFrames++;
      if (_consecutiveBargeInFrames < _bargeInConsecutiveFrames) {
        return const AiseeAudioUplinkDecision(
          frames: <Uint8List>[],
          bargeIn: false,
        );
      }
      return AiseeAudioUplinkDecision(
        frames: <Uint8List>[Uint8List.fromList(bytes)],
        bargeIn: true,
      );
    }

    final double speechThreshold = math.max(
      minSpeechRms,
      _noiseFloor * noiseMultiplier,
    );
    final double continueThreshold = math.max(
      minContinueRms,
      _noiseFloor * continueMultiplier,
    );
    final double bargeInThreshold = math.max(
      minBargeInRms,
      _noiseFloor * bargeInMultiplier,
    );
    final bool startsSpeech = rms >= speechThreshold;
    final bool continuesSpeech = _speechActive && rms >= continueThreshold;
    final bool bargeIn = assistantOutputActive && rms >= bargeInThreshold;
    final bool send =
        startsSpeech || continuesSpeech || bargeIn || _hangover > 0;

    if (!send) {
      _speechActive = false;
      _adaptNoiseFloor(rms);
      _rememberPreRoll(bytes, rms);
      return const AiseeAudioUplinkDecision(
        frames: <Uint8List>[],
        bargeIn: false,
      );
    }

    final List<Uint8List> frames = <Uint8List>[];
    if (!_speechActive && (startsSpeech || bargeIn)) {
      frames.addAll(_preRoll);
      _preRoll.clear();
    }
    frames.add(Uint8List.fromList(bytes));
    _speechActive = startsSpeech || continuesSpeech || bargeIn;
    _hangover = _speechActive ? hangoverFrames : _hangover - 1;

    return AiseeAudioUplinkDecision(frames: frames, bargeIn: bargeIn);
  }

  void reset() {
    _preRoll.clear();
    _noiseFloor = initialNoiseFloor.clamp(0.003, 0.040);
    _hangover = 0;
    _consecutiveBargeInFrames = 0;
    _speechActive = false;
  }

  void _rememberPreRoll(Uint8List bytes, double rms) {
    if (preRollFrames <= 0 || rms < preRollMinRms) {
      return;
    }
    _preRoll.add(Uint8List.fromList(bytes));
    while (_preRoll.length > preRollFrames) {
      _preRoll.removeFirst();
    }
  }

  void _adaptNoiseFloor(double rms) {
    if (rms <= 0) {
      return;
    }
    final double capped = rms.clamp(0.003, 0.040);
    _noiseFloor = (_noiseFloor * 0.98 + capped * 0.02).clamp(0.003, 0.040);
  }

  static double _rms(Uint8List bytes) {
    if (bytes.length < 2) {
      return 0;
    }
    final ByteData data = ByteData.sublistView(bytes);
    double sumSquares = 0;
    int samples = 0;
    for (int index = 0; index + 1 < bytes.length; index += 2) {
      final double normalized = data.getInt16(index, Endian.little) / 32768.0;
      sumSquares += normalized * normalized;
      samples += 1;
    }
    if (samples == 0) {
      return 0;
    }
    return math.sqrt(sumSquares / samples).clamp(0.0, 1.0);
  }
}
