import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/cubit/basket_selectors.dart';
import 'package:fastswipe/features/basket/data/basket_enums.dart';
import 'package:fastswipe/features/basket/data/models.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:fastswipe/features/basket/presentation/basket_ui.dart';
import 'package:fastswipe/features/basket/presentation/widgets/glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class CategoriesView extends StatelessWidget {
  const CategoriesView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketCubit>();
    final categories = context.select((BasketCubit c) => categoriesOf(c.state));
    return Column(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(BasketRadius.xl)),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(BasketSpace.gutter, MediaQuery.paddingOf(context).top + BasketSpace.sm, BasketSpace.gutter, BasketSpace.md),
            decoration: const BoxDecoration(gradient: BasketColors.headerGradient),
            child: Stack(
              children: [
                Positioned(
                  top: -60,
                  right: -50,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: BasketColors.primary.withValues(alpha: 0.14)),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('All categories', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFFFFFBF2), letterSpacing: -0.4)),
                    const SizedBox(height: BasketSpace.xxs),
                    Text(
                      '${categories.length} categories to shop from',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFFFFFBF2).withValues(alpha: 0.55)),
                    ),
                    const SizedBox(height: BasketSpace.sm),
                    InkWell(
                      onTap: () => cubit.go(BasketScreen.search),
                      borderRadius: BasketRadius.input,
                      child: Container(
                        width: double.infinity,
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: BasketSpace.md),
                        decoration: BoxDecoration(
                          color: BasketSurface.card,
                          border: Border.all(color: BasketSurface.borderStrong),
                          borderRadius: BasketRadius.input,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search_rounded, size: 17, color: BasketColors.muted),
                            const SizedBox(width: BasketSpace.xs),
                            Text(
                              'Search 5,000+ products',
                              style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: BasketColors.muted),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(BasketSpace.gutter, BasketSpace.md, BasketSpace.gutter, BasketSpace.lg),
            itemCount: categories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: BasketSpace.sm,
              crossAxisSpacing: BasketSpace.sm,
              childAspectRatio: 1.05,
            ),
            itemBuilder: (context, i) => _CategoryCard(category: categories[i]),
          ),
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category});

  final BasketCategory category;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<BasketCubit>().openCategory(category),
      child: Container(
        padding: const EdgeInsets.all(BasketSpace.sm),
        decoration: glassCard(radius: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(color: BasketColors.primarySoft, borderRadius: BorderRadius.circular(BasketRadius.lg)),
                alignment: Alignment.center,
                child: category.imageUrl.isEmpty
                    ? const Text('🛒', style: TextStyle(fontSize: 40))
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(BasketRadius.lg),
                        child: Image.network(
                          category.imageUrl,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Text('🛒', style: TextStyle(fontSize: 40)),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: BasketSpace.xs),
            SizedBox(
              height: 34,
              child: Text(
                category.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.25, fontWeight: FontWeight.w700, color: BasketColors.ink),
              ),
            ),
            const SizedBox(height: 3),
            Text('${category.count} items', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500, color: BasketColors.faint)),
          ],
        ),
      ),
    );
  }
}
