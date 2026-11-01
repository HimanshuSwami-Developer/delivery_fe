import 'dart:async';

import 'package:fastswipe/core/geo/nominatim_service.dart';
import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/cubit/basket_selectors.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:fastswipe/features/basket/presentation/basket_ui.dart';
import 'package:fastswipe/features/basket/presentation/widgets/labeled_field.dart';
import 'package:fastswipe/features/basket/presentation/widgets/app_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

const _tags = ['Home', 'Work', 'Other'];

/// Koramangala, Bengaluru — a reasonable default center until the user
/// drags the pin or taps "Use my location".
const _defaultCenter = LatLng(12.9352, 77.6146);

class AddressEditView extends StatefulWidget {
  const AddressEditView({super.key});

  @override
  State<AddressEditView> createState() => _AddressEditViewState();
}

class _AddressEditViewState extends State<AddressEditView> {
  final _houseNoController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();

  final _mapController = AppMapController();
  final _geocoder = NominatimService();
  Timer? _geocodeDebounce;

  LatLng _pinLocation = _defaultCenter;
  String _resolvedAddress = 'Move the pin to your delivery location';
  bool _locating = false;

  /// Mirrors [BasketState.editingAddressId] at the time the form opened.
  String? _editingId;

  bool get _isEditingSaved => _editingId != null && _editingId != kGpsAddressId;

