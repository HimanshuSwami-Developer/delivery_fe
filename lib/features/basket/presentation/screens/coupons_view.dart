import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
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
    final coupons = context.select((BasketCubit c) => c.state.apiCoupons);

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
              Text('My coupons', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFFFFBF2))),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
            children: [
              for (final c in coupons)
                Padding(
                  padding: const EdgeInsets.only(bottom: 11),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: glassCard(radius: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(c.code, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1)),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: applied == c.code ? BasketColors.ink.withValues(alpha: 0.08) : BasketColors.primary,
                                shape: const StadiumBorder(),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                minimumSize: Size.zero,
                              ),
                              onPressed: applied == c.code ? cubit.removeCoupon : () => cubit.applyCouponFromCard(c.code),
                              child: Text(
                                applied == c.code ? 'Remove' : 'Apply',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: applied == c.code ? BasketColors.ink : Color(0xFFFFFBF2),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(c.title, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 5),
                        Text(c.terms, style: GoogleFonts.plusJakartaSans(fontSize: 11.5, height: 1.55, fontWeight: FontWeight.w500, color: BasketColors.muted)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
