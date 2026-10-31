import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/cubit/basket_selectors.dart';
import 'package:fastswipe/features/basket/data/basket_enums.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:fastswipe/features/basket/presentation/basket_ui.dart';
import 'package:fastswipe/features/basket/presentation/widgets/product_card.dart';
import 'package:fastswipe/features/basket/presentation/widgets/product_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

const _sortLabels = {
  SortOption.popularity: 'Popularity',
  SortOption.priceAsc: 'Price ↑',
  SortOption.priceDesc: 'Price ↓',
  SortOption.discount: 'Discount',
};

class CategoryListView extends StatelessWidget {
  const CategoryListView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketCubit>();
    final categoryKey = context.select((BasketCubit c) => c.state.category);
    final subcategory = context.select((BasketCubit c) => c.state.subcategory);
    final view = context.select((BasketCubit c) => c.state.view);
    final band = context.select((BasketCubit c) => c.state.band);
    final sort = context.select((BasketCubit c) => c.state.sort);
    final items = context.select((BasketCubit c) => visibleListProducts(c.state));
    final category = context.select((BasketCubit c) => categoryByKey(c.state, categoryKey));

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(BasketSpace.gutter, MediaQuery.paddingOf(context).top + BasketSpace.xs, BasketSpace.gutter, BasketSpace.sm),
          decoration: const BoxDecoration(gradient: BasketColors.headerGradient),
          child: Row(
            children: [
              _CircleIconButton(icon: Icons.arrow_back, onTap: cubit.back),
              const SizedBox(width: BasketSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFFFFFBF2)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subcategory.isEmpty ? '${items.length} items' : '${items.length} items · $subcategory',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFFFFFBF2).withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              ),
              _CircleIconButton(
                icon: view == CatalogView.grid ? Icons.view_list_rounded : Icons.grid_view_rounded,
                onTap: cubit.toggleView,
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (category.subs.isNotEmpty)
                SizedBox(
                  width: 78,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0xFFFFFBF2).withValues(alpha: 0.5),
                      border: Border(right: BorderSide(color: BasketSurface.border)),
                    ),
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: BasketSpace.xs),
                      children: [
                        for (final s in category.subs) _SubcategoryItem(sub: s, active: s == subcategory),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: BasketSpace.gutter, vertical: BasketSpace.sm),
                      child: Row(
                        children: [
                          _FilterPill(
                            label: '⇅ ${_sortLabels[sort]}',
                            onTap: cubit.openFilterSheet,
                          ),
                          const SizedBox(width: BasketSpace.xs),
                          _FilterPill(
                            label: '▽ Filter${band == PriceBand.all ? '' : ' · 1'}',
                            onTap: cubit.openFilterSheet,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: view == CatalogView.grid
                          // Not a `GridView` with a fixed `childAspectRatio` (that clipped long
                          // names or left dead space under short ones): each pair of cards is
                          // as tall as its taller card, prices pinned to the bottom — see
                          // `ProductGrid`.
                          ? SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(BasketSpace.gutter, 0, BasketSpace.gutter, 90),
                              child: ProductGrid(products: items, spacing: BasketSpace.xs),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(BasketSpace.gutter, 0, BasketSpace.gutter, 90),
                              itemCount: items.length,
                              separatorBuilder: (_, _) => const SizedBox(height: BasketSpace.section),
                              itemBuilder: (context, i) => ProductRowCard(product: items[i]),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(BasketRadius.pill),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Color(0xFFFFFBF2).withValues(alpha: 0.1),
          border: Border.all(color: Color(0xFFFFFBF2).withValues(alpha: 0.14)),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: Color(0xFFFFFBF2), size: 16),
      ),
    );
  }
}

class _SubcategoryItem extends StatelessWidget {
  const _SubcategoryItem({required this.sub, required this.active});

  final String sub;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.read<BasketCubit>().setSubcategory(sub),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: BasketSpace.xs, horizontal: BasketSpace.xxs),
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: active ? BasketColors.ink : Colors.transparent, width: 2.5)),
          color: active ? Color(0xFFFFFBF2).withValues(alpha: 0.9) : Colors.transparent,
        ),
        child: Column(
          children: [
            const ProductImageMini(size: 42),
            const SizedBox(height: BasketSpace.xxs),
            Text(
              sub,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(fontSize: 9.5, height: 1.25, fontWeight: FontWeight.w600, color: BasketColors.ink),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: BasketSpace.sm, vertical: 6),
        decoration: BoxDecoration(
          color: BasketSurface.card,
          border: Border.all(color: BasketSurface.borderStrong),
          borderRadius: BorderRadius.circular(BasketRadius.pill),
        ),
        child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

