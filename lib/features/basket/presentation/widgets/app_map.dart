import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Real basemap (Google Maps, needs an API key configured per-platform —
/// see android/ios/web setup) — replaces the old painted [MapGridPainter]
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
  });

  final LatLng center;
  final double zoom;
  final AppMapController? mapController;
  final bool interactive;

  /// Fires whenever the visible center changes — used to know what to
  /// reverse-geocode.
  final void Function(LatLng center)? onPositionChanged;

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(target: center, zoom: zoom),
      onMapCreated: mapController == null ? null : (controller) => mapController!._attach(controller),
      onCameraMove: onPositionChanged == null ? null : (position) => onPositionChanged!(position.target),
      zoomGesturesEnabled: interactive,
      scrollGesturesEnabled: interactive,
      rotateGesturesEnabled: interactive,
      tiltGesturesEnabled: interactive,
      zoomControlsEnabled: false,
      myLocationButtonEnabled: false,
      mapToolbarEnabled: false,
    );
  }
}

/// Thin wrapper around [GoogleMapController] exposing the "move camera to a
/// point" operation the caller needs, without leaking the underlying
/// Future-based controller-attachment dance into every screen.
class AppMapController {
  final Completer<GoogleMapController> _completer = Completer<GoogleMapController>();

  void _attach(GoogleMapController controller) {
    if (!_completer.isCompleted) _completer.complete(controller);
  }

  Future<void> move(LatLng target, double zoom) async {
    final controller = await _completer.future;
    await controller.animateCamera(CameraUpdate.newLatLngZoom(target, zoom));
  }
}
