import 'package:fastswipe/core/basket_api/models/promotion_models.dart';
import 'package:fastswipe/features/basket/cubit/basket_selectors.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:fastswipe/features/basket/presentation/basket_ui.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Horizontal strip of coupon cards (Blinkit-style), each with its own
/// Apply button, plus a trailing "View all" tile that opens the full "My
/// coupons" list. Shared by Cart and Order Summary/checkout — both apply
/// through the same [onApply] callback (`BasketCubit.applyCouponCode`,
/// no navigation) against the same `BasketState.appliedCoupon`, so a
/// coupon applied on either screen — or from "My coupons" itself — shows
/// as "Applied" everywhere immediately. Coupons this customer can't use
/// (already used, expired, or the cart is under the minimum — see
/// [couponAvailability]) look the same but get a grey, non-clickable
/// Apply.
class CouponStrip extends StatelessWidget {
  const CouponStrip({
    super.key,
    required this.coupons,
    required this.appliedCoupon,
    required this.onApply,
    required this.onRemove,
    required this.onViewAll,
    required this.cartSubtotal,
  });

  final List<ApiCoupon> coupons;

  /// Item total the minimum-order rule is checked against.
  final int cartSubtotal;
  final String? appliedCoupon;
  final ValueChanged<String> onApply;
  final VoidCallback onRemove;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    if (coupons.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: coupons.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: BasketSpace.xs),
        itemBuilder: (context, i) {
          if (i == coupons.length) {
            return GestureDetector(
              onTap: onViewAll,
              child: Container(
                width: 78,
                padding: const EdgeInsets.all(BasketSpace.xs),
                decoration: BoxDecoration(color: BasketColors.primarySoft, borderRadius: BorderRadius.circular(BasketRadius.md)),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_forward_rounded, size: 17, color: BasketColors.primary),
                    const SizedBox(height: BasketSpace.xxs),
                    Text(
                      'View all',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w800, color: BasketColors.primary),
                    ),
                  ],
                ),
              ),
            );
          }
          final c = coupons[i];
          final applied = appliedCoupon == c.code;
          final availability = couponAvailability(c, cartSubtotal);
          // An already-applied coupon stays removable even if it's since
          // stopped qualifying (e.g. items taken out below the minimum).
          final disabled = !availability.usable && !applied;
          return Container(
            width: 164,
            padding: const EdgeInsets.all(BasketSpace.sm),
            decoration: basketCard(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.code, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                    const SizedBox(height: 3),
                    Text(
                      c.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w500, color: BasketColors.muted),
                    ),
                  ],
                ),
                BasketButton(
                  label: applied ? 'Remove' : 'Apply',
                  variant: applied ? BasketButtonVariant.tonal : BasketButtonVariant.primary,
                  size: BasketButtonSize.small,
                  onPressed: applied ? onRemove : (disabled ? null : () => onApply(c.code)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Shown in place of the coupon input once a code is applied: the code,
/// the amount saved, and a Remove action that clears it from the cart.
class AppliedCouponBanner extends StatelessWidget {
  const AppliedCouponBanner({super.key, required this.code, required this.savings, required this.onRemove});

  final String code;
  final String savings;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(BasketSpace.sm, BasketSpace.xs, BasketSpace.xs, BasketSpace.xs),
      decoration: BoxDecoration(
        color: BasketColors.primarySoft,
        border: Border.all(color: BasketColors.primary.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(BasketRadius.md),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, size: 18, color: BasketColors.primary),
          const SizedBox(width: BasketSpace.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$code applied',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w800, color: BasketColors.ink),
                ),
                if (savings.isNotEmpty)
                  Text(
                    'You save $savings',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: BasketColors.primary),
                  ),
              ],
            ),
          ),
          BasketButton(label: 'Remove', variant: BasketButtonVariant.danger, size: BasketButtonSize.small, expand: false, onPressed: onRemove),
        ],
      ),
    );
  }
}
