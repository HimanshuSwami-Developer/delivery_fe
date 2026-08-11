import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The product's real Cloudinary-hosted photo (via [imageUrl]) — fills the
/// full width/height of its slot (cropped to fit, never stretched/
/// distorted), the same treatment product photos get on every serious
/// grocery app. Falls back to a placeholder icon on a neutral gray backdrop
/// when the product has no photo yet, or the photo fails to load. Shared by
/// every screen with a product grid/list/detail (home, category browse,
/// search, cart, product detail).
class ProductImage extends StatelessWidget {
  const ProductImage({super.key, required this.height, this.imageUrl = '', this.discountPct = 0, this.radius = 14});

  final double height;
  final String imageUrl;
  final int discountPct;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final placeholder = Center(
      child: Icon(Icons.shopping_basket_rounded, size: height * 0.34, color: BasketColors.faint),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: DecoratedBox(
          decoration: const BoxDecoration(color: BasketColors.surface),
          child: Stack(
            children: [
              if (imageUrl.isEmpty)
                placeholder
              else
                Positioned.fill(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => placeholder,
                  ),
                ),
              if (discountPct > 0)
                Positioned(
                  left: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: const BoxDecoration(color: BasketColors.accentOrangeSoft, borderRadius: BorderRadius.all(Radius.circular(99))),
                    child: Text(
                      '$discountPct% OFF',
                      style: GoogleFonts.poppins(fontSize: 8.5, fontWeight: FontWeight.w800, color: BasketColors.accentOrange),
                    ),
                  ),
                ),
            ],
          ),
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
      decoration: BoxDecoration(color: BasketColors.surface, borderRadius: BorderRadius.circular(size * 0.28)),
      alignment: Alignment.center,
      child: Icon(icon, size: size * 0.44, color: BasketColors.faint),
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
