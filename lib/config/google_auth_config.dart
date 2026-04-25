import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'app_env.dart';

@immutable
class GoogleSignInInitConfig {
  const GoogleSignInInitConfig({this.clientId, this.serverClientId});

  final String? clientId;
  final String? serverClientId;
}

/// Khởi tạo Google Sign-In theo [AppEnv].
///
/// Ghi đè khi build: `--dart-define=GOOGLE_WEB_CLIENT_ID=...` (và tương tự các key trong [AppEnv]).
abstract final class GoogleAuthConfig {
  @visibleForTesting
  static GoogleSignInInitConfig resolveInitConfig({
    required bool isWeb,
    required TargetPlatform platform,
    required String webId,
    required String androidId,
  }) {
    final String? normalizedWebId = webId.isNotEmpty ? webId : null;

    if (isWeb) {
      return GoogleSignInInitConfig(
        clientId: normalizedWebId,
        serverClientId: normalizedWebId,
      );
    }

    if (platform == TargetPlatform.android) {
      // google_sign_in_android only needs the web client ID as
      // serverClientId on Android. Passing an Android clientId from Dart can
      // cause debug builds to break when the local signing SHA doesn't match
      // the server-side OAuth registration.
      return GoogleSignInInitConfig(
        clientId: null,
        serverClientId: normalizedWebId,
      );
    }

    return GoogleSignInInitConfig(
      clientId: null,
      serverClientId: normalizedWebId,
    );
  }

  static Future<void> initializeGoogleSignIn() async {
    final String webId = AppEnv.googleWebClientId;
    final String androidId = AppEnv.googleClientIdAndroid;
    final GoogleSignInInitConfig config = resolveInitConfig(
      isWeb: kIsWeb,
      platform: defaultTargetPlatform,
      webId: webId,
      androidId: androidId,
    );

    await GoogleSignIn.instance.initialize(
      clientId: config.clientId,
      serverClientId: config.serverClientId,
    );
  }
}
