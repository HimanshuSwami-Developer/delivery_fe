import 'package:fastswipe/features/basket/presentation/widgets/image_slot.dart';
import 'package:fastswipe/features/basket_admin/cubit/basket_admin_cubit.dart';
import 'package:fastswipe/features/basket_admin/presentation/basket_admin_style.dart';
import 'package:fastswipe/features/basket_admin/presentation/widgets/admin_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

const _kGstSlabs = ['0%', '5%', '12%', '18%'];
const _kZones = ['Koramangala', 'HSR Layout', 'Jayanagar', 'Whitefield'];

/// Add-product form: a static mock of "Aashirvaad Shudh Chakki Atta" (the
/// source design never wires product rows into this form — every row's
/// "open" action lands on the same prefilled draft), plus pricing/tax,
/// image slots, and per-zone availability toggles.
class AdminProductNewView extends StatelessWidget {
  const AdminProductNewView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketAdminCubit>();
    final gstSlab = context.select((BasketAdminCubit c) => c.state.gstSlab);
    final skuZones = context.select((BasketAdminCubit c) => c.state.skuZones);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton(
            onPressed: cubit.goProducts,
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            child: Text('← All products', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: AdminColors.muted)),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(builder: (context, constraints) {
            final narrow = constraints.maxWidth < 900;

            final left = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: adminGlassCard(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AdminSectionTitle('Product details'),
                      const SizedBox(height: 14),
                      const AdminFieldBox(label: 'Product name', value: 'Aashirvaad Shudh Chakki Atta'),
                      const SizedBox(height: 12),
                      const Row(
                        children: [
                          Expanded(child: AdminFieldBox(label: 'Brand', value: 'Aashirvaad')),
                          SizedBox(width: 12),
                          Expanded(child: AdminFieldBox(label: 'Category', value: 'Atta, Rice & Dal')),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Row(
                        children: [
                          Expanded(child: AdminFieldBox(label: 'Pack size', value: '5 kg')),
                          SizedBox(width: 12),
                          Expanded(child: AdminFieldBox(label: 'SKU code', value: 'SKU-1042')),
                        ],
                      ),
                      const SizedBox(height: 12),
                      AdminFieldBox(
                        label: 'Description',
                        value: '100% whole wheat atta, chakki-ground for soft rotis.',
                        valueColor: AdminColors.muted,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: adminGlassCard(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AdminSectionTitle('Pricing & tax'),
                      const SizedBox(height: 14),
                      const AdminResponsiveGrid(
                        minTileWidth: 130,
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          AdminFieldBox(label: 'MRP', value: '₹320'),
                          AdminFieldBox(label: 'Selling price', value: '₹289'),
                          AdminFieldBox(label: 'Margin', value: '9.7%'),
                          AdminFieldBox(label: 'HSN code', value: '1101'),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 9,
                        runSpacing: 9,
                        children: [
                          for (final g in _kGstSlabs)
                            AdminPillButton(label: 'GST $g', selected: gstSlab == g, onTap: () => cubit.setGstSlab(g)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );

            final right = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: adminGlassCard(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Images', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      const SizedBox(
                        height: 150,
                        width: double.infinity,
                        child: ImageSlot(shape: ImageSlotShape.rounded, radius: 13, caption: 'Primary product image'),
                      ),
                      const SizedBox(height: 9),
                      Row(
                        children: const [
                          Expanded(child: SizedBox(height: 62, child: ImageSlot(shape: ImageSlotShape.rounded, radius: 11, mini: true))),
                          SizedBox(width: 9),
                          Expanded(child: SizedBox(height: 62, child: ImageSlot(shape: ImageSlotShape.rounded, radius: 11, mini: true))),
                          SizedBox(width: 9),
                          Expanded(child: SizedBox(height: 62, child: ImageSlot(shape: ImageSlotShape.rounded, radius: 11, mini: true))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: adminGlassCard(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Availability by zone', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 13),
                      for (final z in _kZones)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 9),
                          child: _ZoneToggleRow(zone: z, on: skuZones[z] ?? false, onTap: () => cubit.toggleSkuZone(z)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: cubit.goProducts,
                    style: FilledButton.styleFrom(
                      backgroundColor: AdminColors.ink,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                    ),
                    child: Text('Save product', style: GoogleFonts.manrope(fontSize: 13.5, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                ),
              ],
            );

            if (narrow) {
              return Column(children: [left, const SizedBox(height: 14), right]);
            }
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 160, child: left),
                  const SizedBox(width: 14),
                  Expanded(flex: 100, child: right),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ZoneToggleRow extends StatelessWidget {
  const _ZoneToggleRow({required this.zone, required this.on, required this.onTap});
  final String zone;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final stock = on ? (zone == 'Koramangala' ? '142 u' : '60 u') : 'Not listed';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AdminColors.ink.withValues(alpha: 0.1)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            AdminToggle(on: on, onTap: onTap, width: 32, height: 17),
            const SizedBox(width: 11),
            Expanded(child: Text(zone, style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w700))),
            Text(stock, style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600, color: AdminColors.faint)),
          ],
        ),
      ),
    );
  }
}
