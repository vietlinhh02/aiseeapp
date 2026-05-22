import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/aisee_navigator_key.dart';
import '../theme/style_tokens.dart';

/// Toast phía trên — [OverlayEntry] trên [Navigator.overlay] (không dùng FToast +
/// [navigatorKey.currentContext] vì Overlay nằm *trong* Navigator, không phải tổ tiên).
abstract final class AppToast {
  static Future<void> show(String message, {bool isError = false}) {
    final NavigatorState? nav = aiseeNavigatorKey.currentState;
    final OverlayState? overlay = nav?.overlay;
    if (overlay != null && overlay.mounted) {
      late OverlayEntry entry;
      entry = OverlayEntry(
        builder: (BuildContext context) {
          final double top = MediaQuery.paddingOf(context).top + 12;
          final double maxW = MediaQuery.sizeOf(context).width - 48;
          return Positioned(
            top: top,
            left: 24,
            right: 24,
            child: Material(
              color: Colors.transparent,
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxW),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: isError
                          ? StyleTokens.toastErrorSurface
                          : StyleTokens.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                        letterSpacing: -0.2,
                        color: isError
                            ? StyleTokens.toastErrorOnSurface
                            : StyleTokens.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
      overlay.insert(entry);
      unawaited(
        Future<void>.delayed(Duration(seconds: isError ? 3 : 2), () {
          if (entry.mounted) {
            entry.remove();
          }
        }),
      );
      return Future.value();
    }

    return Fluttertoast.showToast(
      msg: message,
      toastLength: isError ? Toast.LENGTH_LONG : Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: isError ? 3 : 2,
      backgroundColor: isError
          ? StyleTokens.toastErrorSurface
          : StyleTokens.surfaceCard,
      textColor: isError
          ? StyleTokens.toastErrorOnSurface
          : StyleTokens.textPrimary,
      fontSize: 15,
    );
  }
}
