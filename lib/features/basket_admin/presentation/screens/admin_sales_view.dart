import 'dart:math' as math;

import 'package:fastswipe/core/files/file_download_actions.dart';
import 'package:fastswipe/features/basket_admin/cubit/basket_admin_cubit.dart';
import 'package:fastswipe/features/basket_admin/data/basket_admin_data.dart';
import 'package:fastswipe/features/basket_admin/presentation/admin_ui.dart';
import 'package:fastswipe/features/basket_admin/presentation/basket_admin_style.dart';
import 'package:fastswipe/features/basket_admin/presentation/widgets/admin_common.dart';
import 'package:fastswipe/features/basket_admin/presentation/widgets/admin_delivered_sales_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

/// Sales reports: 4 headline stats, a monthly-revenue bar chart, and a
/// top-categories breakdown with progress bars — all from the live report.
class AdminSalesView extends StatelessWidget {
  const AdminSalesView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketAdminCubit>();
    final report = context.select((BasketAdminCubit c) => c.state.salesReport);
    final error = context.select((BasketAdminCubit c) => c.state.salesError);

    if (report == null) {
      return Center(
        child: error == null
            ? const CircularProgressIndicator()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Couldn\'t load sales reports', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: AdminSpace.xs),
                  Text(error, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w500, color: AdminColors.muted)),
                  const SizedBox(height: AdminSpace.md),
                  AdminButton.secondary(label: 'Retry', onPressed: context.read<BasketAdminCubit>().loadSales),
                ],
              ),
      );
    }

    final stats = [
      ('Revenue this month', adminMoney(report.revenueThisMonth), 'Gross merchandise value'),
      ('Orders this month', indianGroup(report.ordersThisMonth), 'Delivered + in transit'),
      ('Avg basket', adminMoney(report.avgBasket), 'Per order'),
      ('Repeat rate', report.repeatRatePct == null ? '—' : '${report.repeatRatePct!.toStringAsFixed(1)}%', 'Within 30 days'),
    ];

    final monthMax = report.monthlyRevenue.isEmpty
        ? 1
        // Floor of 1 so a month of ₹0 can't divide by zero. (Not
        // `.clamp(1, 1 << 62)` — on web ints are JS numbers, `1 << 62` is 0,
        // and clamp(1, 0) throws, greying out the whole screen.)
        : math.max(1, report.monthlyRevenue.map((m) => m.revenue).reduce((a, b) => a > b ? a : b));
    final catMax = report.topCategories.isEmpty
        ? 0
        : report.topCategories.map((c) => c.revenue).reduce((a, b) => a > b ? a : b);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: SizedBox.shrink()),
              AdminButton.secondary(
                label: '⤓ Export CSV',
                onPressed: () => downloadAndShareBytes(
                  context,
                  fetch: () => cubit.api.reports.fetchSalesExportCsv(),
                  filename: 'sales-report.csv',
                  mimeType: 'text/csv',
                  preparingMessage: 'Preparing sales report…',
                ),
              ),
            ],
          ),
          const SizedBox(height: AdminSpace.section),
          const AdminDeliveredSalesSection(),
          const SizedBox(height: AdminSpace.section),
          AdminResponsiveGrid(children: [for (final s in stats) AdminStatCard(label: s.$1, value: s.$2, sub: s.$3)]),
          const SizedBox(height: AdminSpace.section),
          LayoutBuilder(builder: (context, constraints) {
            final narrow = constraints.maxWidth < 820;

            final revenueCard = Container(
              padding: const EdgeInsets.all(AdminSpace.card),
              decoration: adminCard(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AdminSectionTitle('Monthly revenue'),
                  const SizedBox(height: AdminSpace.lg),
                  if (report.monthlyRevenue.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AdminSpace.xxl),
                      child: Text('No revenue history yet.', style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600, color: AdminColors.muted)),
                    )
                  else
                    SizedBox(
                      height: 200,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (var i = 0; i < report.monthlyRevenue.length; i++) ...[
                            if (i > 0) const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                children: [
                                  Text(_lakhLabel(report.monthlyRevenue[i].revenue), style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 8),
                                  // Expanded + FractionallySizedBox rather than a literal pixel
                                  // height so the bar always fits whatever space the two text
                                  // labels leave, regardless of their rendered font metrics.
                                  Expanded(
                                    child: FractionallySizedBox(
                                      heightFactor: report.monthlyRevenue[i].revenue / monthMax,
                                      alignment: Alignment.bottomCenter,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: report.monthlyRevenue[i].revenue == monthMax ? AdminColors.ink : AdminColors.ink.withValues(alpha: 0.2),
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(report.monthlyRevenue[i].month, style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w600, color: AdminColors.faint)),
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

            final topCatsCard = Container(
              padding: const EdgeInsets.all(AdminSpace.card),
              decoration: adminCard(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AdminSectionTitle('Top categories'),
                  const SizedBox(height: AdminSpace.md),
                  if (report.topCategories.isEmpty)
                    Text('No category sales yet.', style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600, color: AdminColors.muted)),
                  for (var i = 0; i < report.topCategories.length; i++)
                    Padding(
                      padding: EdgeInsets.only(bottom: i == report.topCategories.length - 1 ? 0 : AdminSpace.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(report.topCategories[i].category ?? 'Uncategorised', style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w700)),
                              Text(adminMoney(report.topCategories[i].revenue), style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w700)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AdminRadius.sm),
                            child: LinearProgressIndicator(
                              value: catMax == 0 ? 0 : report.topCategories[i].revenue / catMax,
                              minHeight: 7,
                              backgroundColor: AdminColors.ink.withValues(alpha: 0.09),
                              valueColor: AlwaysStoppedAnimation(i == 0 ? AdminColors.ink : AdminColors.ink.withValues(alpha: 0.24)),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );

            if (narrow) {
              return Column(children: [revenueCard, const SizedBox(height: AdminSpace.section), topCatsCard]);
            }
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 140, child: revenueCard),
                  const SizedBox(width: AdminSpace.section),
                  Expanded(flex: 100, child: topCatsCard),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

String _lakhLabel(int revenue) => '₹${(revenue / 100000).toStringAsFixed(1)}L';
