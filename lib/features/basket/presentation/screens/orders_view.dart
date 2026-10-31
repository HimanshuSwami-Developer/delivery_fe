import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/cubit/basket_selectors.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:fastswipe/features/basket/presentation/basket_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletonizer/skeletonizer.dart';

const _skeletonOrderRow = OrderListRow(
  id: 'x',
  orderNumber: 'BSK-0000',
  dateLabel: '12 Aug, 5:00 PM',
  statusLabel: 'Delivered',
  isLive: false,
  itemCount: 5,
  totalLabel: '₹499',
  ctaLabel: 'Reorder',
);

class OrdersView extends StatelessWidget {
  const OrdersView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketCubit>();
    final ordersLoading = context.select((BasketCubit c) => c.state.ordersLoading);
    final rows = context.select((BasketCubit c) => orderListRows(c.state));
    final showSkeleton = ordersLoading && rows.isEmpty;
    final listRows = showSkeleton ? List.generate(4, (_) => _skeletonOrderRow) : rows;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(BasketSpace.gutter, MediaQuery.paddingOf(context).top + BasketSpace.sm, BasketSpace.gutter, BasketSpace.md),
          decoration: const BoxDecoration(gradient: BasketColors.headerGradient, borderRadius: BorderRadius.vertical(bottom: Radius.circular(BasketRadius.xl))),
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
                    border: Border.all(color: Color(0xFFFFFBF2).withValues(alpha: 0.14)),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.arrow_back, color: Color(0xFFFFFBF2), size: 16),
                ),
              ),
              const SizedBox(width: BasketSpace.xs),
              Text('My orders', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFFFFBF2))),
            ],
          ),
        ),
        Expanded(
          child: Skeletonizer(
            enabled: showSkeleton,
            effect: ShimmerEffect(baseColor: BasketColors.divider, highlightColor: BasketColors.surface),
            child: IgnorePointer(
              ignoring: showSkeleton,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(BasketSpace.gutter, BasketSpace.md, BasketSpace.gutter, BasketSpace.lg),
                children: [
                  for (final row in listRows)
                    Padding(
                      padding: const EdgeInsets.only(bottom: BasketSpace.section),
                      child: _OrderCard(row: row, onTap: () => cubit.openOrderDetail(row.id)),
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

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.row, required this.onTap});

  final OrderListRow row;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(BasketSpace.md),
        decoration: basketCard(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(row.orderNumber, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w800)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: BasketSpace.xs, vertical: BasketSpace.xxs),
                  decoration: BoxDecoration(
                    color: switch ((row.isLive, row.statusLabel)) {
                      (true, _) => BasketColors.primary,
                      (false, 'Cancelled') => BasketColors.errorSoft,
                      (false, _) => BasketColors.primarySoft,
                    },
                    borderRadius: BorderRadius.circular(BasketRadius.pill),
                  ),
                  child: Text(
                    row.statusLabel,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: switch ((row.isLive, row.statusLabel)) {
                        (true, _) => BasketColors.onPrimary,
                        (false, 'Cancelled') => BasketColors.error,
                        (false, _) => BasketColors.primary,
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: BasketSpace.xs),
            Text(
              '${row.dateLabel} · ${row.itemCount} items',
              style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w500, color: BasketColors.muted),
            ),
            const SizedBox(height: BasketSpace.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(row.totalLabel, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800)),
                Text('${row.ctaLabel} ›', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: BasketColors.muted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
