import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The product's real Cloudinary-hosted photo (via [imageUrl]) — falls back
/// to a soft tinted placeholder icon when the product has no photo yet, or
/// the photo fails to load. Shared by every screen with a product
/// grid/list/detail (home, category browse, search, cart, product detail).
class ProductImage extends StatelessWidget {
  const ProductImage({super.key, required this.height, this.imageUrl = '', this.discountPct = 0, this.radius = 14});

  final double height;
  final String imageUrl;
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
              child: imageUrl.isEmpty
                  ? DecoratedBox(
                      decoration: const BoxDecoration(color: BasketColors.primarySoft),
                      child: Center(
                        child: Icon(Icons.shopping_basket_rounded, size: height * 0.34, color: BasketColors.primary.withValues(alpha: 0.45)),
                      ),
                    )
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => DecoratedBox(
                        decoration: const BoxDecoration(color: BasketColors.primarySoft),
                        child: Center(
                          child: Icon(Icons.shopping_basket_rounded, size: height * 0.34, color: BasketColors.primary.withValues(alpha: 0.45)),
                        ),
                      ),
                    ),
            ),
            if (discountPct > 0)
              Positioned(
                left: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(color: BasketColors.accentOrange, borderRadius: BorderRadius.circular(6)),
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
/// last-order card, cart/wishlist/search rows) where the discount badge
/// doesn't fit. Shows the real photo via [imageUrl] when there is one.
class ProductImageMini extends StatelessWidget {
  const ProductImageMini({super.key, this.size = 42, this.imageUrl = '', this.icon = Icons.shopping_basket_rounded});

  final double size;
  final String imageUrl;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: BasketColors.primarySoft, borderRadius: BorderRadius.circular(size * 0.28)),
      alignment: Alignment.center,
      child: Icon(icon, size: size * 0.44, color: BasketColors.primary.withValues(alpha: 0.6)),
    );
    if (imageUrl.isEmpty) return placeholder;
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.28),
      child: Image.network(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => placeholder,
      ),
    );
  }
}
