import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/cubit/basket_selectors.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:fastswipe/features/basket/presentation/basket_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

/// "How would you like to pay?" — the only two checkout options: scan a UPI
/// QR code (-> [BasketCubit.chooseQrPayment], which opens the QR screen) or
/// pay cash on delivery (-> [BasketCubit.payCashOnDelivery], which places
/// the order immediately). Tapping either card acts right away — there's no
/// separate "confirm" step since the two options don't share one CTA.
class PaymentChoiceView extends StatelessWidget {
  const PaymentChoiceView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketCubit>();
    final payable = context.select(
      (BasketCubit c) => cartTotals(c.state).payable,
    );

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            BasketSpace.gutter,
            MediaQuery.paddingOf(context).top + BasketSpace.sm,
            BasketSpace.gutter,
            BasketSpace.md,
          ),
          decoration: const BoxDecoration(
            gradient: BasketColors.headerGradient,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(BasketRadius.xl)),
          ),
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
                    border: Border.all(
                      color: Color(0xFFFFFBF2).withValues(alpha: 0.14),
                    ),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.arrow_back,
                    color: Color(0xFFFFFBF2),
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: BasketSpace.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How would you like to pay?',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFFFBF2),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Paying ${moneyLabel(payable)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFFFFBF2).withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(BasketSpace.gutter, BasketSpace.lg, BasketSpace.gutter, BasketSpace.lg),
            children: [
              _PaymentChoiceCard(
                icon: '◈',
                title: 'UPI QR code',
                sub:
                    'Scan with any UPI app (GPay, PhonePe, Paytm & more), then upload the payment screenshot',
                onTap: cubit.chooseQrPayment,
              ),
              const SizedBox(height: BasketSpace.section),
              _PaymentChoiceCard(
                icon: '₹',
                title: 'Cash on delivery',
                sub: 'Pay the rider when your order arrives · no extra fee',
                onTap: cubit.payCashOnDelivery,
              ),
              const SizedBox(height: BasketSpace.md),
              Container(
                padding: const EdgeInsets.all(BasketSpace.sm),
                decoration: basketCard(),
                child: Text(
                  'A receipt is available to download from your order details as soon as it\'s placed.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    height: 1.6,
                    fontWeight: FontWeight.w500,
                    color: BasketColors.muted,
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

class _PaymentChoiceCard extends StatelessWidget {
  const _PaymentChoiceCard({
    required this.icon,
    required this.title,
    required this.sub,
    required this.onTap,
  });

  final String icon;
  final String title;
  final String sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(BasketSpace.md),
        decoration: basketCard(),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: BasketColors.ink,
                borderRadius: BorderRadius.circular(BasketRadius.md),
              ),
              alignment: Alignment.center,
              child: Text(
                icon,
                style: const TextStyle(fontSize: 17, color: Color(0xFFFFFBF2)),
              ),
            ),
            const SizedBox(width: BasketSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    sub,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: BasketColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: BasketSpace.xs),
            const Icon(
              Icons.chevron_right,
              color: BasketColors.faint,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
