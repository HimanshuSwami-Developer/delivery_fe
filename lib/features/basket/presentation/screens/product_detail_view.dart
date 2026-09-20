import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/cubit/basket_selectors.dart';
import 'package:fastswipe/features/basket/data/basket_enums.dart';
import 'package:fastswipe/features/basket/data/models.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:fastswipe/features/basket/presentation/widgets/glass.dart';
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
                  _ProductGallery(key: ValueKey(p.id), images: p.galleryImages, discountPct: p.discountPct),
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
                ],
              ),
              Transform.translate(
                offset: const Offset(0, -22),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 30),
                  decoration: BoxDecoration(
                    color: Color(0xFFFFFBF2).withValues(alpha: 0.9),
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
                              style: GoogleFonts.plusJakartaSans(fontSize: 19, height: 1.25, fontWeight: FontWeight.w800, letterSpacing: -0.4),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                            decoration: BoxDecoration(border: Border.all(color: BasketColors.ink.withValues(alpha: 0.14)), borderRadius: BorderRadius.circular(99)),
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
                          Text(moneyLabel(p.price), style: GoogleFonts.plusJakartaSans(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
                          const SizedBox(width: 9),
                          Text(
                            moneyLabel(p.mrp),
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500, color: BasketColors.muted, decoration: TextDecoration.lineThrough),
                          ),
                          const SizedBox(width: 9),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(color: BasketColors.gold, borderRadius: BorderRadius.circular(99)),
                            child: Text('${p.discountPct}% off', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: BasketColors.primary)),
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
                      const SizedBox(height: 14),
                      if (tab == PdpTab.reviews)
                        _ReviewsTab(key: ValueKey(p.id), product: p)
                      else
                        Text(
                          _tabBody(tab, p),
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.7, fontWeight: FontWeight.w500, color: const Color(0xFF4A4A52)),
                        ),
                      const SizedBox(height: 22),
                      Text('Frequently bought with', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800)),
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
            color: Color(0xFFFFFBF2).withValues(alpha: 0.9),
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
                        child: Text('$pdpQty', textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800)),
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
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFFFFFBF2)),
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
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Color(0xFFFFFBF2).withValues(alpha: 0.8),
            border: Border.all(color: BasketColors.ink.withValues(alpha: 0.09)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasOwnReview ? 'Update your review' : 'Write a review',
                style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (var i = 1; i <= 5; i++)
                    GestureDetector(
                      onTap: () => cubit.setReviewRating(i),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(
                          i <= ratingInput ? Icons.star_rounded : Icons.star_border_rounded,
                          size: 26,
                          color: i <= ratingInput ? BasketColors.gold : BasketColors.faint,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _comment,
                onChanged: cubit.setReviewComment,
                minLines: 2,
                maxLines: 4,
                style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: "Share what you liked or didn't (optional)",
                  filled: true,
                  fillColor: Color(0xFFFFFBF2),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: BorderSide(color: BasketColors.ink.withValues(alpha: 0.12))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: BorderSide(color: BasketColors.ink.withValues(alpha: 0.12))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: BasketColors.primary, width: 1.6)),
                ),
              ),
              if (formError != null) ...[
                const SizedBox(height: 8),
                Text(formError, style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: BasketColors.error)),
              ],
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: BasketColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                  onPressed: submitting ? null : () => cubit.submitProductReview(widget.product.id),
                  child: submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Color(0xFFFFFBF2))),
                        )
                      : Text(
                          hasOwnReview ? 'Update review' : 'Submit review',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFFFFFBF2)),
                        ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          '${widget.product.reviews.length} ${widget.product.reviews.length == 1 ? 'review' : 'reviews'}',
          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        if (widget.product.reviews.isEmpty)
          Text(
            'No reviews yet — be the first to leave one.',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500, color: BasketColors.muted),
          )
        else
          for (final r in widget.product.reviews)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: Color(0xFFFFFBF2).withValues(alpha: 0.68),
                  border: Border.all(color: Color(0xFFFFFBF2).withValues(alpha: 0.85)),
                  borderRadius: BorderRadius.circular(14),
                ),
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
                    const SizedBox(height: 4),
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
              left: 14,
              right: 14,
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
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: i == _index ? BasketColors.ink : Color(0xFFFFFBF2), width: i == _index ? 2.4 : 1.6),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 6, offset: const Offset(0, 2))],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7.5),
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
      borderRadius: BorderRadius.circular(99),
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
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? BasketColors.ink : Color(0xFFFFFBF2).withValues(alpha: 0.7),
        border: Border.all(color: selected ? BasketColors.ink : BasketColors.ink.withValues(alpha: 0.14)),
        borderRadius: BorderRadius.circular(99),
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
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Color(0xFFFFFBF2).withValues(alpha: 0.8),
        border: Border.all(color: BasketColors.ink.withValues(alpha: 0.07)),
        borderRadius: BorderRadius.circular(14),
      ),
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
        decoration: productCardDecoration(radius: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProductImage(height: 66, imageUrl: product.imageUrl, discountPct: product.discountPct, radius: 10),
            const SizedBox(height: 7),
            SizedBox(
              height: 27,
              child: Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(fontSize: 10.5, height: 1.3, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(moneyLabel(product.price), style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w800)),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: BasketColors.ink, width: 1.3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => context.read<BasketCubit>().bump(product.id, 1),
                  child: Text('ADD', style: GoogleFonts.plusJakartaSans(fontSize: 9.5, fontWeight: FontWeight.w800)),
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
        child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800)),
      ),
    );
  }
}
