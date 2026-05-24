import 'package:flutter/material.dart';
import 'package:aiseeapp/theme/aisee_typography.dart';

abstract final class StyleTokens {
  static const Color background = Color(0xFFF6F6F6);
  static const Color textPrimary = Color(0xFF060913);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textMuted = Color(0xFF999999);

  static const Color brandSecondary = Color(0xFF1A3263);

  static const Color linkAccent = brandSecondary;
  static const Color inputBorder = Color(0xFFCCCCCC);
  static const Color hint = Color(0xFFAAAAAA);
  static const Color buttonPrimary = Color(0xFF1A3263);
  static const Color buttonOnPrimary = Color(0xFFFFFFFF);

  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE0E0E0);
  static const Color error = Color(0xFFFF6B6B);

  /// Toast lỗi: nền xám-xanh nhạt (cùng họ navy), chữ đỏ đậm dễ đọc.
  static const Color toastErrorSurface = Color(0xFFE8ECF4);
  static const Color toastErrorOnSurface = Color(0xFF7D1D2E);

  /// Pill tab nav User UI đang chọn — nền navy, chữ/icon dùng [navSelectedOnPill].
  static const Color navSelectedPill = Color(0xFF1A3263);
  static const Color navSelectedOnPill = Color(0xFFFFFFFF);
  static const Color navUnselectedIcon = Color(0xFF999999);
  static const Color navInactivePill = Color(0xFFEEEEEE);

  /// Nền thanh nav: trắng.
  static const Color navBarBackground = Color(0xFFFFFFFF);

  /// Viền thanh nav: navy 60%.
  static Color navBarBorder = const Color(0xFF1A3263).withValues(alpha: 0.6);
  static const Color navGlassTint = Color(0xEAF0F0F0);
  static const Color navGlassBorder = Color(0xFFE0E0E0);

  static TextStyle titleScreen() => aiseeTextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1,
    letterSpacing: -0.2,
    color: textPrimary,
  );

  static TextStyle bodySmall() => aiseeTextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: -0.2,
    color: textSecondary,
  );

  static TextStyle socialLabel() => aiseeTextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.5,
    letterSpacing: -0.2,
    color: buttonOnPrimary,
  );

  static TextStyle separator() => aiseeTextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1,
    letterSpacing: -0.5,
    color: textPrimary,
  );

  static TextStyle inputHint() => aiseeTextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: -0.2,
    color: hint,
  );

  static TextStyle linkBold() => aiseeTextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 1.5,
    letterSpacing: -0.2,
    color: textPrimary,
  );

  static TextStyle linkAccentStyle() => aiseeTextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 1.5,
    letterSpacing: -0.2,
    color: linkAccent,
  );

  static TextStyle legalMuted() => aiseeTextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: -0.2,
    color: textMuted,
  );

  static TextStyle legalBold() => aiseeTextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 1.5,
    letterSpacing: -0.2,
    color: textPrimary,
  );

  static ThemeData lightTheme() {
    final base = ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      fontFamily: 'PlusJakartaSans',
    );
    final textTheme = aiseeTextTheme(
      base.textTheme,
    ).apply(bodyColor: textPrimary, displayColor: textPrimary);
    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        surface: Color(0xFFF6F6F6),
        primary: brandSecondary,
        onPrimary: Color(0xFFFFFFFF),
        onSurface: Color(0xFF060913),
        secondary: brandSecondary,
        error: Color(0xFFFF6B6B),
      ),
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF6F6F6),
        foregroundColor: Color(0xFF060913),
        elevation: 0,
        centerTitle: true,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: brandSecondary,
      ),
    );
  }
}
