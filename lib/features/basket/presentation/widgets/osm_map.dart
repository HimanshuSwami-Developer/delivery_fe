import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Real basemap (OpenStreetMap tiles via [flutter_map], no API key needed)
/// — replaces the old painted [MapGridPainter] placeholder everywhere the
/// app shows a map: the address pin-drop screen and order tracking.
///
/// Screens keep drawing their own pin/marker overlays as `Positioned`
/// widgets on top via [children] — this widget only owns the tile layer,
/// gestures, and the attribution OSM's tile usage policy requires.
class OsmMap extends StatelessWidget {
  const OsmMap({
    super.key,
    required this.center,
    this.zoom = 15,
    this.mapController,
    this.interactive = true,
    this.onPositionChanged,
    this.children = const [],
  });

  final LatLng center;
  final double zoom;
  final MapController? mapController;
  final bool interactive;

  /// Fires (debounced by the caller if needed) whenever the visible center
  /// changes — used to know what to reverse-geocode.
  final void Function(LatLng center)? onPositionChanged;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: zoom,
        interactionOptions: InteractionOptions(
          flags: interactive ? InteractiveFlag.all : InteractiveFlag.none,
        ),
        onPositionChanged: onPositionChanged == null ? null : (camera, hasGesture) => onPositionChanged!(camera.center),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.fastswipe.app',
        ),
        const RichAttributionWidget(
          attributions: [TextSourceAttribution('OpenStreetMap contributors', prependCopyright: true)],
        ),
        ...children,
      ],
    );
  }
}
