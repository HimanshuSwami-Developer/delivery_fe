import 'package:fastswipe/core/basket_api/models/promotion_models.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Horizontal strip of coupon cards (Blinkit-style), each with its own
/// Apply button, plus a trailing "View all" tile that opens the full "My
/// coupons" list. Shared by Cart and Order Summary/checkout — both apply
/// through the same [onApply] callback (`BasketCubit.applyCouponCode`,
/// no navigation) against the same `BasketState.appliedCoupon`, so a
/// coupon applied on either screen — or from "My coupons" itself — shows
/// as "Applied" everywhere immediately.
class CouponStrip extends StatelessWidget {
  const CouponStrip({
    super.key,
    required this.coupons,
    required this.appliedCoupon,
    required this.onApply,
    required this.onRemove,
    required this.onViewAll,
  });

  final List<ApiCoupon> coupons;
  final String? appliedCoupon;
  final ValueChanged<String> onApply;
  final VoidCallback onRemove;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    if (coupons.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: coupons.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 9),
        itemBuilder: (context, i) {
          if (i == coupons.length) {
            return GestureDetector(
              onTap: onViewAll,
              child: Container(
                width: 78,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: BasketColors.primarySoft, borderRadius: BorderRadius.circular(14)),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_forward_rounded, size: 17, color: BasketColors.primary),
                    const SizedBox(height: 5),
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
          return Container(
            width: 164,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: Color(0xFFFFFBF2),
              border: Border.all(color: BasketColors.ink.withValues(alpha: 0.09)),
              borderRadius: BorderRadius.circular(14),
            ),
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
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: applied ? BasketColors.ink.withValues(alpha: 0.08) : BasketColors.primary,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      minimumSize: Size.zero,
                    ),
                    onPressed: applied ? onRemove : () => onApply(c.code),
                    child: Text(
                      applied ? 'Remove' : 'Apply',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: applied ? BasketColors.ink : Color(0xFFFFFBF2),
                      ),
                    ),
                  ),
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
  const AppliedCouponBanner({
    super.key,
    required this.code,
    required this.savings,
    required this.onRemove,
  });

  final String code;
  final String savings;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
      decoration: BoxDecoration(
        color: BasketColors.primarySoft,
        border: Border.all(color: BasketColors.primary.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, size: 18, color: BasketColors.primary),
          const SizedBox(width: 8),
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
          TextButton(
            onPressed: onRemove,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
            ),
            child: Text(
              'Remove',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }
}
