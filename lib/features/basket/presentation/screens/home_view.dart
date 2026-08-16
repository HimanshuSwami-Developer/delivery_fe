import 'package:fastswipe/core/basket_api/models/promotion_models.dart';
import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/cubit/basket_selectors.dart';
import 'package:fastswipe/features/basket/data/basket_enums.dart';
import 'package:fastswipe/features/basket/data/models.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:fastswipe/features/basket/presentation/widgets/add_qty_control.dart';
import 'package:fastswipe/features/basket/presentation/widgets/glass.dart';
import 'package:fastswipe/features/basket/presentation/widgets/product_image.dart';
import 'package:fastswipe/features/basket/presentation/widgets/promo_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletonizer/skeletonizer.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketCubit>();
    final catalogLoading = context.select((BasketCubit c) => c.state.catalogLoading);
    final categories = context.select((BasketCubit c) => categoriesOf(c.state));
    final buyAgain = context.select((BasketCubit c) => buyAgainProducts(c.state));
    final under99 = context.select((BasketCubit c) => productsOf(c.state).where((p) => p.price < 99 && !p.oos).take(6).toList());
    final recommended = context.select((BasketCubit c) => recommendedProducts(c.state));
    final banners = context.select((BasketCubit c) => c.state.apiBanners);

    if (catalogLoading && categories.isEmpty) {
      return const _HomeSkeleton();
    }

    // Page order: top banner → category → products → banner → recommended
    // → two more banners. `banners` is already ordered by the backend
    // (`Banner.Meta.ordering = ['order', ...]`), so slots just take
    // consecutive slices of it rather than filtering by any client-side
    // placement flag — that also means a slot silently disappears if the
    // admin hasn't added enough banners yet, instead of crashing on a
    // missing index.
    final topBanner = banners.isNotEmpty ? banners[0] : null;
    final midBanner = banners.length > 1 ? banners[1] : null;
    final bottomBanners = banners.length > 2 ? banners.sublist(2, banners.length.clamp(2, 4)) : const <ApiBanner>[];

    return Column(
      children: [
        const _HomeHeader(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(top: 18, bottom: 120),
            children: [
              if (topBanner != null) ...[
                Padding(padding: const EdgeInsets.symmetric(horizontal: 18), child: PromoBanner(banner: topBanner)),
                const SizedBox(height: 22),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: _SectionHeader(title: 'Shop by category', action: 'See all', onAction: () => cubit.go(BasketScreen.cats)),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 106,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  itemCount: categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 14),
                  itemBuilder: (context, i) => _CategoryChip(category: categories[i]),
                ),
              ),
              const SizedBox(height: 26),
              if (BasketCubit.showBuyAgain && buyAgain.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: _SectionHeader(title: 'Buy again', action: 'See all', onAction: () {}),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  // `IntrinsicHeight` (not a fixed-height `SizedBox`) so the
                  // row's height comes from its tallest card's actual
                  // content — a fixed height either clips a longer product
                  // name/rows or leaves dead space under a shorter one.
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        for (var i = 0; i < buyAgain.length; i++) ...[
                          if (i > 0) const SizedBox(width: 10),
                          _BuyAgainCard(product: buyAgain[i]),
                        ],
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(18, 14, 18, 0),
                  child: _LastOrderCard(),
                ),
                const SizedBox(height: 22),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: _SectionHeader(title: 'Under ₹99 store', action: 'See all', onAction: () {}),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      for (var i = 0; i < under99.length; i++) ...[
                        if (i > 0) const SizedBox(width: 10),
                        _PriceCard(product: under99[i], width: 132),
                      ],
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(18, 18, 18, 0),
                child: _CouponBanner(),
              ),
              if (midBanner != null) ...[
                const SizedBox(height: 24),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 18), child: PromoBanner(banner: midBanner)),
              ],
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: _SectionHeader(title: 'Recommended for you', action: '', onAction: () {}),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                // A `Wrap` of fixed-width cards, not a `GridView` with a
                // fixed `childAspectRatio` — the aspect ratio forced every
                // card into the same box regardless of how many lines its
                // name/pack/rating actually needed, clipping longer content
                // and leaving dead space under shorter content. Each card
                // sizes to its own content height here (see
                // `_RecommendedCard`'s `mainAxisSize: min`); rows aren't
                // height-matched across the two columns, same as most
                // grocery-app "recommended" grids.
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cardWidth = (constraints.maxWidth - 12) / 2;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final product in recommended)
                          SizedBox(width: cardWidth, child: _RecommendedCard(product: product)),
                      ],
                    );
                  },
                ),
              ),
              if (bottomBanners.isNotEmpty) ...[
                const SizedBox(height: 24),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 18), child: PromoBannerRow(banners: bottomBanners)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

