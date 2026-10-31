import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/core/basket_api/models/order_models.dart';
import 'package:fastswipe/features/basket/cubit/basket_selectors.dart';
import 'package:fastswipe/features/basket/data/basket_enums.dart';
import 'package:fastswipe/features/basket/data/models.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:fastswipe/features/basket/presentation/basket_ui.dart';
import 'package:fastswipe/features/basket/presentation/widgets/cart_bar.dart';
import 'package:fastswipe/features/basket/presentation/widgets/product_card.dart';
import 'package:fastswipe/features/basket/presentation/widgets/product_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

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
    final delivery = context.select((BasketCubit c) => c.state.deliverySettings);
    final cartQty = context.select((BasketCubit c) => c.state.cart[p.id] ?? 0);
    final cartHasItems = context.select((BasketCubit c) => cartTotals(c.state).itemCount > 0);
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
                  _ProductGallery(key: ValueKey(p.id), images: p.galleryImages, discountPct: p.discountPct),
                  Positioned(
                    top: MediaQuery.paddingOf(context).top + 8,
                    left: BasketSpace.gutter,
                    right: BasketSpace.gutter,
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
                            Builder(
                              builder: (buttonContext) => _DarkCircleButton(
                                icon: Icons.ios_share_rounded,
                                onTap: () => _shareProduct(buttonContext, p),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Transform.translate(
                offset: const Offset(0, -22),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(BasketSpace.gutter, BasketSpace.md, BasketSpace.gutter, BasketSpace.xxl),
                  decoration: BoxDecoration(
                    color: Color(0xFFFFFBF2).withValues(alpha: 0.9),
                    borderRadius: BasketRadius.sheet,
                    boxShadow: [BoxShadow(color: BasketColors.ink.withValues(alpha: 0.18), blurRadius: 40, offset: const Offset(0, -12))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 34,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: BasketSpace.sm),
                          decoration: BoxDecoration(color: BasketColors.ink.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(BasketRadius.sm)),
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              p.name,
                              style: GoogleFonts.plusJakartaSans(fontSize: 19, height: 1.25, fontWeight: FontWeight.w800, letterSpacing: -0.4),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: BasketSpace.xs, vertical: BasketSpace.xxs),
                            decoration: BoxDecoration(border: Border.all(color: BasketSurface.borderStrong), borderRadius: BorderRadius.circular(BasketRadius.pill)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, size: 14, color: BasketColors.gold),
                                const SizedBox(width: 2),
                                Text('${p.rating}', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${p.pack} · Delivery in ${BasketCubit.etaMinutes} min',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500, color: BasketColors.muted),
                      ),
                      const SizedBox(height: BasketSpace.sm),
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
                          Text(moneyLabel(p.price), style: GoogleFonts.plusJakartaSans(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
                          const SizedBox(width: BasketSpace.xs),
                          Text(
                            moneyLabel(p.mrp),
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500, color: BasketColors.muted, decoration: TextDecoration.lineThrough),
                          ),
                          const SizedBox(width: BasketSpace.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: BasketSpace.xs, vertical: BasketSpace.xxs),
                            decoration: BoxDecoration(color: BasketColors.gold, borderRadius: BorderRadius.circular(BasketRadius.pill)),
                            child: Text('${p.discountPct}% off', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: BasketColors.primary)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _InfoTile(title: 'Delivery fee', sub: _deliveryFeeLine(delivery))),
                          const SizedBox(width: 8),
                          const Expanded(child: _InfoTile(title: 'Easy returns', sub: 'On the doorstep')),
                        ],
                      ),
                      const SizedBox(height: BasketSpace.lg),
                      Container(
                        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: BasketSurface.border))),
                        child: Row(
                          children: [
                            for (final t in _pdpTabs)
                              Padding(
                                padding: const EdgeInsets.only(right: BasketSpace.sm),
                                child: GestureDetector(
                                  onTap: () => cubit.setPdpTab(t.$1),
                                  child: Container(
                                    padding: const EdgeInsets.only(bottom: BasketSpace.xs),
                                    decoration: BoxDecoration(
                                      border: Border(bottom: BorderSide(color: tab == t.$1 ? BasketColors.ink : Colors.transparent, width: 2)),
                                    ),
                                    child: Text(
                                      t.$1 == PdpTab.reviews ? 'Reviews ${_reviewCount(p.ratingsCount)}' : t.$2,
                                      style: GoogleFonts.plusJakartaSans(
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
                      const SizedBox(height: BasketSpace.sm),
                      if (tab == PdpTab.reviews)
                        _ReviewsTab(key: ValueKey(p.id), product: p)
                      else
                        Text(
                          _tabBody(tab, p),
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.7, fontWeight: FontWeight.w500, color: const Color(0xFF4A4A52)),
                        ),
                      const SizedBox(height: BasketSpace.xl),
                      Text('Frequently bought with', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800)),
                      const SizedBox(height: BasketSpace.sm),
                      // The shared tile, so ADD flips to a live −/qty/+
                      // stepper here exactly as on home/category.
                      ProductRail(products: also, cardWidth: 140),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // "View basket" bar, sat in-flow above the sticky add bar (the
        // shell's floating one is hidden on this screen so it can't cover
        // that bar) — appears as soon as anything, e.g. a "Frequently
        // bought with" item, is in the cart.
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: cartHasItems
              ? const Padding(
                  padding: EdgeInsets.fromLTRB(BasketSpace.gutter, BasketSpace.xs, BasketSpace.gutter, BasketSpace.xs),
                  child: CartBar(),
                )
              : const SizedBox(width: double.infinity),
        ),
        BasketBottomBar(
          child: Row(
            children: [
              Container(
                height: 52,
                decoration: BoxDecoration(border: Border.all(color: BasketSurface.borderStrong), borderRadius: BasketRadius.button),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _StepButton(label: '−', onTap: () => cubit.bump(p.id, -1)),
                    SizedBox(
                      width: 20,
                      child: Center(child: Text('$pdpQty', textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800))),
                    ),
                    _StepButton(label: '+', onTap: () => cubit.bump(p.id, 1)),
                  ],
                ),
              ),
              const SizedBox(width: BasketSpace.sm),
              Expanded(
                child: BasketButton(
                  label: 'Add to cart · ${moneyLabel(p.price * pdpQty)}',
                  onPressed: cubit.pdpAdd,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Opens the system share sheet with the product's name, pack, price
  /// (and discount vs MRP when there is one) plus the Play Store link.
  /// [context] is the share button's own, so iPad can anchor the popover
  /// to it.
  static Future<void> _shareProduct(BuildContext context, BasketProduct p) {
    final price = p.mrp > p.price
        ? '${moneyLabel(p.price)} (MRP ${moneyLabel(p.mrp)}, ${p.discountPct}% off)'
        : moneyLabel(p.price);
    final text = 'Check out ${p.name} (${p.pack}) on Aapno Bazar — just $price, '
        'delivered in ${BasketCubit.etaMinutes} minutes!\n\n'
        'Get the app: $_playStoreUrl';
    final box = context.findRenderObject() as RenderBox?;
    return SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: p.name,
        sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  static const _playStoreUrl = 'https://play.google.com/store/apps/details?id=com.aapnobazar.app';

  static String _reviewCount(int n) {
    if (n > 999) return '${(n / 100).round() / 10}k';
    return '$n';
  }

  /// Only ever called for [PdpTab.nutrition]/[PdpTab.description] — the
  /// reviews tab renders [_ReviewsTab] instead (see `build`).
  static String _tabBody(PdpTab tab, BasketProduct p) {
    if (tab == PdpTab.nutrition) {
      return 'Per 100 ml — Energy 58 kcal · Protein 3.1 g · Fat 3.0 g · Carbohydrate 4.7 g · Calcium 120 mg. Values are indicative and may vary between batches.';
    }
    return '${p.name} — ${p.pack}. Sourced daily and cold-chain handled from the dark store to your door. Best consumed within 2 days of delivery; keep refrigerated below 5°C.';
  }
}

/// Real customer reviews (`Product.reviews`, from `ProductDetailSerializer`)
/// plus a star-picker + comment form to write/edit the signed-in user's own
/// one. Keyed by product id in the parent so switching products (or
/// reopening this tab) re-seeds the form from that product's own review
/// data instead of carrying over the previous product's draft.
class _ReviewsTab extends StatefulWidget {
  const _ReviewsTab({super.key, required this.product});

  final BasketProduct product;

  @override
  State<_ReviewsTab> createState() => _ReviewsTabState();
}

class _ReviewsTabState extends State<_ReviewsTab> {
  late final TextEditingController _comment;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<BasketCubit>();
    // Pre-fill the form from the user's existing review (if any) the first
    // time this tab opens for this product — `openProduct` already reset
    // both fields to blank, so a still-blank state here means "not seeded
    // yet", not "the user cleared it".
    if (cubit.state.reviewRatingInput == 0 && cubit.state.reviewCommentInput.isEmpty) {
      for (final r in widget.product.reviews) {
        if (r.userId == cubit.state.myUserId) {
          cubit.setReviewRating(r.rating);
          cubit.setReviewComment(r.comment);
          break;
        }
      }
    }
    _comment = TextEditingController(text: cubit.state.reviewCommentInput);
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketCubit>();
    final ratingInput = context.select((BasketCubit c) => c.state.reviewRatingInput);
    final commentInput = context.select((BasketCubit c) => c.state.reviewCommentInput);
    final submitting = context.select((BasketCubit c) => c.state.reviewSubmitting);
    final formError = context.select((BasketCubit c) => c.state.reviewFormError);
    final myUserId = context.select((BasketCubit c) => c.state.myUserId);

    if (_comment.text != commentInput) {
      _comment.value = TextEditingValue(text: commentInput, selection: TextSelection.collapsed(offset: commentInput.length));
    }

    var hasOwnReview = false;
    for (final r in widget.product.reviews) {
      if (r.userId == myUserId) {
        hasOwnReview = true;
        break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(BasketSpace.md),
          decoration: basketCard(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasOwnReview ? 'Update your review' : 'Write a review',
                style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: BasketSpace.sm),
              Row(
                children: [
                  for (var i = 1; i <= 5; i++)
                    GestureDetector(
                      onTap: () => cubit.setReviewRating(i),
                      child: Padding(
                        padding: const EdgeInsets.only(right: BasketSpace.xxs),
                        child: Icon(
                          i <= ratingInput ? Icons.star_rounded : Icons.star_border_rounded,
                          size: 26,
                          color: i <= ratingInput ? BasketColors.gold : BasketColors.faint,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: BasketSpace.sm),
              TextField(
                controller: _comment,
                onChanged: cubit.setReviewComment,
                minLines: 2,
                maxLines: 4,
                cursorColor: BasketColors.primary,
                style: basketInputText(),
                decoration: basketInputDecoration(hintText: "Share what you liked or didn't (optional)"),
              ),
              if (formError != null) ...[
                const SizedBox(height: 8),
                Text(formError, style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: BasketColors.error)),
              ],
              const SizedBox(height: BasketSpace.sm),
              BasketButton(
                label: hasOwnReview ? 'Update review' : 'Submit review',
                size: BasketButtonSize.medium,
                loading: submitting,
                onPressed: submitting ? null : () => cubit.submitProductReview(widget.product.id),
              ),
            ],
          ),
        ),
        const SizedBox(height: BasketSpace.md),
        Text(
          '${widget.product.reviews.length} ${widget.product.reviews.length == 1 ? 'review' : 'reviews'}',
          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: BasketSpace.sm),
        if (widget.product.reviews.isEmpty)
          Text(
            'No reviews yet — be the first to leave one.',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500, color: BasketColors.muted),
          )
        else
          for (final r in widget.product.reviews)
            Padding(
              padding: const EdgeInsets.only(bottom: BasketSpace.section),
              child: Container(
                padding: const EdgeInsets.all(BasketSpace.sm),
                decoration: basketCard(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            (r.userName?.isNotEmpty == true ? r.userName! : 'Customer') + (r.userId == myUserId ? ' (You)' : ''),
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(_reviewDateLabel(r.createdAt), style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w500, color: BasketColors.faint)),
                      ],
                    ),
                    const SizedBox(height: BasketSpace.xxs),
                    Row(
                      children: [
                        for (var i = 1; i <= 5; i++)
                          Icon(i <= r.rating ? Icons.star_rounded : Icons.star_border_rounded, size: 14, color: BasketColors.gold),
                      ],
                    ),
                    if (r.comment.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(r.comment, style: GoogleFonts.plusJakartaSans(fontSize: 12, height: 1.5, fontWeight: FontWeight.w500, color: const Color(0xFF4A4A52))),
                    ],
                  ],
                ),
              ),
            ),
      ],
    );
  }

  static String _reviewDateLabel(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

/// The PDP hero: swipe through [images] via `PageView`, tap a dot or a
/// thumbnail to jump straight to that photo. Keyed by product id in the
/// parent so switching products resets the page/thumbnail state instead of
/// carrying over the previous product's selected index.
class _ProductGallery extends StatefulWidget {
  const _ProductGallery({super.key, required this.images, required this.discountPct});

  final List<String> images;
  final int discountPct;

  @override
  State<_ProductGallery> createState() => _ProductGalleryState();
}

class _ProductGalleryState extends State<_ProductGallery> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int i) {
    setState(() => _index = i);
    _controller.animateToPage(i, duration: const Duration(milliseconds: 260), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    final multi = images.length > 1;

    return SizedBox(
      height: 290,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: images.isEmpty ? 1 : images.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) => ProductImage(
              height: 290,
              imageUrl: images.isEmpty ? '' : images[i],
              discountPct: i == 0 ? widget.discountPct : 0,
              radius: 0,
            ),
          ),
          if (multi)
            Positioned(
              left: 0,
              right: 0,
              bottom: 92,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < images.length; i++) ...[
                      if (i > 0) const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _goTo(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: i == _index ? 16 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: i == _index ? Color(0xFFFFFBF2) : Color(0xFFFFFBF2).withValues(alpha: 0.45),
                            boxShadow: [BoxShadow(color: BasketColors.ink.withValues(alpha: 0.25), blurRadius: 3)],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          if (multi)
            Positioned(
              left: BasketSpace.gutter,
              right: BasketSpace.gutter,
              bottom: 34,
              child: SizedBox(
                height: 46,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) => GestureDetector(
                    onTap: () => _goTo(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(BasketRadius.md),
                        border: Border.all(color: i == _index ? BasketColors.ink : Color(0xFFFFFBF2), width: i == _index ? 2.4 : 1.6),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 6, offset: const Offset(0, 2))],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(BasketRadius.sm),
                        child: Image.network(
                          images[i],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const ColoredBox(color: BasketColors.surface),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
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
      borderRadius: BorderRadius.circular(BasketRadius.pill),
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(color: BasketColors.ink, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Icon(icon, color: Color(0xFFFFFBF2), size: 16),
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
      padding: const EdgeInsets.symmetric(horizontal: BasketSpace.sm, vertical: BasketSpace.xs),
      decoration: BoxDecoration(
        color: selected ? BasketColors.ink : BasketSurface.card,
        border: Border.all(color: selected ? BasketColors.ink : BasketSurface.borderStrong),
        borderRadius: BorderRadius.circular(BasketRadius.pill),
      ),
      child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: selected ? Color(0xFFFFFBF2) : BasketColors.ink)),
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
      padding: const EdgeInsets.all(BasketSpace.sm),
      decoration: basketCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(sub, style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w500, color: BasketColors.faint)),
        ],
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
        padding: const EdgeInsets.symmetric(horizontal: BasketSpace.md),
        child: Center(child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800))),
      ),
    );
  }
}

String _deliveryFeeLine(ApiDeliverySettings d) {
  if (d.deliveryFee == 0) return 'Always free';
  if (d.freeDeliveryEnabled) return 'FREE above ${moneyLabel(d.freeDeliveryAbove)}';
  return '${moneyLabel(d.deliveryFee)} per order';
}
