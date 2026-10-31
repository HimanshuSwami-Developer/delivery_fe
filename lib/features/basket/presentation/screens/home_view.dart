import 'package:fastswipe/core/basket_api/models/promotion_models.dart';
import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/cubit/basket_selectors.dart';
import 'package:fastswipe/features/basket/data/basket_enums.dart';
import 'package:fastswipe/features/basket/data/models.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:fastswipe/features/basket/presentation/basket_ui.dart';
import 'package:fastswipe/features/basket/presentation/festival_theme.dart';
import 'package:fastswipe/features/basket/presentation/widgets/festival_overlay.dart';
import 'package:fastswipe/features/basket/presentation/widgets/glass.dart';
import 'package:fastswipe/features/basket/presentation/widgets/product_card.dart';
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
            padding: const EdgeInsets.only(top: BasketSpace.md, bottom: 120),
            children: [
              if (topBanner != null) ...[
                Padding(padding: const EdgeInsets.symmetric(horizontal: BasketSpace.gutter), child: PromoBanner(banner: topBanner)),
                const SizedBox(height: BasketSpace.xl),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: BasketSpace.gutter),
                child: _SectionHeader(title: 'Shop by category', action: 'See all', onAction: () => cubit.go(BasketScreen.cats)),
              ),
              const SizedBox(height: BasketSpace.sm),
              SizedBox(
                height: 106,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: BasketSpace.gutter),
                  itemCount: categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: BasketSpace.sm),
                  itemBuilder: (context, i) => _CategoryChip(category: categories[i]),
                ),
              ),
              const SizedBox(height: BasketSpace.xl),
              if (BasketCubit.showBuyAgain && buyAgain.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: BasketSpace.gutter),
                  child: _SectionHeader(title: 'Buy again', action: 'See all', onAction: () {}),
                ),
                const SizedBox(height: BasketSpace.sm),
                ProductRail(products: buyAgain, cardWidth: 132, padding: const EdgeInsets.symmetric(horizontal: BasketSpace.gutter)),
                const Padding(
                  padding: EdgeInsets.fromLTRB(BasketSpace.gutter, BasketSpace.section, BasketSpace.gutter, 0),
                  child: _LastOrderCard(),
                ),
                const SizedBox(height: BasketSpace.xl),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: BasketSpace.gutter),
                child: _SectionHeader(title: 'Under ₹99 store', action: 'See all', onAction: () {}),
              ),
              const SizedBox(height: BasketSpace.sm),
              ProductRail(products: under99, cardWidth: 140, padding: const EdgeInsets.symmetric(horizontal: BasketSpace.gutter)),
              const Padding(
                padding: EdgeInsets.fromLTRB(BasketSpace.gutter, BasketSpace.xl, BasketSpace.gutter, 0),
                child: _CouponBanner(),
              ),
              if (midBanner != null) ...[
                const SizedBox(height: BasketSpace.xl),
                Padding(padding: const EdgeInsets.symmetric(horizontal: BasketSpace.gutter), child: PromoBanner(banner: midBanner)),
              ],
              const SizedBox(height: BasketSpace.xl),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: BasketSpace.gutter),
                child: _SectionHeader(title: 'Recommended for you', action: '', onAction: () {}),
              ),
              const SizedBox(height: BasketSpace.sm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: BasketSpace.gutter),
                // Not a `GridView` with a fixed `childAspectRatio` (that clipped long
                // names or left dead space under short ones): each pair of cards is
                // as tall as its taller card, prices pinned to the bottom — see
                // `ProductGrid`.
                child: ProductGrid(products: recommended),
              ),
              if (bottomBanners.isNotEmpty) ...[
                const SizedBox(height: BasketSpace.xl),
                Padding(padding: const EdgeInsets.symmetric(horizontal: BasketSpace.gutter), child: PromoBannerRow(banners: bottomBanners)),
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
                padding: const EdgeInsets.only(top: BasketSpace.md, bottom: 120),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: BasketSpace.gutter),
                    child: Container(height: 132, decoration: BoxDecoration(color: BasketColors.surface, borderRadius: BorderRadius.circular(BasketRadius.xl))),
                  ),
                  const SizedBox(height: BasketSpace.xl),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: BasketSpace.gutter),
                    child: _SectionHeader(title: 'Shop by category', action: 'See all', onAction: () {}),
                  ),
                  const SizedBox(height: BasketSpace.sm),
                  SizedBox(
                    height: 106,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: BasketSpace.gutter),
                      itemCount: categories.length,
                      separatorBuilder: (_, _) => const SizedBox(width: BasketSpace.sm),
                      itemBuilder: (context, i) => _CategoryChip(category: categories[i]),
                    ),
                  ),
                  const SizedBox(height: BasketSpace.xl),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: BasketSpace.gutter),
                    child: _SectionHeader(title: 'Under ₹99 store', action: 'See all', onAction: () {}),
                  ),
                  const SizedBox(height: BasketSpace.sm),
                  ProductRail(products: products, cardWidth: 140, padding: const EdgeInsets.symmetric(horizontal: BasketSpace.gutter)),
                  const SizedBox(height: BasketSpace.xl),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: BasketSpace.gutter),
                    child: _SectionHeader(title: 'Recommended for you', action: '', onAction: () {}),
                  ),
                  const SizedBox(height: BasketSpace.sm),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: BasketSpace.gutter),
                    child: ProductGrid(products: products),
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
    final addressSubtitle = context.select((BasketCubit c) => homeAddressSubtitle(c.state));
    final festivalSettings = context.select((BasketCubit c) => c.state.apiFestivalSettings);
    final festival = FestivalCalendar.activeToday(settings: festivalSettings);
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(BasketRadius.xl)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(BasketSpace.gutter, MediaQuery.paddingOf(context).top + BasketSpace.sm, BasketSpace.gutter, BasketSpace.md),
        decoration: BoxDecoration(gradient: festival?.gradient ?? BasketColors.headerGradient),
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
            if (festival != null) FestivalOverlay(theme: festival),
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
                              Icon(Icons.bolt_rounded, size: 13, color: festival?.accent ?? BasketColors.gold),
                              const SizedBox(width: 3),
                              Text(
                                'DELIVERY IN ${BasketCubit.etaMinutes} MIN',
                                style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFFFFFBF2).withValues(alpha: 0.6), letterSpacing: 0.8),
                              ),
                            ],
                          ),
                          if (festival != null) ...[
                            const SizedBox(height: BasketSpace.xs),
                            FestivalBadge(theme: festival),
                          ],
                          const SizedBox(height: BasketSpace.xxs),
                          GestureDetector(
                            onTap: cubit.goToAddress,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Home',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFFFFBF2)),
                                    ),
                                    const SizedBox(width: BasketSpace.xxs),
                                    Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFFFFFBF2).withValues(alpha: 0.6)),
                                  ],
                                ),
                                Text(
                                  addressSubtitle ?? 'Add a delivery address',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFFFFFBF2).withValues(alpha: 0.65)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: cubit.goToNotifications,
                      borderRadius: BorderRadius.circular(BasketRadius.pill),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(0xFFFFFBF2).withValues(alpha: 0.1),
                          border: Border.all(color: Color(0xFFFFFBF2).withValues(alpha: 0.14)),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.notifications_none_rounded, color: Color(0xFFFFFBF2), size: 19),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: BasketSpace.md),
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
                        Icon(Icons.search_rounded, size: 18, color: BasketColors.muted),
                        const SizedBox(width: BasketSpace.xs),
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
      children: [
        Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: BasketColors.ink)),
        if (action.isNotEmpty)
          BasketButton.text(
            label: action,
            size: BasketButtonSize.small,
            trailingIcon: Icons.chevron_right_rounded,
            onPressed: onAction,
          ),
      ],
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
      padding: const EdgeInsets.all(BasketSpace.sm),
      decoration: glassCard(radius: 18),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: BasketColors.primarySoft, borderRadius: BorderRadius.circular(BasketRadius.md)),
            alignment: Alignment.center,
            child: Icon(Icons.receipt_long_rounded, size: 20, color: BasketColors.primary),
          ),
          const SizedBox(width: BasketSpace.sm),
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
          BasketButton(
            label: 'Repeat',
            size: BasketButtonSize.small,
            expand: false,
            onPressed: context.read<BasketCubit>().repeatOrder,
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
    // Never promote a coupon this customer can't use (already used, expired).
    final coupon = context.select((BasketCubit c) => firstUsableCoupon(c.state));
    if (coupon == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => context.read<BasketCubit>().openCoupons(code: coupon.code),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(BasketSpace.md),
        decoration: BoxDecoration(
          color: BasketColors.accentTeal,
          borderRadius: BorderRadius.circular(BasketRadius.lg),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -30,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFFFBF2).withValues(alpha: 0.14)),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: Color(0xFFFFFBF2), borderRadius: BorderRadius.circular(BasketRadius.md)),
                  alignment: Alignment.center,
                  child: const Icon(Icons.local_offer_rounded, size: 19, color: BasketColors.accentTeal),
                ),
                const SizedBox(width: BasketSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${coupon.code} · ${coupon.title}', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFFFFFBF2))),
                      const SizedBox(height: BasketSpace.xxs),
                      Text(
                        'Tap to apply at checkout',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w500, color: Color(0xFFFFFBF2).withValues(alpha: 0.55)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: BasketSpace.sm, vertical: BasketSpace.xs),
                  decoration: BoxDecoration(color: Color(0xFFFFFBF2).withValues(alpha: 0.14), borderRadius: BorderRadius.circular(BasketRadius.pill)),
                  child: Text('Apply', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFFFFBF2))),
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
                borderRadius: BorderRadius.circular(BasketRadius.xl),
                border: Border.all(color: BasketSurface.border),
              ),
              alignment: Alignment.center,
              child: category.imageUrl.isEmpty
                  ? const Text('🛒', style: TextStyle(fontSize: 28))
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(BasketRadius.xl),
                      child: Image.network(
                        category.imageUrl,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Text('🛒', style: TextStyle(fontSize: 28)),
                      ),
                    ),
            ),
            const SizedBox(height: BasketSpace.xs),
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

