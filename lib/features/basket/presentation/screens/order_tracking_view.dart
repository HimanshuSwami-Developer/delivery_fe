import 'dart:async';
import 'dart:math' as math;

import 'package:fastswipe/core/basket_api/models/order_models.dart';
import 'package:fastswipe/core/geo/osrm_route_service.dart';
import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/cubit/basket_selectors.dart';
import 'package:fastswipe/features/basket/data/basket_catalog.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:fastswipe/features/basket/presentation/basket_ui.dart';
import 'package:fastswipe/features/basket/presentation/widgets/image_slot.dart';
import 'package:fastswipe/features/basket/presentation/widgets/app_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:url_launcher/url_launcher.dart';

const _cream = Color(0xFFFFFBF2);

/// Fraction of the store→customer route the rider is shown at for each of
/// the 4 tracking stages — only used until the rider app has reported a
/// real GPS fix (see `OrderViewSet.rider_location`).
const _riderProgressByStage = [0.0, 0.06, 0.65, 1.0];

/// How often `/orders/{id}/tracking/` is polled. The rider marker glides
/// between fixes over the same interval, so it never visibly stops.
const _pollInterval = Duration(seconds: 4);

/// A rider fix older than this is called out as "last seen …" rather than
/// "live".
const _staleAfter = Duration(seconds: 60);

/// Live order tracking: polls the order's status + the rider's real GPS
/// fix, draws the actual road route (OSRM) from store to the delivery
/// point, and animates the rider marker smoothly (position and heading)
/// between fixes. Until the rider app reports a location, the marker is
/// placed along the route by order stage instead.
class OrderTrackingView extends StatefulWidget {
  const OrderTrackingView({super.key});

  @override
  State<OrderTrackingView> createState() => _OrderTrackingViewState();
}

