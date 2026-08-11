import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/cubit/basket_selectors.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:fastswipe/features/basket/presentation/widgets/glass.dart';
import 'package:fastswipe/features/basket/presentation/widgets/image_slot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

/// Named to avoid colliding with [OrderDetail], the selector's resolved
/// data class this screen renders.
class OrderDetailScreenView extends StatelessWidget {
  const OrderDetailScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketCubit>();
    final detail = context.select((BasketCubit c) => resolveOrderDetail(c.state));
    final etaLeft = context.select((BasketCubit c) => etaLeftForStage(c.state.trackingStage, eta: BasketCubit.etaMinutes));
    final riderName = context.select((BasketCubit c) => c.state.currentOrder?.deliveryPartnerName ?? 'Your rider');

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
                  Text(detail.id, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(detail.statusLabel, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.5))),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
            children: [
              if (detail.isLive)
                GestureDetector(
                  onTap: cubit.goToTrack,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: BasketColors.ink, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Live tracking', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
                            const SizedBox(height: 4),
                            Text(
                              '$riderName · $etaLeft min away',
                              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.55)),
                            ),
                          ],
                        ),
                        Text('›', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: glassCard(radius: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Order placed ${detail.date}', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text(
                              'Add the same items back to your basket',
                              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: BasketColors.muted),
                            ),
                          ],
                        ),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: BasketColors.primary,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          minimumSize: Size.zero,
                        ),
                        onPressed: cubit.reorder,
                        child: Text('Reorder', style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w800, color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 11),
              Container(
                padding: const EdgeInsets.all(13),
                decoration: glassCard(radius: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Items', style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 11),
                    for (final (name, pack, qty, rate) in detail.items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: const SizedBox(width: 44, height: 44, child: ImageSlot(mini: true)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text('$pack · ×$qty', style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w500, color: BasketColors.faint)),
                                ],
                              ),
                            ),
                            Text(moneyLabel(rate * qty), style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 11),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: glassCard(radius: 16),
                child: Column(
                  children: [
                    _Row(label: 'Item total', value: detail.subtotalLabel),
                    const SizedBox(height: 8),
                    _Row(label: 'Discount', value: detail.discountLabel),
                    const SizedBox(height: 8),
                    _Row(label: 'Delivery + GST', value: detail.feeLabel),
                    Container(margin: const EdgeInsets.symmetric(vertical: 12), height: 1, color: BasketColors.ink.withValues(alpha: 0.09)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(detail.paidLabel, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w800)),
                        Text(detail.totalLabel, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ],
                ),
              ),
              if (detail.showInvoice) ...[
                const SizedBox(height: 11),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.68),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.85)),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Download GST invoice', style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w700)),
                      Text('↓ PDF', style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w700, color: BasketColors.muted)),
                    ],
                  ),
                ),
              ],
              if (detail.isLive) ...[
                const SizedBox(height: 11),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: BasketColors.ink, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          minimumSize: Size.zero,
                        ),
                        onPressed: cubit.openCancelSheet,
                        child: Text('Cancel order', style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w700, color: BasketColors.ink)),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: BasketColors.ink, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          minimumSize: Size.zero,
                        ),
                        onPressed: cubit.openReturnSheet,
                        child: Text('Return items', style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w700, color: BasketColors.ink)),
                      ),
                    ),
                  ],
                ),
              ] else if (detail.returnable) ...[
                const SizedBox(height: 11),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: BasketColors.ink, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    onPressed: cubit.openReturnSheet,
                    child: Text('Return items', style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w700, color: BasketColors.ink)),
                  ),
                ),
              ],
              Center(
                child: TextButton(
                  onPressed: cubit.goToSupport,
                  child: Text('Need help with this order?', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: BasketColors.muted)),
                ),
              ),
            ],
          ),
        ),
      ],
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
        Text(label, style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF4A4A52))),
        Text(value, style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF4A4A52))),
      ],
    );
  }
}
