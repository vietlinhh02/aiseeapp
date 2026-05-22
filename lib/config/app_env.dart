import 'package:flutter/foundation.dart';
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
  static const String _revenueCatApiKeyAndroidDefine = String.fromEnvironment(
    'REVENUECAT_API_KEY_ANDROID',
    defaultValue: '',
  );
  static const String _revenueCatApiKeyIosDefine = String.fromEnvironment(
    'REVENUECAT_API_KEY_IOS',
    defaultValue: '',
  );
  static const String _revenueCatEnabledDefine = String.fromEnvironment(
    'BILLING_REVENUECAT_ENABLED',
    defaultValue: '',
  );
  static const String _careWebBaseDefine = String.fromEnvironment(
    'CARE_WEB_BASE_URL',
    defaultValue: '',
  );
  static const String _defaultBackendUrl = 'http://192.168.1.10:8081';
  static const String _defaultCareWebBaseUrl = 'https://aaisee.me';

  /// OAuth Web Client ID — dùng cho web, `serverClientId` Android/iOS (aud `id_token` khớp backend).
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '338486890234-rngvalojohs2924etjgn6hbgdm476ij7.apps.googleusercontent.com',
  );

  /// OAuth Android Client ID — truyền `clientId` khi chạy trên Android.
  static const String googleClientIdAndroid = String.fromEnvironment(
    'GOOGLE_CLIENT_ID_ANDROID',
    defaultValue:
        '338486890234-n3c9llg5b882efhfqdnvuv66s1pv6ngk.apps.googleusercontent.com',
  );

  static String _dotenv(String key) {
    if (!dotenv.isInitialized) {
      return '';
    }
    return dotenv.maybeGet(key, fallback: '')?.trim() ?? '';
  }

  /// Gốc web xem báo cáo / timeline Care (`CARE_WEB_BASE_URL` hoặc `--dart-define=CARE_WEB_BASE_URL=`).
  /// App mở đường dẫn cố định `/family/care` trên host này (query `user_id`, `section`).
  static String get careWebBaseUrl {
    String u = _careWebBaseDefine.trim();
    if (u.isEmpty) {
      u = _dotenv('CARE_WEB_BASE_URL');
    }
    if (u.isEmpty) {
      u = _defaultCareWebBaseUrl;
    }
    return u.endsWith('/') ? u.substring(0, u.length - 1) : u;
  }

  /// `section`: `timeline` | `weekly` | `incident` | `export` — web đọc query và hiển thị đúng màn.
  static Uri familyCareWebUri(String caredUserId, String section) {
    final Uri base = Uri.parse(careWebBaseUrl);
    return Uri(
      scheme: base.scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: '/family/care',
      queryParameters: <String, String>{
        'user_id': caredUserId,
        'section': section,
      },
    );
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

  /// Public SDK key RevenueCat — ưu tiên key theo nền tảng ([REVENUECAT_API_KEY_ANDROID] / [REVENUECAT_API_KEY_IOS]) rồi mới tới [REVENUECAT_API_KEY].
  static String get revenueCatApiKey {
    final String platformKey = _platformSpecificRevenueCatApiKey();
    if (platformKey.isNotEmpty) {
      return platformKey;
    }
    String key = _revenueCatApiKeyDefine.trim();
    if (key.isEmpty) {
      key = _dotenv('REVENUECAT_API_KEY');
    }
    return key;
  }

  /// Kill-switch tạm cho flow bán/restore/manage qua RevenueCat.
  static bool get billingRevenueCatEnabled {
    final String raw = _revenueCatEnabledDefine.trim().isNotEmpty
        ? _revenueCatEnabledDefine.trim()
        : _dotenv('BILLING_REVENUECAT_ENABLED');
    if (raw.isEmpty) {
      return true;
    }
    switch (raw.toLowerCase()) {
      case '0':
      case 'false':
      case 'no':
      case 'off':
        return false;
      default:
        return true;
    }
  }

  static String _platformSpecificRevenueCatApiKey() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final String fromDefine = _revenueCatApiKeyAndroidDefine.trim();
        if (fromDefine.isNotEmpty) {
          return fromDefine;
        }
        return _dotenv('REVENUECAT_API_KEY_ANDROID');
      case TargetPlatform.iOS:
        final String fromDefine = _revenueCatApiKeyIosDefine.trim();
        if (fromDefine.isNotEmpty) {
          return fromDefine;
        }
        return _dotenv('REVENUECAT_API_KEY_IOS');
      default:
        return '';
    }
  }
}
