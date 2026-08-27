import 'package:fastswipe/core/api/api_exception.dart';
import 'package:fastswipe/core/basket_api/models/delivery_models.dart';
import 'package:fastswipe/features/basket_admin/cubit/basket_admin_cubit.dart';
import 'package:fastswipe/features/basket_admin/presentation/widgets/admin_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const _kVehicles = {'bike': 'Motorbike', 'scooter': 'Scooter', 'bicycle': 'Bicycle'};
const _kStatuses = {'available': 'Available', 'on_trip': 'On trip', 'off_duty': 'Off duty'};

/// Add/edit delivery partner — [BasketAdminState.editingPartner] (read once
/// at `initState`) says which mode: null seeds a blank form and calls
/// `createPartner`, non-null seeds every field from that partner and calls
/// `updatePartner`. Mobile number provisions the underlying account on
/// create (see `DeliveryPartnerWriteSerializer.create`), so it's locked
/// once a partner already exists — changing it there wouldn't do anything
/// server-side.
class PartnerFormModal extends StatefulWidget {
  const PartnerFormModal({super.key});

  @override
  State<PartnerFormModal> createState() => _PartnerFormModalState();
}

class _PartnerFormModalState extends State<PartnerFormModal> {
  late final ApiDeliveryPartner? _editing = context.read<BasketAdminCubit>().state.editingPartner;

  late final _mobile = TextEditingController(text: _editing?.mobileNumber ?? '');
  late final _partnerCode = TextEditingController(text: _editing?.partnerCode ?? '');
  late final _name = TextEditingController(text: _editing?.name ?? '');
  late final _photoUrl = TextEditingController();

  late String _vehicle = _editing?.vehicle ?? 'bike';
  late String _status = _editing?.status ?? 'off_duty';
  int? _zoneId;
  bool _zoneInitialized = false;

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _mobile.dispose();
    _partnerCode.dispose();
    _name.dispose();
    _photoUrl.dispose();
    super.dispose();
  }

  Future<void> _submit(BasketAdminCubit cubit) async {
    final mobile = _mobile.text.trim();
    final partnerCode = _partnerCode.text.trim();
    final name = _name.text.trim();
    if (_editing == null && mobile.isEmpty) {
      setState(() => _error = 'Mobile number is required.');
      return;
    }
    if (partnerCode.isEmpty || name.isEmpty) {
      setState(() => _error = 'Partner code and name are required.');
      return;
    }
    if (_zoneId == null) {
      setState(() => _error = 'Pick a zone.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = {
        'partner_code': partnerCode,
        'name': name,
        'vehicle': _vehicle,
        'zone': _zoneId,
        'status': _status,
        if (_photoUrl.text.trim().isNotEmpty) 'photo_url': _photoUrl.text.trim(),
      };
      if (_editing == null) {
        await cubit.createPartner({...data, 'mobile_number': mobile});
      } else {
        await cubit.updatePartner(_editing.id, data);
      }
      if (mounted) cubit.closeModal();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketAdminCubit>();
    final zones = context.select((BasketAdminCubit c) => c.state.apiZones);

    // Zone list loads async — seed [_zoneId] from the partner being edited
    // (or the single store's zone) the first time it's non-empty.
    if (!_zoneInitialized && zones.isNotEmpty) {
      _zoneId = _editing?.zoneId ?? zones.first.id;
      _zoneInitialized = true;
    }

    return AdminFormModal(
      title: _editing == null ? 'Add delivery partner' : 'Edit ${_editing.name}',
      subtitle: _editing == null
          ? 'Provisions a delivery-role account on this mobile number — they sign in later via the normal OTP flow.'
          : 'Partner code: ${_editing.partnerCode}',
      loading: _loading,
      error: _error,
      onCancel: cubit.closeModal,
      onSubmit: zones.isEmpty ? null : () => _submit(cubit),
      submitLabel: _editing == null ? 'Add partner' : 'Save changes',
      fields: [
        AdminEditField(
          label: 'Mobile number',
          controller: _mobile,
          hint: '+91XXXXXXXXXX',
          keyboardType: TextInputType.phone,
          enabled: _editing == null,
        ),
        AdminEditField(label: 'Partner code', controller: _partnerCode, hint: 'BSK-DP-2210'),
        AdminEditField(label: 'Name', controller: _name, hint: 'Ravi Kumar'),
        // No zone picker — there's a single store, so [_zoneId] is just
        // auto-seeded from it above rather than asked of the admin.
        AdminEditDropdown<String>(
          label: 'Vehicle',
          value: _vehicle,
          items: _kVehicles.keys.toList(),
          itemLabel: (key) => _kVehicles[key]!,
          onChanged: (v) => setState(() => _vehicle = v ?? _vehicle),
        ),
        AdminEditDropdown<String>(
          label: 'Status',
          value: _status,
          items: _kStatuses.keys.toList(),
          itemLabel: (key) => _kStatuses[key]!,
          onChanged: (v) => setState(() => _status = v ?? _status),
        ),
        AdminEditField(label: 'Photo URL (optional)', controller: _photoUrl, hint: 'https://...'),
      ],
    );
  }
}
