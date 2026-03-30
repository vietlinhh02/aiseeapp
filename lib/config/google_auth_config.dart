import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'app_env.dart';

/// Khởi tạo Google Sign-In theo [AppEnv].
///
/// Ghi đè khi build: `--dart-define=GOOGLE_WEB_CLIENT_ID=...` (và tương tự các key trong [AppEnv]).
abstract final class GoogleAuthConfig {
  static Future<void> initializeGoogleSignIn() async {
    final String webId = AppEnv.googleWebClientId;
    final String androidId = AppEnv.googleClientIdAndroid;

    if (kIsWeb) {
      await GoogleSignIn.instance.initialize(
        clientId: webId.isNotEmpty ? webId : null,
        serverClientId: webId.isNotEmpty ? webId : null,
      );
      return;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      await GoogleSignIn.instance.initialize(
        clientId: androidId.isNotEmpty ? androidId : null,
        serverClientId: webId.isNotEmpty ? webId : null,
      );
      return;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      await GoogleSignIn.instance.initialize(
        clientId: null,
        serverClientId: webId.isNotEmpty ? webId : null,
      );
      return;
    }
    await GoogleSignIn.instance.initialize(
      clientId: null,
      serverClientId: webId.isNotEmpty ? webId : null,
    );
  }
}
