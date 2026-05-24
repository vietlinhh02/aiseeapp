import 'package:flutter/material.dart';
import 'package:aiseeapp/theme/aisee_typography.dart';

import '../theme/style_tokens.dart';

Widget familyDashboardSectionTitle(String text) => Padding(
  padding: const EdgeInsets.only(bottom: 8),
  child: Text(
    text,
    style: aiseeTextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: StyleTokens.textPrimary,
    ),
  ),
);

Widget familyDashboardEmptyCard(String text) => Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: StyleTokens.surfaceCard,
    borderRadius: BorderRadius.circular(16),
  ),
  child: Center(child: Text(text, style: StyleTokens.bodySmall())),
);
