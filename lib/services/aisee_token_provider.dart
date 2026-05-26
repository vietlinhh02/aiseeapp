import '../models/aisee_api_models.dart';
import '../utils/jwt_expiry.dart';
import 'aisee_auth_service.dart';
import 'aisee_session_store.dart';

class AiseeTokenProvider {
  AiseeTokenProvider({AiseeAuthService? authService})
    : _authService = authService ?? AiseeAuthService();

  static final AiseeTokenProvider instance = AiseeTokenProvider();

  final AiseeAuthService _authService;
  Future<AiseeAuthTokens?>? _refreshInFlight;

  Future<AiseeAuthTokens?> tokens({bool forceRefresh = false}) async {
    final AiseeAuthTokens? stored = await AiseeSessionStore.instance.read();
    if (stored == null) return null;
    if (!forceRefresh && !isJwtExpiringSoon(stored.accessToken)) {
      return stored;
    }
    return _refresh(stored.refreshToken);
  }

  Future<String?> accessToken({bool forceRefresh = false}) async {
    final AiseeAuthTokens? current = await tokens(forceRefresh: forceRefresh);
    return current?.accessToken;
  }

  Future<T?> withAccessToken<T>(
    Future<T> Function(String accessToken) action,
  ) async {
    AiseeAuthTokens? current = await tokens();
    if (current == null) return null;
    try {
      return await action(current.accessToken);
    } on AiseeApiException catch (e) {
      if (!_isInvalidToken(e)) rethrow;
      current = await tokens(forceRefresh: true);
      if (current == null) return null;
      return action(current.accessToken);
    }
  }

  Future<AiseeAuthTokens?> _refresh(String refreshToken) {
    final Future<AiseeAuthTokens?>? existing = _refreshInFlight;
    if (existing != null) return existing;

    final Future<AiseeAuthTokens?> refresh = _refreshAndStore(refreshToken);
    _refreshInFlight = refresh;
    refresh.whenComplete(() => _refreshInFlight = null);
    return refresh;
  }

  Future<AiseeAuthTokens?> _refreshAndStore(String refreshToken) async {
    final AiseeAuthTokens rotated = await _authService.refreshTokens(
      refreshToken,
    );
    await AiseeSessionStore.instance.write(rotated);
    return rotated;
  }

  bool _isInvalidToken(AiseeApiException e) {
    return e.code == 'invalid_token' || e.message.contains('401');
  }
}
