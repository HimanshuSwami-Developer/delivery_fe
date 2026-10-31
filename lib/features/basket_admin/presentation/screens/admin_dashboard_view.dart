import 'package:fastswipe/features/basket/presentation/widgets/image_slot.dart';
import 'package:fastswipe/features/basket_admin/cubit/basket_admin_cubit.dart';
import 'package:fastswipe/features/basket_admin/data/basket_admin_data.dart';
import 'package:fastswipe/features/basket_admin/presentation/admin_ui.dart';
import 'package:fastswipe/features/basket_admin/presentation/basket_admin_style.dart';
import 'package:fastswipe/features/basket_admin/presentation/widgets/admin_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

const _kRanges = [('7d', '7 days'), ('14d', '14 days'), ('30d', '30 days')];

String _pctLabel(double? v) => v == null ? '—' : '${v >= 0 ? '+' : ''}${v.toStringAsFixed(1)}%';

class AdminDashboardView extends StatelessWidget {
  const AdminDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketAdminCubit>();
    final range = context.select((BasketAdminCubit c) => c.state.range);
    final report = context.select((BasketAdminCubit c) => c.state.dashboardReport);
    final loading = context.select((BasketAdminCubit c) => c.state.dashboardLoading);

    if (loading && report == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (report == null) {
      return const Center(child: Text('Could not load the dashboard.'));
    }

    final chart = report.chart14d;
    final maxBar = chart.map((c) => c.gmv).fold(1, (a, b) => a > b ? a : b);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminResponsiveGrid(
            children: [
              AdminKpiCard(
                label: "Today's GMV",
                value: adminMoney(report.gmvToday),
                sub: 'vs yesterday',
                delta: _pctLabel(report.gmvDeltaPct),
                chipBg: AdminColors.ink,
                chipFg: Color(0xFFFFFBF2),
              ),
              AdminKpiCard(
                label: 'Orders',
                value: '${report.ordersToday}',
                sub: 'Today so far',
                delta: _pctLabel(report.ordersDeltaPct),
                chipBg: AdminColors.ink,
                chipFg: Color(0xFFFFFBF2),
              ),
              AdminKpiCard(
                label: 'Avg basket',
                value: adminMoney(report.avgBasket),
                sub: 'Today so far',
                delta: '',
                chipBg: AdminColors.ink.withValues(alpha: 0.08),
                chipFg: AdminColors.ink,
              ),
              AdminKpiCard(
                label: 'On-time rate',
                value: report.onTimeRatePct == null ? '—' : '${report.onTimeRatePct!.toStringAsFixed(1)}%',
                sub: 'Last 30 days',
                delta: '',
                chipBg: AdminColors.ink.withValues(alpha: 0.08),
                chipFg: AdminColors.ink,
              ),
            ],
          ),
          const SizedBox(height: AdminSpace.section),
          LayoutBuilder(builder: (context, constraints) {
            final narrow = constraints.maxWidth < 860;
            final chartCard = Container(
              padding: const EdgeInsets.all(AdminSpace.card),
              decoration: adminCard(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AdminSectionTitle('Sales · last 14 days'),
                            const SizedBox(height: AdminSpace.xxs),
                            Text('Gross merchandise value',
                                style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w500, color: AdminColors.muted)),
                          ],
                        ),
                      ),
                      Wrap(
                        spacing: AdminSpace.xs,
                        children: [
                          for (final r in _kRanges) AdminPillButton(label: r.$2, selected: range == r.$1, onTap: () => cubit.setRange(r.$1)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AdminSpace.lg),
                  SizedBox(
                    height: 190,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (var i = 0; i < chart.length; i++) ...[
                          if (i > 0) const SizedBox(width: 7),
                          Expanded(
                            child: Column(
                              children: [
                                Text('₹${(chart[i].gmv / 1000).round()}k',
                                    style: GoogleFonts.manrope(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: chart[i].gmv == maxBar ? AdminColors.ink : AdminColors.faint)),
                                const SizedBox(height: 8),
                                // Expanded + FractionallySizedBox (rather than a literal pixel
                                // height derived from maxBar) so the bar always fits whatever
                                // space is left after the two text labels, however tall their
                                // rendered font metrics turn out to be.
                                Expanded(
                                  child: FractionallySizedBox(
                                    heightFactor: chart[i].gmv / maxBar,
                                    alignment: Alignment.bottomCenter,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: chart[i].gmv == maxBar ? AdminColors.ink : AdminColors.ink.withValues(alpha: 0.2),
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(chart[i].date.substring(8), style: GoogleFonts.manrope(fontSize: 9.5, fontWeight: FontWeight.w600, color: AdminColors.faint)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );

            final lowStockCard = Container(
              padding: const EdgeInsets.all(AdminSpace.card),
              decoration: adminDarkCard(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Low stock alerts', style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFFFFFBF2))),
                  const SizedBox(height: AdminSpace.xxs),
                  Text('${report.lowStock.length} SKUs below reorder level',
                      style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w500, color: Color(0xFFFFFBF2).withValues(alpha: 0.5))),
                  const SizedBox(height: AdminSpace.md),
                  if (report.lowStock.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AdminSpace.xs),
                      child: Text('Nothing below reorder level right now.',
                          style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w500, color: Color(0xFFFFFBF2).withValues(alpha: 0.6))),
                    ),
                  for (final l in report.lowStock)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AdminSpace.xs),
                      child: Container(
                        padding: const EdgeInsets.all(AdminSpace.sm),
                        decoration: BoxDecoration(
                          color: Color(0xFFFFFBF2).withValues(alpha: 0.08),
                          border: Border.all(color: Color(0xFFFFFBF2).withValues(alpha: 0.12)),
                          borderRadius: BorderRadius.circular(AdminRadius.md),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 34, height: 34, child: ImageSlot(shape: ImageSlotShape.rounded, radius: AdminRadius.sm, mini: true)),
                            const SizedBox(width: AdminSpace.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(l.product, style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFFFFFBF2))),
                                  const SizedBox(height: 3),
                                  Text(l.sku, style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFFFFFBF2).withValues(alpha: 0.45))),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${l.onHand}', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFFFFBF2))),
                                Text('left', style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFFFFFBF2).withValues(alpha: 0.45))),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: AdminSpace.xxs),
                  // Secondary (white fill), not primary — an ink button would
                  // vanish against this dark ink card.
                  AdminButton.secondary(label: 'Open inventory', expand: true, onPressed: cubit.goInventory),
                ],
              ),
            );

