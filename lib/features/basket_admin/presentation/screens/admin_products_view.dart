import 'package:fastswipe/core/api/api_exception.dart';
import 'package:fastswipe/core/basket_api/models/catalog_models.dart';
import 'package:fastswipe/features/basket/presentation/widgets/image_slot.dart';
import 'package:fastswipe/features/basket_admin/cubit/basket_admin_cubit.dart';
import 'package:fastswipe/features/basket_admin/data/basket_admin_data.dart';
import 'package:fastswipe/features/basket_admin/presentation/admin_ui.dart';
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
                child: AdminPillTabs<String>(
                  tabs: [('All', 'All'), for (final c in categories) (c.key, c.name)],
                  selected: catTab,
                  onSelected: cubit.setCatTab,
                ),
              ),
              const SizedBox(width: AdminSpace.xs),
              AdminButton.secondary(label: 'Manage categories', onPressed: cubit.goCategories),
              const SizedBox(width: AdminSpace.xs),
              AdminButton(label: '+ Add product', onPressed: cubit.goProductNew),
            ],
          ),
          const SizedBox(height: AdminSpace.section),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: adminCard(),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 900,
                child: Column(
                  children: [
                    const AdminTableHeader(flex: _kFlex, labels: ['Product', 'Category', 'SKU', 'MRP', 'Price', 'Status', '']),
                    if (rows.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AdminSpace.sm, vertical: AdminSpace.lg),
                        child: Text('No products in this category yet.', style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600, color: AdminColors.muted)),
                      ),
                    for (final p in rows)
                      _ProductRow(
                        p: p,
                        categoryName: categoryNameByKey[p.cat] ?? p.cat,
                        onEdit: () => cubit.goProductNew(product: p),
                        onDelete: () => _confirmDelete(context, cubit, p),
                        onToggleActive: () => _toggleActive(context, cubit, p),
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
      boundHeight: true,
      children: [
        Row(
          children: [
            const SizedBox(width: 38, height: 38, child: ImageSlot(shape: ImageSlotShape.rounded, radius: AdminRadius.sm, mini: true)),
            const SizedBox(width: AdminSpace.sm),
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
                        const SizedBox(width: AdminSpace.xs),
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(adminMoney(p.sellingPrice), style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w800)),
            Text('${adminMoney(p.price)} + GST', style: GoogleFonts.manrope(fontSize: 10.5, fontWeight: FontWeight.w500, color: AdminColors.muted)),
          ],
        ),
        InkWell(
          onTap: onToggleActive,
          // Fills the whole cell (both axes) — with `boundHeight` on the
          // parent row this is now a concrete size, not unbounded, so a tap
          // anywhere in the Status column hits the toggle, never the row's
          // own `onEdit` underneath it.
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AdminToggle(on: p.isActive, onTap: onToggleActive),
                  const SizedBox(width: AdminSpace.xs),
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
            AdminIconActionButton(icon: Icons.edit_outlined, onTap: onEdit),
            const SizedBox(width: AdminSpace.xs),
            AdminIconActionButton(icon: Icons.delete_outline, onTap: onDelete, color: AdminSurface.error),
          ],
        ),
      ],
    );
  }
}

Future<void> _toggleActive(BuildContext context, BasketAdminCubit cubit, ApiProduct p) async {
  try {
    await cubit.toggleProduct(p.id, !p.isActive);
  } on ApiException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

Future<void> _confirmDelete(BuildContext context, BasketAdminCubit cubit, ApiProduct p) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Delete "${p.name}"?', style: GoogleFonts.manrope(fontWeight: FontWeight.w800)),
      content: Text('SKU ${p.sku} — this can\'t be undone.', style: GoogleFonts.manrope(fontSize: 13)),
      actions: [
        AdminButton.secondary(label: 'Cancel', onPressed: () => Navigator.of(dialogContext).pop(false)),
        AdminButton(label: 'Delete', variant: AdminButtonVariant.danger, onPressed: () => Navigator.of(dialogContext).pop(true)),
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