const _skeletonCategory = BasketCategory(key: 'x', name: 'Category name', subs: [], count: 12);
const _skeletonProduct = BasketProduct(
  id: 'x',
  name: 'Product name placeholder',
  pack: '500 g',
  price: 99,
  mrp: 129,
  cat: 'x',
  sub: 'x',
  brand: 'Brand',
  rating: 4.5,
  ratingsCount: 10,
);

/// Shown while [BasketState.catalogLoading] and nothing's cached yet —
/// mirrors [HomeView]'s real layout with placeholder cards so the shimmer
/// matches what's about to load in, instead of a plain spinner.
class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    final categories = List.generate(5, (_) => _skeletonCategory);
    final products = List.generate(4, (_) => _skeletonProduct);

    return Column(
      children: [
        const _HomeHeader(),
        Expanded(
          child: IgnorePointer(
            child: Skeletonizer(
              effect: ShimmerEffect(baseColor: BasketColors.divider, highlightColor: BasketColors.surface),
              child: ListView(
                padding: const EdgeInsets.only(top: 18, bottom: 120),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Container(height: 132, decoration: BoxDecoration(color: BasketColors.surface, borderRadius: BorderRadius.circular(20))),
                  ),
                  const SizedBox(height: 22),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: _SectionHeader(title: 'Shop by category', action: 'See all', onAction: () {}),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 106,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      itemCount: categories.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 14),
                      itemBuilder: (context, i) => _CategoryChip(category: categories[i]),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: _SectionHeader(title: 'Under ₹99 store', action: 'See all', onAction: () {}),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 226,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      itemCount: products.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, i) => _PriceCard(product: products[i], width: 132),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: _SectionHeader(title: 'Recommended for you', action: '', onAction: () {}),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: products.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.66,
                      ),
                      itemBuilder: (context, i) => _RecommendedCard(product: products[i]),
                    ),
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

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketCubit>();
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(26)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(18, MediaQuery.paddingOf(context).top + 12, 18, 18),
        decoration: const BoxDecoration(gradient: BasketColors.headerGradient),
        child: Stack(
          children: [
            Positioned(
              top: -50,
              right: -40,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(shape: BoxShape.circle, color: BasketColors.primary.withValues(alpha: 0.14)),
              ),
            ),
            Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.bolt_rounded, size: 13, color: BasketColors.gold),
                              const SizedBox(width: 3),
                              Text(
                                'DELIVERY IN ${BasketCubit.etaMinutes} MIN',
                                style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.6), letterSpacing: 0.8),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'Home · Koramangala',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Colors.white.withValues(alpha: 0.6)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: cubit.goToNotifications,
                      borderRadius: BorderRadius.circular(99),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 19),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => cubit.go(BasketScreen.search),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded, size: 18, color: BasketColors.muted),
                        const SizedBox(width: 10),
                        Text(
                          'Search "atta, milk, dal"',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600, color: BasketColors.muted),
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
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.action, required this.onAction});

  final String title;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: BasketColors.ink)),
        if (action.isNotEmpty)
          GestureDetector(
            onTap: onAction,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(action, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: BasketColors.primary)),
                Icon(Icons.chevron_right_rounded, size: 15, color: BasketColors.primary),
              ],
            ),
          ),
      ],
    );
  }
}

class _RatingPill extends StatelessWidget {
  const _RatingPill({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    if (rating <= 0) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: 13, color: BasketColors.gold),
        const SizedBox(width: 2),
        Text(rating.toStringAsFixed(1), style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w600, color: BasketColors.muted)),
      ],
    );
  }
}

class _BuyAgainCard extends StatelessWidget {
  const _BuyAgainCard({required this.product});