            return narrow
                ? Column(children: [chartCard, const SizedBox(height: AdminSpace.section), lowStockCard])
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 165, child: chartCard),
                      const SizedBox(width: AdminSpace.section),
                      Expanded(flex: 100, child: lowStockCard),
                    ],
                  );
          }),
          const SizedBox(height: AdminSpace.section),
          Container(
            padding: const EdgeInsets.all(AdminSpace.card),
            decoration: adminCard(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(child: AdminSectionTitle('Recent orders')),
                    AdminButton(
                      label: 'View all orders →',
                      variant: AdminButtonVariant.text,
                      size: AdminButtonSize.small,
                      onPressed: cubit.goOrders,
                    ),
                  ],
                ),
                const SizedBox(height: AdminSpace.sm),
                if (report.recentOrders.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AdminSpace.md),
                    child: Text('No orders yet.', style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600, color: AdminColors.muted)),
                  )
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: 760,
                      child: Column(
                        children: [
                          const AdminTableHeader(flex: [1.1, 1.5, 1, 1, 1, 0.9], labels: ['Order', 'Customer', 'Items', 'Value', 'Partner', 'Status']),
                          for (final o in report.recentOrders)
                            AdminTableRow(
                              flex: const [1.1, 1.5, 1, 1, 1, 0.9],
                              onTap: () => cubit.openOrder(o.id.toString()),
                              children: [
                                Text(o.orderNumber, style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w800)),
                                Text(o.customer, style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600)),
                                Text('${o.itemCount} items', style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600, color: AdminColors.muted)),
                                Text(adminMoney(o.total), style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w800)),
                                Text(o.deliveryPartner ?? '—', style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600, color: AdminColors.muted)),
                                Align(alignment: Alignment.centerLeft, child: AdminChipBadge(kOrderStatusFromCode[o.status] ?? o.status)),
                              ],
                            ),
                        ],
                      ),
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
