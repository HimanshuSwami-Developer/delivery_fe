import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/data/basket_catalog.dart';
import 'package:fastswipe/features/basket/data/basket_enums.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:fastswipe/features/basket/presentation/basket_ui.dart';
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
              padding: const EdgeInsets.fromLTRB(BasketSpace.gutter, BasketSpace.md, BasketSpace.gutter, BasketSpace.xl),
              decoration: BoxDecoration(
                color: Color(0xFFFFFBF2).withValues(alpha: 0.96),
                borderRadius: BasketRadius.sheet,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isReturn ? 'Return items' : 'Cancel this order?',
                    style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: BasketSpace.xs),
                  Text(
                    isReturn
                        ? 'Pick a reason. Refunds reach your original payment method in 3–5 working days.'
                        : 'Free to cancel until the rider picks up your order. Refunds are instant to UPI.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11.5, height: 1.6, fontWeight: FontWeight.w500, color: BasketColors.muted),
                  ),
                  const SizedBox(height: BasketSpace.md),
                  Column(
                    children: [
                      for (final r in reasons)
                        Padding(
                          padding: const EdgeInsets.only(bottom: BasketSpace.xs),
                          child: _ReasonTile(
                            label: r,
                            selected: reason == r,
                            onTap: () => cubit.pickCancelReason(r),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: BasketSpace.xs),
                  Row(
                    children: [
                      Expanded(
                        child: BasketButton.secondary(label: 'Keep order', onPressed: cubit.closeSheet),
                      ),
                      const SizedBox(width: BasketSpace.sm),
                      Expanded(
                        flex: 2,
                        child: BasketButton(
                          label: isReturn ? 'Request return' : 'Cancel order',
                          variant: BasketButtonVariant.danger,
                          onPressed: cubit.confirmCancel,
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
        padding: const EdgeInsets.all(BasketSpace.sm),
        decoration: basketCard(selected: selected),
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
            const SizedBox(width: BasketSpace.sm),
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
