import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/cubit/basket_selectors.dart';
import 'package:fastswipe/features/basket/data/basket_catalog.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:fastswipe/features/basket/presentation/widgets/image_slot.dart';
import 'package:fastswipe/features/basket/presentation/widgets/app_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

/// The store the rider dispatches from for every order.
const _storeLocation = LatLng(28.201806, 76.627815);

/// Fraction of the store→customer line the rider has covered at each of
/// the 4 tracking stages: still at the store while the order is being
/// packed, most of the way there once "on the way", arrived on delivery.
const _riderProgressByStage = [0.0, 0.06, 0.65, 1.0];

/// The backend has no live rider GPS (`Order`/`DeliveryPartner` carry no
/// lat/lng), so the rider marker's position is still simulated from
/// [trackingStage] — this is just a real basemap and real store coordinates
/// under it instead of the painted grid placeholder. The map is interactive
/// (pan/zoom) so the user can look around.
class OrderTrackingView extends StatefulWidget {
  const OrderTrackingView({super.key});

  @override
  State<OrderTrackingView> createState() => _OrderTrackingViewState();
}

class _OrderTrackingViewState extends State<OrderTrackingView> {
  // Null until a real GPS fix comes back — no hardcoded stand-in, so the
  // customer marker/route/rider only ever appear once we actually know
  // where "here" is.
  LatLng? _customerLocation;
  final _mapController = AppMapController();

  // Computed once — the first time a customer location becomes known —
  // and then frozen — flutter_map re-applies `initialCameraFit` whenever a
  // new instance is passed in, so recomputing this every rebuild (e.g. on
  // every tick of the rider's move animation) would keep yanking the
  // camera back and fighting the user's own pan/zoom.
  CameraFit? _cameraFit;

  @override
  void initState() {
    super.initState();
    _loadCustomerLocation();
  }

