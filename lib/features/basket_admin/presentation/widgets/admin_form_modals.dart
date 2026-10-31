import 'package:fastswipe/core/api/api_exception.dart';
import 'package:fastswipe/core/basket_api/models/catalog_models.dart';
import 'package:fastswipe/core/basket_api/models/promotion_models.dart';
import 'package:fastswipe/features/basket_admin/cubit/basket_admin_cubit.dart';
import 'package:fastswipe/features/basket_admin/presentation/admin_ui.dart';
import 'package:fastswipe/features/basket_admin/presentation/basket_admin_style.dart';
import 'package:fastswipe/features/basket_admin/presentation/widgets/admin_common.dart';
import 'package:fastswipe/features/basket_admin/presentation/widgets/admin_image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

/// The simple "one card's worth of fields" add/edit forms — category,
/// coupon, banner — each a thin [AdminFormModal] wrapper around its own
/// local controllers and a direct call into [BasketAdminCubit]'s
/// create/update method. (Delivery partner has its own file since it
/// carries a bit more state.)

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
          hint: 'Enter slug (e.g. atta-rice-dal)',
          // The key is the URL lookup for this category (and what
          // products/banners reference) — changing it after creation
          // would silently break those links, so it's locked once set.
          enabled: _editing == null,
          inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
        ),
        AdminEditField(label: 'Name', controller: _name, hint: 'Enter category name (e.g. Atta, Rice & Dal)'),
        AdminImagePicker(imageUrl: _imageUrl, onChanged: (url) => setState(() => _imageUrl = url)),
      ],
    );
  }
}

class AddSubcategoryModal extends StatefulWidget {
  const AddSubcategoryModal({super.key});

  @override
  State<AddSubcategoryModal> createState() => _AddSubcategoryModalState();
}

class _AddSubcategoryModalState extends State<AddSubcategoryModal> {
  late final ApiSubcategory? _editing = context.read<BasketAdminCubit>().state.editingSubcategory;
  late final ApiCategory? _category = context.read<BasketAdminCubit>().state.addSubcategoryCategory;

