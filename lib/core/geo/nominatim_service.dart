import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Result of a Nominatim (OpenStreetMap) reverse-geocode lookup.
class ReverseGeocodeResult {
  const ReverseGeocodeResult({
    required this.displayName,
    required this.city,
    required this.state,
    required this.postcode,
  });

  final String displayName;
  final String city;
  final String state;
  final String postcode;
}

/// Free reverse geocoding via OpenStreetMap's Nominatim — no API key, but
/// their usage policy requires a real User-Agent and caps requests at
/// roughly 1/sec, so callers should debounce (the map pin should reverse
/// geocode on move-end, not on every drag frame).
class NominatimService {
  NominatimService() : _dio = Dio(BaseOptions(baseUrl: 'https://nominatim.openstreetmap.org'));

  final Dio _dio;

  Future<ReverseGeocodeResult?> reverseGeocode(LatLng point) async {
    try {
      final response = await _dio.get(
        '/reverse',
        queryParameters: {
          'format': 'jsonv2',
          'lat': point.latitude,
          'lon': point.longitude,
        },
        options: Options(headers: {'User-Agent': 'fastswipe-app/1.0'}),
      );
      final data = response.data as Map<String, dynamic>;
      final address = data['address'] as Map<String, dynamic>? ?? {};
      return ReverseGeocodeResult(
        displayName: data['display_name'] as String? ?? '',
        city: (address['city'] ?? address['town'] ?? address['village'] ?? address['suburb'] ?? '') as String,
        state: (address['state'] ?? '') as String,
        postcode: (address['postcode'] ?? '') as String,
      );
    } catch (_) {
      return null;
    }
  }
}
