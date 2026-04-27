import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Cấu hình: ưu tiên `--dart-define=KEY=value`, sau đó [assets/app_config.env] (flutter_dotenv).
abstract final class AppEnv {
  static const String _backendDefine = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: '',
  );
  static const String _liveKitDefine = String.fromEnvironment(
    'LIVEKIT_URL',
    defaultValue: '',
  );
  static const String _mapboxTokenDefine = String.fromEnvironment(
    'MAPBOX_ACCESS_TOKEN',
    defaultValue: '',
  );
  static const String _revenueCatApiKeyDefine = String.fromEnvironment(
    'REVENUECAT_API_KEY',
    defaultValue: '',
  );
  static const String _defaultBackendUrl = 'http://192.168.1.10:8081';

  /// OAuth Web Client ID — dùng cho web, `serverClientId` Android/iOS (aud `id_token` khớp backend).
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '426558011849-rgvtpskfhennhjg5p5r3knu9hau436c8.apps.googleusercontent.com',
  );

  /// OAuth Android Client ID — truyền `clientId` khi chạy trên Android.
  static const String googleClientIdAndroid = String.fromEnvironment(
    'GOOGLE_CLIENT_ID_ANDROID',
    defaultValue:
        '426558011849-cf6t820harsi5hb16pqsi4r14djje5df.apps.googleusercontent.com',
  );

  static String _dotenv(String key) {
    if (!dotenv.isInitialized) {
      return '';
    }
    return dotenv.maybeGet(key, fallback: '')?.trim() ?? '';
  }

  static String get apiBaseUrl {
    String u = _backendDefine.trim();
    if (u.isEmpty) {
      u = _dotenv('BACKEND_URL');
    }
    if (u.isEmpty) {
      u = _defaultBackendUrl;
    }
    return u.endsWith('/') ? u.substring(0, u.length - 1) : u;
  }

  static String get liveKitWsUrl {
    String u = _liveKitDefine.trim();
    if (u.isEmpty) {
      u = _dotenv('LIVEKIT_URL');
    }
    return u.endsWith('/') ? u.substring(0, u.length - 1) : u;
  }

  /// Token công khai Mapbox (pk.*) — dùng Static Images / SDK; giới hạn URL trong Mapbox Dashboard.
  static String get mapboxAccessToken {
    String t = _mapboxTokenDefine.trim();
    if (t.isEmpty) {
      t = _dotenv('MAPBOX_ACCESS_TOKEN');
    }
    return t;
  }

  static String get revenueCatApiKey {
    String key = _revenueCatApiKeyDefine.trim();
    if (key.isEmpty) {
      key = _dotenv('REVENUECAT_API_KEY');
    }
    return key;
  }
}
