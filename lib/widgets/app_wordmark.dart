import 'package:flutter/material.dart';
import 'package:aiseeapp/theme/aisee_typography.dart';

import '../theme/style_tokens.dart';

/// Logo chữ **aisee** — Plus Jakarta Sans Bold.
class AppWordmark extends StatelessWidget {
  const AppWordmark({super.key, this.fontSize = 32});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'aisee',
      child: Text(
        'aisee',
        style: aiseeTextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          height: 1,
          letterSpacing: -0.5,
          color: StyleTokens.textPrimary,
        ),
      ),
    );
  }
}