  Future<void> _loadCustomerLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(timeLimit: Duration(seconds: 8)),
      );
      if (!mounted) return;
      final location = LatLng(position.latitude, position.longitude);
      setState(() => _customerLocation = location);
      // `AppMap.cameraFit` only takes effect on the map's first attach —
      // the map is already showing by the time this async fix lands, so
      // command the re-frame explicitly or the store+customer route would
      // silently sit off-screen until the user manually zooms out.
      _cameraFit ??= _cameraFitFor(location);
      _mapController.fitCamera(_cameraFit!);
    } catch (_) {
      // Best-effort — no fallback point; the customer marker/route just
      // stay hidden until a fix (or a retry) succeeds.
    }
  }

  CameraFit _cameraFitFor(LatLng customerLocation) {
    return CameraFit.coordinates(
      coordinates: [_storeLocation, customerLocation],
      padding: const EdgeInsets.fromLTRB(40, 90, 40, 40),
      maxZoom: 16,
    );
  }

  /// Pans the map to the customer's own location — re-requesting a GPS fix
  /// first if one isn't known yet, same as a "locate me" button elsewhere.
  void _goToCustomerLocation() {
    final location = _customerLocation;
    if (location == null) {
      _loadCustomerLocation();
      return;
    }
    _mapController.move(location, 16);
  }

  /// Opens the store→customer route in the real Google Maps app (or the
  /// browser, if it's not installed) — these are real coordinates, so
  /// handing them off to a proper navigation app is more useful than
  /// anything this in-app map can offer.
  Future<void> _openInGoogleMaps() async {
    final destination = _customerLocation;
    final uri = destination == null
        ? Uri.parse('https://www.google.com/maps/search/?api=1&query=${_storeLocation.latitude},${_storeLocation.longitude}')
        : Uri.parse(
            'https://www.google.com/maps/dir/?api=1'
            '&origin=${_storeLocation.latitude},${_storeLocation.longitude}'
            '&destination=${destination.latitude},${destination.longitude}'
            '&travelmode=driving',
          );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  LatLng _riderLocationForProgress(LatLng customerLocation, double t) {
    return LatLng(
      _storeLocation.latitude + (customerLocation.latitude - _storeLocation.latitude) * t,
      _storeLocation.longitude + (customerLocation.longitude - _storeLocation.longitude) * t,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketCubit>();
    final stage = context.select((BasketCubit c) => c.state.trackingStage);
    final order = context.select((BasketCubit c) => c.state.currentOrder);
    final etaLeft = etaLeftForStage(stage, eta: BasketCubit.etaMinutes);
    final headline = ['Order confirmed', 'Packing your basket', 'Rider is on the way', 'Delivered — enjoy!'][stage];
    final riderName = order?.deliveryPartnerName ?? 'Your rider';
    // A rider marker only makes sense once the backend has actually
    // assigned one to this order — not from the moment tracking opens.
    final riderAssigned = order?.deliveryPartnerId != null;
    final customerLocation = _customerLocation;
    final cameraFit = customerLocation == null ? null : (_cameraFit ??= _cameraFitFor(customerLocation));

    return Stack(
      children: [
        // Full-screen backdrop — the sheet below slides up over it, from a
        // small "Order confirmed" peek up to 0.7 of the screen height.
        Positioned.fill(
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(end: _riderProgressByStage[stage]),
            duration: const Duration(milliseconds: 1400),
            curve: Curves.easeInOut,
            builder: (context, t, child) {
              final riderLocation = customerLocation == null
                  ? null
                  : _riderLocationForProgress(customerLocation, t);
              final showRider = riderAssigned && riderLocation != null;
              return AppMap(
                center: _storeLocation,
                cameraFit: cameraFit,
                mapController: _mapController,
                polylines: [
                  if (customerLocation != null) ...[
                    // Full route, muted — the road still ahead.
                    Polyline(
                      points: [_storeLocation, customerLocation],
                      strokeWidth: 3,
                      color: BasketColors.ink.withValues(alpha: 0.25),
                      pattern: StrokePattern.dashed(segments: const [8, 6]),
                    ),
                    // Distance already covered, solid.
                    if (showRider && t > 0.001)
                      Polyline(
                        points: [_storeLocation, riderLocation],
                        strokeWidth: 4,
                        color: BasketColors.primary,
                      ),
                  ],
                ],
                markers: [
                  Marker(
                    point: _storeLocation,
                    width: 66,
                    height: 58,
                    alignment: Alignment.topCenter,
                    child: const _MapPin(label: 'Store', icon: Icons.home_rounded, style: _PinStyle.outlined),
                  ),
                  if (showRider)
                    Marker(
                      point: riderLocation,
                      width: 70,
                      height: 62,
                      alignment: Alignment.topCenter,
                      child: const _MapPin(label: 'Rider', icon: Icons.two_wheeler_rounded, style: _PinStyle.filled),
                    ),
                  if (customerLocation != null)
                    Marker(
                      point: customerLocation,
                      width: 66,
                      height: 58,
                      alignment: Alignment.topCenter,
                      child: const _MapPin(label: 'You', icon: Icons.person_rounded, style: _PinStyle.outlined),
                    ),
                ],
              );
            },
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: IgnorePointer(
            child: Container(height: 60, color: Colors.white.withValues(alpha: 0.78)),
          ),
        ),
        Positioned(
          top: MediaQuery.paddingOf(context).top + 8,
          left: 14,
          child: InkWell(
            onTap: cubit.back,
            borderRadius: BorderRadius.circular(99),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(color: BasketColors.ink, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 16),
            ),
          ),
        ),
        // Map controls — floating bottom-right, just above the sheet's
        // collapsed peek so they stay reachable regardless of how far the
        // sheet has been dragged up.
        Positioned(
          right: 14,
          bottom: MediaQuery.sizeOf(context).height * 0.17 + 14,
          child: Column(
            children: [
              _MapControlButton(icon: Icons.map_outlined, onTap: _openInGoogleMaps),
              const SizedBox(height: 8),
              _MapControlButton(icon: Icons.my_location, onTap: _goToCustomerLocation),
              const SizedBox(height: 8),
              _MapControlButton(icon: Icons.add, onTap: _mapController.zoomIn),
              const SizedBox(height: 8),
              _MapControlButton(icon: Icons.remove, onTap: _mapController.zoomOut),
            ],
          ),
        ),
        // Draggable details sheet — starts collapsed to just the headline
        // ("Order confirmed") so the map (rider en route) is what the user
        // sees first; dragging it up to 0.7 reveals the full rider card,
        // timeline, and actions.
        DraggableScrollableSheet(
          initialChildSize: 0.17,
          minChildSize: 0.17,
          maxChildSize: 0.7,
          builder: (context, scrollController) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 34,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(color: BasketColors.ink.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(9)),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(headline, style: GoogleFonts.plusJakartaSans(fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
                            const SizedBox(height: 5),
                            Text(
                              '${order?.orderNumber ?? '—'} · ${order?.itemCount ?? 0} ${order?.itemCount == 1 ? 'item' : 'items'}',
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500, color: BasketColors.muted),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('$etaLeft min', style: GoogleFonts.plusJakartaSans(fontSize: 19, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text('remaining', style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w500, color: BasketColors.faint)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: BasketColors.ink, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: const SizedBox(width: 42, height: 42, child: ImageSlot(shape: ImageSlotShape.circle, mini: true)),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(riderName, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                              const SizedBox(height: 3),
                              Text('Honda Activa · ★ 4.8', style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.55))),
                            ],
                          ),
                        ),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: const Icon(Icons.call_outlined, color: Colors.white, size: 15),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: const Icon(Icons.mail_outline, color: BasketColors.ink, size: 15),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  for (var i = 0; i < BasketCatalog.trackingSteps.length; i++)
                    _TimelineStep(
                      index: i,
                      title: BasketCatalog.trackingSteps[i].title,
                      sub: i == stage ? 'Now' : BasketCatalog.trackingSteps[i].sub,
                      done: i <= stage,
                      isLast: i == BasketCatalog.trackingSteps.length - 1,
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: BasketColors.ink, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            minimumSize: Size.zero,
                          ),
                          onPressed: cubit.refreshTracking,
                          child: Text('Refresh status', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: BasketColors.ink)),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: BasketColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            minimumSize: Size.zero,
                          ),
                          onPressed: cubit.goToSupport,
                          child: Text('Get help', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.index,
    required this.title,
    required this.sub,
    required this.done,
    required this.isLast,
  });

  final int index;
  final String title;
  final String sub;
  final bool done;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: done ? 1 : 0.45,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? BasketColors.ink : Colors.white,
                  border: Border.all(color: BasketColors.ink, width: 2),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 26,
                  color: done ? BasketColors.ink : BasketColors.ink.withValues(alpha: 0.12),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(sub, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500, color: BasketColors.muted)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Filled/dark badges call out the rider (the thing that moves); outlined
/// badges mark the two fixed ends of the route (store and customer).
enum _PinStyle { filled, outlined }

/// A labeled icon marker on the tracking map.
class _MapPin extends StatelessWidget {
  const _MapPin({required this.label, required this.icon, required this.style});

  final String label;
  final IconData icon;
  final _PinStyle style;

  @override
  Widget build(BuildContext context) {
    final filled = style == _PinStyle.filled;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: filled ? BasketColors.ink : Colors.white,
            border: filled ? null : Border.all(color: BasketColors.ink.withValues(alpha: 0.12)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: filled ? Colors.white : BasketColors.ink,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: filled ? 30 : 26,
          height: filled ? 30 : 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? BasketColors.ink : Colors.white,
            border: filled ? null : Border.all(color: BasketColors.ink, width: 2),
            boxShadow: [BoxShadow(color: BasketColors.ink.withValues(alpha: filled ? 0.22 : 0.1), blurRadius: 6, spreadRadius: filled ? 1 : 0)],
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: filled ? 17 : 14, color: filled ? Colors.white : BasketColors.ink),
        ),
      ],
    );
  }
}

/// A round zoom in/out control floating over the map.
class _MapControlButton extends StatelessWidget {
  const _MapControlButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: BasketColors.ink.withValues(alpha: 0.16), blurRadius: 6)],
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: BasketColors.ink, size: 18),
      ),
    );
  }
}
