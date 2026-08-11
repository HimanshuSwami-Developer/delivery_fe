import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/cubit/basket_selectors.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
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
                    color: Colors.white.withValues(alpha: 0.1),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 16),
                ),
              ),
              const SizedBox(width: 10),
              Text('My orders', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            ],
          ),
        ),
        Expanded(
          child: Skeletonizer(
            enabled: showSkeleton,
            child: IgnorePointer(
              ignoring: showSkeleton,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
                children: [
                  for (final row in listRows)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
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
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.68),
          border: Border.all(color: Colors.white.withValues(alpha: 0.85)),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: BasketColors.ink.withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(row.orderNumber, style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w800)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: switch ((row.isLive, row.statusLabel)) {
                      (true, _) => BasketColors.primary,
                      (false, 'Cancelled') => BasketColors.errorSoft,
                      (false, _) => BasketColors.primarySoft,
                    },
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    row.statusLabel,
                    style: GoogleFonts.poppins(
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
            const SizedBox(height: 7),
            Text(
              '${row.dateLabel} · ${row.itemCount} items',
              style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w500, color: BasketColors.muted),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(row.totalLabel, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800)),
                Text('${row.ctaLabel} ›', style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w700, color: BasketColors.muted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
