import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../auth/google_sign_in_web_button_stub.dart'
    if (dart.library.js_util) '../auth/google_sign_in_web_button_web.dart';
import '../theme/style_tokens.dart';
import '../widgets/app_wordmark.dart';
import '../widgets/google_g_logo.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({
    super.key,
    required this.onSignInWillStart,
    required this.onSignInWithGoogle,
  });

  final VoidCallback onSignInWillStart;
  final VoidCallback onSignInWithGoogle;

  @override
  Widget build(BuildContext context) {
    final bool useWebButton =
        kIsWeb && !GoogleSignIn.instance.supportsAuthenticate();

    return Scaffold(
      backgroundColor: StyleTokens.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const AppWordmark(fontSize: 36),
                            const SizedBox(height: 14),
                            Text(
                              'Không chỉ nhìn thay bạn — hành động cùng bạn',
                              style: StyleTokens.bodySmall().copyWith(
                                color: StyleTokens.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                height: 1.35,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'AiSee là trợ lý AI cho người suy giảm thị lực tại Việt Nam. '
                              'Bạn chỉ cần nói — AiSee nghe, hiểu và thực hiện. '
                              'Thiết kế ưu tiên giọng nói, hỗ trợ tiếng Việt.',
                              style: StyleTokens.bodySmall(),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 28),
                            Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 320,
                                ),
                                child: useWebButton
                                    ? Listener(
                                        behavior: HitTestBehavior.translucent,
                                        onPointerDown: (_) =>
                                            onSignInWillStart(),
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            color: StyleTokens.buttonPrimary,
                                            borderRadius: BorderRadius.circular(
                                              100,
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                              horizontal: 12,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                const GoogleGLogo(size: 22),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child:
                                                      buildGoogleSignInButton(),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      )
                                    : Material(
                                        color: StyleTokens.buttonPrimary,
                                        borderRadius: BorderRadius.circular(
                                          100,
                                        ),
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(
                                            100,
                                          ),
                                          onTap: () {
                                            onSignInWillStart();
                                            onSignInWithGoogle();
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 18,
                                              horizontal: 24,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const GoogleGLogo(size: 22),
                                                const SizedBox(width: 10),
                                                Text(
                                                  'Đăng nhập bằng Google',
                                                  style:
                                                      StyleTokens.socialLabel(),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 22),
                            Text(
                              'Đăng nhập bằng Google để vào ứng dụng. '
                              'Chúng tôi dùng tài khoản Google để xác thực an toàn và đồng bộ hồ sơ của bạn.',
                              style: StyleTokens.bodySmall().copyWith(
                                color: StyleTokens.textMuted,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(
                  'Bằng việc đăng nhập, bạn đồng ý với điều khoản dịch vụ của Google và AiSee.',
                  style: StyleTokens.legalMuted(),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