class _OrderTrackingViewState extends State<OrderTrackingView>
    with TickerProviderStateMixin {
  // Null until `/orders/store_location/` responds — no hardcoded fallback.
  LatLng? _storeLocation;

  // The order's own drop-pin when it has one, otherwise this device's GPS
  // fix — null until one of those is known.
  LatLng? _customerLocation;

  final _mapController = AppMapController();
  // Frozen once computed — see `_onEndpointsChanged`.
  CameraFit? _cameraFit;
  bool _followRider = false;

  Timer? _pollTimer;
  ApiOrderTracking? _tracking;
  bool _polling = false;

  /// False until the first poll (and the full-order refresh it triggers)
  /// has finished — the screen shows a skeleton until then instead of a
  /// flash of "— · 0 items" and a stale stage. Set on failure too, so a
  /// network error falls back to whatever the cubit already has.
  bool _firstLoadDone = false;

  // ── Route state ──
  // The path the rider marker travels along. Before pickup it's the road
  // route store → customer; once the rider reports live GPS it's the road
  // route rider → customer, re-fetched if they leave it. Until a road route
  // arrives it's a straight-line placeholder.
  final _routeService = OsrmRouteService();
  _RoutePath? _path;
  RoadRoute? _road; // road route [_path] came from, null = placeholder
  bool _roadFromRider = false;
  bool _routeLoading = false;
  DateTime? _lastRouteAttempt;

  // ── Rider animation ──
  // The rider's position is a distance along [_path]; the animation
  // interpolates that distance, so the marker follows road curves instead
  // of cutting straight between GPS fixes.
  late final AnimationController _riderAnim;
  double _distFrom = 0;
  double _distTo = 0;
  bool _hasRiderPosition = false;
  int? _syncedStage;
  // Accumulated heading (in turns) along the shortest arc, so 359°→1°
  // doesn't spin all the way round.
  double _riderTurns = 0;

  // Drives the pulsing halo on the "You" and live-indicator dots.
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _riderAnim = AnimationController(vsync: this)..addListener(_onRiderFrame);
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _seedCustomerLocationFromOrder();
    _loadStoreLocation();
    if (_customerLocation == null) _loadDeviceLocation();
    _poll();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _poll());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _riderAnim.dispose();
    _pulse.dispose();
    super.dispose();
  }

  // ── Data ───────────────────────────────────────────────────────────

  void _seedCustomerLocationFromOrder() {
    final order = context.read<BasketCubit>().state.currentOrder;
    if (order?.latitude != null && order?.longitude != null) {
      _customerLocation = LatLng(order!.latitude!, order.longitude!);
    }
  }

  Future<void> _loadStoreLocation() async {
    try {
      final location = await context
          .read<BasketCubit>()
          .api
          .orders
          .fetchStoreLocation();
      if (!mounted) return;
      setState(
        () => _storeLocation = LatLng(location.latitude, location.longitude),
      );
      _onEndpointsChanged();
    } catch (_) {
      // Map stays on its loading state; no hardcoded fallback point.
    }
  }

  Future<void> _loadDeviceLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          timeLimit: Duration(seconds: 8),
        ),
      );
      if (!mounted || _customerLocation != null) return;
      setState(
        () => _customerLocation = LatLng(position.latitude, position.longitude),
      );
      _onEndpointsChanged();
    } catch (_) {}
  }

  /// Store and customer resolve independently (in either order) — once
  /// both are known, frame the camera and lay down the route.
  void _onEndpointsChanged() {
    final store = _storeLocation;
    final customer = _customerLocation;
    if (store == null || customer == null) return;
    _cameraFit ??= CameraFit.coordinates(
      coordinates: [store, customer],
      padding: const EdgeInsets.fromLTRB(48, 110, 48, 220),
      maxZoom: 16,
    );
    _mapController.fitCamera(_cameraFit!);
    _syncRoute();
  }

  Future<void> _poll() async {
    if (_polling) return;
    final cubit = context.read<BasketCubit>();
    final id = cubit.state.currentOrder?.id;
    if (id == null) {
      if (!_firstLoadDone) setState(() => _firstLoadDone = true);
      return;
    }
    _polling = true;
    try {
      final tracking = await cubit.api.orders.fetchTracking(id);
      if (!mounted) return;
      final statusChanged =
          tracking.status != _tracking?.status ||
          tracking.deliveryPartnerId != _tracking?.deliveryPartnerId;
      // Status moved on server-side — refresh the full order so the
      // timeline/headline (driven by the cubit) follow. Awaited before
      // the setState below so the first real frame is fully up to date.
      if (statusChanged) await cubit.refreshTracking();
      if (!mounted) return;
      setState(() {
        _tracking = tracking;
        _firstLoadDone = true;
      });
      if (tracking.status == 'delivered' || tracking.status == 'cancelled') {
        _pollTimer?.cancel();
      }
      _syncRoute();
    } catch (_) {
      // Transient — the next tick retries.
      if (mounted && !_firstLoadDone) setState(() => _firstLoadDone = true);
    } finally {
      _polling = false;
    }
  }

  // ── Route + rider position ─────────────────────────────────────────

  bool get _hasLiveFix {
    final t = _tracking;
    return t != null && t.hasRiderLocation && t.status == 'out_for_delivery';
  }

  LatLng? get _liveFix => _hasLiveFix
      ? LatLng(_tracking!.riderLatitude!, _tracking!.riderLongitude!)
      : null;

  int get _stage => context.read<BasketCubit>().state.trackingStage;

  /// Makes sure [_path] is the right route for the current situation,
  /// fetching a road route when needed, then moves the rider along it.
  void _syncRoute() {
    final store = _storeLocation;
    final customer = _customerLocation;
    if (store == null || customer == null) return;
    final fix = _liveFix;

    if (fix == null) {
      // No live GPS — store → customer, rider placed by order stage.
      if (_path == null || _roadFromRider) {
        _setPath(_RoutePath([store, customer]), road: null, fromRider: false);
      }
      if (_road == null) _fetchRoad(store, customer, fromRider: false);
      _moveRiderTo(_path!.length * _riderProgressByStage[_stage]);
      return;
    }

    // Live GPS — follow the rider along the road route rider → customer.
    final path = _path;
    final onRoad = path != null && _roadFromRider && _road != null;
    final projected = path?.project(fix);
    final offRoute = projected == null || projected.offMeters > 45;

    if (onRoad && !offRoute) {
      // Never slide backwards on GPS jitter.
      _moveRiderTo(math.max(projected.distance, _currentDistance));
      return;
    }

    // Not on a usable road path yet (first fix, or rider took another
    // road): glide straight from where the marker is to the fix while the
    // proper road route loads.
    final from = _riderPosition() ?? fix;
    final placeholder = _RoutePath([from, fix, customer]);
    _setPath(placeholder, road: null, fromRider: true);
    _distFrom = 0;
    _distTo = 0;
    _moveRiderTo(placeholder.cumulative[1]);
    _fetchRoad(fix, customer, fromRider: true);
  }

  void _setPath(
    _RoutePath path, {
    required RoadRoute? road,
    required bool fromRider,
  }) {
    final previous = _riderPosition();
    _path = path;
    _road = road;
    _roadFromRider = fromRider;
    if (previous != null && _hasRiderPosition) {
      final d = path.project(previous).distance;
      _distFrom = d;
      _distTo = d;
      _riderAnim.value = 1;
    }
  }

  Future<void> _fetchRoad(
    LatLng from,
    LatLng to, {
    required bool fromRider,
  }) async {
    final last = _lastRouteAttempt;
    if (_routeLoading ||
        (last != null &&
            DateTime.now().difference(last) < const Duration(seconds: 8))) {
      return;
    }
    _routeLoading = true;
    _lastRouteAttempt = DateTime.now();
    final road = await _routeService.route(from, to);
    _routeLoading = false;
    if (!mounted || road == null) return;
    // Discard if the situation changed while loading (e.g. live GPS
    // started while the store route was in flight).
    if (fromRider != (_liveFix != null)) return;
    setState(
      () => _setPath(_RoutePath(road.points), road: road, fromRider: fromRider),
    );
    if (!fromRider && _cameraFit != null) {
      _cameraFit = CameraFit.coordinates(
        coordinates: road.points,
        padding: const EdgeInsets.fromLTRB(48, 110, 48, 220),
        maxZoom: 16,
      );
      _mapController.fitCamera(_cameraFit!);
    }
    _syncRoute();
  }

  double get _currentDistance =>
      _distFrom + (_distTo - _distFrom) * _riderAnim.value;

  void _moveRiderTo(double distance) {
    final path = _path;
    if (path == null) return;
    final target = distance.clamp(0.0, path.length);
    if (!_hasRiderPosition) {
      _hasRiderPosition = true;
      _distFrom = target;
      _distTo = target;
      _riderAnim.value = 1;
      _updateHeading();
      setState(() {});
      return;
    }
    if ((target - _distTo).abs() < 0.5 && !_riderAnim.isAnimating) return;
    _distFrom = _currentDistance;
    _distTo = target;
    // Live fixes glide linearly across the whole poll interval so the
    // marker never visibly stops; stage jumps ease in/out.
    _riderAnim.duration = _hasLiveFix
        ? _pollInterval + const Duration(milliseconds: 300)
        : const Duration(milliseconds: 1800);
    _riderAnim.value = 0;
    _riderAnim.animateTo(
      1,
      curve: _hasLiveFix ? Curves.linear : Curves.easeInOutCubic,
    );
  }

  LatLng? _riderPosition() {
    final path = _path;
    if (path == null || !_hasRiderPosition) return null;
    return path.at(_currentDistance);
  }

  /// Heading follows the road: the bearing across a short window around
  /// the rider's spot on the path, which also smooths out sharp vertices.
  void _updateHeading() {
    final path = _path;
    if (path == null || path.length < 1) return;
    final d = _currentDistance;
    final a = path.at(d - 8);
    final b = path.at(d + 8);
    if (const Distance().as(LengthUnit.Meter, a, b) < 1) return;
    final bearing = const Distance().bearing(a, b);
    final currentDeg = (_riderTurns * 360) % 360;
    var delta = (bearing - currentDeg) % 360;
    if (delta > 180) delta -= 360;
    if (delta < -180) delta += 360;
    // Ease toward the target heading each frame rather than snapping.
    _riderTurns += (delta / 360) * 0.25;
  }

  void _onRiderFrame() {
    _updateHeading();
    if (_followRider) {
      final rider = _riderPosition();
      if (rider != null) _mapController.move(rider, 16.5);
    }
  }

  // ── Actions ────────────────────────────────────────────────────────

  void _goToCustomerLocation() {
    final location = _customerLocation;
    if (location == null) {
      _loadDeviceLocation();
      return;
    }
    setState(() => _followRider = false);
    _mapController.move(location, 16);
  }

  void _toggleFollowRider() {
    setState(() => _followRider = !_followRider);
    if (!_followRider && _cameraFit != null) {
      _mapController.fitCamera(_cameraFit!);
    } else {
      _onRiderFrame();
    }
  }

  Future<void> _openInGoogleMaps() async {
    final store = _storeLocation!;
    final destination = _customerLocation;
    final uri = destination == null
        ? Uri.parse(
            'https://www.google.com/maps/search/?api=1&query=${store.latitude},${store.longitude}',
          )
        : Uri.parse(
            'https://www.google.com/maps/dir/?api=1'
            '&origin=${store.latitude},${store.longitude}'
            '&destination=${destination.latitude},${destination.longitude}'
            '&travelmode=driving',
          );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // ── UI ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final storeLocation = _storeLocation;
    final cubit = context.read<BasketCubit>();
    if (storeLocation == null || !_firstLoadDone) {
      return _TrackingSkeleton(onBack: cubit.back, pulse: _pulse);
    }
    final stage = context.select((BasketCubit c) => c.state.trackingStage);
    final order = context.select((BasketCubit c) => c.state.currentOrder);
    final customerLocation = _customerLocation;
    final riderAssigned =
        (_tracking?.deliveryPartnerId ?? order?.deliveryPartnerId) != null;
    final riderName =
        _tracking?.deliveryPartnerName ??
        order?.deliveryPartnerName ??
        'Your rider';
    // Stage changes come in through the cubit — move the rider along the
    // route to match once one lands.
    if (stage != _syncedStage) {
      _syncedStage = stage;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncRoute();
      });
    }

    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: Listenable.merge([_riderAnim, _pulse]),
            builder: (context, _) {
              final path = _path;
              final rider = _riderPosition();
              final showRider = riderAssigned && rider != null && stage > 0;
              final split = (path != null && showRider)
                  ? path.split(_currentDistance)
                  : null;
              // Straight-line placeholder until the road route loads —
              // drawn dashed so it doesn't read as the real route.
              final isRoad = _road != null;
              return AppMap(
                center: storeLocation,
                cameraFit: _cameraFit,
                mapController: _mapController,
                polylines: [
                  if (path != null && customerLocation != null && !isRoad)
                    Polyline(
                      points: split?.$2 ?? path.points,
                      strokeWidth: 3,
                      color: BasketColors.ink.withValues(alpha: 0.3),
                      pattern: StrokePattern.dashed(segments: const [8, 6]),
                    ),
                  if (path != null && customerLocation != null && isRoad) ...[
                    // Casing under the whole route, for contrast on the
                    // basemap.
                    Polyline(
                      points: path.points,
                      strokeWidth: 9,
                      color: _cream.withValues(alpha: 0.9),
                    ),
                    Polyline(
                      points: split?.$2 ?? path.points,
                      strokeWidth: 5,
                      color: BasketColors.primary,
                    ),
                    if (split != null)
                      Polyline(
                        points: split.$1,
                        strokeWidth: 5,
                        color: BasketColors.ink.withValues(alpha: 0.28),
                      ),
                  ],
                ],
                markers: [
                  Marker(
                    point: storeLocation,
                    width: 66,
                    height: 58,
                    alignment: Alignment.topCenter,
                    child: const _MapPin(
                      label: 'Store',
                      icon: Icons.storefront_rounded,
                    ),
                  ),
                  if (customerLocation != null)
                    Marker(
                      point: customerLocation,
                      width: 80,
                      height: 80,
                      child: _PulsingHomePin(pulse: _pulse.value),
                    ),
                  if (showRider)
                    Marker(
                      point: rider,
                      width: 56,
                      height: 56,
                      child: _RiderMarker(turns: _riderTurns),
                    ),
                ],
              );
            },
          ),
        ),
        Positioned(
          top: MediaQuery.paddingOf(context).top + BasketSpace.xs,
          left: BasketSpace.gutter,
          right: BasketSpace.gutter,
          child: Row(
            children: [
              InkWell(
                onTap: cubit.back,
                borderRadius: BorderRadius.circular(BasketRadius.pill),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: BasketColors.ink,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.arrow_back, color: _cream, size: 18),
                ),
              ),
              const Spacer(),
              _LiveChip(tracking: _tracking, live: _hasLiveFix, pulse: _pulse),
            ],
          ),
        ),
        Positioned(
          right: BasketSpace.gutter,
          bottom: MediaQuery.sizeOf(context).height * 0.24 + BasketSpace.md,
          child: Column(
            children: [
              if (riderAssigned && stage == 2) ...[
                _MapControlButton(
                  icon: Icons.two_wheeler_rounded,
                  active: _followRider,
                  onTap: _toggleFollowRider,
                ),
                const SizedBox(height: 8),
              ],
              _MapControlButton(
                icon: Icons.map_outlined,
                onTap: _openInGoogleMaps,
              ),
              const SizedBox(height: 8),
              _MapControlButton(
                icon: Icons.my_location,
                onTap: _goToCustomerLocation,
              ),
              const SizedBox(height: 8),
              _MapControlButton(icon: Icons.add, onTap: _mapController.zoomIn),
              const SizedBox(height: 8),
              _MapControlButton(
                icon: Icons.remove,
                onTap: _mapController.zoomOut,
              ),
            ],
          ),
        ),
        DraggableScrollableSheet(
          initialChildSize: 0.24,
          minChildSize: 0.24,
          maxChildSize: 0.72,
          snap: true,
          builder: (context, scrollController) {
            return Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: _cream,
                borderRadius: BasketRadius.sheet,
                boxShadow: [
                  BoxShadow(
                    color: BasketColors.ink.withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(
                  BasketSpace.gutter,
                  BasketSpace.sm,
                  BasketSpace.gutter,
                  BasketSpace.lg,
                ),
                children: [
                  Center(
                    child: Container(
                      width: 34,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: BasketSpace.sm),
                      decoration: BoxDecoration(
                        color: BasketColors.ink.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(BasketRadius.sm),
                      ),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _riderAnim,
                    builder: (context, _) => _SheetHeader(
                      stage: stage,
                      orderLine:
                          '${order?.orderNumber ?? '—'} · ${order?.itemCount ?? 0} ${order?.itemCount == 1 ? 'item' : 'items'}',
                      etaMinutes: _etaMinutes(stage),
                      distanceLabel: _distanceLabel(stage),
                    ),
                  ),
                  const SizedBox(height: BasketSpace.sm),
                  _StageProgressBar(stage: stage),
                  const SizedBox(height: BasketSpace.md),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    child: riderAssigned
                        ? _RiderCard(
                            key: const ValueKey('rider'),
                            name: riderName,
                            subtitle: _riderSubtitle(stage),
                          )
                        : const _AssigningRiderCard(key: ValueKey('none')),
                  ),
                  const SizedBox(height: BasketSpace.lg),
                  for (var i = 0; i < BasketCatalog.trackingSteps.length; i++)
                    _TimelineStep(
                      title: BasketCatalog.trackingSteps[i].title,
                      sub: _timelineSub(i, stage, order),
                      done: i < stage || stage == 3,
                      current: i == stage && stage < 3,
                      isLast: i == BasketCatalog.trackingSteps.length - 1,
                      pulse: _pulse,
                    ),
                  const SizedBox(height: BasketSpace.xs),
                  Row(
                    children: [
                      Expanded(
                        child: BasketButton.secondary(
                          label: 'Refresh status',
                          size: BasketButtonSize.medium,
                          onPressed: _poll,
                        ),
                      ),
                      const SizedBox(width: BasketSpace.sm),
                      Expanded(
                        child: BasketButton(
                          label: 'Get help',
                          size: BasketButtonSize.medium,
                          onPressed: cubit.goToSupport,
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

  /// Remaining road distance from the rider's current (animated) spot,
  /// or null when there's no live fix to measure from.
  double? _remainingMeters() {
    final path = _path;
    if (!_hasLiveFix || path == null || !_hasRiderPosition) return null;
    return math.max(0, path.length - _currentDistance);
  }

  int _etaMinutes(int stage) {
    if (stage >= 3) return 0;
    final remaining = _remainingMeters();
    final road = _road;
    if (remaining != null && road != null && road.distanceMeters > 0) {
      final seconds = road.durationSeconds * (remaining / road.distanceMeters);
      return math.max(1, (seconds / 60).ceil());
    }
    if (remaining != null) {
      // Placeholder path — assume ~20 km/h city riding.
      return math.max(1, (remaining / 333).ceil());
    }
    return etaLeftForStage(stage, eta: BasketCubit.etaMinutes);
  }

  String? _distanceLabel(int stage) {
    if (stage != 2) return null;
    final remaining = _remainingMeters();
    if (remaining == null) return null;
    return remaining < 1000
        ? '${(remaining / 10).round() * 10} m away'
        : '${(remaining / 1000).toStringAsFixed(1)} km away';
  }

  String _riderSubtitle(int stage) {
    if (stage == 3) return 'Delivered your order';
    if (stage < 2) return 'Will pick up your order shortly';
    if (_hasLiveFix) return 'On the way · live location';
    return 'On the way';
  }

  String _timelineSub(int i, int stage, ApiOrder? order) {
    final at = switch (i) {
      0 => order?.createdAt,
      1 => order?.packedAt,
      2 => order?.outForDeliveryAt,
      _ => order?.deliveredAt,
    };
    if (i <= stage && at != null) return _clock(at.toLocal());
    if (i == stage) return 'Now';
    return BasketCatalog.trackingSteps[i].sub;
  }

  static String _clock(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m ${t.hour < 12 ? 'AM' : 'PM'}';
  }
}

// ── Sheet pieces ─────────────────────────────────────────────────────

/// Loading state: the real screen's layout — map area, sheet header,
/// progress bar, rider card, timeline — as shimmering bones (same
/// `Skeletonizer` look as home), with a working back button.
class _TrackingSkeleton extends StatelessWidget {
  const _TrackingSkeleton({required this.onBack, required this.pulse});

  final VoidCallback onBack;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    final steps = BasketCatalog.trackingSteps;
    return Stack(
      children: [
        Positioned.fill(
          child: Skeletonizer(
            effect: ShimmerEffect(baseColor: BasketColors.divider, highlightColor: BasketColors.surface),
            child: Column(
              children: [
                const Expanded(child: Bone(width: double.infinity)),
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(color: _cream, borderRadius: BasketRadius.sheet),
                  padding: EdgeInsets.fromLTRB(
                    BasketSpace.gutter,
                    BasketSpace.lg,
                    BasketSpace.gutter,
                    BasketSpace.lg + MediaQuery.paddingOf(context).bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SheetHeader(stage: 0, orderLine: 'ORD-000000 · 3 items', etaMinutes: BasketCubit.etaMinutes, distanceLabel: null),
                      const SizedBox(height: BasketSpace.sm),
                      const _StageProgressBar(stage: 1),
                      const SizedBox(height: BasketSpace.md),
                      const _RiderCard(name: 'Rider name', subtitle: 'Will pick up your order shortly'),
                      const SizedBox(height: BasketSpace.lg),
                      for (var i = 0; i < 2; i++)
                        _TimelineStep(
                          title: steps[i].title,
                          sub: steps[i].sub,
                          done: false,
                          current: false,
                          isLast: i == 1,
                          pulse: pulse,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.paddingOf(context).top + BasketSpace.xs,
          left: BasketSpace.gutter,
          child: InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(BasketRadius.pill),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: BasketColors.ink, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: const Icon(Icons.arrow_back, color: _cream, size: 18),
            ),
          ),
        ),
      ],
    );
  }
}


class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.stage,
    required this.orderLine,
    required this.etaMinutes,
    required this.distanceLabel,
  });

  final int stage;
  final String orderLine;
  final int etaMinutes;
  final String? distanceLabel;

  static const _headlines = [
    'Order confirmed',
    'Packing your basket',
    'Rider is on the way',
    'Delivered — enjoy!',
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0, 0.35),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.centerLeft,
                  children: [...previous, ?current],
                ),
                child: Text(
                  _headlines[stage],
                  key: ValueKey(stage),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              const SizedBox(height: BasketSpace.xxs),
              Text(
                distanceLabel == null
                    ? orderLine
                    : '$distanceLabel · $orderLine',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: BasketColors.muted,
                ),
              ),
            ],
          ),
        ),
        if (stage < 3)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: BasketColors.ink,
              borderRadius: BasketRadius.card,
            ),
            child: Column(
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(end: etaMinutes.toDouble()),
                  duration: const Duration(milliseconds: 600),
                  builder: (context, v, _) => Text(
                    '${v.round()}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      height: 1,
                      fontWeight: FontWeight.w800,
                      color: _cream,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'min',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _cream.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: BasketColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: _cream),
          ),
      ],
    );
  }
}

