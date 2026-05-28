import 'package:flutter/material.dart';

import '../theme/aisee_typography.dart';

class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Đang tải...',
        style: aiseeTextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: color ?? const Color(0xFF999999),
        ),
      ),
    );
  }
}
