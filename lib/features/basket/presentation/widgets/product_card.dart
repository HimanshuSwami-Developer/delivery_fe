import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/cubit/basket_selectors.dart';
import 'package:fastswipe/features/basket/data/models.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:fastswipe/features/basket/presentation/basket_ui.dart';
import 'package:fastswipe/features/basket/presentation/widgets/add_qty_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

/// The one product tile used by every grid/rail on home, category browse
/// and the product page — quick-commerce layout built only from data the
/// product already has: photo on a soft backdrop with a discount flag,
/// wishlist heart and the ADD/stepper overlapping its bottom edge; then
/// name, pack (+ rating when it has one), price vs MRP and the saving.
///
/// Rows only take space when they have something to show — no reserved
/// blank lines. In a horizontal rail pass [fill] (inside an
/// `IntrinsicHeight` row with `CrossAxisAlignment.stretch`) to pin the
/// price to the bottom so neighbouring tiles line their prices up.
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, required this.width, this.fill = false});

  final BasketProduct product;

  /// Tile width — the photo is sized from it (roughly square), which is
  /// why it's passed in rather than measured: these tiles sit inside
  /// `IntrinsicHeight` rails, where a `LayoutBuilder` isn't allowed.
  final double width;

  /// Stretch to the parent's (bounded) height, pushing the price block to
  /// the bottom. Only for rails that give the tile a height — inside a
  /// `Wrap` the height is unbounded, so leave it off there.
  final bool fill;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketCubit>();
    final imageHeight = (width - 2 * BasketSpace.xs).clamp(84.0, 156.0);
    final saving = product.mrp - product.price;

    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => cubit.openProduct(product.id),
          borderRadius: BasketRadius.card,
          child: Ink(
            decoration: basketCard(),
            padding: const EdgeInsets.all(BasketSpace.xs),
            child: Column(
              mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photo + the ADD control half-hanging off its bottom edge.
                // The extra 14px below the photo is that overhang, kept
                // inside the Stack so the button stays tappable.
                SizedBox(
                  height: imageHeight + 14,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        height: imageHeight,
                        child: _ProductPhoto(product: product),
                      ),
                      Positioned(right: BasketSpace.xxs, bottom: 0, child: AddQtyControl(product: product)),
                    ],
                  ),
                ),
                const SizedBox(height: BasketSpace.xxs),
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(fontSize: 12.5, height: 1.3, fontWeight: FontWeight.w700, color: BasketColors.ink),
                ),
                const SizedBox(height: 2),
                _PackLine(product: product),
                if (fill) const Spacer() else const SizedBox(height: 6),
                if (fill) const SizedBox(height: 6),
                ProductPrice(product: product),
                if (saving > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(
                      'SAVE ${moneyLabel(saving)}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.2, color: BasketColors.success),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "1 kg · ★ 4.3 (128)" — pack size, with the rating tucked on the same
/// line only when the product actually has ratings.
class _PackLine extends StatelessWidget {
  const _PackLine({required this.product});

  final BasketProduct product;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            product.pack,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500, color: BasketColors.muted),
          ),
        ),
        if (product.rating > 0) ...[
          Text(' · ', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: BasketColors.faint)),
          Flexible(child: ProductRating(product: product)),
        ],
      ],
    );
  }
}

/// Two-column product grid whose rows are height-matched: each pair sits
/// in an `IntrinsicHeight` row and the cards [ProductCard.fill] it, so
/// prices line up across a row without any reserved blank lines.
class ProductGrid extends StatelessWidget {
  const ProductGrid({super.key, required this.products, this.spacing = BasketSpace.sm});

  final List<BasketProduct> products;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - spacing) / 2;
        return Column(
          children: [
            for (var i = 0; i < products.length; i += 2) ...[
              if (i > 0) SizedBox(height: spacing),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ProductCard(product: products[i], width: cardWidth, fill: true),
                    SizedBox(width: spacing),
                    if (i + 1 < products.length) ProductCard(product: products[i + 1], width: cardWidth, fill: true),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// A horizontal rail of [ProductCard]s, height-matched the same way.
class ProductRail extends StatelessWidget {
  const ProductRail({super.key, required this.products, this.cardWidth = 140, this.padding = EdgeInsets.zero});

  final List<BasketProduct> products;
  final double cardWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      clipBehavior: Clip.none,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < products.length; i++) ...[
              if (i > 0) const SizedBox(width: BasketSpace.sm),
              ProductCard(product: products[i], width: cardWidth, fill: true),
            ],
          ],
        ),
      ),
    );
  }
}

/// List-view version of [ProductCard] for category browse's row mode: the
/// same pieces laid out horizontally.
class ProductRowCard extends StatelessWidget {
  const ProductRowCard({super.key, required this.product});