/// Four segments that fill in as the order advances; the current one
/// shimmers so the screen always shows something is happening.
class _StageProgressBar extends StatelessWidget {
  const _StageProgressBar({required this.stage});

  final int stage;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 4; i++) ...[
          if (i > 0) const SizedBox(width: BasketSpace.xxs),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(BasketRadius.sm),
              child: Container(
                height: 5,
                color: BasketColors.ink.withValues(alpha: 0.1),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(
                    end: i < stage || stage == 3
                        ? 1.0
                        : i == stage
                        ? 0.5
                        : 0.0,
                  ),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) => FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: v,
                    child: Container(color: BasketColors.primary),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _RiderCard extends StatelessWidget {
  const _RiderCard({super.key, required this.name, required this.subtitle});

  final String name;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(BasketSpace.sm),
      decoration: const BoxDecoration(
        color: BasketColors.ink,
        borderRadius: BasketRadius.card,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(BasketRadius.pill),
            child: const SizedBox(
              width: 42,
              height: 42,
              child: ImageSlot(shape: ImageSlotShape.circle, mini: true),
            ),
          ),
          const SizedBox(width: BasketSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _cream,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: _cream.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _cream.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.call_outlined, color: _cream, size: 15),
          ),
        ],
      ),
    );
  }
}

