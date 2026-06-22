import 'dart:async';

import 'package:aiseeapp/models/aisee_api_models.dart';
import 'package:aiseeapp/services/aisee_auth_service.dart';
import 'package:aiseeapp/services/aisee_session_store.dart';
import 'package:aiseeapp/services/aisee_token_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  test(
    'returns latest stored tokens when another refresh rotated first',
    () async {
      const AiseeAuthTokens staleTokens = AiseeAuthTokens(
        accessToken: 'old-access',
        refreshToken: 'old-refresh',
      );
      const AiseeAuthTokens rotatedTokens = AiseeAuthTokens(
        accessToken: 'new-access',
        refreshToken: 'new-refresh',
      );
      await AiseeSessionStore.instance.write(staleTokens);
      final _FailingRefreshAuthService authService = _FailingRefreshAuthService(
        concurrentlyRotatedTokens: rotatedTokens,
      );
      final AiseeTokenProvider provider = AiseeTokenProvider(
        authService: authService,
      );

      final AiseeAuthTokens? tokens = await provider.tokens(forceRefresh: true);

      expect(authService.refreshCalls, 1);
      expect(authService.receivedRefreshToken, 'old-refresh');
      expect(tokens?.accessToken, 'new-access');
      expect(tokens?.refreshToken, 'new-refresh');
    },
  );

  test('keeps invalid refresh failures when storage did not rotate', () async {
    const AiseeAuthTokens staleTokens = AiseeAuthTokens(
      accessToken: 'old-access',
      refreshToken: 'old-refresh',
    );
    await AiseeSessionStore.instance.write(staleTokens);
    final _FailingRefreshAuthService authService = _FailingRefreshAuthService();
    final AiseeTokenProvider provider = AiseeTokenProvider(
      authService: authService,
    );

    await expectLater(
      provider.tokens(forceRefresh: true),
      throwsA(isA<AiseeApiException>()),
    );
    expect(authService.refreshCalls, 1);
  });

  test('deduplicates simultaneous refresh requests', () async {
    const AiseeAuthTokens staleTokens = AiseeAuthTokens(
      accessToken: 'old-access',
      refreshToken: 'old-refresh',
    );
    const AiseeAuthTokens rotatedTokens = AiseeAuthTokens(
      accessToken: 'new-access',
      refreshToken: 'new-refresh',
    );
    await AiseeSessionStore.instance.write(staleTokens);
    final _DelayedRefreshAuthService authService = _DelayedRefreshAuthService(
      rotatedTokens,
    );
    final AiseeTokenProvider provider = AiseeTokenProvider(
      authService: authService,
    );

    final Future<AiseeAuthTokens?> first = provider.tokens(forceRefresh: true);
    final Future<AiseeAuthTokens?> second = provider.tokens(forceRefresh: true);
    await Future<void>.delayed(Duration.zero);

    expect(authService.refreshCalls, 1);
    authService.complete();

    final List<AiseeAuthTokens?> tokens = await Future.wait(
      <Future<AiseeAuthTokens?>>[first, second],
    );
    expect(tokens[0]?.refreshToken, 'new-refresh');
    expect(tokens[1]?.refreshToken, 'new-refresh');
    expect(authService.refreshCalls, 1);
  });

  test('withAccessToken refreshes when API reports unauthorized', () async {
    const AiseeAuthTokens staleTokens = AiseeAuthTokens(
      accessToken: 'old-access',
      refreshToken: 'old-refresh',
    );
    const AiseeAuthTokens rotatedTokens = AiseeAuthTokens(
      accessToken: 'new-access',
      refreshToken: 'new-refresh',
    );
    await AiseeSessionStore.instance.write(staleTokens);
    final _SuccessfulRefreshAuthService authService =
        _SuccessfulRefreshAuthService(rotatedTokens);
    final AiseeTokenProvider provider = AiseeTokenProvider(
      authService: authService,
    );
    int actionCalls = 0;

    final String? result = await provider.withAccessToken((String accessToken) {
      actionCalls += 1;
      if (accessToken == 'old-access') {
        throw AiseeApiException('unauthorized');
      }
      return Future<String>.value('ok:$accessToken');
    });

    expect(result, 'ok:new-access');
    expect(actionCalls, 2);
    expect(authService.refreshCalls, 1);
  });
}

class _FailingRefreshAuthService implements AiseeAuthService {
  _FailingRefreshAuthService({this.concurrentlyRotatedTokens});

  final AiseeAuthTokens? concurrentlyRotatedTokens;
  int refreshCalls = 0;
  String? receivedRefreshToken;

  @override
  Future<AiseeAuthTokens> refreshTokens(String refreshToken) async {
    refreshCalls += 1;
    receivedRefreshToken = refreshToken;
    final AiseeAuthTokens? tokens = concurrentlyRotatedTokens;
    if (tokens != null) {
      await AiseeSessionStore.instance.write(tokens);
    }
    throw AiseeApiException('invalid refresh session', code: 'invalid_token');
  }

  @override
  void close() {}

  @override
  Future<AiseeUserProfile> fetchCurrentUser(String accessToken) {
    throw UnimplementedError();
  }

  @override
  Future<({AiseeUserProfile profile, AiseeAuthTokens tokens})?> resumeSession(
    AiseeAuthTokens initial,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<AiseeAuthTokens> signInWithGoogle(
    String idToken, {
    String role = 'user',
  }) {
    throw UnimplementedError();
  }
}

class _DelayedRefreshAuthService extends _FailingRefreshAuthService {
  _DelayedRefreshAuthService(this.rotatedTokens);

  final AiseeAuthTokens rotatedTokens;
  final Completer<AiseeAuthTokens> _completer = Completer<AiseeAuthTokens>();

  @override
  Future<AiseeAuthTokens> refreshTokens(String refreshToken) async {
    refreshCalls += 1;
    receivedRefreshToken = refreshToken;
    return _completer.future;
  }

  void complete() {
    _completer.complete(rotatedTokens);
  }
}

class _SuccessfulRefreshAuthService extends _FailingRefreshAuthService {
  _SuccessfulRefreshAuthService(this.rotatedTokens);

  final AiseeAuthTokens rotatedTokens;

  @override
  Future<AiseeAuthTokens> refreshTokens(String refreshToken) async {
    refreshCalls += 1;
    receivedRefreshToken = refreshToken;
    return rotatedTokens;
  }
}
