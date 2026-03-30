import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/aisee_api_models.dart';

/// Lưu JWT AiSee trên thiết bị (Keychain / Keystore / web localStorage).
class AiseeSessionStore {
  AiseeSessionStore._();
  static final AiseeSessionStore instance = AiseeSessionStore._();

  static const String _kAccess = 'aisee_access_token';
  static const String _kRefresh = 'aisee_refresh_token';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> write(AiseeAuthTokens tokens) async {
    await _storage.write(key: _kAccess, value: tokens.accessToken);
    await _storage.write(key: _kRefresh, value: tokens.refreshToken);
  }

  Future<AiseeAuthTokens?> read() async {
    final String? access = await _storage.read(key: _kAccess);
    final String? refresh = await _storage.read(key: _kRefresh);
    if (access == null ||
        access.isEmpty ||
        refresh == null ||
        refresh.isEmpty) {
      return null;
    }
    return AiseeAuthTokens(accessToken: access, refreshToken: refresh);
  }

  Future<void> clear() async {
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
  }
}
