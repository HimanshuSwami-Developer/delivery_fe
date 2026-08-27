import 'package:fastswipe/core/api/api_exception.dart';
import 'package:fastswipe/core/basket_api/models/catalog_models.dart';
import 'package:fastswipe/core/basket_api/models/promotion_models.dart';
import 'package:fastswipe/features/basket_admin/cubit/basket_admin_cubit.dart';
import 'package:fastswipe/features/basket_admin/presentation/widgets/admin_common.dart';
import 'package:fastswipe/features/basket_admin/presentation/widgets/admin_image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The simple "one card's worth of fields" add/edit forms — category,
/// zone, coupon, banner — each a thin [AdminFormModal] wrapper around its
/// own local controllers and a direct call into [BasketAdminCubit]'s
/// create/update method. (Delivery partner has its own file since it
/// carries a bit more state — a zone dropdown fed by a separate fetch.)

class AddCategoryModal extends StatefulWidget {
  const AddCategoryModal({super.key});

  @override
  State<AddCategoryModal> createState() => _AddCategoryModalState();
}

class _AddCategoryModalState extends State<AddCategoryModal> {
  late final ApiCategory? _editing = context.read<BasketAdminCubit>().state.editingCategory;

  late final _key = TextEditingController(text: _editing?.key ?? '');
  late final _name = TextEditingController(text: _editing?.name ?? '');
  late String _imageUrl = _editing?.imageUrl ?? '';
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _key.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit(BasketAdminCubit cubit) async {
    final name = _name.text.trim();
    if ((_editing == null && _key.text.trim().isEmpty) || name.isEmpty) {
      setState(() => _error = 'Key and name are required.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_editing == null) {
        await cubit.createCategory({'key': _key.text.trim(), 'name': name, 'image_url': _imageUrl});
      } else {
        await cubit.updateCategory(_editing.key, {'name': name, 'image_url': _imageUrl});
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
    return AdminFormModal(
      title: _editing == null ? 'Add category' : 'Edit ${_editing.name}',
      subtitle: 'Shows up as a tab on the Products page and in the customer app.',
      loading: _loading,
      error: _error,
      onCancel: cubit.closeModal,
      onSubmit: () => _submit(cubit),
      submitLabel: _editing == null ? 'Add category' : 'Save changes',
      fields: [
        AdminEditField(
          label: 'Key',
          controller: _key,
          hint: 'e.g. atta-rice-dal',
          // The key is the URL lookup for this category (and what
          // products/banners reference) — changing it after creation
          // would silently break those links, so it's locked once set.
          enabled: _editing == null,
          inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
        ),
        AdminEditField(label: 'Name', controller: _name, hint: 'Atta, Rice & Dal'),
        AdminImagePicker(imageUrl: _imageUrl, onChanged: (url) => setState(() => _imageUrl = url)),
      ],
    );
  }
}

class AddZoneModal extends StatefulWidget {
  const AddZoneModal({super.key});

  @override
  State<AddZoneModal> createState() => _AddZoneModalState();
}

class _AddZoneModalState extends State<AddZoneModal> {
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _pincodes = TextEditingController();
  final _eta = TextEditingController(text: '12');
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _pincodes.dispose();
    _eta.dispose();
    super.dispose();
  }

  Future<void> _submit(BasketAdminCubit cubit) async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Name is required.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final pincodes = _pincodes.text.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
      await cubit.createZone({
        'name': name,
        'address': _address.text.trim(),
        'pincodes': pincodes,
        'avg_eta_minutes': int.tryParse(_eta.text.trim()) ?? 12,
      });
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
    return AdminFormModal(
      title: 'Set up your store',
      subtitle: 'The single dark store the inventory page and delivery flow target.',
      loading: _loading,
      error: _error,
      onCancel: cubit.closeModal,
      onSubmit: () => _submit(cubit),
      submitLabel: 'Save store',
      fields: [
        AdminEditField(label: 'Name', controller: _name, hint: 'Koramangala dark store'),
        AdminEditField(label: 'Address (optional)', controller: _address, hint: '4th Block, Koramangala'),
        AdminEditField(label: 'Pincodes (comma-separated, optional)', controller: _pincodes, hint: '560034, 560095'),
        AdminEditField(label: 'Avg ETA (minutes)', controller: _eta, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
      ],
    );
  }
}

class AddCouponModal extends StatefulWidget {
  const AddCouponModal({super.key});

  @override
  State<AddCouponModal> createState() => _AddCouponModalState();
}

class _AddCouponModalState extends State<AddCouponModal> {
  late final ApiCoupon? _editing = context.read<BasketAdminCubit>().state.editingCoupon;

  late final _code = TextEditingController(text: _editing?.code ?? '');
  late final _title = TextEditingController(text: _editing?.title ?? '');
  late final _minOrder = TextEditingController(text: '${_editing?.minOrderValue ?? 0}');
  late final _flatDiscount = TextEditingController(text: _editing?.flatDiscount?.toString() ?? '');
  late final _percentDiscount = TextEditingController(text: _editing?.percentDiscount?.toString() ?? '');
  late final _maxDiscount = TextEditingController(text: _editing?.maxDiscount?.toString() ?? '');
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    _title.dispose();
    _minOrder.dispose();
    _flatDiscount.dispose();
    _percentDiscount.dispose();
    _maxDiscount.dispose();
    super.dispose();
  }

