import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/cubit/basket_selectors.dart';
import 'package:fastswipe/features/basket/data/basket_enums.dart';
import 'package:fastswipe/features/basket/data/models.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:fastswipe/features/basket/presentation/widgets/product_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

const _pdpTabs = [
  (PdpTab.description, 'Description'),
  (PdpTab.nutrition, 'Nutrition'),
  (PdpTab.reviews, 'Reviews'),
];

class ProductDetailView extends StatelessWidget {
  const ProductDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketCubit>();
    final p = context.select((BasketCubit c) => pdpProduct(c.state));
    final cartQty = context.select((BasketCubit c) => c.state.cart[p.id] ?? 0);
    final pdpQty = cartQty > 0 ? cartQty : 1;
    final wished = context.select((BasketCubit c) => c.state.wishlist.contains(p.id));
    final tab = context.select((BasketCubit c) => c.state.pdpTab);
    final also = context.select(
      (BasketCubit c) => productsOf(c.state).where((x) => x.cat == p.cat && x.id != p.id).take(4).toList(),
    );

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Stack(
                children: [
                  ProductImage(height: 290, discountPct: p.discountPct, radius: 0),
                  Positioned(
                    top: MediaQuery.paddingOf(context).top + 8,
                    left: 14,
                    right: 14,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _DarkCircleButton(icon: Icons.arrow_back, onTap: cubit.back),
                        Row(
                          children: [
                            _DarkCircleButton(
                              icon: wished ? Icons.favorite : Icons.favorite_border,
                              onTap: () => cubit.toggleWishlist(p.id),
                            ),
                            const SizedBox(width: 8),
                            const _DarkCircleButton(icon: Icons.ios_share_rounded, onTap: null),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 14,
                    bottom: 34,
                    child: Column(
                      children: [
                        for (var i = 0; i < 4; i++) ...[
                          if (i > 0) const SizedBox(height: 7),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i == 0 ? BasketColors.ink : BasketColors.ink.withValues(alpha: 0.22),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              Transform.translate(
                offset: const Offset(0, -22),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 30),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                    boxShadow: [BoxShadow(color: BasketColors.ink.withValues(alpha: 0.18), blurRadius: 40, offset: const Offset(0, -12))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 34,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(color: BasketColors.ink.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(9)),
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              p.name,
                              style: GoogleFonts.poppins(fontSize: 19, height: 1.25, fontWeight: FontWeight.w800, letterSpacing: -0.4),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                            decoration: BoxDecoration(border: Border.all(color: BasketColors.ink.withValues(alpha: 0.14)), borderRadius: BorderRadius.circular(99)),
                            child: Text('★ ${p.rating}', style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${p.pack} · Delivery in ${BasketCubit.etaMinutes} min',
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: BasketColors.muted),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          for (var i = 0; i < 3; i++) ...[
                            if (i > 0) const SizedBox(width: 8),
                            _VariantPill(label: i == 0 ? p.pack : (i == 1 ? '2 × ${p.pack}' : 'Monthly pack'), selected: i == 0),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(moneyLabel(p.price), style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
                          const SizedBox(width: 9),
                          Text(
                            moneyLabel(p.mrp),
                            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: BasketColors.faint, decoration: TextDecoration.lineThrough),
                          ),
                          const SizedBox(width: 9),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(color: BasketColors.ink, borderRadius: BorderRadius.circular(99)),
                            child: Text('${p.discountPct}% off', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _InfoTile(title: 'Free delivery', sub: 'Above ${moneyLabel(BasketCubit.freeDeliveryAbove)}')),
                          const SizedBox(width: 8),
                          const Expanded(child: _InfoTile(title: 'Easy returns', sub: 'On the doorstep')),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: BasketColors.ink.withValues(alpha: 0.09)))),
                        child: Row(
                          children: [
                            for (final t in _pdpTabs)
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: GestureDetector(
                                  onTap: () => cubit.setPdpTab(t.$1),
                                  child: Container(
                                    padding: const EdgeInsets.only(bottom: 9),
                                    decoration: BoxDecoration(
                                      border: Border(bottom: BorderSide(color: tab == t.$1 ? BasketColors.ink : Colors.transparent, width: 2)),
                                    ),
                                    child: Text(
                                      t.$1 == PdpTab.reviews ? 'Reviews ${_reviewCount(p.ratingsCount)}' : t.$2,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: tab == t.$1 ? BasketColors.ink : BasketColors.faint,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _tabBody(tab, p),
                        style: GoogleFonts.poppins(fontSize: 13, height: 1.7, fontWeight: FontWeight.w500, color: const Color(0xFF4A4A52)),
                      ),
                      const SizedBox(height: 22),
                      Text('Frequently bought with', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 11),
                      SizedBox(
                        height: 148,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: also.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 9),
                          itemBuilder: (context, i) => _AlsoBoughtCard(product: also[i]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            border: Border(top: BorderSide(color: BasketColors.ink.withValues(alpha: 0.07))),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(border: Border.all(color: BasketColors.ink, width: 1.5), borderRadius: BorderRadius.circular(13)),
                  child: Row(
                    children: [
                      _StepButton(label: '−', onTap: () => cubit.bump(p.id, -1)),
                      SizedBox(
                        width: 20,
                        child: Text('$pdpQty', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800)),
                      ),
                      _StepButton(label: '+', onTap: () => cubit.bump(p.id, 1)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: BasketColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: cubit.pdpAdd,
                    child: Text(
                      'Add to cart · ${moneyLabel(p.price * pdpQty)}',
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _reviewCount(int n) {
    if (n > 999) return '${(n / 100).round() / 10}k';
    return '$n';
  }

  static String _tabBody(PdpTab tab, BasketProduct p) {
    switch (tab) {
      case PdpTab.nutrition:
        return 'Per 100 ml — Energy 58 kcal · Protein 3.1 g · Fat 3.0 g · Carbohydrate 4.7 g · Calcium 120 mg. Values are indicative and may vary between batches.';
      case PdpTab.reviews:
        return '4.4 out of 5 from ${indianGroup(p.ratingsCount)} shoppers. Most mentioned: fresh on arrival, well sealed, good value for the pack size.';
      case PdpTab.description:
        return '${p.name} — ${p.pack}. Sourced daily and cold-chain handled from the dark store to your door. Best consumed within 2 days of delivery; keep refrigerated below 5°C.';
    }
  }
}

class _DarkCircleButton extends StatelessWidget {
  const _DarkCircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(color: BasketColors.ink, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }
}

class _VariantPill extends StatelessWidget {
  const _VariantPill({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? BasketColors.ink : Colors.white.withValues(alpha: 0.7),
        border: Border.all(color: selected ? BasketColors.ink : BasketColors.ink.withValues(alpha: 0.14)),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(label, style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w700, color: selected ? Colors.white : BasketColors.ink)),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.title, required this.sub});

  final String title;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        border: Border.all(color: BasketColors.ink.withValues(alpha: 0.07)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(sub, style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w500, color: BasketColors.faint)),
        ],
      ),
    );
  }
}

class _AlsoBoughtCard extends StatelessWidget {
  const _AlsoBoughtCard({required this.product});

  final BasketProduct product;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<BasketCubit>().openProduct(product.id),
      child: Container(
        width: 112,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
          border: Border.all(color: BasketColors.ink.withValues(alpha: 0.07)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProductImage(height: 66, discountPct: product.discountPct, radius: 10),
            const SizedBox(height: 7),
            SizedBox(
              height: 27,
              child: Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 10.5, height: 1.3, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(moneyLabel(product.price), style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w800)),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: BasketColors.ink, width: 1.3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => context.read<BasketCubit>().bump(product.id, 1),
                  child: Text('ADD', style: GoogleFonts.poppins(fontSize: 9.5, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        child: Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800)),
      ),
    );
  }
}
