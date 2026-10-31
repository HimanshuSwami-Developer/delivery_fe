import 'package:fastswipe/core/invoice/invoice_actions.dart';
import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/cubit/basket_selectors.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:fastswipe/features/basket/presentation/basket_ui.dart';
import 'package:fastswipe/features/basket/presentation/widgets/glass.dart';
import 'package:fastswipe/features/basket/presentation/widgets/image_slot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletonizer/skeletonizer.dart';

const _shimmer = ShimmerEffect(
  baseColor: BasketColors.divider,
  highlightColor: BasketColors.surface,
);

/// Bones on the navy header — light-on-dark so they stay visible.
final _shimmerOnDark = ShimmerEffect(
  baseColor: Color(0xFFFFFBF2).withValues(alpha: 0.18),
  highlightColor: Color(0xFFFFFBF2).withValues(alpha: 0.32),
);

/// Placeholder shape the skeleton is drawn from while the order loads.
const _skeletonDetail = OrderDetail(
  id: 'ORD-000000',
  statusLabel: 'Out for delivery',
  date: '31 Oct, 1:45 PM',
  isLive: false,
  isClosed: false,
  returnable: false,
  showInvoice: true,
  items: [
    ('Product name here', '1 kg', 1, 120),
    ('Another product', '500 g', 2, 60),
    ('Third product name', '1 pc', 1, 45),
  ],
  subtotalLabel: '₹285',
  discountLabel: '—',
  totalLabel: '₹285',
  paidLabel: 'Paid · COD',
);

/// Named to avoid colliding with [OrderDetail], the selector's resolved
/// data class this screen renders.
class OrderDetailScreenView extends StatelessWidget {
  const OrderDetailScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketCubit>();
    // Opened from the orders list: until the fetched detail for *this*
    // order lands, [currentOrder] is null or the previously opened order —
    // show a skeleton instead of that empty/stale data.
    final loading = context.select((BasketCubit c) {
      final selected = c.state.selectedOrderId;
      return selected != null &&
          c.state.currentOrder?.id.toString() != selected;
    });
    final resolved = context.select(
      (BasketCubit c) => resolveOrderDetail(c.state),
    );
    final detail = loading ? _skeletonDetail : resolved;
    final etaLeft = context.select(
      (BasketCubit c) =>
          etaLeftForStage(c.state.trackingStage, eta: BasketCubit.etaMinutes),
    );
    final riderName = context.select(
      (BasketCubit c) =>
          c.state.currentOrder?.deliveryPartnerName ?? 'Your rider',
    );
    final orderId = context.select((BasketCubit c) => c.state.currentOrder?.id);

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
          decoration: darkHeaderDecoration(),
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
              const SizedBox(width: BasketSpace.xs),
              Skeletonizer(
                enabled: loading,
                effect: _shimmerOnDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.id,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFFFBF2),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detail.statusLabel,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFFFFBF2).withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Skeletonizer(
            enabled: loading,
            effect: _shimmer,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                BasketSpace.gutter,
                BasketSpace.md,
                BasketSpace.gutter,
                BasketSpace.lg,
              ),
              children: [
                if (detail.isLive)
                  GestureDetector(
                    onTap: cubit.goToTrack,
                    child: Container(
                      padding: const EdgeInsets.all(BasketSpace.md),
                      decoration: BoxDecoration(
                        color: BasketColors.ink,
                        borderRadius: BasketRadius.card,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Live tracking',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFFFFBF2),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$riderName · $etaLeft min away',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Color(
                                    0xFFFFFBF2,
                                  ).withValues(alpha: 0.55),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '›',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFFFFBF2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(BasketSpace.md),
                    decoration: basketCard(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order placed ${detail.date}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Add the same items back to your basket',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: BasketColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: BasketSpace.sm),
                        BasketButton(
                          label: 'Reorder',
                          size: BasketButtonSize.small,
                          expand: false,
                          onPressed: cubit.reorder,
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: BasketSpace.section),
                Container(
                  padding: const EdgeInsets.all(BasketSpace.md),
                  decoration: basketCard(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Items',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: BasketSpace.sm),
                      for (final (name, pack, qty, rate) in detail.items)
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: BasketSpace.xs,
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  BasketRadius.md,
                                ),
                                child: const SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: ImageSlot(mini: true),
                                ),
                              ),
                              const SizedBox(width: BasketSpace.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$pack · ×$qty',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w500,
                                        color: BasketColors.faint,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                moneyLabel(rate * qty),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: BasketSpace.section),
                Container(
                  padding: const EdgeInsets.all(BasketSpace.md),
                  decoration: basketCard(),
                  child: Column(
                    children: [
                      _Row(label: 'Item total', value: detail.subtotalLabel),
                      const SizedBox(height: BasketSpace.xs),
                      _Row(label: 'Discount', value: detail.discountLabel),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: BasketSpace.sm),
                        child: Divider(height: 1, color: BasketSurface.border),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            detail.paidLabel,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            detail.totalLabel,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (detail.showInvoice && orderId != null) ...[
                  const SizedBox(height: BasketSpace.section),
                  SizedBox(
                    width: double.infinity,
                    child: _DownloadTile(
                      label: 'Receipt',
                      onTap: () => downloadOrderReceipt(
                        context,
                        orders: cubit.api.orders,
                        orderId: orderId,
                        orderNumber: detail.id,
                      ),
                    ),
                  ),
                ],
                if (detail.isLive) ...[
                  const SizedBox(height: BasketSpace.section),
                  Row(
                    children: [
                      Expanded(
                        child: BasketButton(
                          label: 'Cancel order',
                          variant: BasketButtonVariant.danger,
                          size: BasketButtonSize.medium,
                          onPressed: cubit.openCancelSheet,
                        ),
                      ),
                      const SizedBox(width: BasketSpace.sm),
                      Expanded(
                        child: BasketButton.secondary(
                          label: 'Return items',
                          size: BasketButtonSize.medium,
                          onPressed: cubit.openReturnSheet,
                        ),
                      ),
                    ],
                  ),
                ] else if (detail.returnable) ...[
                  const SizedBox(height: BasketSpace.section),
                  BasketButton.secondary(
                    label: 'Return items',
                    size: BasketButtonSize.medium,
                    onPressed: cubit.openReturnSheet,
                  ),
                ],
                const SizedBox(height: BasketSpace.xs),
                Center(
                  child: BasketButton.text(
                    label: 'Need help with this order?',
                    onPressed: cubit.goToSupport,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DownloadTile extends StatelessWidget {
  const _DownloadTile({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: BasketSpace.md,
          vertical: BasketSpace.sm,
        ),
        decoration: basketCard(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '↓ PDF',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: BasketColors.muted,
              ),
            ),
          ],
        ),
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
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF4A4A52),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF4A4A52),
          ),
        ),
      ],
    );
  }
}
