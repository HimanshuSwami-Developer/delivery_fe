import 'dart:async';

import 'package:fastswipe/core/geo/nominatim_service.dart';
import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:fastswipe/features/basket/presentation/widgets/labeled_field.dart';
import 'package:fastswipe/features/basket/presentation/widgets/osm_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
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
  final _cityController = TextEditingController(text: 'Bengaluru');
  final _stateController = TextEditingController(text: 'Karnataka');
  final _pincodeController = TextEditingController();

  final _mapController = MapController();
  final _geocoder = NominatimService();
  Timer? _geocodeDebounce;

  LatLng _pinLocation = _defaultCenter;
  String _resolvedAddress = '4th Block, Koramangala, Bengaluru 560034';
  bool _locating = false;

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
      if (!await Geolocator.isLocationServiceEnabled()) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      final here = LatLng(position.latitude, position.longitude);
      _mapController.move(here, 16);
      setState(() => _pinLocation = here);
      await _resolveAddress(here);
    } catch (_) {
      // Best-effort — the user can still drag the pin manually.
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketCubit>();
    final phone = context.select((BasketCubit c) => c.state.phone);
    final newTag = context.select((BasketCubit c) => c.state.newAddressTag);
    final saving = context.select((BasketCubit c) => c.state.addressSaving);
    final formError = context.select((BasketCubit c) => c.state.addressFormError);
    final phoneLabel = phone.isEmpty ? '98765 43210' : phone;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 250,
          child: Stack(
            children: [
              Positioned.fill(
                child: OsmMap(
                  center: _pinLocation,
                  mapController: _mapController,
                  onPositionChanged: _onMapMoved,
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: BasketColors.ink, borderRadius: BorderRadius.circular(9)),
                      child: Text('Drag to set pin', style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.white)),
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
              Positioned(
                right: 14,
                bottom: 14,
                child: InkWell(
                  onTap: _locating ? null : _useMyLocation,
                  borderRadius: BorderRadius.circular(11),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      border: Border.all(color: BasketColors.ink.withValues(alpha: 0.1)),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: _locating
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 1.5),
                          )
                        : Text('◎ Use my location', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700)),
                  ),
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
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ListView(
                children: [
                  Text('Add address details', style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
                  const SizedBox(height: 5),
                  Text(_resolvedAddress, style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w500, color: BasketColors.muted)),
                  const SizedBox(height: 16),
                  LabeledTextField(
                    label: 'Flat / House no.',
                    controller: _houseNoController,
                    hintText: '302, Sunrise Residency',
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 10),
                  LabeledTextField(
                    label: 'Landmark',
                    controller: _landmarkController,
                    hintText: 'Near Forum Mall',
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: LabeledTextField(
                          label: 'City',
                          controller: _cityController,
                          textCapitalization: TextCapitalization.words,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: LabeledTextField(
                          label: 'State',
                          controller: _stateController,
                          textCapitalization: TextCapitalization.words,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  LabeledTextField(
                    label: 'Pincode',
                    controller: _pincodeController,
                    hintText: '560034',
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                  ),
                  const SizedBox(height: 10),
                  LabeledStaticField(label: 'Receiver', value: 'Aarav · +91 $phoneLabel'),
                  const SizedBox(height: 18),
                  Text('Save as', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      for (final tag in _tags) ...[
                        _TagPill(label: tag, selected: newTag == tag, onTap: () => cubit.setNewAddressTag(tag)),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                  if (formError != null) ...[
                    const SizedBox(height: 14),
                    Text(formError, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFC0392B))),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: BasketColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: saving
                          ? null
                          : () => cubit.submitNewAddress(
                                houseNo: _houseNoController.text,
                                landmark: _landmarkController.text,
                                city: _cityController.text,
                                stateName: _stateController.text,
                                pincode: _pincodeController.text,
                              ),
                      child: saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                            )
                          : Text('Save address', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                  ),
                ],
              ),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: style.bg,
          border: Border.all(color: style.border),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: style.fg)),
      ),
    );
  }
}
