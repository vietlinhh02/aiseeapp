import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/style_tokens.dart';

/// Thông báo dạng toast + snackbar helper.
abstract final class AppToast {
  static Future<void> show(String message, {bool isError = false}) {
    return Fluttertoast.showToast(
      msg: message,
      toastLength: isError ? Toast.LENGTH_LONG : Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: isError ? 3 : 2,
      backgroundColor: isError
          ? const Color(0xFFFFF0F0)
          : const Color(0xFFFFFFFF),
      textColor: isError ? StyleTokens.error : StyleTokens.textPrimary,
      fontSize: 14,
    );
  }

  /// Styled SnackBar — floating, bo 12, top margin cao.
  static void snack(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isError ? StyleTokens.error : StyleTokens.textPrimary,
          ),
        ),
        backgroundColor: isError
            ? const Color(0xFFFFF0F0)
            : StyleTokens.surfaceCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isError
                ? StyleTokens.error.withAlpha(60)
                : StyleTokens.cardBorder,
          ),
        ),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        elevation: 0,
        duration: Duration(seconds: isError ? 3 : 2),
      ),
    );
  }
}
