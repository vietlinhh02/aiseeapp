import 'package:aiseeapp/models/aisee_api_models.dart';
import 'package:aiseeapp/services/aisee_auth_service.dart';
import 'package:aiseeapp/widgets/auth_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  testWidgets('invalid stored session returns user to login UI', (
    WidgetTester tester,
  ) async {
    bool sessionCleared = false;
    bool profileCleared = false;

    await tester.pumpWidget(
      MaterialApp(
        home: AuthShell(
          authService: _FakeAuthService(),
          enableGoogleBootstrap: false,
          readCachedProfile: () async => null,
          readStoredSession: () async => const AiseeAuthTokens(
            accessToken: 'expired-access',
            refreshToken: 'expired-refresh',
          ),
          clearStoredSession: () async {
            sessionCleared = true;
          },
          clearCachedProfile: () async {
            profileCleared = true;
          },
          buildLoginScreen: (_, _) =>
              const Placeholder(key: ValueKey<String>('login-ui')),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byKey(const ValueKey<String>('login-ui')), findsOneWidget);
    expect(sessionCleared, isTrue);
    expect(profileCleared, isTrue);
  });
}

class _FakeAuthService extends AiseeAuthService {
  _FakeAuthService() : super(httpClient: _NoopClient());

  @override
  Future<({AiseeUserProfile profile, AiseeAuthTokens tokens})?> resumeSession(
    AiseeAuthTokens initial,
  ) async {
    return null;
  }
}

class _NoopClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw UnimplementedError('HTTP should not be used in this test');
  }
}
