import 'package:flutter/material.dart';

const String aiseeFontFamily = 'GoogleSans';

TextStyle aiseeTextStyle({
  TextStyle? textStyle,
  Color? color,
  Color? backgroundColor,
  double? fontSize,
  FontWeight? fontWeight,
  FontStyle? fontStyle,
  double? letterSpacing,
  double? wordSpacing,
  TextBaseline? textBaseline,
  double? height,
  Locale? locale,
  Paint? foreground,
  Paint? background,
  List<Shadow>? shadows,
  List<FontFeature>? fontFeatures,
  List<FontVariation>? fontVariations,
  TextDecoration? decoration,
  Color? decorationColor,
  TextDecorationStyle? decorationStyle,
  double? decorationThickness,
  TextOverflow? overflow,
  TextLeadingDistribution? leadingDistribution,
}) {
  final TextStyle base = textStyle ?? const TextStyle();
  return base.copyWith(
    color: color,
    backgroundColor: backgroundColor,
    fontSize: fontSize,
    fontWeight: fontWeight,
    fontStyle: fontStyle,
    letterSpacing: letterSpacing,
    wordSpacing: wordSpacing,
    textBaseline: textBaseline,
    height: height,
    locale: locale,
    foreground: foreground,
    background: background,
    shadows: shadows,
    fontFeatures: fontFeatures,
    fontVariations: fontVariations,
    decoration: decoration,
    decorationColor: decorationColor,
    decorationStyle: decorationStyle,
    decorationThickness: decorationThickness,
    overflow: overflow,
    leadingDistribution: leadingDistribution,
    fontFamily: aiseeFontFamily,
    package: null,
  );
}

TextTheme aiseeTextTheme([TextTheme? textTheme]) {
  final TextTheme base = textTheme ?? ThemeData.light().textTheme;
  return base.apply(fontFamily: aiseeFontFamily);
}
