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
    return Material(
      color: const Color(0x66000000),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Align(
            alignment: Alignment.topCenter,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: StyleTokens.surfaceCard,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    blurRadius: 24,
                    offset: Offset(0, 12),
                    color: Color(0x22060913),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(0xFFE9EEF8),
                      child: Text(
                        call.callerName.characters.first.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          color: StyleTokens.brandSecondary,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      call.callerName,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        color: StyleTokens.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      call.isVideo
                          ? 'Cuộc gọi video đến'
                          : 'Cuộc gọi thoại đến',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        color: StyleTokens.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              unawaited(onDecline());
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: StyleTokens.textPrimary,
                              side: const BorderSide(
                                color: StyleTokens.cardBorder,
                              ),
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text('Từ chối'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              unawaited(onAccept());
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: StyleTokens.buttonPrimary,
                              foregroundColor: StyleTokens.buttonOnPrimary,
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text('Nghe'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