  final BasketProduct product;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketCubit>();
    final saving = product.mrp - product.price;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => cubit.openProduct(product.id),
        borderRadius: BasketRadius.card,
        child: Ink(
          decoration: basketCard(),
          padding: const EdgeInsets.all(BasketSpace.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 92, height: 92, child: _ProductPhoto(product: product, compact: true)),
              const SizedBox(width: BasketSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.3, fontWeight: FontWeight.w700, color: BasketColors.ink),
                    ),
                    const SizedBox(height: 2),
                    _PackLine(product: product),
                    const SizedBox(height: BasketSpace.xs),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ProductPrice(product: product),
                              if (saving > 0)
                                Text(
                                  'SAVE ${moneyLabel(saving)}',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.2, color: BasketColors.success),
                                ),
                            ],
                          ),
                        ),
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

/// Photo on a soft ivory backdrop (`contain`, so packshots aren't cropped),
/// discount flag in the top-left corner, wishlist heart top-right, and a
/// greyed-out "Out of stock" state.
class _ProductPhoto extends StatelessWidget {
  const _ProductPhoto({required this.product, this.compact = false});

  final BasketProduct product;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final placeholder = Center(child: Icon(Icons.shopping_basket_rounded, size: compact ? 30 : 38, color: BasketColors.faint));
    Widget photo = product.imageUrl.isEmpty
        ? placeholder
        : Padding(
            padding: const EdgeInsets.all(BasketSpace.xs),
            child: Image.network(
              product.imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => placeholder,
            ),
          );
    if (product.oos) {
      photo = ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          0.33, 0.33, 0.33, 0, 0, //
          0.33, 0.33, 0.33, 0, 0,
          0.33, 0.33, 0.33, 0, 0,
          0, 0, 0, 0.55, 0,
        ]),
        child: photo,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(BasketRadius.sm),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), BasketColors.primarySoft],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            photo,
            if (product.discountPct > 0 && !product.oos) Positioned(left: 0, top: 0, child: _DiscountFlag(pct: product.discountPct)),
            if (!compact) Positioned(right: BasketSpace.xxs, top: BasketSpace.xxs, child: _WishlistHeart(productId: product.id)),
            if (product.oos)
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: BasketSpace.xs, vertical: BasketSpace.xxs),
                  decoration: BoxDecoration(color: BasketColors.ink.withValues(alpha: 0.82), borderRadius: BasketRadius.chip),
                  child: Text(
                    'Out of stock',
                    style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w700, color: BasketColors.onPrimary),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Corner flag — "18% OFF" stacked on two lines, gold on navy, squared
/// off where it meets the photo's corner.
class _DiscountFlag extends StatelessWidget {
  const _DiscountFlag({required this.pct});

  final int pct;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 4, 7, 5),
      decoration: const BoxDecoration(
        color: BasketColors.primary,
        borderRadius: BorderRadius.only(bottomRight: Radius.circular(BasketRadius.sm)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$pct%', style: GoogleFonts.plusJakartaSans(fontSize: 11, height: 1, fontWeight: FontWeight.w800, color: BasketColors.gold)),
          const SizedBox(height: 1),
          Text('OFF', style: GoogleFonts.plusJakartaSans(fontSize: 8, height: 1, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: BasketColors.onPrimary)),
        ],
      ),
    );
  }
}

class _WishlistHeart extends StatelessWidget {
  const _WishlistHeart({required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context) {
    final saved = context.select((BasketCubit c) => c.state.wishlist.contains(productId));
    return Semantics(
      button: true,
      label: saved ? 'Remove from wishlist' : 'Add to wishlist',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.read<BasketCubit>().toggleWishlist(productId),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            shape: BoxShape.circle,
            border: Border.all(color: BasketSurface.border),
          ),
          alignment: Alignment.center,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
            child: Icon(
              saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              key: ValueKey(saved),
              size: 16,
              color: saved ? BasketColors.error : BasketColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}

/// ★ 4.3 (128) — nothing when the product has no ratings yet.
class ProductRating extends StatelessWidget {
  const ProductRating({super.key, required this.product});

  final BasketProduct product;

  @override
  Widget build(BuildContext context) {
    if (product.rating <= 0) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, size: 13, color: BasketColors.gold),
        const SizedBox(width: 2),
        Flexible(
          child: Text.rich(
            TextSpan(
              text: product.rating.toStringAsFixed(1),
              style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: BasketColors.ink),
              children: [
                if (product.ratingsCount > 0)
                  TextSpan(
                    text: ' (${product.ratingsCount})',
                    style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w500, color: BasketColors.faint),
                  ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Selling price, with the MRP struck through beside it when discounted.
class ProductPrice extends StatelessWidget {
  const ProductPrice({super.key, required this.product});

  final BasketProduct product;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: moneyLabel(product.price),
            style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w800, color: BasketColors.ink),
          ),
          if (product.mrp > product.price)
            TextSpan(
              text: '  ${moneyLabel(product.mrp)}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: BasketColors.faint,
                decoration: TextDecoration.lineThrough,
                decorationColor: BasketColors.faint,
              ),
            ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
