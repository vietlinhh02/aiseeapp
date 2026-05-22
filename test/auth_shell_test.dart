import 'dart:async';

import 'package:aiseeapp/generated/l10n/app_localizations.dart';
import 'package:aiseeapp/models/aisee_api_models.dart';
import 'package:aiseeapp/services/aisee_auth_service.dart';
import 'package:aiseeapp/services/aisee_onboarding_store.dart';
import 'package:aiseeapp/widgets/auth_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  testWidgets('first launch shows onboarding before login UI', (
    WidgetTester tester,
  ) async {
    final _FakeOnboardingStore onboardingStore = _FakeOnboardingStore(
      hasCompletedAppOnboardingValue: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AuthShell(
          authService: _FakeAuthService(),
          onboardingStore: onboardingStore,
          enableGoogleBootstrap: false,
          readCachedProfile: () async => null,
          readStoredSession: () async => null,
          buildAppOnboardingScreen: (void Function(String role) onCompleted) =>
              ElevatedButton(
                key: const ValueKey<String>('app-onboarding-ui'),
                onPressed: () => onCompleted('user'),
                child: const Text('Hoan tat onboarding'),
              ),
          buildLoginScreen: (_, _) =>
              const Placeholder(key: ValueKey<String>('login-ui')),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(
      find.byKey(const ValueKey<String>('app-onboarding-ui')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey<String>('login-ui')), findsNothing);
  });

  testWidgets('completing onboarding stores role and reveals login UI', (
    WidgetTester tester,
  ) async {
    final _FakeOnboardingStore onboardingStore = _FakeOnboardingStore(
      hasCompletedAppOnboardingValue: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AuthShell(
          authService: _FakeAuthService(),
          onboardingStore: onboardingStore,
          enableGoogleBootstrap: false,
          readCachedProfile: () async => null,
          readStoredSession: () async => null,
          buildAppOnboardingScreen: (void Function(String role) onCompleted) =>
              ElevatedButton(
                key: const ValueKey<String>('app-onboarding-ui'),
                onPressed: () => onCompleted('user'),
                child: const Text('Hoan tat onboarding'),
              ),
          buildLoginScreen: (_, _) =>
              const Placeholder(key: ValueKey<String>('login-ui')),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.byKey(const ValueKey<String>('app-onboarding-ui')));
    await tester.pump();

    expect(find.byKey(const ValueKey<String>('login-ui')), findsOneWidget);
    expect(onboardingStore.completedRoles, contains('user'));
    expect(onboardingStore.selectedRole, 'user');
  });

  testWidgets(
    'completed onboarding skips directly to login without role prompt',
    (WidgetTester tester) async {
      final _FakeOnboardingStore onboardingStore = _FakeOnboardingStore(
        hasCompletedAppOnboardingValue: true,
        selectedRole: 'user',
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AuthShell(
            authService: _FakeAuthService(),
            onboardingStore: onboardingStore,
            enableGoogleBootstrap: false,
            readCachedProfile: () async => null,
            readStoredSession: () async => null,
            buildAppOnboardingScreen:
                (void Function(String role) onCompleted) => ElevatedButton(
                  key: const ValueKey<String>('app-onboarding-ui'),
                  onPressed: () => onCompleted('user'),
                  child: const Text('Hoan tat onboarding'),
                ),
            buildLoginScreen: (_, _) =>
                const Placeholder(key: ValueKey<String>('login-ui')),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byKey(const ValueKey<String>('login-ui')), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('app-onboarding-ui')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'cached session enters home immediately while backend revalidates in background',
    (WidgetTester tester) async {
      final Completer<({AiseeUserProfile profile, AiseeAuthTokens tokens})?>
      resumeCompleter =
          Completer<({AiseeUserProfile profile, AiseeAuthTokens tokens})?>();

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AuthShell(
            authService: _ResumingAuthService(resumeCompleter),
            enableGoogleBootstrap: false,
            onboardingStore: _FakeOnboardingStore(
              hasCompletedAppOnboardingValue: true,
              selectedRole: 'user',
            ),
            readCachedProfile: () async => const AiseeUserProfile(
              id: 'u1',
              email: 'u1@example.com',
              role: 'user',
              displayName: 'User One',
            ),
            readStoredSession: () async => const AiseeAuthTokens(
              accessToken: 'cached-access',
              refreshToken: 'cached-refresh',
            ),
            buildPermissionGate: (Widget child, VoidCallback onCompleted) =>
                const Placeholder(key: ValueKey<String>('home-ui')),
            activateAuthenticatedSession: (_, _) async {},
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const ValueKey<String>('home-ui')), findsOneWidget);

      resumeCompleter.complete((
        profile: const AiseeUserProfile(
          id: 'u1',
          email: 'u1@example.com',
          role: 'user',
          displayName: 'User One',
        ),
        tokens: const AiseeAuthTokens(
          accessToken: 'fresh-access',
          refreshToken: 'fresh-refresh',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey<String>('home-ui')), findsOneWidget);
    },
  );
}

class _FakeAuthService extends AiseeAuthService {
  _FakeAuthService() : super(httpClient: _NoopClient());
}

class _ResumingAuthService extends AiseeAuthService {
  _ResumingAuthService(this.resumeCompleter) : super(httpClient: _NoopClient());

  final Completer<({AiseeUserProfile profile, AiseeAuthTokens tokens})?>
  resumeCompleter;

  @override
  Future<({AiseeUserProfile profile, AiseeAuthTokens tokens})?> resumeSession(
    AiseeAuthTokens initial,
  ) {
    return resumeCompleter.future;
  }
}

class _FakeOnboardingStore extends AiseeOnboardingStore {
  _FakeOnboardingStore({
    required bool hasCompletedAppOnboardingValue,
    this.selectedRole,
  }) : _hasCompletedAppOnboardingValue = hasCompletedAppOnboardingValue;

  bool _hasCompletedAppOnboardingValue;
  String? selectedRole;
  final List<String> completedRoles = <String>[];

  @override
  Future<bool> hasCompletedAppOnboarding() async {
    return _hasCompletedAppOnboardingValue;
  }

  @override
  Future<String?> readSelectedRole() async {
    return selectedRole;
  }

  @override
  Future<void> completeAppOnboarding({required String role}) async {
    _hasCompletedAppOnboardingValue = true;
    selectedRole = role;
    completedRoles.add(role);
  }
}

class _NoopClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw UnimplementedError('HTTP should not be used in this test');
  }
}
