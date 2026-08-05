import 'package:fastswipe/core/basket_api/models/catalog_models.dart';
import 'package:fastswipe/features/basket/presentation/widgets/image_slot.dart';
import 'package:fastswipe/features/basket_admin/cubit/basket_admin_cubit.dart';
import 'package:fastswipe/features/basket_admin/data/basket_admin_data.dart';
import 'package:fastswipe/features/basket_admin/presentation/basket_admin_style.dart';
import 'package:fastswipe/features/basket_admin/presentation/widgets/admin_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

const _kFlex = [2.3, 1.0, 1.0, 0.9, 0.9, 0.8];

/// Product catalog: category tabs (built from the real catalog, not a
/// hardcoded list) + a table (image/name, category, SKU, MRP, price,
/// live/out-of-stock chip).
class AdminProductsView extends StatelessWidget {
  const AdminProductsView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketAdminCubit>();
    final catTab = context.select((BasketAdminCubit c) => c.state.catTab);
    final categories = context.select((BasketAdminCubit c) => c.state.apiCategories);
    final products = context.select((BasketAdminCubit c) => c.state.apiProducts);
    final loading = context.select((BasketAdminCubit c) => c.state.productsLoading);
    final categoryNameByKey = {for (final c in categories) c.key: c.name};
    final rows = catTab == 'All' ? products : products.where((p) => p.cat == catTab).toList();

    if (loading && products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 9,
                  runSpacing: 9,
                  children: [
                    AdminPillButton(label: 'All', selected: catTab == 'All', onTap: () => cubit.setCatTab('All')),
                    for (final c in categories) AdminPillButton(label: c.name, selected: catTab == c.key, onTap: () => cubit.setCatTab(c.key)),
                  ],
                ),
              ),
              const SizedBox(width: 9),
              OutlinedButton(
                onPressed: cubit.goCategories,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AdminColors.ink.withValues(alpha: 0.12)),
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                ),
                child: Text('Manage categories', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: AdminColors.ink)),
              ),
              const SizedBox(width: 9),
              FilledButton(
                onPressed: cubit.goProductNew,
                style: FilledButton.styleFrom(
                  backgroundColor: AdminColors.ink,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                ),
                child: Text('+ Add product', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 14),
            decoration: adminGlassCard(),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 900,
                child: Column(
                  children: [
                    const AdminTableHeader(flex: _kFlex, labels: ['Product', 'Category', 'SKU', 'MRP', 'Price', 'Status']),
                    if (rows.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text('No products in this category yet.', style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600, color: AdminColors.muted)),
                      ),
                    for (final p in rows) _ProductRow(p: p, categoryName: categoryNameByKey[p.cat] ?? p.cat, onTap: cubit.goProductNew),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.p, required this.categoryName, required this.onTap});
  final ApiProduct p;
  final String categoryName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final state = p.isOutOfStock ? 'Out of stock' : 'Live';
    return AdminTableRow(
      flex: _kFlex,
      onTap: onTap,
      children: [
        Row(
          children: [
            const SizedBox(width: 38, height: 38, child: ImageSlot(shape: ImageSlotShape.rounded, radius: 10, mini: true)),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(p.name, overflow: TextOverflow.ellipsis, style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('${p.pack} · ${p.brand}',
                      overflow: TextOverflow.ellipsis, style: GoogleFonts.manrope(fontSize: 10.5, fontWeight: FontWeight.w500, color: AdminColors.faint)),
                ],
              ),
            ),
          ],
        ),
        Text(categoryName, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: AdminColors.muted)),
        Text(p.sku, style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w600, color: AdminColors.muted)),
        Text(adminMoney(p.mrp), style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: AdminColors.muted)),
        Text(adminMoney(p.price), style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w800)),
        Align(alignment: Alignment.centerLeft, child: AdminChipBadge(state)),
      ],
    );
  }
}