  @override
  void initState() {
    super.initState();
    final s = context.read<BasketCubit>().state;
    _editingId = s.editingAddressId;
    final draft = s.gpsDraft;
    final gpsPoint = draft?.latitude != null && draft?.longitude != null
        ? LatLng(draft!.latitude!, draft.longitude!)
        : null;

    if (_isEditingSaved) {
      final a = s.apiAddresses.where((a) => a.id == _editingId).firstOrNull;
      if (a != null) {
        _houseNoController.text = a.addressLine1;
        _landmarkController.text = a.addressLine2 ?? '';
        _cityController.text = a.city;
        _stateController.text = a.state;
        _pincodeController.text = a.pincode;
        _resolvedAddress = [a.addressLine1, a.addressLine2 ?? '', a.city, a.state, a.pincode]
            .where((p) => p.isNotEmpty)
            .join(', ');
        if (a.latitude != null && a.longitude != null) {
          _pinLocation = LatLng(a.latitude!, a.longitude!);
        } else if (gpsPoint != null) {
          _pinLocation = gpsPoint;
        }
      }
      return;
    }

    if (_editingId == kGpsAddressId && draft != null && gpsPoint != null) {
      // Saving the live location: pin sits on the exact GPS fix and the
      // geocoded street goes in Landmark — the customer adds flat no.
      _pinLocation = gpsPoint;
      _landmarkController.text = draft.addressLine1;
      _cityController.text = draft.city;
      _stateController.text = draft.state;
      _pincodeController.text = draft.pincode;
      _resolvedAddress = s.gpsAddress ?? draft.addressLine1;
      return;
    }

    // Brand-new address: start at the device's exact location.
    if (gpsPoint != null) {
      _pinLocation = gpsPoint;
      _resolveAddress(gpsPoint);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _useMyLocation();
      });
    }
  }

  @override
  void dispose() {
    _houseNoController.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _geocodeDebounce?.cancel();
    super.dispose();
  }

  void _onMapMoved(LatLng center) {
    _pinLocation = center;
    _geocodeDebounce?.cancel();
    // Nominatim's usage policy caps lookups at ~1/sec — only resolve once
    // the pin has settled, not on every drag frame.
    _geocodeDebounce = Timer(const Duration(milliseconds: 700), () => _resolveAddress(center));
  }

  Future<void> _resolveAddress(LatLng point) async {
    final result = await _geocoder.reverseGeocode(point);
    if (result == null || !mounted) return;
    setState(() {
      if (result.displayName.isNotEmpty) _resolvedAddress = result.displayName;
      if (result.city.isNotEmpty) _cityController.text = result.city;
      if (result.state.isNotEmpty) _stateController.text = result.state;
      if (result.postcode.isNotEmpty) _pincodeController.text = result.postcode;
    });
  }

  Future<void> _useMyLocation() async {
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _toast('Turn on location services to use your current location.');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        _toast('Location permission is needed to fetch your exact location.');
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.best, timeLimit: Duration(seconds: 15)),
      );
      final here = LatLng(position.latitude, position.longitude);
      await _mapController.move(here, 17);
      setState(() => _pinLocation = here);
      await _resolveAddress(here);
    } catch (_) {
      _toast('Could not get your location — drag the pin instead.');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketCubit>();
    final phone = context.select((BasketCubit c) => c.state.phone);
    final newTag = context.select((BasketCubit c) => c.state.newAddressTag);
    final saving = context.select((BasketCubit c) => c.state.addressSaving);
    final formError = context.select((BasketCubit c) => c.state.addressFormError);
    final name = context.select((BasketCubit c) => c.state.name);

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 250,
          child: Stack(
            children: [
              Positioned.fill(
                child: AppMap(
                  center: _pinLocation,
                  zoom: 17,
                  mapController: _mapController,
                  gestureMovesOnly: true,
                  onPositionChanged: _onMapMoved,
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: BasketSpace.sm, vertical: 6),
                      decoration: BoxDecoration(color: BasketColors.ink, borderRadius: BorderRadius.circular(BasketRadius.sm)),
                      child: Text('Drag to set pin', style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFFFFFBF2))),
                    ),
                    Container(width: 2, height: 16, color: BasketColors.ink),
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: BasketColors.ink,
                        boxShadow: [BoxShadow(color: BasketColors.ink.withValues(alpha: 0.16), blurRadius: 0, spreadRadius: 6)],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: MediaQuery.paddingOf(context).top + BasketSpace.xs,
                left: BasketSpace.gutter,
                child: InkWell(
                  onTap: cubit.back,
                  borderRadius: BorderRadius.circular(BasketRadius.pill),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(color: BasketColors.ink, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: const Icon(Icons.arrow_back, color: Color(0xFFFFFBF2), size: 16),
                  ),
                ),
              ),
              Positioned(
                right: BasketSpace.gutter,
                // Clears the 20px the details panel below overlaps the map by.
                bottom: BasketSpace.xxl,
                child: BasketButton.secondary(
                  label: '◎ Use my location',
                  size: BasketButtonSize.small,
                  expand: false,
                  loading: _locating,
                  onPressed: _useMyLocation,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Transform.translate(
            offset: const Offset(0, -20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(BasketSpace.gutter, BasketSpace.md, BasketSpace.gutter, BasketSpace.lg),
              decoration: BoxDecoration(
                color: Color(0xFFFFFBF2).withValues(alpha: 0.85),
                borderRadius: BasketRadius.sheet,
              ),
              child: ListView(
                children: [
                  Text(_isEditingSaved ? 'Edit address' : 'Add address details', style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
                  const SizedBox(height: BasketSpace.xxs),
                  Text(_resolvedAddress, style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w500, color: BasketColors.muted)),
                  const SizedBox(height: BasketSpace.md),
                  LabeledTextField(
                    label: 'Flat / House no.',
                    controller: _houseNoController,
                    hintText: 'Enter flat / house no. (e.g. 302, Green Apartments)',
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: BasketSpace.md),
                  LabeledTextField(
                    label: 'Landmark',
                    controller: _landmarkController,
                    hintText: 'Enter a nearby landmark (e.g. Near City Mall)',
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: BasketSpace.md),
                  Row(
                    children: [
                      Expanded(
                        child: LabeledTextField(
                          label: 'City',
                          controller: _cityController,
                          hintText: 'Enter city (e.g. Pune)',
                          textCapitalization: TextCapitalization.words,
                        ),
                      ),
                      const SizedBox(width: BasketSpace.sm),
                      Expanded(
                        child: LabeledTextField(
                          label: 'State',
                          controller: _stateController,
                          hintText: 'Enter state (e.g. Maharashtra)',
                          textCapitalization: TextCapitalization.words,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: BasketSpace.md),
                  LabeledTextField(
                    label: 'Pincode',
                    controller: _pincodeController,
                    hintText: 'Enter pincode (e.g. 411001)',
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                  ),
                  const SizedBox(height: BasketSpace.md),
                  LabeledStaticField(label: 'Receiver', value: [if (name.isNotEmpty) name, if (phone.isNotEmpty) '+91 $phone'].join(' · ')),
                  const SizedBox(height: BasketSpace.lg),
                  Text('Save as', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: BasketSpace.xs),
                  Row(
                    children: [
                      for (final tag in _tags) ...[
                        _TagPill(label: tag, selected: newTag == tag, onTap: () => cubit.setNewAddressTag(tag)),
                        const SizedBox(width: BasketSpace.xs),
                      ],
                    ],
                  ),
                  if (formError != null) ...[
                    const SizedBox(height: BasketSpace.sm),
                    Text(formError, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFC0392B))),
                  ],
                ],
              ),
            ),
          ),
        ),
        BasketBottomBar(
          child: BasketButton(
            label: _isEditingSaved ? 'Update address' : 'Save address',
            loading: saving,
            onPressed: saving
                ? null
                : () => cubit.submitNewAddress(
                      houseNo: _houseNoController.text,
                      landmark: _landmarkController.text,
                      city: _cityController.text,
                      stateName: _stateController.text,
                      pincode: _pincodeController.text,
                      latitude: _pinLocation.latitude,
                      longitude: _pinLocation.longitude,
                    ),
          ),
        ),
      ],
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = pillStyle(selected);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: BasketSpace.md, vertical: BasketSpace.xs),
        decoration: BoxDecoration(
          color: style.bg,
          border: Border.all(color: style.border),
          borderRadius: BorderRadius.circular(BasketRadius.pill),
        ),
        child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: style.fg)),
      ),
    );
  }
}
