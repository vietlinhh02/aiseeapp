import 'package:aiseeapp/config/google_auth_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android init only uses serverClientId from web OAuth client', () {
    final GoogleSignInInitConfig config = GoogleAuthConfig.resolveInitConfig(
      isWeb: false,
      platform: TargetPlatform.android,
      webId: 'web-client-id',
      androidId: 'android-client-id',
    );

    expect(config.clientId, isNull);
    expect(config.serverClientId, 'web-client-id');
  });

  test('Web init uses web OAuth client for both client identifiers', () {
    final GoogleSignInInitConfig config = GoogleAuthConfig.resolveInitConfig(
      isWeb: true,
      platform: TargetPlatform.android,
      webId: 'web-client-id',
      androidId: 'android-client-id',
    );

    expect(config.clientId, 'web-client-id');
    expect(config.serverClientId, 'web-client-id');
  });

  test('Apple platforms only use serverClientId', () {
    final GoogleSignInInitConfig config = GoogleAuthConfig.resolveInitConfig(
      isWeb: false,
      platform: TargetPlatform.iOS,
      webId: 'web-client-id',
      androidId: 'android-client-id',
    );

    expect(config.clientId, isNull);
    expect(config.serverClientId, 'web-client-id');
  });
}
