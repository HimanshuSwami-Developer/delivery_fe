import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/cubit/basket_selectors.dart';
import 'package:fastswipe/features/basket/data/basket_enums.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:fastswipe/features/basket/presentation/basket_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

const _bands = [
  (PriceBand.all, 'All prices'),
  (PriceBand.low, 'Under ₹50'),
  (PriceBand.mid, '₹50–200'),
  (PriceBand.high, '₹200+'),
];

const _sorts = [
  (SortOption.popularity, 'Popularity'),
  (SortOption.priceAsc, 'Price low → high'),
  (SortOption.priceDesc, 'Price high → low'),
  (SortOption.discount, 'Biggest discount'),
];

/// Price/sort bottom sheet shared by "Sort" and "Filter" pills on the
/// category list screen — both open this same sheet, matching the source.
class FilterSheet extends StatelessWidget {
  const FilterSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketCubit>();
    final band = context.select((BasketCubit c) => c.state.band);
    final sort = context.select((BasketCubit c) => c.state.sort);
    final listCount = context.select((BasketCubit c) => visibleListProducts(c.state).length);

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: cubit.closeSheet,
            child: Container(color: BasketColors.ink.withValues(alpha: 0.35)),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(BasketSpace.gutter, BasketSpace.md, BasketSpace.gutter, BasketSpace.xl),
              decoration: BoxDecoration(
                color: Color(0xFFFFFBF2).withValues(alpha: 0.96),
                borderRadius: BasketRadius.sheet,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Filters', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800)),
                      BasketButton.text(
                        label: 'Clear all',
                        size: BasketButtonSize.small,
                        onPressed: cubit.resetFilters,
                      ),
                    ],
                  ),
                  const SizedBox(height: BasketSpace.md),
                  Text('Price', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: BasketSpace.xs),
                  Wrap(
                    spacing: BasketSpace.xs,
                    runSpacing: BasketSpace.xs,
                    children: [
                      for (final b in _bands)
                        _Pill(
                          label: b.$2,
                          style: pillStyle(band == b.$1),
                          onTap: () => cubit.setBand(b.$1),
                        ),
                    ],
                  ),
                  const SizedBox(height: BasketSpace.md),
                  Text('Sort by', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: BasketSpace.xs),
                  Wrap(
                    spacing: BasketSpace.xs,
                    runSpacing: BasketSpace.xs,
                    children: [
                      for (final s in _sorts)
                        _Pill(
                          label: s.$2,
                          style: pillStyle(sort == s.$1),
                          onTap: () => cubit.setSort(s.$1),
                        ),
                    ],
                  ),
                  const SizedBox(height: BasketSpace.xl),
                  Row(
                    children: [
                      Expanded(
                        child: BasketButton.secondary(label: 'Reset', onPressed: cubit.resetFilters),
                      ),
                      const SizedBox(width: BasketSpace.sm),
                      Expanded(
                        flex: 2,
                        child: BasketButton(label: 'Show $listCount results', onPressed: cubit.closeSheet),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.style, required this.onTap});

  final String label;
  final PillStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: BasketSpace.sm, vertical: BasketSpace.xs),
        decoration: BoxDecoration(
          color: style.bg,
          border: Border.all(color: style.border),
          borderRadius: BorderRadius.circular(BasketRadius.pill),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: style.fg),
        ),
      ),
    );
  }
}