  late final _name = TextEditingController(text: _editing?.name ?? '');
  late String _imageUrl = _editing?.imageUrl ?? '';
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit(BasketAdminCubit cubit) async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Name is required.');
      return;
    }
    if (_category == null) {
      setState(() => _error = 'No category selected.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_editing == null) {
        await cubit.createSubcategory({'category': _category.id, 'name': name, 'image_url': _imageUrl});
      } else {
        await cubit.updateSubcategory(_editing.id, {'name': name, 'image_url': _imageUrl});
      }
      if (mounted) cubit.closeModal();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete(BasketAdminCubit cubit) async {
    final editing = _editing;
    if (editing == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete "${editing.name}"?', style: GoogleFonts.manrope(fontWeight: FontWeight.w800)),
        content: Text('This can\'t be undone.', style: GoogleFonts.manrope(fontSize: 13)),
        actions: [
          AdminButton.secondary(label: 'Cancel', onPressed: () => Navigator.of(dialogContext).pop(false)),
          AdminButton(label: 'Delete', variant: AdminButtonVariant.danger, onPressed: () => Navigator.of(dialogContext).pop(true)),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await cubit.deleteSubcategory(editing.id);
      if (mounted) cubit.closeModal();
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketAdminCubit>();
    return AdminFormModal(
      title: _editing == null ? 'Add subcategory' : 'Edit ${_editing.name}',
      subtitle: _category == null
          ? 'Lets products be grouped one level deeper than the category.'
          : 'In ${_category.name} — lets products be grouped one level deeper than the category.',
      loading: _loading,
      error: _error,
      onCancel: cubit.closeModal,
      onSubmit: () => _submit(cubit),
      submitLabel: _editing == null ? 'Add subcategory' : 'Save changes',
      fields: [
        AdminEditField(label: 'Name', controller: _name, hint: 'Enter subcategory name (e.g. Fresh Vegetables)'),
        AdminImagePicker(imageUrl: _imageUrl, onChanged: (url) => setState(() => _imageUrl = url)),
        if (_editing != null)
          // Aligned so the ListView's tight width doesn't stretch it full-width.
          Align(
            alignment: Alignment.centerLeft,
            child: AdminButton(
              label: 'Delete subcategory',
              variant: AdminButtonVariant.danger,
              size: AdminButtonSize.small,
              onPressed: _loading ? null : () => _delete(cubit),
            ),
          ),
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
          hint: 'Enter coupon code (e.g. FIRST50)',
          // Code is the URL lookup for this coupon — changing it after
          // creation would break the link, so it's locked once set.
          enabled: _editing == null,
          inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
        ),
        AdminEditField(label: 'Title', controller: _title, hint: 'Enter coupon title (e.g. 50% off your first order)'),
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
        AdminEditField(label: 'Title', controller: _title, hint: 'Enter banner title (e.g. Fresh fruit, up to 30% off)'),
        AdminImagePicker(imageUrl: _imageUrl, onChanged: (url) => setState(() => _imageUrl = url)),
        AdminEditDropdown<String>(
          label: 'Placement',
          value: _placement,
          items: _kBannerPlacements.keys.toList(),
          itemLabel: (key) => _kBannerPlacements[key]!,
          onChanged: (v) => setState(() => _placement = v ?? _placement),
        ),
        AdminEditField(label: 'Link screen (optional)', controller: _linkScreen, hint: 'Enter screen name (e.g. category_list)'),
      ],
    );
  }
}

const _kFestivalOverrideModes = {'auto': 'Auto — by date', 'force_on': 'Always on', 'force_off': 'Always off'};
const _kFestivalMotifs = {
  'diyaLights': 'Diya / string lights',
  'colorSplash': 'Colour splash',
  'snowfall': 'Snowfall',
  'confetti': 'Confetti',
};

Color? _hexOrNull(String hex) {
  final cleaned = hex.replaceFirst('#', '').trim();
  if (cleaned.length != 6) return null;
  final value = int.tryParse('FF$cleaned', radix: 16);
  return value == null ? null : Color(value);
}

/// A hex-code [AdminEditField] with a live colour swatch next to it —
/// this console's stand-in for a full colour-picker (kept text-based,
/// consistent with every other field here) while still giving the admin
/// visual feedback on what they typed.
class _AdminColorField extends StatelessWidget {
  const _AdminColorField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: AdminEditField(
            label: label,
            controller: controller,
            hint: '#RRGGBB',
            inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
          ),
        ),
        const SizedBox(width: AdminSpace.xs),
        Padding(
          padding: const EdgeInsets.only(bottom: AdminSpace.xxs),
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) => Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _hexOrNull(controller.text) ?? AdminColors.faint,
                shape: BoxShape.circle,
                border: Border.all(color: AdminSurface.borderStrong),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Edit form for one festival's home-header theme — colours, motif,
/// greeting/popup text, and the auto/on/off override. Always editing an
/// existing row (every festival is seeded server-side; there's no "create
/// new" here) — see `AdminFestivalSettingsView`.
class EditFestivalSettingModal extends StatefulWidget {
  const EditFestivalSettingModal({super.key});

  @override
  State<EditFestivalSettingModal> createState() => _EditFestivalSettingModalState();
}

class _EditFestivalSettingModalState extends State<EditFestivalSettingModal> {
  late final ApiFestivalSetting _editing = context.read<BasketAdminCubit>().state.editingFestivalSetting!;

  late String _overrideMode = _editing.overrideMode;
  late String _motif = _editing.motif;
  late bool _popupEnabled = _editing.popupEnabled;
  late final _startsOn = TextEditingController(text: _editing.startsOn != null ? _fmt(_editing.startsOn!) : '');
  late final _endsOn = TextEditingController(text: _editing.endsOn != null ? _fmt(_editing.endsOn!) : '');
  late final _accent = TextEditingController(text: _editing.accentColor);
  late final _gradientStart = TextEditingController(text: _editing.gradientStart);
  late final _gradientEnd = TextEditingController(text: _editing.gradientEnd);
  late final _greeting = TextEditingController(text: _editing.greetingText);
  late final _popupTitle = TextEditingController(text: _editing.popupTitle);
  late final _popupMessage = TextEditingController(text: _editing.popupMessage);
  bool _loading = false;
  String? _error;

  static String _fmt(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _startsOn.dispose();
    _endsOn.dispose();
    _accent.dispose();
    _gradientStart.dispose();
    _gradientEnd.dispose();
    _greeting.dispose();
    _popupTitle.dispose();
    _popupMessage.dispose();
    super.dispose();
  }

  /// `null` for a blank field, a parsed date for a valid `yyyy-mm-dd`, or
  /// throws [FormatException] (caught by [_submit]) for anything else.
  DateTime? _parseDate(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    return DateTime.parse(trimmed);
  }

  Future<void> _submit(BasketAdminCubit cubit) async {
    if (_accent.text.trim().isEmpty || _gradientStart.text.trim().isEmpty || _gradientEnd.text.trim().isEmpty) {
      setState(() => _error = 'All three colours are required.');
      return;
    }
    DateTime? startsOn;
    DateTime? endsOn;
    try {
      startsOn = _parseDate(_startsOn.text);
      endsOn = _parseDate(_endsOn.text);
    } on FormatException {
      setState(() => _error = 'Dates must be yyyy-mm-dd, e.g. 2026-11-06.');
      return;
    }
    if ((startsOn == null) != (endsOn == null)) {
      setState(() => _error = 'Set both dates, or leave both blank to use the app default.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await cubit.updateFestivalSetting(_editing.id, {
        'override_mode': _overrideMode,
        'starts_on': startsOn?.toIso8601String().substring(0, 10),
        'ends_on': endsOn?.toIso8601String().substring(0, 10),
        'accent_color': _accent.text.trim(),
        'gradient_start': _gradientStart.text.trim(),
        'gradient_end': _gradientEnd.text.trim(),
        'motif': _motif,
        'greeting_text': _greeting.text.trim(),
        'popup_enabled': _popupEnabled,
        'popup_title': _popupTitle.text.trim(),
        'popup_message': _popupMessage.text.trim(),
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
      title: 'Edit ${_kFestivalLabelsForModal[_editing.key] ?? _editing.key}',
      subtitle: 'Changes apply immediately to the customer app\'s home header.',
      loading: _loading,
      error: _error,
      onCancel: cubit.closeModal,
      onSubmit: () => _submit(cubit),
      submitLabel: 'Save changes',
      fields: [
        AdminEditDropdown<String>(
          label: 'Activation',
          value: _overrideMode,
          items: _kFestivalOverrideModes.keys.toList(),
          itemLabel: (key) => _kFestivalOverrideModes[key]!,
          onChanged: (v) => setState(() => _overrideMode = v ?? _overrideMode),
        ),
        Row(
          children: [
            Expanded(child: AdminEditField(label: 'Starts on (yyyy-mm-dd, optional)', controller: _startsOn, hint: 'Enter start date (e.g. 2026-11-06)')),
            const SizedBox(width: AdminSpace.sm),
            Expanded(child: AdminEditField(label: 'Ends on (yyyy-mm-dd, optional)', controller: _endsOn, hint: 'Enter end date (e.g. 2026-11-10)')),
          ],
        ),
        _AdminColorField(label: 'Accent colour', controller: _accent),
        _AdminColorField(label: 'Gradient — near corner', controller: _gradientStart),
        _AdminColorField(label: 'Gradient — far corner', controller: _gradientEnd),
        AdminEditDropdown<String>(
          label: 'Decoration',
          value: _motif,
          items: _kFestivalMotifs.keys.toList(),
          itemLabel: (key) => _kFestivalMotifs[key]!,
          onChanged: (v) => setState(() => _motif = v ?? _motif),
        ),
        AdminEditField(label: 'Header greeting badge', controller: _greeting, hint: 'Enter greeting text (e.g. Happy Diwali!)'),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: AdminSpace.sm, vertical: AdminSpace.sm),
          decoration: adminCard(),
          child: Row(
            children: [
              Expanded(child: Text('Show popup on app open', style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w700, color: AdminColors.ink))),
              AdminToggle(on: _popupEnabled, onTap: () => setState(() => _popupEnabled = !_popupEnabled)),
            ],
          ),
        ),
        AdminEditField(label: 'Popup title', controller: _popupTitle, hint: 'Enter popup title (e.g. Festive offers are live)'),
        AdminEditField(label: 'Popup message', controller: _popupMessage, hint: 'Enter popup message (e.g. Enjoy festive prices on top picks)', maxLines: 2),
      ],
    );
  }
}

const _kFestivalLabelsForModal = {
  'diwali': 'Diwali',
  'holi': 'Holi',
  'christmas': 'Christmas',
  'new_year': 'New Year',
  'independence_day': 'Independence / Republic Day',
  'raksha_bandhan': 'Raksha Bandhan',
};
