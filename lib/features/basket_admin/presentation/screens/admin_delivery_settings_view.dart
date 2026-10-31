import 'package:fastswipe/core/basket_api/models/order_models.dart';
import 'package:fastswipe/features/basket_admin/cubit/basket_admin_cubit.dart';
import 'package:fastswipe/features/basket_admin/data/basket_admin_data.dart';
import 'package:fastswipe/features/basket_admin/presentation/admin_ui.dart';
import 'package:fastswipe/features/basket_admin/presentation/basket_admin_style.dart';
import 'package:fastswipe/features/basket_admin/presentation/widgets/admin_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

/// "Delivery charges": the flat delivery fee per order and the item-total
/// limit above which delivery is free. Saved to `StoreSettings` and applied
/// by the backend to the cart and every new order — the customer app shows
/// the fee, a "₹X more for FREE delivery" nudge, and a party-popper burst
/// when the limit is crossed.
class AdminDeliverySettingsView extends StatefulWidget {
  const AdminDeliverySettingsView({super.key});

  @override
  State<AdminDeliverySettingsView> createState() => _AdminDeliverySettingsViewState();
}

class _AdminDeliverySettingsViewState extends State<AdminDeliverySettingsView> {
  final _fee = TextEditingController();
  final _threshold = TextEditingController();
  bool _freeEnabled = true;
  ApiDeliverySettings? _loaded;

  @override
  void initState() {
    super.initState();
    _fee.addListener(_refresh);
    _threshold.addListener(_refresh);
  }

  @override
  void dispose() {
    _fee.dispose();
    _threshold.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  /// Fill the form from the server copy whenever a fresh one arrives (first
  /// load, or the response to a save).
  void _syncFrom(ApiDeliverySettings s) {
    if (identical(s, _loaded)) return;
    _loaded = s;
    _fee.text = '${s.deliveryFee}';
    _threshold.text = '${s.freeDeliveryAbove}';
    _freeEnabled = s.freeDeliveryEnabled;
  }

  ApiDeliverySettings? get _draft {
    final fee = int.tryParse(_fee.text);
    final above = int.tryParse(_threshold.text);
    if (fee == null || above == null) return null;
    return ApiDeliverySettings(deliveryFee: fee, freeDeliveryEnabled: _freeEnabled, freeDeliveryAbove: above);
  }

  bool get _dirty {
    final d = _draft;
    final l = _loaded;
    return d != null &&
        l != null &&
        (d.deliveryFee != l.deliveryFee ||
            d.freeDeliveryEnabled != l.freeDeliveryEnabled ||
            d.freeDeliveryAbove != l.freeDeliveryAbove);
  }

  Future<void> _save() async {
    final draft = _draft;
    if (draft == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await context.read<BasketAdminCubit>().saveDeliverySettings(draft);
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(
      content: Text(ok ? 'Delivery charges saved — live in the app now.' : 'Could not save delivery charges.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketAdminCubit>();
    final settings = context.select((BasketAdminCubit c) => c.state.deliverySettings);
    final saving = context.select((BasketAdminCubit c) => c.state.deliverySettingsSaving);
    final error = context.select((BasketAdminCubit c) => c.state.deliverySettingsError);

    if (settings == null) {
      return Center(
        child: error == null
            ? const CircularProgressIndicator()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Couldn\'t load delivery charges', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: AdminSpace.xs),
                  Text(error, style: GoogleFonts.manrope(fontSize: 12, color: AdminColors.muted)),
                  const SizedBox(height: AdminSpace.md),
                  AdminButton.secondary(label: 'Retry', onPressed: cubit.loadDeliverySettings),
                ],
              ),
      );
    }
    _syncFrom(settings);

    final draft = _draft;
    final digits = [FilteringTextInputFormatter.digitsOnly];
    final form = Container(
      padding: const EdgeInsets.all(AdminSpace.card),
      decoration: adminCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSectionTitle('Delivery charges'),
          const SizedBox(height: 4),
          Text(
            'Applies to the cart and every new order straight away.',
            style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w500, color: AdminColors.muted),
          ),
          const SizedBox(height: AdminSpace.md),
          AdminEditField(
            label: 'Delivery fee per order (₹)',
            controller: _fee,
            hint: 'e.g. 19 — set 0 to make delivery always free',
            keyboardType: TextInputType.number,
            inputFormatters: digits,
          ),
          const SizedBox(height: AdminSpace.md),
          Row(
            children: [
              AdminToggle(on: _freeEnabled, onTap: () => setState(() => _freeEnabled = !_freeEnabled)),
              const SizedBox(width: AdminSpace.xs),
              Expanded(
                child: Text(
                  'Free delivery above a limit',
                  style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: AdminSpace.md),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _freeEnabled ? 1 : 0.4,
            child: AdminEditField(
              label: 'Free delivery when item total reaches (₹)',
              controller: _threshold,
              hint: 'e.g. 199',
              keyboardType: TextInputType.number,
              inputFormatters: digits,
              enabled: _freeEnabled,
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: AdminSpace.sm),
            Text(error, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: AdminSurface.error)),
          ],
          const SizedBox(height: AdminSpace.lg),
          Row(
            children: [
              AdminButton(
                label: 'Save changes',
                size: AdminButtonSize.large,
                loading: saving,
                onPressed: !_dirty || saving ? null : _save,
              ),
              const SizedBox(width: AdminSpace.sm),
              if (_dirty)
                AdminButton.secondary(
                  label: 'Discard',
                  size: AdminButtonSize.large,
                  onPressed: () => setState(() {
                    _loaded = null;
                    _syncFrom(settings);
                  }),
                ),
            ],
          ),
        ],
      ),
    );

