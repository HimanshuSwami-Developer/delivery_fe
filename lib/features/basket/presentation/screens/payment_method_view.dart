import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/cubit/basket_selectors.dart';
import 'package:fastswipe/features/basket/data/basket_catalog.dart';
import 'package:fastswipe/features/basket/data/models.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class PaymentMethodView extends StatelessWidget {
  const PaymentMethodView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketCubit>();
    final payable = context.select((BasketCubit c) => cartTotals(c.state).payable);
    final selected = context.select((BasketCubit c) => c.state.paymentMethodId);
    final payCta = selected == 'cod' ? 'Place order · pay on delivery' : 'Pay ${moneyLabel(payable)}';

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(18, MediaQuery.paddingOf(context).top + 12, 18, 16),
          decoration: BoxDecoration(color: BasketColors.ink, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(26))),
          child: Row(
            children: [
              InkWell(
                onTap: cubit.back,
                borderRadius: BorderRadius.circular(99),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 16),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payment method', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text('Paying ${moneyLabel(payable)}', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.5))),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
            children: [
              for (final m in BasketCatalog.paymentMethods)
                Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: _PaymentMethodTile(method: m, selected: m.id == selected, onTap: () => cubit.selectPaymentMethod(m.id)),
                ),
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.68),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.85)),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  'Payments are processed over an encrypted gateway. A GST invoice is emailed once the order is delivered.',
                  style: GoogleFonts.poppins(fontSize: 11.5, height: 1.6, fontWeight: FontWeight.w500, color: BasketColors.muted),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            border: Border(top: BorderSide(color: BasketColors.ink.withValues(alpha: 0.07))),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: BasketColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onPressed: cubit.payNow,
                    child: Text(payCta, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 9),
                TextButton(
                  onPressed: cubit.simulatePaymentFailure,
                  child: Text('Simulate a failed payment', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: BasketColors.faint)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({required this.method, required this.selected, required this.onTap});

  final PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.68),
          border: Border.all(color: selected ? BasketColors.ink : Colors.white.withValues(alpha: 0.85), width: 1.5),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: BasketColors.ink, borderRadius: BorderRadius.circular(10)),
              alignment: Alignment.center,
              child: Text(method.icon, style: const TextStyle(fontSize: 14, color: Colors.white)),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(method.name, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(method.sub, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: BasketColors.muted)),
                ],
              ),
            ),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? BasketColors.ink : Colors.transparent,
                border: Border.all(color: BasketColors.ink, width: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