class _AssigningRiderCard extends StatelessWidget {
  const _AssigningRiderCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(BasketSpace.md),
      decoration: basketCard(),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(
            'Assigning a delivery partner…',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.title,
    required this.sub,
    required this.done,
    required this.current,
    required this.isLast,
    required this.pulse,
  });

  final String title;
  final String sub;
  final bool done;
  final bool current;
  final bool isLast;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    final active = done || current;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 400),
      opacity: active ? 1 : 0.45,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (current)
                      AnimatedBuilder(
                        animation: pulse,
                        builder: (context, _) => Container(
                          width: 10 + 8 * pulse.value,
                          height: 10 + 8 * pulse.value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: BasketColors.primary.withValues(
                              alpha: 0.35 * (1 - pulse.value),
                            ),
                          ),
                        ),
                      ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done
                            ? BasketColors.ink
                            : current
                            ? BasketColors.primary
                            : _cream,
                        border: Border.all(
                          color: current
                              ? BasketColors.primary
                              : BasketColors.ink,
                          width: 2,
                        ),
                      ),
                      child: done
                          ? const Icon(Icons.check, size: 7, color: _cream)
                          : null,
                    ),
                  ],
                ),
              ),
              if (!isLast)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: 2,
                  height: 24,
                  color: done
                      ? BasketColors.ink
                      : BasketColors.ink.withValues(alpha: 0.12),
                ),
            ],
          ),
          const SizedBox(width: BasketSpace.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: BasketSpace.sm, top: 1),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    sub,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: current ? FontWeight.w700 : FontWeight.w500,
                      color: current
                          ? BasketColors.primary
                          : BasketColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Map pieces ───────────────────────────────────────────────────────

