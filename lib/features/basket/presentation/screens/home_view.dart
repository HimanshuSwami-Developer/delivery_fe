import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/cubit/basket_selectors.dart';
import 'package:fastswipe/features/basket/data/basket_enums.dart';
import 'package:fastswipe/features/basket/data/models.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:fastswipe/features/basket/presentation/widgets/add_qty_control.dart';
import 'package:fastswipe/features/basket/presentation/widgets/glass.dart';
import 'package:fastswipe/features/basket/presentation/widgets/image_slot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

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

    if (catalogLoading && categories.isEmpty) {
      return const Column(children: [_HomeHeader(), Expanded(child: Center(child: CircularProgressIndicator()))]);
    }

    return Column(
      children: [
        const _HomeHeader(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(top: 16, bottom: 120),
            children: [
              if (BasketCubit.showBuyAgain && buyAgain.isNotEmpty) ...[
                _SectionHeader(title: 'Buy again', action: 'See all', onAction: () {}),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    itemCount: buyAgain.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, i) => _BuyAgainCard(product: buyAgain[i]),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(18, 14, 18, 0),
                  child: _LastOrderCard(),
                ),
              ],
              const Padding(
                padding: EdgeInsets.fromLTRB(18, 18, 18, 0),
                child: _CouponBanner(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
                child: _SectionHeader(title: 'Shop by category', action: 'All', onAction: () => cubit.go(BasketScreen.cats)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: categories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.7,
                  ),
                  itemBuilder: (context, i) => _CategoryTile(category: categories[i]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 0),
                child: _SectionHeader(title: 'Under ₹99 store', action: 'See all', onAction: () {}),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 196,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  itemCount: under99.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, i) => _PriceCard(product: under99[i], width: 126, imageHeight: 78),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 0),
                child: Text('Recommended for you', style: GoogleFonts.manrope(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recommended.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.72,
                  ),
                  itemBuilder: (context, i) => _RecommendedCard(product: recommended[i]),
                ),
              ),
            ],
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
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(18, MediaQuery.paddingOf(context).top + 12, 18, 16),
      decoration: darkHeaderDecoration(),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DELIVERY IN ${BasketCubit.etaMinutes} MIN',
                      style: GoogleFonts.manrope(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.5), letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('Home · Koramangala', style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                        const SizedBox(width: 6),
                        Text('▾', style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.6))),
                      ],
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: cubit.goToNotifications,
                borderRadius: BorderRadius.circular(99),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: () => cubit.go(BasketScreen.search),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, size: 16, color: Colors.white.withValues(alpha: 0.6)),
                  const SizedBox(width: 10),
                  Text(
                    'Search "atta, milk, dal"',
                    style: GoogleFonts.manrope(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.55)),
                  ),
                ],
              ),
            ),
          ),
        ],
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(title, style: GoogleFonts.manrope(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
          GestureDetector(
            onTap: onAction,
            child: Text(action, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: BasketColors.muted)),
          ),
        ],
      ),
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
        width: 104,
        padding: const EdgeInsets.all(8),
        decoration: glassCard(radius: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: SizedBox(width: double.infinity, height: 64, child: const ImageSlot(mini: true)),
            ),
            const SizedBox(height: 7),
            SizedBox(
              height: 28,
              child: Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(fontSize: 11, height: 1.3, fontWeight: FontWeight.w600),
              ),
            ),
            Text(product.pack, style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w500, color: BasketColors.faint)),
            const SizedBox(height: 7),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: BasketColors.ink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                  elevation: 0,
                ),
                onPressed: () => cubit.bump(product.id, 1),
                child: Text(
                  'ADD ${moneyLabel(product.price)}',
                  style: GoogleFonts.manrope(fontSize: 10.5, fontWeight: FontWeight.w700),
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
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: const SizedBox(width: 46, height: 46, child: ImageSlot(mini: true)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your last order · ${last.itemCount} items', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(
                  '${moneyLabel(last.total)} · ${orderStatusLabel(last.status)}',
                  style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w500, color: BasketColors.muted),
                ),
              ],
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: BasketColors.ink,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              minimumSize: Size.zero,
            ),
            onPressed: context.read<BasketCubit>().repeatOrder,
            child: Text('Repeat', style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white)),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: BasketColors.ink, borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${coupon.code} · ${coupon.title}', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to apply at checkout',
                    style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.55)),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(99)),
              child: Text('Apply', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category});

  final BasketCategory category;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<BasketCubit>().openCategory(category.key, category.subs.first),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: glassCard(radius: 16),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: const SizedBox(width: 38, height: 38, child: ImageSlot(mini: true)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(fontSize: 12, height: 1.25, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text('${category.count} items', style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w500, color: BasketColors.faint)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  const _PriceCard({
    required this.product,
    required this.width,
    required this.imageHeight,
  });

  final BasketProduct product;
  final double width;
  final double imageHeight;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<BasketCubit>().openProduct(product.id),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(9),
        decoration: glassCard(radius: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(width: double.infinity, height: imageHeight, child: const ImageSlot(mini: true)),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 29,
              child: Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(fontSize: 11.5, height: 1.3, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 2),
            Text(product.pack, style: GoogleFonts.manrope(fontSize: 10.5, fontWeight: FontWeight.w500, color: BasketColors.faint)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(moneyLabel(product.price), style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w800)),
                    Text(
                      moneyLabel(product.mrp),
                      style: GoogleFonts.manrope(fontSize: 9.5, fontWeight: FontWeight.w500, color: BasketColors.faint, decoration: TextDecoration.lineThrough),
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
        decoration: glassCard(radius: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(width: double.infinity, height: 88, child: const ImageSlot(mini: true)),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 29,
              child: Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(fontSize: 11.5, height: 1.3, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 2),
            Text('${product.pack} · ★ ${product.rating}', style: GoogleFonts.manrope(fontSize: 10.5, fontWeight: FontWeight.w500, color: BasketColors.faint)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(moneyLabel(product.price), style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w800)),
                AddQtyControl(product: product),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
