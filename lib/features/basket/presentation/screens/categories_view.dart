import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/cubit/basket_selectors.dart';
import 'package:fastswipe/features/basket/data/basket_enums.dart';
import 'package:fastswipe/features/basket/data/models.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
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
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(26)),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(18, MediaQuery.paddingOf(context).top + 12, 18, 16),
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
                    Text('All categories', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.4)),
                    const SizedBox(height: 4),
                    Text(
                      '${categories.length} categories to shop from',
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.55)),
                    ),
                    const SizedBox(height: 14),
                    InkWell(
                      onTap: () => cubit.go(BasketScreen.search),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                        child: Row(
                          children: [
                            Icon(Icons.search_rounded, size: 17, color: BasketColors.muted),
                            const SizedBox(width: 10),
                            Text(
                              'Search 5,000+ products',
                              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: BasketColors.muted),
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
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
            itemCount: categories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
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
      onTap: () => context.read<BasketCubit>().openCategory(category.key, category.subs.first),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: glassCard(radius: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(color: BasketColors.primarySoft, borderRadius: BorderRadius.circular(16)),
                alignment: Alignment.center,
                child: category.imageUrl.isEmpty
                    ? const Text('🛒', style: TextStyle(fontSize: 40))
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(16),
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
            const SizedBox(height: 10),
            SizedBox(
              height: 34,
              child: Text(
                category.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(fontSize: 13, height: 1.25, fontWeight: FontWeight.w700, color: BasketColors.ink),
              ),
            ),
            const SizedBox(height: 3),
            Text('${category.count} items', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: BasketColors.faint)),
          ],
        ),
      ),
    );
  }
}