  final BasketProduct product;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketCubit>();
    return GestureDetector(
      onTap: () => cubit.openProduct(product.id),
      child: Container(
        width: 108,
        padding: const EdgeInsets.all(8),
        decoration: productCardDecoration(radius: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProductImage(height: 66, imageUrl: product.imageUrl),
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: BasketColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                  elevation: 0,
                ),
                onPressed: () => cubit.bump(product.id, 1),
                child: Text(
                  'ADD ${moneyLabel(product.price)}',
                  style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LastOrderCard extends StatelessWidget {
  const _LastOrderCard();

  @override
  Widget build(BuildContext context) {
    final last = context.select((BasketCubit c) => c.state.apiOrders.isNotEmpty ? c.state.apiOrders.first : null);
    if (last == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: glassCard(radius: 18),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: BasketColors.primarySoft, borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: Icon(Icons.receipt_long_rounded, size: 20, color: BasketColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your last order · ${last.itemCount} items', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: BasketColors.ink)),
                const SizedBox(height: 3),
                Text(
                  '${moneyLabel(last.total)} · ${orderStatusLabel(last.status)}',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w500, color: BasketColors.muted),
                ),
              ],
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: BasketColors.primary,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              minimumSize: Size.zero,
            ),
            onPressed: context.read<BasketCubit>().repeatOrder,
            child: Text('Repeat', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _CouponBanner extends StatelessWidget {
  const _CouponBanner();

  @override
  Widget build(BuildContext context) {
    final coupon = context.select((BasketCubit c) => c.state.apiCoupons.isNotEmpty ? c.state.apiCoupons.first : null);
    if (coupon == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => context.read<BasketCubit>().openCoupons(code: coupon.code),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: BasketColors.accentTeal,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -30,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.14)),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(11)),
                  alignment: Alignment.center,
                  child: const Icon(Icons.local_offer_rounded, size: 19, color: BasketColors.accentTeal),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${coupon.code} · ${coupon.title}', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(
                        'Tap to apply at checkout',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.55)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(99)),
                  child: Text('Apply', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category});

  final BasketCategory category;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<BasketCubit>().openCategory(category),
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: BasketColors.primarySoft,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: BasketColors.primary.withValues(alpha: 0.12)),
              ),
              alignment: Alignment.center,
              child: category.imageUrl.isEmpty
                  ? const Text('🛒', style: TextStyle(fontSize: 28))
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        category.imageUrl,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Text('🛒', style: TextStyle(fontSize: 28)),
                      ),
                    ),
            ),
            const SizedBox(height: 7),
            SizedBox(
              height: 30,
              child: Text(
                category.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(fontSize: 11, height: 1.2, fontWeight: FontWeight.w700, color: BasketColors.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  const _PriceCard({required this.product, required this.width});

  final BasketProduct product;
  final double width;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<BasketCubit>().openProduct(product.id),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(9),
        decoration: productCardDecoration(radius: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProductImage(height: 84, imageUrl: product.imageUrl, discountPct: product.discountPct),
            const SizedBox(height: 8),
            SizedBox(
              height: 30,
              child: Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(fontSize: 11.5, height: 1.3, fontWeight: FontWeight.w600, color: BasketColors.ink),
              ),
            ),
            const SizedBox(height: 2),
            Text(product.pack, style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w500, color: BasketColors.faint)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(moneyLabel(product.price), style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: BasketColors.ink)),
                    if (product.mrp > product.price)
                      Text(
                        moneyLabel(product.mrp),
                        style: GoogleFonts.plusJakartaSans(fontSize: 9.5, fontWeight: FontWeight.w500, color: BasketColors.muted, decoration: TextDecoration.lineThrough),
                      ),
                  ],
                ),
                AddQtyControl(product: product),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendedCard extends StatelessWidget {
  const _RecommendedCard({required this.product});

  final BasketProduct product;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<BasketCubit>().openProduct(product.id),
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: productCardDecoration(radius: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProductImage(height: 96, imageUrl: product.imageUrl, discountPct: product.discountPct),
            const SizedBox(height: 8),
            SizedBox(
              height: 30,
              child: Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(fontSize: 11.5, height: 1.3, fontWeight: FontWeight.w600, color: BasketColors.ink),
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: Text(product.pack, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w500, color: BasketColors.faint)),
                ),
                _RatingPill(rating: product.rating),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(moneyLabel(product.price), style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: BasketColors.ink)),
                AddQtyControl(product: product),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
