import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/cubit/basket_selectors.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:fastswipe/features/basket/presentation/basket_ui.dart';
import 'package:fastswipe/features/basket/presentation/widgets/glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class CouponsView extends StatelessWidget {
  const CouponsView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketCubit>();
    final applied = context.select((BasketCubit c) => c.state.appliedCoupon);
    final coupons = usableCouponsFirst(context.select((BasketCubit c) => c.state.apiCoupons));
    final cartSubtotal = context.select((BasketCubit c) => cartTotals(c.state).subtotal);

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(BasketSpace.gutter, MediaQuery.paddingOf(context).top + BasketSpace.sm, BasketSpace.gutter, BasketSpace.md),
          decoration: darkHeaderDecoration(),
          child: Row(
            children: [
              InkWell(
                onTap: cubit.back,
                borderRadius: BorderRadius.circular(BasketRadius.pill),
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
              const SizedBox(width: BasketSpace.sm),
              Text(
                'My coupons',
                style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFFFFBF2)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(BasketSpace.gutter, BasketSpace.md, BasketSpace.gutter, BasketSpace.lg),
            children: [
              if (coupons.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: BasketSpace.xxl),
                  child: Text(
                    'No coupons right now — check back soon.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: BasketColors.muted),
                  ),
                ),
              for (final c in coupons)
                Builder(
                  builder: (context) {
                    final isApplied = applied == c.code;
                    final availability = couponAvailability(c, cartSubtotal);
                    // Still removable if it was applied before it stopped
                    // qualifying (e.g. cart dropped under the minimum).
                    final disabled = !availability.usable && !isApplied;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: BasketSpace.section),
                      child: Container(
                        padding: const EdgeInsets.all(BasketSpace.md),
                        decoration: basketCard(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(c.code, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1)),
                                ),
                                const SizedBox(width: BasketSpace.xs),
                                BasketButton(
                                  label: isApplied ? 'Remove' : 'Apply',
                                  variant: isApplied ? BasketButtonVariant.tonal : BasketButtonVariant.primary,
                                  size: BasketButtonSize.small,
                                  expand: false,
                                  onPressed: isApplied ? cubit.removeCoupon : (disabled ? null : () => cubit.applyCouponFromCard(c.code)),
                                ),
                              ],
                            ),
                            const SizedBox(height: BasketSpace.xs),
                            Text(c.title, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600)),
                            const SizedBox(height: BasketSpace.xxs),
                            Text(
                              c.terms,
                              style: GoogleFonts.plusJakartaSans(fontSize: 11.5, height: 1.55, fontWeight: FontWeight.w500, color: BasketColors.muted),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}
