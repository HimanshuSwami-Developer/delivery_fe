import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Real basemap (OpenStreetMap via flutter_map — free, no API key or
/// billing account needed) — replaces the old painted [MapGridPainter]
/// placeholder everywhere the app shows a map: the address pin-drop screen
/// and order tracking.
///
/// Screens keep drawing their own pin/marker overlays as `Positioned`
/// widgets on top via a surrounding [Stack] — this widget only owns the
/// map surface and gestures.
class AppMap extends StatelessWidget {
  const AppMap({
    super.key,
    required this.center,
    this.zoom = 15,
    this.mapController,
    this.interactive = true,
    this.onPositionChanged,
    this.cameraFit,
    this.markers = const [],
    this.polylines = const [],
  });

  final LatLng center;
  final double zoom;
  final AppMapController? mapController;
  final bool interactive;

  /// Fires whenever the visible center changes — used to know what to
  /// reverse-geocode.
  final void Function(LatLng center)? onPositionChanged;

  /// When set, overrides [center]/[zoom] to frame a set of points (e.g. the
  /// store and the delivery point) instead of a single fixed camera.
  final CameraFit? cameraFit;

  final List<Marker> markers;
  final List<Polyline> polylines;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController?._controller,
      options: MapOptions(
        initialCenter: center,
        initialZoom: zoom,
        initialCameraFit: cameraFit,
        interactionOptions: InteractionOptions(
          flags: interactive ? InteractiveFlag.all : InteractiveFlag.none,
        ),
        onPositionChanged: onPositionChanged == null
            ? null
            : (position, hasGesture) => onPositionChanged!(position.center),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.aapnobazar.app',
        ),
        if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
        if (markers.isNotEmpty) MarkerLayer(markers: markers),
      ],
    );
  }
}

/// Thin wrapper around [MapController] exposing the "move camera to a
/// point" operation the caller needs, without leaking flutter_map's own
/// controller type into every screen.
class AppMapController {
  final MapController _controller = MapController();

  Future<void> move(LatLng target, double zoom) async {
    _controller.move(target, zoom);
  }

  void zoomIn() {
    final camera = _controller.camera;
    _controller.move(camera.center, camera.zoom + 1);
  }

  void zoomOut() {
    final camera = _controller.camera;
    _controller.move(camera.center, camera.zoom - 1);
  }

  /// Explicitly re-frames the camera — unlike [AppMap.cameraFit], which
  /// flutter_map only ever applies on the map's very first attach, this
  /// takes effect immediately even if the map is already showing (e.g.
  /// once an async GPS fix resolves after the map first rendered).
  void fitCamera(CameraFit fit) {
    _controller.fitCamera(fit);
  }
}
