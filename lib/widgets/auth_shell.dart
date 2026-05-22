import 'dart:async';
import 'dart:developer' as developer;

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/aisee_locale_controller.dart';
import '../config/google_auth_config.dart';
import '../generated/l10n/app_localizations.dart';
import '../models/aisee_api_models.dart';
import '../theme/style_tokens.dart';
import '../screens/family_home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/user_onboarding_screen.dart';
import '../screens/user_home_screen.dart';
import '../services/aisee_auth_service.dart';
import '../services/aisee_analytics_service.dart';
import '../services/aisee_chat_socket.dart';
import '../services/aisee_family_service.dart';
import '../services/aisee_onboarding_store.dart';
import '../services/aisee_push_service.dart';
import '../services/in_app_message_controller.dart';
import '../services/aisee_revenuecat_service.dart';
import 'auth_bootstrapping.dart';
import 'permission_bootstrap_gate.dart';
import '../services/aisee_profile_cache.dart';
import '../services/aisee_session_store.dart';
import '../utils/app_toast.dart';

void _authLog(String message) {
  debugPrint('[AiSeeAuth] $message');
  developer.log(message, name: 'AiSeeAuth');
}

class AuthShell extends StatefulWidget {
  const AuthShell({
    super.key,
    this.authService,
    this.enableGoogleBootstrap = true,
    this.readCachedProfile,
    this.readStoredSession,
    this.clearStoredSession,
    this.clearCachedProfile,
    this.onboardingStore,
    this.activateAuthenticatedSession,
    this.buildLoginScreen,
    this.buildAppOnboardingScreen,
    this.buildPermissionGate,
  });

  final AiseeAuthService? authService;
  final bool enableGoogleBootstrap;
  final Future<AiseeUserProfile?> Function()? readCachedProfile;
  final Future<AiseeAuthTokens?> Function()? readStoredSession;
  final Future<void> Function()? clearStoredSession;
  final Future<void> Function()? clearCachedProfile;
  final AiseeOnboardingStore? onboardingStore;
  final Future<void> Function(AiseeUserProfile profile, AiseeAuthTokens tokens)?
  activateAuthenticatedSession;
  final Widget Function(
    VoidCallback onSignInWillStart,
    VoidCallback onSignInWithGoogle,
  )?
  buildLoginScreen;
  final Widget Function(void Function(String role) onCompleted)?
  buildAppOnboardingScreen;
  final Widget Function(Widget child, VoidCallback onCompleted)?
  buildPermissionGate;

  @override
  State<AuthShell> createState() => _AuthShellState();
}

class _AuthShellState extends State<AuthShell> with WidgetsBindingObserver {
  bool _initializing = true;
  String? _bootstrapError;
  GoogleSignInAccount? _user;
  bool _toastAfterSignIn = false;
  bool _toastAfterSignOut = false;
  String? _bootstrapDetail;

  final AiseeChatSocket _chatSocket = AiseeChatSocket();
  late final AiseeAuthService _aiseeAuth;
  late final AiseeOnboardingStore _onboardingStore;
  late final bool _ownsAuthService;
  AiseeUserProfile? _aiseeProfile;
  bool _profileLoading = false;
  String? _profileError;
  bool _appOnboardingCompleted = false;
  String? _selectedRole;

