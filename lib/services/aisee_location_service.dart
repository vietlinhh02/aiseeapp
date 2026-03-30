import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class AiseeLocationResult {
  const AiseeLocationResult({
    required this.lat,
    required this.lng,
    required this.address,
  });

  final double lat;
  final double lng;
  final String address;
}

class AiseeLocationService {
  /// Returns lat, lng, and reverse-geocoded address.
  static Future<AiseeLocationResult> getCurrentLocation() async {
    if (kIsWeb) {
      throw Exception('Location not supported on web');
    }

    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('GPS đang tắt. Hãy bật định vị.');
    }

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }
    }
    if (perm == LocationPermission.deniedForever) {
      throw Exception(
        'Quyền vị trí đã bị từ chối vĩnh viễn. Hãy bật trong Cài đặt.',
      );
    }

    // Fast path: cached position.
    final Position? last = await Geolocator.getLastKnownPosition();
    final double lat;
    final double lng;
    if (last != null) {
      lat = last.latitude;
      lng = last.longitude;
    } else {
      // Fallback: fresh GPS fix.
      final Position pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 4),
        ),
      );
      lat = pos.latitude;
      lng = pos.longitude;
    }

    // Reverse geocode to human-readable address.
    final String address = await _reverseGeocode(lat, lng);
    return AiseeLocationResult(lat: lat, lng: lng, address: address);
  }

  static Future<String> _reverseGeocode(double lat, double lng) async {
    try {
      final List<Placemark> marks = await placemarkFromCoordinates(lat, lng);
      if (marks.isEmpty) return '';
      final Placemark p = marks.first;
      final List<String> parts = <String>[
        if (p.street != null && p.street!.isNotEmpty) p.street!,
        if (p.subLocality != null && p.subLocality!.isNotEmpty) p.subLocality!,
        if (p.locality != null && p.locality!.isNotEmpty) p.locality!,
        if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty)
          p.administrativeArea!,
      ];
      return parts.join(', ');
    } catch (e) {
      debugPrint('[AiSee:Location] Reverse geocode failed: $e');
      return '';
    }
  }
}
