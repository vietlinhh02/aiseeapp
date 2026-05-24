import 'dart:async';

import 'package:flutter/material.dart';
import 'package:aiseeapp/theme/aisee_typography.dart';

import '../generated/l10n/app_localizations.dart';
import '../models/aisee_incoming_call.dart';
import '../services/incoming_call_controller.dart';
import '../theme/style_tokens.dart';

class IncomingCallOverlayHost extends StatelessWidget {
  const IncomingCallOverlayHost({
    super.key,
    required this.child,
    required this.controller,
    this.onAccept,
    this.onDecline,
  });

  final Widget child;
  final AiseeIncomingCallController controller;
  final Future<void> Function(AiseeIncomingCall call)? onAccept;
  final Future<void> Function(AiseeIncomingCall call)? onDecline;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? _) {
        final AiseeIncomingCall? call = controller.currentCall;
        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            child,
            if (controller.shouldShowOverlay && call != null)
              _IncomingCallCard(
                call: call,
                onAccept: () async {
                  controller.hideIncomingCall();
                  await onAccept?.call(call);
                },
                onDecline: () async {
                  controller.hideIncomingCall();
                  await onDecline?.call(call);
                },
              ),
          ],
        );
      },
    );
  }
}

class _IncomingCallCard extends StatefulWidget {
  const _IncomingCallCard({
    required this.call,
    required this.onAccept,
    required this.onDecline,
  });

  final AiseeIncomingCall call;
  final Future<void> Function() onAccept;
  final Future<void> Function() onDecline;

  @override
  State<_IncomingCallCard> createState() => _IncomingCallCardState();
}

class _IncomingCallCardState extends State<_IncomingCallCard>
    with TickerProviderStateMixin {
  late final AnimationController _ripple = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();
  late final AnimationController _breathe = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ripple.dispose();
    _breathe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AiseeIncomingCall call = widget.call;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        child: Align(
          alignment: Alignment.topCenter,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            builder: (BuildContext context, double value, Widget? child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, -16 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 390),
              child: Material(
                color: StyleTokens.surfaceCard,
                elevation: 10,
                shadowColor: const Color(0x24060913),
                borderRadius: BorderRadius.circular(22),
                clipBehavior: Clip.antiAlias,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: StyleTokens.navBarBorder.withValues(alpha: 0.18),
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
                  child: Row(
                    children: <Widget>[
                      _PulsingAvatar(call: call, ripple: _ripple),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              call.isVideo
                                  ? AppLocalizations.of(
                                      context,
                                    ).incomingVideoCall
                                  : AppLocalizations.of(
                                      context,
                                    ).incomingVoiceCall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: aiseeTextStyle(
                                color: StyleTokens.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                height: 1.18,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              call.callerName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: aiseeTextStyle(
                                color: StyleTokens.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                height: 1.18,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _RingingDots(controller: _breathe),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      _CallActionButton(
                        tooltip: AppLocalizations.of(context).declineCall,
                        icon: Icons.call_end_rounded,
                        backgroundColor: const Color(0xFFE53935),
                        foregroundColor: Colors.white,
                        onPressed: () => unawaited(widget.onDecline()),
                      ),
                      const SizedBox(width: 6),
                      _BreathingButton(
                        controller: _breathe,
                        child: _CallActionButton(
                          tooltip: 'Nghe',
                          icon: Icons.call_rounded,
                          backgroundColor: StyleTokens.buttonPrimary,
                          foregroundColor: Colors.white,
                          onPressed: () => unawaited(widget.onAccept()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PulsingAvatar extends StatelessWidget {
  const _PulsingAvatar({required this.call, required this.ripple});

  final AiseeIncomingCall call;
  final AnimationController ripple;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      height: 58,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          AnimatedBuilder(
            animation: ripple,
            builder: (BuildContext context, Widget? _) {
              return CustomPaint(
                size: const Size(58, 58),
                painter: _RipplePainter(
                  progress: ripple.value,
                  color: StyleTokens.buttonPrimary,
                ),
              );
            },
          ),
          _CallerAvatar(call: call),
        ],
      ),
    );
  }
}

class _RipplePainter extends CustomPainter {
  _RipplePainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double base = size.width / 2 - 6;
    for (int i = 0; i < 2; i++) {
      final double t = (progress + i * 0.5) % 1.0;
      final double r = base + t * 14;
      final double alpha = (1 - t) * 0.35;
      if (alpha <= 0) continue;
      final Paint paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = color.withValues(alpha: alpha);
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RipplePainter old) =>
      old.progress != progress || old.color != color;
}

class _BreathingButton extends StatelessWidget {
  const _BreathingButton({required this.controller, required this.child});

  final AnimationController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? c) {
        final double t = Curves.easeInOut.transform(controller.value);
        final double scale = 1.0 + 0.06 * t;
        return Transform.scale(scale: scale, child: c);
      },
      child: child,
    );
  }
}

class _RingingDots extends StatelessWidget {
  const _RingingDots({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? _) {
        final int active = (controller.value * 3).floor() % 3;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              AppLocalizations.of(context).ringing,
              style: aiseeTextStyle(
                color: StyleTokens.buttonPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.0,
              ),
            ),
            const SizedBox(width: 2),
            for (int i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Opacity(
                  opacity: i <= active ? 1.0 : 0.25,
                  child: Container(
                    width: 3,
                    height: 3,
                    decoration: const BoxDecoration(
                      color: StyleTokens.buttonPrimary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CallActionButton extends StatelessWidget {
  const _CallActionButton({
    required this.tooltip,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: tooltip,
      button: true,
      child: Material(
        color: backgroundColor,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox.square(
            dimension: 42,
            child: Icon(icon, color: foregroundColor, size: 21),
          ),
        ),
      ),
    );
  }
}

class _CallerAvatar extends StatelessWidget {
  const _CallerAvatar({required this.call});

  final AiseeIncomingCall call;

  @override
  Widget build(BuildContext context) {
    final String initial = call.callerName.characters.isEmpty
        ? '?'
        : call.callerName.characters.first.toUpperCase();
    final String? avatarUrl = call.callerAvatarUrl;
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: StyleTokens.navInactivePill,
        shape: BoxShape.circle,
        border: Border.all(color: StyleTokens.navGlassBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: avatarUrl == null
          ? _CallerAvatarFallback(initial: initial)
          : Image.network(
              avatarUrl,
              fit: BoxFit.cover,
              errorBuilder:
                  (BuildContext context, Object error, StackTrace? stack) {
                    return _CallerAvatarFallback(initial: initial);
                  },
            ),
    );
  }
}

class _CallerAvatarFallback extends StatelessWidget {
  const _CallerAvatarFallback({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initial,
        style: aiseeTextStyle(
          color: StyleTokens.brandSecondary,
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
