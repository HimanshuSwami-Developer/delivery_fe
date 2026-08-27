import 'package:fastswipe/features/basket/presentation/widgets/image_slot.dart';
import 'package:fastswipe/features/basket_admin/cubit/basket_admin_cubit.dart';
import 'package:fastswipe/features/basket_admin/data/basket_admin_data.dart';
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
    final zoneLabel = context.select(
      (BasketAdminCubit c) => c.state.apiZones.isNotEmpty && c.state.zone < c.state.apiZones.length
          ? c.state.apiZones[c.state.zone].name
          : 'All zones',
    );
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
                chipFg: Colors.white,
              ),
              AdminKpiCard(
                label: 'Orders',
                value: '${report.ordersToday}',
                sub: 'Today so far',
                delta: _pctLabel(report.ordersDeltaPct),
                chipBg: AdminColors.ink,
                chipFg: Colors.white,
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
          const SizedBox(height: 14),
          LayoutBuilder(builder: (context, constraints) {
            final narrow = constraints.maxWidth < 860;
            final chartCard = Container(
              padding: const EdgeInsets.all(18),
              decoration: adminGlassCard(),
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
                            const SizedBox(height: 5),
                            Text('Gross merchandise value, $zoneLabel',
                                style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w500, color: AdminColors.muted)),
                          ],
                        ),
                      ),
                      Wrap(
                        spacing: 7,
                        children: [
                          for (final r in _kRanges) AdminPillButton(label: r.$2, selected: range == r.$1, onTap: () => cubit.setRange(r.$1)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
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
              padding: const EdgeInsets.all(18),
              decoration: adminDarkCard(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Low stock alerts', style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 5),
                  Text('${report.lowStock.length} SKUs below reorder level',
                      style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.5))),
                  const SizedBox(height: 15),
                  if (report.lowStock.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text('Nothing below reorder level right now.',
                          style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.6))),
                    ),
                  for (final l in report.lowStock)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 34, height: 34, child: ImageSlot(shape: ImageSlotShape.rounded, radius: 9, mini: true)),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(l.product, style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white)),
                                  const SizedBox(height: 3),
                                  Text(l.zone, style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.45))),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${l.onHand}', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
                                Text('left', style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.45))),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: cubit.goInventory,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Open inventory', style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w800, color: AdminColors.ink)),
                    ),
                  ),
                ],
              ),
            );

            return narrow
                ? Column(children: [chartCard, const SizedBox(height: 14), lowStockCard])
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 165, child: chartCard),
                      const SizedBox(width: 14),
                      Expanded(flex: 100, child: lowStockCard),
                    ],
                  );
          }),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: adminGlassCard(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(child: AdminSectionTitle('Recent orders')),
                    TextButton(
                      onPressed: cubit.goOrders,
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      child: Text('View all orders →', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: AdminColors.muted)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (report.recentOrders.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
