import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/cubit/basket_selectors.dart';
import 'package:fastswipe/features/basket/data/basket_enums.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

/// Floating "view basket" bar shown over home/categories/list/search once
/// the cart has items.
class CartBar extends StatelessWidget {
  const CartBar({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.select((BasketCubit c) => cartTotals(c.state));
    final free = t.freeDeliveryUnlocked
        ? 'Free delivery unlocked'
        : 'Add ${moneyLabel(t.freeDeliveryAbove - t.subtotal)} for free delivery';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.read<BasketCubit>().go(BasketScreen.cart),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: BasketColors.ink.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: BasketColors.ink.withValues(alpha: 0.4),
                blurRadius: 34,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${t.itemCount} ${t.itemCount == 1 ? 'item' : 'items'} · ${moneyLabel(t.subtotal)}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      free,
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  'View basket',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: BasketColors.ink,
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
