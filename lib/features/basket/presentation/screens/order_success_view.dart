import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/cubit/basket_selectors.dart';
import 'package:fastswipe/features/basket/data/basket_catalog.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class OrderSuccessView extends StatelessWidget {
  const OrderSuccessView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketCubit>();
    final order = context.select((BasketCubit c) => c.state.currentOrder);
    final fallbackPayable = context.select((BasketCubit c) => cartTotals(c.state).payable);
    // Item price minus discount only — the real placed order's `total`
    // includes GST + delivery fee (charged server-side), which isn't shown
    // to the customer anywhere in this app (see `cartTotals`/`OrderDetail`).
    final payable = order == null
        ? fallbackPayable
        : (order.subtotal - order.discount < 0 ? 0 : order.subtotal - order.discount);
    final methodName = context.select((BasketCubit c) => BasketCatalog.paymentMethodById(c.state.paymentMethodId).name);
    final addr = context.select((BasketCubit c) => addressForState(c.state));
    final day = context.select((BasketCubit c) => c.state.deliveryDay);
    final slot = context.select((BasketCubit c) => BasketCatalog.slotById(c.state.deliverySlotId));
    final slotLabel = slot.id == 'exp'
        ? 'Express, ${BasketCubit.etaMinutes} min'
        : '${BasketCatalog.deliveryDays[day].label} ${slot.label}';
    final orderNumberLabel = order?.orderNumber ?? '—';

    return Container(
      color: Color(0xFFFFFBF2),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(22, MediaQuery.paddingOf(context).top + 30, 22, 34),
            decoration: const BoxDecoration(gradient: BasketColors.headerGradient, borderRadius: BorderRadius.vertical(bottom: Radius.circular(30))),
            child: Column(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: const BoxDecoration(color: Color(0xFFFFFBF2), shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: const Icon(Icons.check, color: BasketColors.ink, size: 30),
                ),
                const SizedBox(height: 16),
                Text('Order confirmed', style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFFFFFBF2), letterSpacing: -0.4)),
                const SizedBox(height: 7),
                Text(
                  '$orderNumberLabel · paid by $methodName',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w500, color: Color(0xFFFFFBF2).withValues(alpha: 0.55)),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Color(0xFFFFFBF2).withValues(alpha: 0.7),
                    border: Border.all(color: BasketColors.ink.withValues(alpha: 0.08)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Arriving $slotLabel', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text(addr.line, style: GoogleFonts.plusJakartaSans(fontSize: 11.5, height: 1.55, fontWeight: FontWeight.w500, color: BasketColors.muted)),
                    ],
                  ),
                ),
                const SizedBox(height: 11),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Color(0xFFFFFBF2).withValues(alpha: 0.7),
                    border: Border.all(color: BasketColors.ink.withValues(alpha: 0.08)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Amount paid', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700)),
                      Text(moneyLabel(payable), style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                const SizedBox(height: 11),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: BasketColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onPressed: cubit.goToTrack,
                    child: Text('Track this order', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFFFFFBF2))),
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
                    onPressed: cubit.goHome,
                    child: Text('Continue shopping', style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700, color: BasketColors.ink)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
