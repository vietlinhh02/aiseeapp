import 'package:flutter/material.dart';

import '../generated/l10n/app_localizations.dart';
import '../theme/style_tokens.dart';
import 'app_wordmark.dart';

/// Màn hình trung gian khi app đang xác minh token lưu + Google (không hiện form login).
class AuthBootstrapping extends StatefulWidget {
  const AuthBootstrapping({super.key, this.title, this.detail});

  final String? title;
  final String? detail;

  @override
  State<AuthBootstrapping> createState() => _AuthBootstrappingState();
}

class _AuthBootstrappingState extends State<AuthBootstrapping>
    with TickerProviderStateMixin {
  late final AnimationController _intro;
  late final AnimationController _pulse;
  late final AnimationController _dots;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    )..forward();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _dots = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _intro.dispose();
    _pulse.dispose();
    _dots.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String resolvedTitle =
        widget.title ?? AppLocalizations.of(context).bootstrapCheckingSession;
    final Animation<double> introCurve = CurvedAnimation(
      parent: _intro,
      curve: Curves.easeOutCubic,
    );
    final Animation<double> introFade = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );
    final Animation<double> introSlide = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    );

    return Scaffold(
      backgroundColor: StyleTokens.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FadeTransition(
                  opacity: introFade,
                  child: ScaleTransition(
                    scale: Tween<double>(
                      begin: 0.92,
                      end: 1.0,
                    ).animate(introCurve),
                    child: AnimatedBuilder(
                      animation: _pulse,
                      builder: (BuildContext context, Widget? child) {
                        final double t = Curves.easeInOut.transform(
                          _pulse.value,
                        );
                        return Transform.scale(
                          scale: 1.0 + 0.025 * t,
                          child: child,
                        );
                      },
                      child: const AppWordmark(fontSize: 40),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                FadeTransition(
                  opacity: introSlide,
                  child: const _LoadingDots(),
                ),
                const SizedBox(height: 24),
                FadeTransition(
                  opacity: introSlide,
                  child: Text(
                    resolvedTitle,
                    style: StyleTokens.bodySmall(),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (widget.detail case final String d
                    when d.trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: 8),
                  FadeTransition(
                    opacity: introSlide,
                    child: Text(
                      d.trim(),
                      style: StyleTokens.bodySmall().copyWith(
                        color: StyleTokens.textMuted,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (BuildContext context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List<Widget>.generate(3, (int i) {
            final double phase = (_ctrl.value - i * 0.18) % 1.0;
            final double normalized = phase < 0 ? phase + 1.0 : phase;
            final double t = (1.0 - (normalized * 2 - 1).abs()).clamp(0.0, 1.0);
            final double eased = Curves.easeInOut.transform(t);
            final double scale = 0.6 + eased * 0.6;
            final double opacity = 0.35 + eased * 0.65;
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: i == 1 ? 6 : 4),
              child: Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: StyleTokens.buttonPrimary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
