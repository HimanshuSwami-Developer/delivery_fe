import 'package:fastswipe/core/api/api_exception.dart';
import 'package:fastswipe/core/basket_api/models/catalog_models.dart';
import 'package:fastswipe/features/basket/presentation/widgets/image_slot.dart';
import 'package:fastswipe/features/basket_admin/cubit/basket_admin_cubit.dart';
import 'package:fastswipe/features/basket_admin/presentation/admin_ui.dart';
import 'package:fastswipe/features/basket_admin/presentation/basket_admin_style.dart';
import 'package:fastswipe/features/basket_admin/presentation/widgets/admin_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

/// Category management: a grid of cards, each with its subcategory chips
/// and Edit/Delete actions.
class AdminCategoriesView extends StatelessWidget {
  const AdminCategoriesView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketAdminCubit>();
    final categories = context.select((BasketAdminCubit c) => c.state.apiCategories);
    final loading = context.select((BasketAdminCubit c) => c.state.categoriesLoading);
    final subcategories = context.select((BasketAdminCubit c) => c.state.apiSubcategories);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: AdminSectionTitle('Categories')),
              AdminButton(label: '+ Add category', onPressed: cubit.openAddCategory),
            ],
          ),
          const SizedBox(height: AdminSpace.section),
          if (loading && categories.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: CircularProgressIndicator()))
          else if (categories.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'No categories exist yet — add one to get started.',
                  style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: AdminColors.faint),
                ),
              ),
            )
          else
            AdminResponsiveGrid(
              minTileWidth: 300,
              children: [
                for (final c in categories)
                  _CategoryCard(
                    category: c,
                    cubit: cubit,
                    subcategories: subcategories.where((s) => s.categoryId == c.id).toList(),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.cubit, required this.subcategories});
  final ApiCategory category;
  final BasketAdminCubit cubit;
  final List<ApiSubcategory> subcategories;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AdminSpace.md),
      decoration: adminCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 52,
                height: 52,
                child: category.imageUrl.isEmpty
                    ? const ImageSlot(shape: ImageSlotShape.rounded, radius: AdminRadius.md, mini: true)
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(AdminRadius.md),
                        child: Image.network(
                          category.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const ImageSlot(shape: ImageSlotShape.rounded, radius: AdminRadius.md, mini: true),
                        ),
                      ),
              ),
              const SizedBox(width: AdminSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(category.name, overflow: TextOverflow.ellipsis, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('${category.productCount} SKUs · ${subcategories.length} subcategories',
                        overflow: TextOverflow.ellipsis, style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w500, color: AdminColors.faint)),
                  ],
                ),
              ),
              const AdminChipBadge('Live'),
            ],
          ),
          const SizedBox(height: AdminSpace.sm),
          Wrap(
            spacing: AdminSpace.xs,
            runSpacing: AdminSpace.xs,
            children: [
              for (final s in subcategories)
                AdminPillButton(label: s.name, selected: false, onTap: () => cubit.openAddSubcategory(category: category, subcategory: s)),
              AdminButton(label: '+ Add', size: AdminButtonSize.small, onPressed: () => cubit.openAddSubcategory(category: category)),
            ],
          ),
          const SizedBox(height: AdminSpace.sm),
          Row(
            children: [
              Expanded(
                child: AdminButton.secondary(label: 'Edit', size: AdminButtonSize.small, expand: true, onPressed: () => cubit.openAddCategory(category: category)),
              ),
              const SizedBox(width: AdminSpace.xs),
              Expanded(
                child: AdminButton(
                  label: 'Delete',
                  variant: AdminButtonVariant.danger,
                  size: AdminButtonSize.small,
                  expand: true,
                  onPressed: () => _confirmDelete(context, cubit, category),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> _confirmDelete(BuildContext context, BasketAdminCubit cubit, ApiCategory category) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Delete "${category.name}"?', style: GoogleFonts.manrope(fontWeight: FontWeight.w800)),
      content: Text(
        category.productCount > 0
            ? 'This category still has ${category.productCount} product(s) in it — deletion will be rejected until they\'re moved or removed.'
            : 'This can\'t be undone.',
        style: GoogleFonts.manrope(fontSize: 13),
      ),
      actions: [
        AdminButton.secondary(label: 'Cancel', onPressed: () => Navigator.of(dialogContext).pop(false)),
        AdminButton(label: 'Delete', variant: AdminButtonVariant.danger, onPressed: () => Navigator.of(dialogContext).pop(true)),
      ],
    ),
  );
  if (confirmed != true) return;
  try {
    await cubit.deleteCategory(category.key);
  } on ApiException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}