/// "LIVE" / "Last seen 2m ago" pill in the top bar.
class _LiveChip extends StatelessWidget {
  const _LiveChip({
    required this.tracking,
    required this.live,
    required this.pulse,
  });

  final ApiOrderTracking? tracking;
  final bool live;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    final updated = tracking?.riderLocationUpdatedAt;
    final age = updated == null ? null : DateTime.now().difference(updated);
    final stale = age != null && age > _staleAfter;
    final label = !live
        ? 'Tracking'
        : stale
        ? 'Last seen ${age.inMinutes}m ago'
        : 'Live';
    final dotColor = live && !stale
        ? const Color(0xFF22C55E)
        : BasketColors.faint;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BasketSpace.sm,
        vertical: BasketSpace.xs,
      ),
      decoration: basketCard(radius: BasketRadius.pill, elevated: true),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: AnimatedBuilder(
              animation: pulse,
              builder: (context, _) => Stack(
                alignment: Alignment.center,
                children: [
                  if (live && !stale)
                    Container(
                      width: 6 + 6 * pulse.value,
                      height: 6 + 6 * pulse.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: dotColor.withValues(
                          alpha: 0.4 * (1 - pulse.value),
                        ),
                      ),
                    ),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: dotColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: BasketSpace.xs),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Rider marker: a dark disc with a scooter, plus a heading arrow that
/// rotates smoothly toward the direction of travel.
class _RiderMarker extends StatelessWidget {
  const _RiderMarker({required this.turns});

  final double turns;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.rotate(
          angle: turns * 2 * math.pi,
          child: SizedBox(
            width: 56,
            height: 56,
            child: Align(
              alignment: Alignment.topCenter,
              child: Icon(
                Icons.navigation_rounded,
                size: 16,
                color: BasketColors.primary,
              ),
            ),
          ),
        ),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: BasketColors.ink,
            shape: BoxShape.circle,
            border: Border.all(color: _cream, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: BasketColors.ink.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.two_wheeler_rounded, size: 18, color: _cream),
        ),
      ],
    );
  }
}

