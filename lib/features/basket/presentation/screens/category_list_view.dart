import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/cubit/basket_selectors.dart';
import 'package:fastswipe/features/basket/data/basket_enums.dart';
import 'package:fastswipe/features/basket/data/models.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:fastswipe/features/basket/presentation/widgets/add_qty_control.dart';
import 'package:fastswipe/features/basket/presentation/widgets/glass.dart';
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
          padding: EdgeInsets.fromLTRB(14, MediaQuery.paddingOf(context).top + 8, 14, 14),
          decoration: const BoxDecoration(gradient: BasketColors.headerGradient),
          child: Row(
            children: [
              _CircleIconButton(icon: Icons.arrow_back, onTap: cubit.back),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subcategory.isEmpty ? '${items.length} items' : '${items.length} items · $subcategory',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.5)),
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
                      color: Colors.white.withValues(alpha: 0.5),
                      border: Border(right: BorderSide(color: BasketColors.ink.withValues(alpha: 0.07))),
                    ),
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 10),
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          _FilterPill(
                            label: '⇅ ${_sortLabels[sort]}',
                            onTap: cubit.openFilterSheet,
                          ),
                          const SizedBox(width: 7),
                          _FilterPill(
                            label: '▽ Filter${band == PriceBand.all ? '' : ' · 1'}',
                            onTap: cubit.openFilterSheet,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: view == CatalogView.grid
                          // A `Wrap` of fixed-width cards, not a `GridView`
                          // with a fixed `childAspectRatio` — the aspect
                          // ratio forced every card into the same box
                          // regardless of how many lines its name actually
                          // needed, clipping longer names or leaving dead
                          // space under shorter ones. Each card sizes to
                          // its own content height here (see `_GridCard`'s
                          // `mainAxisSize: min`).
                          ? SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(12, 2, 12, 90),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final cardWidth = (constraints.maxWidth - 9) / 2;
                                  return Wrap(
                                    spacing: 9,
                                    runSpacing: 9,
                                    children: [
                                      for (final product in items)
                                        SizedBox(width: cardWidth, child: _GridCard(product: product)),
                                    ],
                                  );
                                },
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(12, 2, 12, 90),
                              itemCount: items.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 9),
                              itemBuilder: (context, i) => _RowCard(product: items[i]),
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
      borderRadius: BorderRadius.circular(99),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: Colors.white, size: 16),
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
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: active ? BasketColors.ink : Colors.transparent, width: 2.5)),
          color: active ? Colors.white.withValues(alpha: 0.9) : Colors.transparent,
        ),
        child: Column(
          children: [
            const ProductImageMini(size: 42),
            const SizedBox(height: 5),
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
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          border: Border.all(color: BasketColors.ink.withValues(alpha: 0.14)),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _GridCard extends StatelessWidget {
  const _GridCard({required this.product});

  final BasketProduct product;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: product.oos ? 0.5 : 1,
      child: GestureDetector(
        onTap: () => context.read<BasketCubit>().openProduct(product.id),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: productCardDecoration(radius: 15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProductImage(height: 78, imageUrl: product.imageUrl, discountPct: product.discountPct, radius: 11),
              const SizedBox(height: 7),
              SizedBox(
                height: 28,
                child: Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, height: 1.3, fontWeight: FontWeight.w600, color: BasketColors.ink),
                ),
              ),
              Text(product.pack, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w500, color: BasketColors.faint)),
              const SizedBox(height: 7),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(moneyLabel(product.price), style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w800, color: BasketColors.ink)),
                  AddQtyControl(product: product),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RowCard extends StatelessWidget {
  const _RowCard({required this.product});

  final BasketProduct product;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: product.oos ? 0.5 : 1,
      child: GestureDetector(
        onTap: () => context.read<BasketCubit>().openProduct(product.id),
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: productCardDecoration(radius: 15),
          child: Row(
            children: [
              SizedBox(width: 64, height: 64, child: ProductImage(height: 64, imageUrl: product.imageUrl, discountPct: product.discountPct, radius: 11)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, height: 1.25, fontWeight: FontWeight.w600, color: BasketColors.ink),
                    ),
                    const SizedBox(height: 3),
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w500, color: BasketColors.faint),
                        children: [
                          TextSpan(text: '${product.pack} · '),
                          const TextSpan(text: '★ ', style: TextStyle(color: BasketColors.gold)),
                          TextSpan(text: '${product.rating}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Text(moneyLabel(product.price), style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: BasketColors.ink)),
                        const SizedBox(width: 6),
                        Text(
                          moneyLabel(product.mrp),
                          style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w500, color: BasketColors.faint, decoration: TextDecoration.lineThrough),
                        ),
                        const Spacer(),
                        AddQtyControl(product: product),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