  Future<void> _submit(BasketAdminCubit cubit) async {
    final code = _code.text.trim().toUpperCase();
    final title = _title.text.trim();
    if (code.isEmpty || title.isEmpty) {
      setState(() => _error = 'Code and title are required.');
      return;
    }
    if (_flatDiscount.text.trim().isEmpty && _percentDiscount.text.trim().isEmpty) {
      setState(() => _error = 'Set either a flat or a percent discount.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = {
        'title': title,
        'min_order_value': int.tryParse(_minOrder.text.trim()) ?? 0,
        'flat_discount': _flatDiscount.text.trim().isEmpty ? null : int.tryParse(_flatDiscount.text.trim()),
        'percent_discount': _percentDiscount.text.trim().isEmpty ? null : int.tryParse(_percentDiscount.text.trim()),
        'max_discount': _maxDiscount.text.trim().isEmpty ? null : int.tryParse(_maxDiscount.text.trim()),
      };
      if (_editing == null) {
        await cubit.createCoupon({'code': code, ...data});
      } else {
        await cubit.updateCoupon(_editing.code, data);
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
    return AdminFormModal(
      title: _editing == null ? 'New coupon' : 'Edit ${_editing.code}',
      subtitle: _editing == null
          ? 'Goes live immediately — customers can redeem it as soon as it\'s created.'
          : 'Changes apply immediately to a coupon that\'s already live.',
      loading: _loading,
      error: _error,
      onCancel: cubit.closeModal,
      onSubmit: () => _submit(cubit),
      submitLabel: _editing == null ? 'Create coupon' : 'Save changes',
      fields: [
        AdminEditField(
          label: 'Code',
          controller: _code,
          hint: 'FIRST50',
          // Code is the URL lookup for this coupon — changing it after
          // creation would break the link, so it's locked once set.
          enabled: _editing == null,
          inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
        ),
        AdminEditField(label: 'Title', controller: _title, hint: '50% off your first order'),
        AdminEditField(label: 'Min order value (₹)', controller: _minOrder, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
        AdminEditField(label: 'Flat discount (₹, or leave blank)', controller: _flatDiscount, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
        AdminEditField(label: 'Percent discount (0-100, or leave blank)', controller: _percentDiscount, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
        AdminEditField(label: 'Max discount cap (₹, optional)', controller: _maxDiscount, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
      ],
    );
  }
}

const _kBannerPlacements = {
  'home_carousel': 'Home carousel',
  'category_strip': 'Category strip',
  'profile': 'Profile',
};

class AddBannerModal extends StatefulWidget {
  const AddBannerModal({super.key});

  @override
  State<AddBannerModal> createState() => _AddBannerModalState();
}

class _AddBannerModalState extends State<AddBannerModal> {
  late final ApiBanner? _editing = context.read<BasketAdminCubit>().state.editingBanner;

  late final _title = TextEditingController(text: _editing?.title ?? '');
  late final _linkScreen = TextEditingController(text: _editing?.linkScreen ?? '');
  late String _imageUrl = _editing?.imageUrl ?? '';
  late String _placement = _editing?.placement ?? 'home_carousel';
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _linkScreen.dispose();
    super.dispose();
  }

  Future<void> _submit(BasketAdminCubit cubit) async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Title is required.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = {
        'title': title,
        'image_url': _imageUrl,
        'placement': _placement,
        'link_screen': _linkScreen.text.trim(),
      };
      if (_editing == null) {
        await cubit.createBanner(data);
      } else {
        await cubit.updateBanner(_editing.id, data);
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
    return AdminFormModal(
      title: _editing == null ? 'New banner' : 'Edit ${_editing.title}',
      subtitle: _editing == null
          ? 'Goes live immediately in the placement you pick below.'
          : 'Changes apply immediately to a banner that\'s already live.',
      loading: _loading,
      error: _error,
      onCancel: cubit.closeModal,
      onSubmit: () => _submit(cubit),
      submitLabel: _editing == null ? 'Create banner' : 'Save changes',
      fields: [
        AdminEditField(label: 'Title', controller: _title, hint: 'Fresh fruit, up to 30% off'),
        AdminImagePicker(imageUrl: _imageUrl, onChanged: (url) => setState(() => _imageUrl = url)),
        AdminEditDropdown<String>(
          label: 'Placement',
          value: _placement,
          items: _kBannerPlacements.keys.toList(),
          itemLabel: (key) => _kBannerPlacements[key]!,
          onChanged: (v) => setState(() => _placement = v ?? _placement),
        ),
        AdminEditField(label: 'Link screen (optional)', controller: _linkScreen, hint: 'category_list'),
      ],
    );
  }
}