/// Delivery point: a home badge with a radar-style pulse ring.
class _PulsingHomePin extends StatelessWidget {
  const _PulsingHomePin({required this.pulse});

  final double pulse;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 24 + 52 * pulse,
          height: 24 + 52 * pulse,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: BasketColors.primary.withValues(alpha: 0.28 * (1 - pulse)),
          ),
        ),
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: BasketColors.primary,
            shape: BoxShape.circle,
            border: Border.all(color: _cream, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: BasketColors.ink.withValues(alpha: 0.2),
                blurRadius: 6,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.home_rounded, size: 15, color: _cream),
        ),
      ],
    );
  }
}

/// A labeled outlined marker for a fixed end of the route (the store).
class _MapPin extends StatelessWidget {
  const _MapPin({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: _cream,
            border: Border.all(color: BasketColors.ink.withValues(alpha: 0.12)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: BasketColors.ink,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _cream,
            border: Border.all(color: BasketColors.ink, width: 2),
            boxShadow: [
              BoxShadow(
                color: BasketColors.ink.withValues(alpha: 0.1),
                blurRadius: 6,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 14, color: BasketColors.ink),
        ),
      ],
    );
  }
}

class _MapControlButton extends StatelessWidget {
  const _MapControlButton({
    required this.icon,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: active ? BasketColors.ink : _cream,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: BasketColors.ink.withValues(alpha: 0.16),
              blurRadius: 6,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: active ? _cream : BasketColors.ink, size: 18),
      ),
    );
  }
}

