import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/cubit/basket_selectors.dart';
import 'package:fastswipe/features/basket/data/models.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:fastswipe/features/basket/presentation/widgets/glass.dart';
import 'package:fastswipe/features/basket/presentation/widgets/product_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class WishlistView extends StatelessWidget {
  const WishlistView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketCubit>();
    final items = context.select(
      (BasketCubit c) => c.state.wishlist.map((id) => productById(c.state, id)).whereType<BasketProduct>().toList(),
    );

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(18, MediaQuery.paddingOf(context).top + 12, 18, 16),
          decoration: darkHeaderDecoration(),
          child: Row(
            children: [
              InkWell(
                onTap: cubit.back,
                borderRadius: BorderRadius.circular(99),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Color(0xFFFFFBF2).withValues(alpha: 0.1),
                    border: Border.all(color: Color(0xFFFFFBF2).withValues(alpha: 0.14)),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.arrow_back, color: Color(0xFFFFFBF2), size: 16),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Wishlist', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFFFFBF2))),
                  const SizedBox(height: 2),
                  Text(
                    '${items.length} saved items',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFFFFFBF2).withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Nothing saved yet', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the heart on any product to keep it here.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, height: 1.6, fontWeight: FontWeight.w500, color: BasketColors.muted),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
                  children: [
                    for (final p in items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: _WishRow(product: p),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _WishRow extends StatelessWidget {
  const _WishRow({required this.product});

  final BasketProduct product;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketCubit>();
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: glassCard(radius: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => cubit.openProduct(product.id),
            child: ProductImageMini(size: 58, imageUrl: product.imageUrl),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(product.pack, style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w500, color: BasketColors.faint)),
                const SizedBox(height: 4),
                Text(moneyLabel(product.price), style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () => cubit.removeFromWishlist(product.id),
                child: Text('✕', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: BasketColors.faint)),
              ),
              const SizedBox(height: 6),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: BasketColors.ink, width: 1.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => cubit.addToCart(product.id),
                child: Text('ADD', style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
