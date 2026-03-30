import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../theme/style_tokens.dart';

/// Thông báo dạng toast (không dùng SnackBar).
abstract final class AppToast {
  static Future<void> show(String message, {bool isError = false}) {
    return Fluttertoast.showToast(
      msg: message,
      toastLength: isError ? Toast.LENGTH_LONG : Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: isError
          ? const Color(0xFFFFF0F0)
          : const Color(0xFFFFFFFF),
      textColor: StyleTokens.textPrimary,
      fontSize: 14,
    );
  }
}
