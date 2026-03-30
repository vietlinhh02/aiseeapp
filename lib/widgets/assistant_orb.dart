import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/agent_state.dart';

/// Audio visualizer bars — smooth animation driven by a single
/// AnimationController at 60fps. Voice energy is exponentially
/// smoothed to eliminate jitter from the 50ms input updates.
class AssistantOrb extends StatefulWidget {
  const AssistantOrb({
    super.key,
    required this.agentState,
    required this.voiceEnergy,
    this.barCount = 5,
  });

  final ValueListenable<AgentState> agentState;
  final ValueListenable<double> voiceEnergy;
  final int barCount;

  @override
  State<AssistantOrb> createState() => _AssistantOrbState();
}

class _AssistantOrbState extends State<AssistantOrb>
    with SingleTickerProviderStateMixin {
  // Single 60fps driver — all animation derived from elapsed time.
  late final AnimationController _tick = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  )..repeat();

  // Smoothed energy — lerps toward target each frame.
  double _smoothEnergy = 0;

  // Continuous phase accumulators (radians) — never reset, always smooth.
  double _pulsePhase = 0;
  double _thinkingPhase = 0;
  double _lastTickValue = 0;

  @override
  void initState() {
    super.initState();
    _tick.addListener(_onTick);
  }

  @override
  void dispose() {
    _tick.removeListener(_onTick);
    _tick.dispose();
    super.dispose();
  }

  void _onTick() {
    // Compute delta from controller (wraps 0→1 every second).
    double dt = _tick.value - _lastTickValue;
    if (dt < 0) dt += 1.0; // handle wrap-around
    _lastTickValue = _tick.value;

    final double dtSeconds = dt; // controller period = 1s, so value delta = seconds

    // Exponential smoothing: ~12% per frame at 60fps ≈ smooth 120ms settle.
    const double smoothing = 0.12;
    final double target = widget.voiceEnergy.value.clamp(0.0, 1.0);
    _smoothEnergy += smoothing * (target - _smoothEnergy);

    // Accumulate phases at state-dependent speeds.
    final AgentState s = widget.agentState.value;
    final double pulseSpeed = switch (s) {
      AgentState.listening => 5.0,
      AgentState.speaking => 6.0,
      AgentState.connecting || AgentState.initializing => 2.0,
      _ => 3.0,
    };
    _pulsePhase += pulseSpeed * dtSeconds;

    if (s == AgentState.thinking) {
      _thinkingPhase += 4.5 * dtSeconds;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.agentState.value.displayTextVi,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _tick,
          builder: (BuildContext context, Widget? child) {
            return CustomPaint(
              size: const Size(200, 80),
              painter: _BarsPainter(
                state: widget.agentState.value,
                energy: _smoothEnergy,
                pulsePhase: _pulsePhase,
                thinkingPhase: _thinkingPhase,
                barCount: widget.barCount,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter({
    required this.state,
    required this.energy,
    required this.pulsePhase,
    required this.thinkingPhase,
    required this.barCount,
  });

  final AgentState state;
  final double energy;
  final double pulsePhase;
  final double thinkingPhase;
  final int barCount;

  static const Color _active = Color(0xFF1A3263);
  static const Color _gray = Color(0xFFCCCCCC);

  @override
  void paint(Canvas canvas, Size size) {
    final bool isDead =
        state == AgentState.disconnected || state == AgentState.failed;

    final double opacity = switch (state) {
      AgentState.speaking => 1.0,
      AgentState.listening => 0.85,
      AgentState.idle => 0.5,
      AgentState.thinking => 0.7 + 0.3 * math.sin(thinkingPhase),
      AgentState.connecting || AgentState.initializing =>
        0.3 + 0.2 * math.sin(pulsePhase),
      AgentState.disconnected || AgentState.failed => 0.3,
    };

    final Paint barPaint = Paint()
      ..color = (isDead ? _gray : _active).withValues(alpha: opacity);

    const double barWidth = 6;
    const double gap = 6;
    final double totalWidth = barCount * barWidth + (barCount - 1) * gap;
    final double startX = (size.width - totalWidth) / 2;
    final double maxH = size.height * 0.85;
    final double minH = size.height * 0.12;
    final double range = maxH - minH;
    final double center = (barCount - 1) / 2;
    final double centerMax = math.max(center, 1);

    for (int i = 0; i < barCount; i++) {
      final double x = startX + i * (barWidth + gap);
      final double dist = (i - center).abs() / centerMax;
      final double phase = pulsePhase + i * 0.9;

      final double h = switch (state) {
        AgentState.speaking =>
          minH +
              range *
                  (energy * (1.0 - dist * 0.4) +
                          0.12 * math.sin(phase * 2))
                      .clamp(0.0, 1.0),
        AgentState.listening =>
          minH +
              range *
                  ((0.3 + 0.2 * math.sin(phase)) * (1.0 - dist * 0.3))
                      .clamp(0.0, 1.0),
        AgentState.thinking =>
          minH +
              range *
                  (0.25 + 0.35 * math.sin(thinkingPhase + i * 0.7))
                      .clamp(0.0, 1.0),
        AgentState.idle =>
          minH + range * (0.15 + 0.08 * math.sin(phase)),
        AgentState.connecting || AgentState.initializing =>
          minH + range * (0.1 + 0.1 * math.sin(phase)),
        AgentState.disconnected || AgentState.failed => minH,
      };

      final double top = (size.height - h) / 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, top, barWidth, h),
          const Radius.circular(3),
        ),
        barPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) => true;
}