    final preview = Container(
      padding: const EdgeInsets.all(AdminSpace.card),
      decoration: adminCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSectionTitle('How customers see it'),
          const SizedBox(height: AdminSpace.md),
          if (draft == null)
            Text('Enter both amounts to see a preview.', style: GoogleFonts.manrope(fontSize: 12, color: AdminColors.muted))
          else
            for (final example in _examples(draft)) ...[
              _PreviewRow(itemTotal: example, settings: draft),
              const SizedBox(height: AdminSpace.xs),
            ],
        ],
      ),
    );

    return SingleChildScrollView(
      child: LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth < 820) {
          return Column(children: [form, const SizedBox(height: AdminSpace.section), preview]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 11, child: form),
            const SizedBox(width: AdminSpace.section),
            Expanded(flex: 9, child: preview),
          ],
        );
      }),
    );
  }

  /// A basket below, exactly at, and above the limit.
  List<int> _examples(ApiDeliverySettings s) {
    if (!s.freeDeliveryEnabled || s.deliveryFee == 0) return [150, 500];
    final t = s.freeDeliveryAbove;
    return [if (t > 50) (t * 0.6).round(), t, t + 100];
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.itemTotal, required this.settings});

  final int itemTotal;
  final ApiDeliverySettings settings;

  @override
  Widget build(BuildContext context) {
    final fee = settings.feeFor(itemTotal);
    final free = fee == 0;
    final short = settings.freeDeliveryEnabled ? settings.freeDeliveryAbove - itemTotal : 0;
    return Container(
      padding: const EdgeInsets.all(AdminSpace.sm),
      decoration: BoxDecoration(
        color: free ? AdminSurface.success.withValues(alpha: 0.08) : AdminSurface.card,
        borderRadius: BorderRadius.circular(AdminRadius.md),
        border: Border.all(color: free ? AdminSurface.success.withValues(alpha: 0.4) : AdminSurface.border),
      ),
      child: Row(
        children: [
          Text(free ? '🎉' : '🛵', style: const TextStyle(fontSize: 18)),
          const SizedBox(width: AdminSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cart of ${adminMoney(itemTotal)}', style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  free
                      ? 'FREE delivery 🎉 (party popper plays)'
                      : short > 0
                          ? '"Add ${adminMoney(short)} more for FREE delivery"'
                          : 'Delivery fee charged',
                  style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w500, color: AdminColors.muted),
                ),
              ],
            ),
          ),
          Text(
            free ? 'FREE' : '+ ${adminMoney(fee)}',
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: free ? AdminSurface.success : AdminColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
