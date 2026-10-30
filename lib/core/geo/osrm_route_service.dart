import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

/// A driving route along real roads.
class RoadRoute {
  const RoadRoute({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;
}

/// Free road routing via public OSRM servers — no API key, same spirit as
/// [NominatimService]. They're fair-use only, so callers should fetch a
/// route once per leg (not on every GPS tick) and fall back to a straight
/// line when every server is unavailable.
class OsrmRouteService {
  OsrmRouteService()
      : _dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 6),
            receiveTimeout: const Duration(seconds: 6),
          ),
        );

  final Dio _dio;

  /// Tried in order — the OSM-hosted mirror covers the demo server being
  /// down or rate-limiting.
  static const _servers = [
    'https://router.project-osrm.org/route/v1/driving',
    'https://routing.openstreetmap.de/routed-car/route/v1/driving',
  ];

  Future<RoadRoute?> route(LatLng from, LatLng to) async {
    for (final server in _servers) {
      final route = await _routeFrom(server, from, to);
      if (route != null) return route;
    }
    return null;
  }

  Future<RoadRoute?> _routeFrom(String server, LatLng from, LatLng to) async {
    try {
      final response = await _dio.get(
        '$server/${from.longitude},${from.latitude};${to.longitude},${to.latitude}',
        queryParameters: {'overview': 'full', 'geometries': 'geojson'},
        // Browsers refuse to set User-Agent (and these servers' CORS policy
        // doesn't allow it), so it's only sent from native builds.
        options: kIsWeb
            ? null
            : Options(headers: {'User-Agent': 'fastswipe-app/1.0'}),
      );
      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : null;
      if (data == null || data['code'] != 'Ok') {
        debugPrint('[osrm] $server: ${data?['code'] ?? 'bad response'}');
        return null;
      }
      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) return null;
      final best = routes.first as Map<String, dynamic>;
      final coords =
          (best['geometry'] as Map<String, dynamic>)['coordinates'] as List;
      final points = [
        for (final c in coords)
          LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
      ];
      if (points.length < 2) return null;
      return RoadRoute(
        points: points,
        distanceMeters: (best['distance'] as num).toDouble(),
        durationSeconds: (best['duration'] as num).toDouble(),
      );
    } catch (e) {
      debugPrint('[osrm] $server failed: $e');
      return null;
    }
  }
}
