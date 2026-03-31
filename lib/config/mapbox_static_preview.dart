import 'app_env.dart';

/// URL ảnh tĩnh Mapbox (Static Images API) — preview không cần SDK native.
/// Cần [AppEnv.mapboxAccessToken] (pk.*).
abstract final class MapboxStaticPreview {
  static bool get isConfigured => AppEnv.mapboxAccessToken.isNotEmpty;

  /// Giới hạn Mapbox: cạnh tối đa 1280px.
  static Uri? previewUri(
    double lng,
    double lat, {
    int widthPx = 800,
    int heightPx = 480,
    double zoom = 15,
  }) {
    final token = AppEnv.mapboxAccessToken;
    if (token.isEmpty) return null;

    final w = widthPx.clamp(1, 1280);
    final h = heightPx.clamp(1, 1280);
    final lon = lng.toStringAsFixed(6);
    final la = lat.toStringAsFixed(6);
    final zi = zoom.round().clamp(0, 22);
    final path =
        '/styles/v1/mapbox/dark-v11/static/pin-s+6dd210($lon,$la)/$lon,$la,$zi/${w}x$h@2x';
    return Uri.https('api.mapbox.com', path, {'access_token': token});
  }
}
