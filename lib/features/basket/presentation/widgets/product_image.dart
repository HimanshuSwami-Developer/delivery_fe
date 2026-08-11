import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Soft green-tinted panel that stands in for a product photo — there's no
/// real image pipeline, so this reads as "designed" instead of a
/// broken-image gray box, and keeps the green accent present on every
/// product card. Shared by every screen with a product grid/list/detail
/// (home, category browse, search, cart, product detail).
class ProductImage extends StatelessWidget {
  const ProductImage({super.key, required this.height, this.discountPct = 0, this.radius = 14});

  final double height;
  final int discountPct;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(color: BasketColors.primarySoft),
                child: Center(
                  child: Icon(Icons.shopping_basket_rounded, size: height * 0.34, color: BasketColors.primary.withValues(alpha: 0.45)),
                ),
              ),
            ),
            if (discountPct > 0)
              Positioned(
                left: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(color: BasketColors.ink, borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    '$discountPct% OFF',
                    style: GoogleFonts.poppins(fontSize: 8.5, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Small rounded-square version for compact rows/lists (subcategory rail,
/// last-order card) where the discount badge doesn't fit.
class ProductImageMini extends StatelessWidget {
  const ProductImageMini({super.key, this.size = 42, this.icon = Icons.shopping_basket_rounded});

  final double size;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: BasketColors.primarySoft, borderRadius: BorderRadius.circular(size * 0.28)),
      alignment: Alignment.center,
      child: Icon(icon, size: size * 0.44, color: BasketColors.primary.withValues(alpha: 0.6)),
    );
  }
}
