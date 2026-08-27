import 'package:fastswipe/core/api/api_exception.dart';
import 'package:fastswipe/core/basket_api/models/catalog_models.dart';
import 'package:fastswipe/features/basket/presentation/widgets/image_slot.dart';
import 'package:fastswipe/features/basket_admin/cubit/basket_admin_cubit.dart';
import 'package:fastswipe/features/basket_admin/data/basket_admin_data.dart';
import 'package:fastswipe/features/basket_admin/presentation/basket_admin_style.dart';
import 'package:fastswipe/features/basket_admin/presentation/widgets/admin_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

const _kFlex = [2.1, 1.0, 1.0, 0.9, 0.9, 1.0, 0.7];

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
                    const AdminTableHeader(flex: _kFlex, labels: ['Product', 'Category', 'SKU', 'MRP', 'Price', 'Status', '']),
                    if (rows.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text('No products in this category yet.', style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600, color: AdminColors.muted)),
                      ),
                    for (final p in rows)
                      _ProductRow(
                        p: p,
                        categoryName: categoryNameByKey[p.cat] ?? p.cat,
                        onEdit: () => cubit.goProductNew(product: p),
                        onDelete: () => _confirmDelete(context, cubit, p),
                        onToggleActive: () => cubit.toggleProduct(p.id, !p.isActive),
                      ),
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
  const _ProductRow({
    required this.p,
    required this.categoryName,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });
  final ApiProduct p;
  final String categoryName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context) {
    return AdminTableRow(
      flex: _kFlex,
      onTap: onEdit,
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
                  Row(
                    children: [
                      Flexible(
                        child: Text('${p.pack} · ${p.brand}',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(fontSize: 10.5, fontWeight: FontWeight.w500, color: AdminColors.faint)),
                      ),
                      if (p.isOutOfStock) ...[
                        const SizedBox(width: 6),
                        AdminChipBadge('Out of stock'),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        Text(categoryName, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: AdminColors.muted)),
        Text(p.sku, style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w600, color: AdminColors.muted)),
        Text(adminMoney(p.mrp), style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: AdminColors.muted)),
        Text(adminMoney(p.price), style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w800)),
        InkWell(
          onTap: onToggleActive,
          child: SizedBox(
            width: double.infinity,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AdminToggle(on: p.isActive, onTap: onToggleActive),
                  const SizedBox(width: 7),
                  Text(p.isActive ? 'Live' : 'Paused',
                      style: GoogleFonts.manrope(
                          fontSize: 11.5, fontWeight: FontWeight.w700, color: p.isActive ? AdminColors.ink : AdminColors.faint)),
                ],
              ),
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: onEdit,
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.edit_outlined, size: 17, color: AdminColors.faint),
              ),
            ),
            InkWell(
              onTap: onDelete,
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.delete_outline, size: 17, color: AdminColors.faint),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

Future<void> _confirmDelete(BuildContext context, BasketAdminCubit cubit, ApiProduct p) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Delete "${p.name}"?', style: GoogleFonts.manrope(fontWeight: FontWeight.w800)),
      content: Text('SKU ${p.sku} — this can\'t be undone.', style: GoogleFonts.manrope(fontSize: 13)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text('Cancel', style: GoogleFonts.manrope(fontWeight: FontWeight.w600, color: AdminColors.muted)),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text('Delete', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: const Color(0xFFC0392B))),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  try {
    await cubit.deleteProduct(p.id);
  } on ApiException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}