  StreamSubscription<GoogleSignInAuthenticationEvent>? _authSub;
  String? _lastUiRouteLog;
  String? _lastHomeForRoleLog;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _aiseeAuth = widget.authService ?? AiseeAuthService();
    _onboardingStore = widget.onboardingStore ?? AiseeOnboardingStore.instance;
    _ownsAuthService = widget.authService == null;
    _chatSocket.tokenProvider = () async {
      final AiseeAuthTokens? tokens = await AiseeSessionStore.instance.read();
      return tokens?.accessToken;
    };
    _chatSocket.refreshTokenProvider = () async {
      final AiseeAuthTokens? tokens = await AiseeSessionStore.instance.read();
      if (tokens == null) return null;
      try {
        final AiseeAuthTokens rotated = await _aiseeAuth.refreshTokens(
          tokens.refreshToken,
        );
        await AiseeSessionStore.instance.write(rotated);
        return rotated.accessToken;
      } catch (_) {
        return null;
      }
    };
    unawaited(_bootstrap());
  }

  Future<AiseeUserProfile?> _readCachedProfile() {
    return widget.readCachedProfile?.call() ??
        AiseeProfileCache.instance.read();
  }

  Future<AiseeAuthTokens?> _readStoredSession() {
    return widget.readStoredSession?.call() ??
        AiseeSessionStore.instance.read();
  }

  Future<void> _clearStoredSession() {
    return widget.clearStoredSession?.call() ??
        AiseeSessionStore.instance.clear();
  }

  Future<void> _clearCachedProfile() {
    return widget.clearCachedProfile?.call() ??
        AiseeProfileCache.instance.clear();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_aiseeProfile == null) return;
    if (state == AppLifecycleState.resumed) {
      _connectChatSocketIfNeeded();
    }
  }

  Future<void> _connectChatSocketIfNeeded() async {
    if (_chatSocket.isConnected) return;
    final AiseeAuthTokens? tokens = await AiseeSessionStore.instance.read();
    if (tokens != null) {
      await _chatSocket.connect(tokens.accessToken);
      unawaited(_primeMessageContacts(tokens.accessToken));
      _authLog('ChatSocket connected');
    }
  }

  Future<void> _primeMessageContacts(String accessToken) async {
    final AiseeFamilyService svc = AiseeFamilyService();
    try {
      final contacts = await svc.fetchFamily(accessToken);
      AiseeInAppMessageController.instance.rememberContacts(contacts);
    } catch (e) {
      _authLog('messageContacts: preload skipped: $e');
    } finally {
      svc.close();
    }
  }

  Future<void> _clearSessionAndRouteToLogin({
    bool showExpiredToast = false,
  }) async {
    await _clearStoredSession();
    await _clearCachedProfile();
    unawaited(_chatSocket.disconnect());
    unawaited(AiseeRevenueCatService.instance.logOut());
    AiseeInAppMessageController.instance.setCurrentUserId(null);
    AiseeInAppMessageController.instance.setActiveConversation(null);
    if (!mounted) return;
    setState(() {
      _aiseeProfile = null;
      _profileLoading = false;
      _profileError = null;
    });
    if (showExpiredToast) {
      unawaited(AppToast.show(_l().authSessionExpired, isError: true));
    }
  }

  Future<void> _bootstrap() async {
    try {
      if (widget.enableGoogleBootstrap) {
        await GoogleAuthConfig.initializeGoogleSignIn();
        _authSub = GoogleSignIn.instance.authenticationEvents.listen(
          _onAuthEvent,
          onError: _onAuthError,
        );
      }
      final bool appOnboardingCompleted = await _onboardingStore
          .hasCompletedAppOnboarding();
      final String? selectedRole = await _onboardingStore.readSelectedRole();
      final AiseeUserProfile? cachedProfile = await _readCachedProfile();
      final AiseeAuthTokens? storedSession = await _readStoredSession();
      final bool canUseCachedSession =
          storedSession != null && cachedProfile != null;

      if (mounted) {
        setState(() {
          _appOnboardingCompleted = appOnboardingCompleted;
          _selectedRole = selectedRole;
          _bootstrapDetail = _bootstrapHintFromProfile(cachedProfile);
          if (canUseCachedSession) {
            _aiseeProfile = cachedProfile;
            _profileLoading = false;
            _profileError = null;
          }
        });
      }
      if (canUseCachedSession) {
        unawaited(_revalidateSessionInBackground(storedSession));
      } else {
        await _restoreStoredSession(
          cachedProfile,
          storedSession: storedSession,
        );
      }
      if (widget.enableGoogleBootstrap) {
        final Future<GoogleSignInAccount?>? lightweightFut = GoogleSignIn
            .instance
            .attemptLightweightAuthentication();
        if (lightweightFut != null) {
          unawaited(lightweightFut);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _bootstrapError = e.toString();
          _initializing = false;
        });
      }
      return;
    }
    if (mounted) {
      setState(() => _initializing = false);
    }
  }

  /// Áp dụng phiên sau khi máy chủ xác nhận (refresh token / GET /users/me).
  Future<void> _applySessionFromServer(
    ({AiseeUserProfile profile, AiseeAuthTokens tokens}) resumed,
  ) async {
    await _activateAuthenticatedSession(resumed.profile, resumed.tokens);
    final String? selectedRole = await _syncOnboardingRoleFromProfile(
      resumed.profile,
    );
    if (!mounted) return;
    setState(() {
      _aiseeProfile = resumed.profile;
      _profileLoading = false;
      _profileError = null;
      _appOnboardingCompleted = true;
      _selectedRole = selectedRole ?? _selectedRole ?? resumed.profile.role;
    });
    AiseeInAppMessageController.instance.setCurrentUserId(resumed.profile.id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AiseePushService.instance.flushPendingCallNavigation();
      unawaited(AiseePushService.instance.syncActiveAcceptedCall());
    });
  }

  Future<void> _restoreStoredSession(
    AiseeUserProfile? cachedProfile, {
    AiseeAuthTokens? storedSession,
  }) async {
    final AiseeAuthTokens? stored = storedSession ?? await _readStoredSession();
    if (stored == null) {
      return;
    }
    if (cachedProfile != null) {
      _authLog(
        'restoreSession: có cache userId=${cachedProfile.id} '
        '— chờ máy chủ xác nhận trước khi vào home',
      );
    }
    final ({AiseeUserProfile profile, AiseeAuthTokens tokens})? resumed =
        await _aiseeAuth.resumeSession(stored);
    if (!mounted) {
      return;
    }
    if (resumed == null) {
      _authLog('restoreSession: refresh failed, về login');
      await _clearSessionAndRouteToLogin();
      return;
    }
    _authLog(
      'restoreSession: ok userId=${resumed.profile.id} '
      'role=${resumed.profile.role ?? "null"}',
    );
    await _applySessionFromServer(resumed);
  }

  Future<void> _revalidateSessionInBackground(AiseeAuthTokens current) async {
    final AiseeAuthTokens? latest = await _readStoredSession();
    final AiseeAuthTokens tokens = latest ?? current;
    final ({AiseeUserProfile profile, AiseeAuthTokens tokens})? resumed =
        await _aiseeAuth.resumeSession(tokens);
    if (!mounted) {
      return;
    }
    if (resumed == null) {
      _authLog('syncSession(nền): refresh failed, về login');
      await _clearSessionAndRouteToLogin(showExpiredToast: true);
      return;
    }
    _authLog(
      'syncSession(nền): ok userId=${resumed.profile.id} '
      'role=${resumed.profile.role ?? "null"}',
    );
    await _applySessionFromServer(resumed);
  }

  void _onAuthEvent(GoogleSignInAuthenticationEvent event) {
    if (!mounted) return;
    switch (event) {
      case GoogleSignInAuthenticationEventSignIn(:final user):
        if (_aiseeProfile != null) {
          _authLog(
            'googleSignIn: đã có phiên backend, gắn Google user=${user.id} '
            'giữ role=${_aiseeProfile!.role ?? "null"}',
          );
          setState(() => _user = user);
          if (_toastAfterSignIn) {
            _toastAfterSignIn = false;
            unawaited(AppToast.show(_l().authSignInSuccess, isError: false));
          }
          return;
        }
        final String? role = _selectedRole;
        if (role == null || role.isEmpty) {
          _authLog('googleSignIn: thiếu role đã lưu, quay lại onboarding');
          setState(() {
            _user = null;
            _aiseeProfile = null;
            _profileLoading = false;
            _profileError = null;
            _appOnboardingCompleted = false;
          });
          AiseeInAppMessageController.instance.setCurrentUserId(null);
          AiseeInAppMessageController.instance.setActiveConversation(null);
          unawaited(GoogleSignIn.instance.signOut());
          return;
        }
        _authLog('googleSignIn: dùng role đã lưu="$role" user=${user.id}');
        setState(() {
          _user = user;
          _profileLoading = true;
          _profileError = null;
          _aiseeProfile = null;
        });
        AiseeInAppMessageController.instance.setCurrentUserId(null);
        AiseeInAppMessageController.instance.setActiveConversation(null);
        unawaited(_completeSignInWithRole(role));
      case GoogleSignInAuthenticationEventSignOut():
        _authLog('googleSignOut');
        final bool showOutToast = _toastAfterSignOut;
        _toastAfterSignOut = false;
        unawaited(AiseeSessionStore.instance.clear());
        unawaited(AiseeProfileCache.instance.clear());
        setState(() {
          _aiseeProfile = null;
          _profileLoading = false;
          _profileError = null;
          _user = null;
        });
        AiseeInAppMessageController.instance.setCurrentUserId(null);
        AiseeInAppMessageController.instance.setActiveConversation(null);
        if (showOutToast) {
          unawaited(AppToast.show(_l().authSignedOut, isError: false));
        }
    }
  }

  Future<void> _completeSignInWithRole(String role) async {
    final GoogleSignInAccount? account = _user;
    if (account == null) return;
    final String accountId = account.id;
    _authLog('completeSignIn: POST /auth/google role="$role"');
    setState(() {
      _profileLoading = true;
      _profileError = null;
    });
    final String? idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      if (!mounted) return;
      final String err = _l().authNoIdToken;
      setState(() {
        _user = null;
        _profileLoading = false;
        _profileError = err;
      });
      _toastAfterSignIn = false;
      unawaited(AppToast.show(err, isError: true));
      return;
    }

    try {
      final AiseeAuthTokens tokens = await _aiseeAuth.signInWithGoogle(
        idToken,
        role: role,
      );
      if (!mounted || _user?.id != accountId) return;
      final AiseeUserProfile profile = await _aiseeAuth.fetchCurrentUser(
        tokens.accessToken,
      );
      if (!mounted || _user?.id != accountId) return;
      await _activateAuthenticatedSession(profile, tokens);
      final String? selectedRole = await _syncOnboardingRoleFromProfile(
        profile,
      );
      _authLog(
        'completeSignIn: GET /users/me xong — gửi role="$role" '
        '→ API profile.role="${profile.role ?? "null"}" '
        '→ home=${profile.role == "user" ? "UserHomeScreen" : "FamilyHomeScreen"}',
      );
      setState(() {
        _aiseeProfile = profile;
        _profileLoading = false;
        _profileError = null;
        _appOnboardingCompleted = true;
        _selectedRole = selectedRole ?? _selectedRole ?? profile.role;
      });
      AiseeInAppMessageController.instance.setCurrentUserId(profile.id);
      unawaited(
        AiseeAnalyticsService.instance.track(
          AiseeAnalyticsEvent.signupCompleted,
          parameters: <String, Object?>{'role': role},
        ),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        AiseePushService.instance.flushPendingCallNavigation();
        unawaited(AiseePushService.instance.syncActiveAcceptedCall());
      });
      _toastAfterSignIn = false;
      unawaited(AppToast.show(_l().authSignInSuccess, isError: false));
    } catch (e) {
      if (!mounted || _user?.id != accountId) return;
      final String msg = e is AiseeApiException ? e.message : e.toString();
      _authLog('completeSignIn: lỗi role="$role" → $msg');
      setState(() {
        _user = null;
        _profileLoading = false;
        _profileError = msg;
        _aiseeProfile = null;
      });
      _toastAfterSignIn = false;
      AiseeInAppMessageController.instance.setCurrentUserId(null);
      AiseeInAppMessageController.instance.setActiveConversation(null);
      unawaited(AppToast.show(msg, isError: true));
    }
  }

  Future<void> _activateAuthenticatedSession(
    AiseeUserProfile profile,
    AiseeAuthTokens tokens,
  ) async {
    final Future<void> Function(AiseeUserProfile, AiseeAuthTokens)? override =
        widget.activateAuthenticatedSession;
    if (override != null) {
      await override(profile, tokens);
      return;
    }

    await AiseeSessionStore.instance.write(tokens);
    await AiseeProfileCache.instance.write(profile);
    unawaited(AiseeAnalyticsService.instance.setUser(profile));
    unawaited(AiseeRevenueCatService.instance.identify(profile));
    await AiseePushService.instance.initAndUploadToken(tokens.accessToken);
    unawaited(_chatSocket.connect(tokens.accessToken));
    unawaited(_primeMessageContacts(tokens.accessToken));
  }

  Future<String?> _syncOnboardingRoleFromProfile(
    AiseeUserProfile profile,
  ) async {
    final String? role = profile.role?.trim();
    if (role == null || role.isEmpty) {
      return _selectedRole;
    }
    if (!_appOnboardingCompleted || _selectedRole != role) {
      await _onboardingStore.completeAppOnboarding(role: role);
    }
    return role;
  }

  Future<void> _completeAppOnboarding(String role) async {
    final String normalizedRole = role.trim();
    if (normalizedRole.isEmpty) {
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _appOnboardingCompleted = true;
      _selectedRole = normalizedRole;
    });
    unawaited(_persistCompletedAppOnboarding(normalizedRole));
  }

  Future<void> _persistCompletedAppOnboarding(String role) async {
    try {
      await _onboardingStore.completeAppOnboarding(role: role);
      await AiseeAnalyticsService.instance.track(
        AiseeAnalyticsEvent.roleSelected,
        parameters: <String, Object?>{'role': role},
      );
    } catch (e) {
      _authLog('completeAppOnboarding: persist failed role="$role" → $e');
    }
  }

  void _onAuthError(Object error, StackTrace stackTrace) {
    if (!mounted) return;
    unawaited(AiseeSessionStore.instance.clear());
    unawaited(AiseeProfileCache.instance.clear());
    setState(() {
      _toastAfterSignIn = false;
      _aiseeProfile = null;
      _profileLoading = false;
      _profileError = null;
      _user = null;
    });
    AiseeInAppMessageController.instance.setCurrentUserId(null);
    AiseeInAppMessageController.instance.setActiveConversation(null);
    if (error is GoogleSignInException &&
        error.code == GoogleSignInExceptionCode.canceled) {
      _authLog(
        'googleSignIn: canceled by user or Credential Manager. '
        'Trên Android, đây cũng có thể là dấu hiệu OAuth config/SHA không khớp.',
      );
      return;
    }
    final String msg = error is GoogleSignInException
        ? _messageFromGoogleSignInException(error)
        : error.toString();
    unawaited(AppToast.show(msg, isError: true));
  }

  void _onSignInWillStart() {
    _toastAfterSignIn = true;
    unawaited(
      AiseeAnalyticsService.instance.track(AiseeAnalyticsEvent.signupStarted),
    );
  }

  Future<void> _signInWithGoogle() async {
    try {
      await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      _toastAfterSignIn = false;
      if (e.code == GoogleSignInExceptionCode.canceled) {
        _authLog(
          'googleSignIn.authenticate: canceled by user or Credential Manager. '
          'Trên Android, đây cũng có thể là dấu hiệu OAuth config/SHA không khớp.',
        );
        return;
      }
      unawaited(
        AppToast.show(_messageFromGoogleSignInException(e), isError: true),
      );
    }
  }

  Future<void> _signOut() async {
    _toastAfterSignOut = true;
    await AiseeSessionStore.instance.clear();
    await AiseeProfileCache.instance.clear();
    await GoogleSignIn.instance.signOut();
  }

  Widget _homeForRole({
    required GoogleSignInAccount? googleUser,
    required AiseeUserProfile? aiseeProfile,
    required bool aiseeLoading,
    required String? aiseeError,
  }) {
    final String? role = aiseeProfile?.role;
    final String homeKey = '${aiseeProfile?.id}|$role';
    if (homeKey != _lastHomeForRoleLog) {
      _lastHomeForRoleLog = homeKey;
      _authLog(
        '_homeForRole: raw role=${role ?? "null"} '
        '(== "user" → ${role == "user"})',
      );
    }
    if (role == 'user') {
      return UserHomeScreen(
        googleUser: googleUser,
        aiseeProfile: aiseeProfile,
        aiseeLoading: aiseeLoading,
        aiseeError: aiseeError,
        onSignOut: _signOut,
        chatSocket: _chatSocket,
      );
    }
    return FamilyHomeScreen(
      googleUser: googleUser,
      aiseeProfile: aiseeProfile,
      aiseeLoading: aiseeLoading,
      aiseeError: aiseeError,
      onSignOut: _signOut,
      chatSocket: _chatSocket,
    );
  }

  Widget _buildPermissionWrappedHome() {
    final Widget home = _homeForRole(
      googleUser: _user,
      aiseeProfile: _aiseeProfile,
      aiseeLoading: _profileLoading,
      aiseeError: _profileError,
    );
    void onCompleted() {
      final String key = _aiseeProfile?.id == null
          ? AiseeAnalyticsEvent.onboardingCompleted
          : '${AiseeAnalyticsEvent.onboardingCompleted}.${_aiseeProfile!.id}';
      unawaited(
        AiseeAnalyticsService.instance.trackOnce(
          AiseeAnalyticsEvent.onboardingCompleted,
          parameters: <String, Object?>{'role': _aiseeProfile?.role},
          key: key,
        ),
      );
    }

    return widget.buildPermissionGate?.call(home, onCompleted) ??
        PermissionBootstrapGate(onCompleted: onCompleted, child: home);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _chatSocket.dispose();
    unawaited(_authSub?.cancel());
    if (_ownsAuthService) {
      _aiseeAuth.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_bootstrapError != null) {
      return Scaffold(
        backgroundColor: StyleTokens.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _l().authBootstrapFailed(_bootstrapError!),
              style: StyleTokens.bodySmall().copyWith(
                color: StyleTokens.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (_initializing) {
      return AuthBootstrapping(detail: _bootstrapDetail);
    }

    final bool hasBackendSession = _aiseeProfile != null;
    final bool showAppOnboarding =
        !hasBackendSession && !_appOnboardingCompleted;
    final bool showLogin =
        !showAppOnboarding &&
        _user == null &&
        !hasBackendSession &&
        !_profileLoading;
    final bool showBackendLoading =
        _user != null && !hasBackendSession && _profileLoading;

    final String routeSnap =
        'appOnboarding=$showAppOnboarding login=$showLogin '
        'backendLoading=$showBackendLoading '
        'hasProfile=$hasBackendSession profile.role=${_aiseeProfile?.role ?? "—"}';
    if (routeSnap != _lastUiRouteLog) {
      _lastUiRouteLog = routeSnap;
      _authLog('uiRoute: $routeSnap');
    }

    final Widget child = showAppOnboarding
        ? (widget.buildAppOnboardingScreen?.call(
                (String role) => unawaited(_completeAppOnboarding(role)),
              ) ??
              AppOnboardingScreen(
                onCompleted: (String role) =>
                    unawaited(_completeAppOnboarding(role)),
              ))
        : showLogin
        ? (widget.buildLoginScreen?.call(
                _onSignInWillStart,
                _signInWithGoogle,
              ) ??
              LoginScreen(
                onSignInWillStart: _onSignInWillStart,
                onSignInWithGoogle: _signInWithGoogle,
              ))
        : showBackendLoading
        ? AuthBootstrapping(
            title: _l().authBootstrapTitle,
            detail: _l().authBootstrapDetail,
          )
        : _buildPermissionWrappedHome();

    return SizedBox.expand(
      child: ClipRect(
        child: PageTransitionSwitcher(
          duration: const Duration(milliseconds: 520),
          reverse: false,
          transitionBuilder:
              (
                Widget child,
                Animation<double> primaryAnimation,
                Animation<double> secondaryAnimation,
              ) {
                return FadeThroughTransition(
                  animation: primaryAnimation,
                  secondaryAnimation: secondaryAnimation,
                  fillColor: StyleTokens.background,
                  child: child,
                );
              },
          child: KeyedSubtree(
            key: ValueKey<String>(
              showLogin
                  ? 'login'
                  : showAppOnboarding
                  ? 'app_onboarding'
                  : showBackendLoading
                  ? 'loading'
                  : 'home_${_aiseeProfile?.role ?? _aiseeProfile?.id}',
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

String? _bootstrapHintFromProfile(AiseeUserProfile? profile) {
  if (profile == null) return null;
  final String name = profile.displayName?.trim() ?? '';
  if (name.isNotEmpty) return name;
  final String email = profile.email.trim();
  return email.isEmpty ? null : email;
}

String _messageFromGoogleSignInException(GoogleSignInException e) {
  final AppLocalizations l = lookupAppLocalizations(
    AiseeLocaleController.instance.value,
  );
  return switch (e.code) {
    GoogleSignInExceptionCode.canceled => l.authGoogleCanceled,
    _ => l.authGoogleError(e.description ?? e.code.name),
  };
}

AppLocalizations _l() =>
    lookupAppLocalizations(AiseeLocaleController.instance.value);
