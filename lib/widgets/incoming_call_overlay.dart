import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

class _IncomingCallCard extends StatelessWidget {
  const _IncomingCallCard({
    required this.call,
    required this.onAccept,
    required this.onDecline,
  });

  final AiseeIncomingCall call;
  final Future<void> Function() onAccept;
  final Future<void> Function() onDecline;

  @override
  Widget build(BuildContext context) {
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
                  padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                  child: Row(
                    children: <Widget>[
                      _CallerAvatar(call: call),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              call.isVideo
                                  ? 'Cuộc gọi video đến'
                                  : 'Cuộc gọi thoại đến',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
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
                              style: GoogleFonts.plusJakartaSans(
                                color: StyleTokens.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                height: 1.18,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _CallActionButton(
                        tooltip: 'Từ chối',
                        icon: Icons.call_end_rounded,
                        backgroundColor: const Color(0xFFE53935),
                        foregroundColor: Colors.white,
                        onPressed: () => unawaited(onDecline()),
                      ),
                      const SizedBox(width: 6),
                      _CallActionButton(
                        tooltip: 'Nghe',
                        icon: Icons.call_rounded,
                        backgroundColor: StyleTokens.buttonPrimary,
                        foregroundColor: Colors.white,
                        onPressed: () => unawaited(onAccept()),
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
        style: GoogleFonts.plusJakartaSans(
          color: StyleTokens.brandSecondary,
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
