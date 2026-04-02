import 'dart:async';
import 'dart:developer' as developer;

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/google_auth_config.dart';
import '../models/aisee_api_models.dart';
import '../theme/style_tokens.dart';
import '../screens/family_home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/role_selection_screen.dart';
import '../screens/user_home_screen.dart';
import '../services/aisee_auth_service.dart';
import '../services/aisee_chat_socket.dart';
import '../services/aisee_push_service.dart';
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
    this.buildLoginScreen,
  });

  final AiseeAuthService? authService;
  final bool enableGoogleBootstrap;
  final Future<AiseeUserProfile?> Function()? readCachedProfile;
  final Future<AiseeAuthTokens?> Function()? readStoredSession;
  final Future<void> Function()? clearStoredSession;
  final Future<void> Function()? clearCachedProfile;
  final Widget Function(
    VoidCallback onSignInWillStart,
    VoidCallback onSignInWithGoogle,
  )?
  buildLoginScreen;

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
  late final bool _ownsAuthService;
  AiseeUserProfile? _aiseeProfile;
  bool _profileLoading = false;
  String? _profileError;

  StreamSubscription<GoogleSignInAuthenticationEvent>? _authSub;
  String? _lastUiRouteLog;
  String? _lastHomeForRoleLog;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _aiseeAuth = widget.authService ?? AiseeAuthService();
    _ownsAuthService = widget.authService == null;
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
    } else if (state == AppLifecycleState.paused) {
      _chatSocket.disconnect();
      _authLog('ChatSocket disconnected (app paused)');
    }
  }

  Future<void> _connectChatSocketIfNeeded() async {
    if (_chatSocket.isConnected) return;
    final AiseeAuthTokens? tokens =
        await AiseeSessionStore.instance.read();
    if (tokens != null) {
      await _chatSocket.connect(tokens.accessToken);
      _authLog('ChatSocket connected');
    }
  }

  Future<void> _clearSessionAndRouteToLogin({
    bool showExpiredToast = false,
  }) async {
    await _clearStoredSession();
    await _clearCachedProfile();
    unawaited(_chatSocket.disconnect());
    if (!mounted) return;
    setState(() {
      _aiseeProfile = null;
      _profileLoading = false;
      _profileError = null;
    });
    if (showExpiredToast) {
      unawaited(
        AppToast.show('Phiên hết hạn, vui lòng đăng nhập lại', isError: true),
      );
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
      final AiseeUserProfile? cachedProfile = await _readCachedProfile();
      if (mounted) {
        setState(() {
          _bootstrapDetail = _bootstrapHintFromProfile(cachedProfile);
        });
      }
      await _restoreStoredSession(cachedProfile);
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
    await AiseeSessionStore.instance.write(resumed.tokens);
    await AiseeProfileCache.instance.write(resumed.profile);
    await AiseePushService.instance.initAndUploadToken(
      resumed.tokens.accessToken,
    );
    unawaited(_chatSocket.connect(resumed.tokens.accessToken));
    if (!mounted) return;
    setState(() {
      _aiseeProfile = resumed.profile;
      _profileLoading = false;
      _profileError = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AiseePushService.instance.flushPendingCallNavigation();
      unawaited(AiseePushService.instance.syncActiveAcceptedCall());
    });
  }

  /// Đồng bộ JWT + profile với máy chủ sau khi đã vào app từ cache cục bộ.
  Future<void> _revalidateSessionInBackground() async {
    final AiseeAuthTokens? current = await AiseeSessionStore.instance.read();
    if (current == null || !mounted) {
      return;
    }
    final ({AiseeUserProfile profile, AiseeAuthTokens tokens})? resumed =
        await _aiseeAuth.resumeSession(current);
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

  Future<void> _restoreStoredSession(AiseeUserProfile? cachedProfile) async {
    final AiseeAuthTokens? stored = await _readStoredSession();
    if (stored == null) {
      return;
    }
    if (cachedProfile != null) {
      _authLog(
        'restoreSession: vào app từ cache userId=${cachedProfile.id} '
        '— đồng bộ máy chủ sau',
      );
      await AiseePushService.instance.initAndUploadToken(stored.accessToken);
      unawaited(_chatSocket.connect(stored.accessToken));
      if (!mounted) {
        return;
      }
      setState(() {
        _aiseeProfile = cachedProfile;
        _profileLoading = false;
        _profileError = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        AiseePushService.instance.flushPendingCallNavigation();
        unawaited(AiseePushService.instance.syncActiveAcceptedCall());
      });
      unawaited(_revalidateSessionInBackground());
      return;
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
            unawaited(AppToast.show('Đăng nhập thành công', isError: false));
          }
          return;
        }
        _authLog(
          'googleSignIn: chờ chọn role user=${user.id} email=${user.email}',
        );
        setState(() {
          _user = user;
          _profileLoading = false;
          _profileError = null;
          _aiseeProfile = null;
        });
        if (_toastAfterSignIn) {
          _toastAfterSignIn = false;
          unawaited(AppToast.show('Đã kết nối Google', isError: false));
        }
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
        if (showOutToast) {
          unawaited(AppToast.show('Đã đăng xuất', isError: false));
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
      const String err = 'Không lấy được mã xác thực từ Google.';
      setState(() {
        _profileLoading = false;
        _profileError = err;
      });
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
      await AiseeSessionStore.instance.write(tokens);
      await AiseeProfileCache.instance.write(profile);
      await AiseePushService.instance.initAndUploadToken(tokens.accessToken);
      _authLog(
        'completeSignIn: GET /users/me xong — gửi role="$role" '
        '→ API profile.role="${profile.role ?? "null"}" '
        '→ home=${profile.role == "user" ? "UserHomeScreen" : "FamilyHomeScreen"}',
      );
      setState(() {
        _aiseeProfile = profile;
        _profileLoading = false;
        _profileError = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        AiseePushService.instance.flushPendingCallNavigation();
        unawaited(AiseePushService.instance.syncActiveAcceptedCall());
      });
      unawaited(AppToast.show('Đăng nhập thành công', isError: false));
    } catch (e) {
      if (!mounted || _user?.id != accountId) return;
      final String msg = e is AiseeApiException ? e.message : e.toString();
      _authLog('completeSignIn: lỗi role="$role" → $msg');
      setState(() {
        _profileLoading = false;
        _profileError = msg;
        _aiseeProfile = null;
      });
      unawaited(AppToast.show(msg, isError: true));
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
    if (error is GoogleSignInException &&
        error.code == GoogleSignInExceptionCode.canceled) {
      return;
    }
    final String msg = error is GoogleSignInException
        ? _messageFromGoogleSignInException(error)
        : error.toString();
    unawaited(AppToast.show(msg, isError: true));
  }

  void _onSignInWillStart() {
    _toastAfterSignIn = true;
  }

  Future<void> _signInWithGoogle() async {
    try {
      await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      _toastAfterSignIn = false;
      if (e.code == GoogleSignInExceptionCode.canceled) return;
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
              'Không khởi tạo được Google Sign-In:\n$_bootstrapError',
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
    final bool showLogin =
        _user == null && !hasBackendSession && !_profileLoading;
    final bool showBackendLoading =
        _user != null && !hasBackendSession && _profileLoading;
    final bool showRolePicker =
        _user != null && !hasBackendSession && !_profileLoading;

    final String routeSnap =
        'login=$showLogin rolePicker=$showRolePicker '
        'backendLoading=$showBackendLoading '
        'hasProfile=$hasBackendSession profile.role=${_aiseeProfile?.role ?? "—"}';
    if (routeSnap != _lastUiRouteLog) {
      _lastUiRouteLog = routeSnap;
      _authLog('uiRoute: $routeSnap');
    }

    final Widget child = showLogin
        ? (widget.buildLoginScreen?.call(
                _onSignInWillStart,
                _signInWithGoogle,
              ) ??
              LoginScreen(
                onSignInWillStart: _onSignInWillStart,
                onSignInWithGoogle: _signInWithGoogle,
              ))
        : showBackendLoading
        ? const AuthBootstrapping(
            title: 'Đang đăng nhập AiSee…',
            detail: 'Đang xác thực với máy chủ',
          )
        : showRolePicker
        ? RoleSelectionScreen(
            googleUser: _user!,
            onSelectRole: (String role) {
              unawaited(_completeSignInWithRole(role));
            },
            onSignOut: _signOut,
          )
        : PermissionBootstrapGate(
            child: _homeForRole(
              googleUser: _user,
              aiseeProfile: _aiseeProfile,
              aiseeLoading: _profileLoading,
              aiseeError: _profileError,
            ),
          );

    final bool loggedIn = !showLogin;

    return SizedBox.expand(
      child: ClipRect(
        child: PageTransitionSwitcher(
          duration: const Duration(milliseconds: 520),
          reverse: !loggedIn,
          transitionBuilder:
              (
                Widget child,
                Animation<double> primaryAnimation,
                Animation<double> secondaryAnimation,
              ) {
                return SharedAxisTransition(
                  animation: primaryAnimation,
                  secondaryAnimation: secondaryAnimation,
                  transitionType: SharedAxisTransitionType.horizontal,
                  fillColor: StyleTokens.background,
                  child: child,
                );
              },
          child: KeyedSubtree(
            key: ValueKey<String>(
              showLogin
                  ? 'login'
                  : showRolePicker
                  ? 'role'
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
  return switch (e.code) {
    GoogleSignInExceptionCode.canceled => 'Đã hủy đăng nhập',
    _ => 'Lỗi Google: ${e.description ?? e.code.name}',
  };
}
