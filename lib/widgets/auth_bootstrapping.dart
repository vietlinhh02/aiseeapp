import 'package:flutter/material.dart';

import '../theme/style_tokens.dart';
import 'app_wordmark.dart';

/// Màn hình trung gian khi app đang xác minh token lưu + Google (không hiện form login).
class AuthBootstrapping extends StatelessWidget {
  const AuthBootstrapping({
    super.key,
    this.title = 'Đang kiểm tra phiên đăng nhập…',
    this.detail,
  });

  final String title;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StyleTokens.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppWordmark(fontSize: 36),
                const SizedBox(height: 36),
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: StyleTokens.bodySmall(),
                  textAlign: TextAlign.center,
                ),
                if (detail case final String d when d.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    d.trim(),
                    style: StyleTokens.bodySmall().copyWith(
                      color: StyleTokens.textMuted,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