/// A polyline with cumulative distances, so a position can be expressed as
/// "metres along the route" — which is what the rider animation
/// interpolates.
class _RoutePath {
  _RoutePath(this.points) : cumulative = _cumulative(points);

  final List<LatLng> points;
  final List<double> cumulative;

  double get length => cumulative.last;

  static List<double> _cumulative(List<LatLng> points) {
    const d = Distance();
    final out = <double>[0];
    for (var i = 1; i < points.length; i++) {
      out.add(out.last + d.as(LengthUnit.Meter, points[i - 1], points[i]));
    }
    return out;
  }

  /// Point [distance] metres along the path (clamped to its ends).
  LatLng at(double distance) {
    if (points.length == 1 || distance <= 0) return points.first;
    if (distance >= length) return points.last;
    // Binary search for the segment containing [distance].
    var lo = 0, hi = cumulative.length - 1;
    while (hi - lo > 1) {
      final mid = (lo + hi) >> 1;
      if (cumulative[mid] <= distance) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    final segLen = cumulative[hi] - cumulative[lo];
    final f = segLen == 0 ? 0.0 : (distance - cumulative[lo]) / segLen;
    final a = points[lo], b = points[hi];
    return LatLng(
      a.latitude + (b.latitude - a.latitude) * f,
      a.longitude + (b.longitude - a.longitude) * f,
    );
  }

  /// (covered, remaining) halves of the path, split [distance] metres in.
  (List<LatLng>, List<LatLng>) split(double distance) {
    final p = at(distance);
    var i = 0;
    while (i < cumulative.length - 1 && cumulative[i + 1] <= distance) {
      i++;
    }
    return ([...points.sublist(0, i + 1), p], [p, ...points.sublist(i + 1)]);
  }

  /// Nearest spot on the path to [p]: its distance along the path, and
  /// how far [p] is from it (to detect the rider leaving the route).
  ({double distance, double offMeters}) project(LatLng p) {
    if (points.length == 1) {
      return (
        distance: 0,
        offMeters: const Distance().as(LengthUnit.Meter, p, points.first),
      );
    }
    var best = (distance: 0.0, offMeters: double.infinity);
    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i], b = points[i + 1];
      // Equirectangular approximation — plenty accurate at city scale.
      final k = math.cos(a.latitude * math.pi / 180);
      final dx = (b.longitude - a.longitude) * k;
      final dy = b.latitude - a.latitude;
      final px = (p.longitude - a.longitude) * k;
      final py = p.latitude - a.latitude;
      final len2 = dx * dx + dy * dy;
      final t = len2 == 0 ? 0.0 : ((px * dx + py * dy) / len2).clamp(0.0, 1.0);
      final q = LatLng(
        a.latitude + dy * t,
        a.longitude + (b.longitude - a.longitude) * t,
      );
      final off = const Distance().as(LengthUnit.Meter, p, q);
      if (off < best.offMeters) {
        best = (
          distance: cumulative[i] + (cumulative[i + 1] - cumulative[i]) * t,
          offMeters: off,
        );
      }
    }
    return best;
  }
}
