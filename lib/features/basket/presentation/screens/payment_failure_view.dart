import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/cubit/basket_selectors.dart';
import 'package:fastswipe/features/basket/data/basket_catalog.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class PaymentFailureView extends StatelessWidget {
  const PaymentFailureView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketCubit>();
    final payable = context.select((BasketCubit c) => cartTotals(c.state).payable);
    final methodName = context.select((BasketCubit c) => BasketCatalog.paymentMethodById(c.state.paymentMethodId).name);

    return Container(
      color: Color(0xFFFFFBF2),
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(22, MediaQuery.paddingOf(context).top + 24, 22, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(color: BasketColors.ink, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text('!', style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFFFFFBF2))),
          ),
          const SizedBox(height: 18),
          Text(
            "Payment didn't go through",
            style: GoogleFonts.plusJakartaSans(fontSize: 22, height: 1.25, fontWeight: FontWeight.w800, letterSpacing: -0.4),
          ),
          const SizedBox(height: 10),
          Text(
            'No money has left your account. Your basket is saved — try another method or pay on delivery.',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.65, fontWeight: FontWeight.w500, color: BasketColors.muted),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Color(0xFFFFFBF2).withValues(alpha: 0.7),
              border: Border.all(color: BasketColors.ink.withValues(alpha: 0.08)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _Row(label: 'Attempted', value: moneyLabel(payable)),
                const SizedBox(height: 8),
                _Row(label: 'Method', value: methodName),
                const SizedBox(height: 8),
                const _Row(label: 'Reference', value: 'TXN-4471'),
              ],
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: BasketColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              onPressed: cubit.goToPaymentChoice,
              child: Text('Retry payment', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFFFFFBF2))),
            ),
          ),
          const SizedBox(height: 9),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: BasketColors.ink, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: cubit.payCashOnDelivery,
              child: Text('Switch to cash on delivery', style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700, color: BasketColors.ink)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF4A4A52))),
        Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF4A4A52))),
      ],
    );
  }
}
