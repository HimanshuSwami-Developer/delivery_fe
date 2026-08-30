import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/data/basket_catalog.dart';
import 'package:fastswipe/features/basket/data/basket_enums.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

/// Cancel/return-order bottom sheet, opened from the order-detail screen.
/// Same sheet handles both flows — only copy and the reason list change,
/// matching the source design's `sheetCancel` (`sheet === 'cancel' ||
/// sheet === 'return'`).
class CancelSheet extends StatelessWidget {
  const CancelSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketCubit>();
    final mode = context.select((BasketCubit c) => c.state.cancelMode);
    final reason = context.select((BasketCubit c) => c.state.cancelReason);
    final isReturn = mode == CancelMode.returnItems;
    final reasons = BasketCatalog.reasonsFor(mode);

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: cubit.closeSheet,
            child: Container(color: BasketColors.ink.withValues(alpha: 0.35)),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 26),
              decoration: BoxDecoration(
                color: Color(0xFFFFFBF2).withValues(alpha: 0.96),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isReturn ? 'Return items' : 'Cancel this order?',
                    style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isReturn
                        ? 'Pick a reason. Refunds reach your original payment method in 3–5 working days.'
                        : 'Free to cancel until the rider picks up your order. Refunds are instant to UPI.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11.5, height: 1.6, fontWeight: FontWeight.w500, color: BasketColors.muted),
                  ),
                  const SizedBox(height: 15),
                  Column(
                    children: [
                      for (final r in reasons)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _ReasonTile(
                            label: r,
                            selected: reason == r,
                            onTap: () => cubit.pickCancelReason(r),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
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
                          onPressed: cubit.closeSheet,
                          child: Text('Keep order', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: BasketColors.ink)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: BasketColors.error,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            minimumSize: Size.zero,
                          ),
                          onPressed: cubit.confirmCancel,
                          child: Text(
                            isReturn ? 'Request return' : 'Cancel order',
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFFFFFBF2)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReasonTile extends StatelessWidget {
  const _ReasonTile({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? BasketColors.ink.withValues(alpha: 0.05) : Color(0xFFFFFBF2),
          border: Border.all(color: selected ? BasketColors.ink : BasketColors.ink.withValues(alpha: 0.12), width: 1.5),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? BasketColors.ink : Colors.transparent,
                border: Border.all(color: BasketColors.ink, width: 1.5),
              ),
            ),
            const SizedBox(width: 10),
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
