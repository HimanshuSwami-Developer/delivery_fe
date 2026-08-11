import 'package:fastswipe/core/api/api_exception.dart';
import 'package:fastswipe/core/basket_api/models/catalog_models.dart';
import 'package:fastswipe/features/basket/presentation/widgets/image_slot.dart';
import 'package:fastswipe/features/basket_admin/cubit/basket_admin_cubit.dart';
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

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: AdminSectionTitle('Categories')),
              FilledButton(
                onPressed: cubit.openAddCategory,
                style: FilledButton.styleFrom(
                  backgroundColor: AdminColors.ink,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                ),
                child: Text('+ Add category', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (categories.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: CircularProgressIndicator()))
          else
            LayoutBuilder(builder: (context, constraints) {
              final cols = constraints.maxWidth < 640 ? 1 : (constraints.maxWidth < 980 ? 2 : 3);
              return GridView.count(
                crossAxisCount: cols,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.15,
                children: [for (final c in categories) _CategoryCard(category: c, cubit: cubit)],
              );
            }),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.cubit});
  final ApiCategory category;
  final BasketAdminCubit cubit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: adminGlassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(width: 52, height: 52, child: ImageSlot(shape: ImageSlotShape.rounded, radius: 13, mini: true)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(category.name, overflow: TextOverflow.ellipsis, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('${category.productCount} SKUs · ${category.subs.length} subcategories',
                        overflow: TextOverflow.ellipsis, style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w500, color: AdminColors.faint)),
                  ],
                ),
              ),
              const AdminChipBadge('Live'),
            ],
          ),
          const SizedBox(height: 13),
          Expanded(
            child: Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final s in category.subs)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                    decoration: BoxDecoration(border: Border.all(color: AdminColors.ink.withValues(alpha: 0.12)), borderRadius: BorderRadius.circular(99)),
                    child: Text(s, style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                if (category.subs.isEmpty)
                  Text('No subcategories yet', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w500, color: AdminColors.faint)),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => cubit.openAddCategory(category: category),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AdminColors.ink, width: 1.3),
                    foregroundColor: AdminColors.ink,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Edit', style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w700, color: AdminColors.ink)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _confirmDelete(context, cubit, category),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AdminColors.ink.withValues(alpha: 0.14)),
                    foregroundColor: AdminColors.muted,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Delete', style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w700, color: AdminColors.muted)),
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
    await cubit.deleteCategory(category.key);
  } on ApiException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}
