import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/cubit/basket_selectors.dart';
import 'package:fastswipe/features/basket/data/basket_enums.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
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
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.96),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Filters', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800)),
                      GestureDetector(
                        onTap: cubit.resetFilters,
                        child: Text(
                          'Clear all',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: BasketColors.muted),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text('Price', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final b in _bands)
                        _Pill(
                          label: b.$2,
                          style: pillStyle(band == b.$1),
                          onTap: () => cubit.setBand(b.$1),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text('Sort by', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final s in _sorts)
                        _Pill(
                          label: s.$2,
                          style: pillStyle(sort == s.$1),
                          onTap: () => cubit.setSort(s.$1),
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: BasketColors.ink, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            minimumSize: Size.zero,
                          ),
                          onPressed: cubit.resetFilters,
                          child: Text('Reset', style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700, color: BasketColors.ink)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: BasketColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            minimumSize: Size.zero,
                          ),
                          onPressed: cubit.closeSheet,
                          child: Text(
                            'Show $listCount results',
                            style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ),
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
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: style.bg,
          border: Border.all(color: style.border),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: style.fg),
        ),
      ),
    );
  }
}
