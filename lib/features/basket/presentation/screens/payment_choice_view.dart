import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/cubit/basket_selectors.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
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
    final payable = context.select((BasketCubit c) => cartTotals(c.state).payable);

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(18, MediaQuery.paddingOf(context).top + 12, 18, 16),
          decoration: const BoxDecoration(gradient: BasketColors.headerGradient, borderRadius: BorderRadius.vertical(bottom: Radius.circular(26))),
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
                  Text('How would you like to pay?', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFFFFBF2))),
                  const SizedBox(height: 2),
                  Text('Paying ${moneyLabel(payable)}', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFFFFFBF2).withValues(alpha: 0.5))),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
            children: [
              _PaymentChoiceCard(
                icon: '◈',
                title: 'UPI QR code',
                sub: 'Scan with any UPI app (GPay, PhonePe, Paytm & more), then upload the payment screenshot',
                onTap: cubit.chooseQrPayment,
              ),
              const SizedBox(height: 12),
              _PaymentChoiceCard(
                icon: '₹',
                title: 'Cash on delivery',
                sub: 'Pay the rider when your order arrives · no extra fee',
                onTap: cubit.payCashOnDelivery,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: Color(0xFFFFFBF2).withValues(alpha: 0.68),
                  border: Border.all(color: Color(0xFFFFFBF2).withValues(alpha: 0.85)),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  'A GST invoice is available to download from your order details as soon as it\'s placed.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11.5, height: 1.6, fontWeight: FontWeight.w500, color: BasketColors.muted),
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
  const _PaymentChoiceCard({required this.icon, required this.title, required this.sub, required this.onTap});

  final String icon;
  final String title;
  final String sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFFFFFBF2).withValues(alpha: 0.68),
          border: Border.all(color: Color(0xFFFFFBF2).withValues(alpha: 0.85)),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: BasketColors.ink, borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.center,
              child: Text(icon, style: const TextStyle(fontSize: 17, color: Color(0xFFFFFBF2))),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(sub, style: GoogleFonts.plusJakartaSans(fontSize: 11.5, height: 1.4, fontWeight: FontWeight.w500, color: BasketColors.muted)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: BasketColors.faint, size: 20),
          ],
        ),
      ),
    );
  }
}
