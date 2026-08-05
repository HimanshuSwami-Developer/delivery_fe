import 'package:fastswipe/core/basket_api/models/promotion_models.dart';
import 'package:fastswipe/features/basket_admin/cubit/basket_admin_cubit.dart';
import 'package:fastswipe/features/basket_admin/data/basket_admin_data.dart';
import 'package:fastswipe/features/basket_admin/presentation/basket_admin_style.dart';
import 'package:fastswipe/features/basket_admin/presentation/widgets/admin_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

/// Coupon management: active/scheduled campaign cards with a pause/resume
/// toggle and real redemption stats from the promotions API.
class AdminCouponsView extends StatelessWidget {
  const AdminCouponsView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketAdminCubit>();
    final coupons = context.select((BasketAdminCubit c) => c.state.apiCoupons);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: AdminSectionTitle('Active & scheduled campaigns')),
              FilledButton(
                onPressed: null,
                style: FilledButton.styleFrom(
                  backgroundColor: AdminColors.ink,
                  disabledBackgroundColor: AdminColors.ink,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                ),
                child: Text('+ New coupon', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (coupons.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Text('No coupons yet.', style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600, color: AdminColors.muted)),
            ),
          LayoutBuilder(builder: (context, constraints) {
            final cols = constraints.maxWidth < 700 ? 1 : 2;
            return GridView.count(
              crossAxisCount: cols,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.75,
              children: [
                for (final c in coupons)
                  _CouponCard(
                    coupon: c,
                    onToggle: () => cubit.toggleCoupon(c.code, !c.isActive),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _CouponCard extends StatelessWidget {
  const _CouponCard({required this.coupon, required this.onToggle});

  final ApiCoupon coupon;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final on = coupon.isActive;
    final discountLabel =
        coupon.percentDiscount != null ? '${coupon.percentDiscount}% off' : '${adminMoney(coupon.flatDiscount ?? 0)} off';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: adminGlassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(coupon.code, style: GoogleFonts.manrope(fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: 1)),
                    const SizedBox(height: 6),
                    Text(coupon.title, style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600, color: AdminColors.muted)),
                  ],
                ),
              ),
              InkWell(
                onTap: onToggle,
                child: Row(
                  children: [
                    AdminToggle(on: on, onTap: onToggle),
                    const SizedBox(width: 8),
                    Text(on ? 'Active' : 'Paused',
                        style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w700, color: on ? AdminColors.ink : AdminColors.faint)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: AdminMiniStat(label: 'Redeemed', value: '${coupon.usedCount}')),
              Expanded(child: AdminMiniStat(label: 'Discount given', value: adminMoney(coupon.discountGiven))),
              Expanded(child: AdminMiniStat(label: 'Ends', value: coupon.validUntil == null ? 'Ongoing' : _dateLabel(coupon.validUntil!))),
            ],
          ),
          const SizedBox(height: 15),
          Text('Min order ${adminMoney(coupon.minOrderValue)} · $discountLabel${coupon.maxDiscount != null ? ' · max ${adminMoney(coupon.maxDiscount!)}' : ''}',
              style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w500, color: AdminColors.muted)),
        ],
      ),
    );
  }
}

String _dateLabel(String iso) {
  final dt = DateTime.tryParse(iso);
  if (dt == null) return iso;
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${dt.day} ${months[dt.month - 1]}';
}
