import 'package:fastswipe/core/basket_api/models/report_models.dart';
import 'package:fastswipe/core/files/file_download_actions.dart';
import 'package:fastswipe/features/basket_admin/cubit/basket_admin_cubit.dart';
import 'package:fastswipe/features/basket_admin/data/basket_admin_data.dart';
import 'package:fastswipe/features/basket_admin/presentation/basket_admin_style.dart';
import 'package:fastswipe/features/basket_admin/presentation/widgets/admin_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

const _periods = [
  ('daily', 'Daily'),
  ('weekly', 'Weekly'),
  ('monthly', 'Monthly'),
  ('yearly', 'Yearly'),
];

const _xlsxMime = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

/// "Delivered sales" on the Sales reports screen: successfully delivered
/// orders only, grouped daily/weekly/monthly/yearly — KPIs, a revenue bar
/// chart, a per-period table, and an Excel download of the same report
/// (plus every delivered order and products sold). See
/// `DeliveredSalesReportView` / `DeliveredSalesExportView`.
class AdminDeliveredSalesSection extends StatelessWidget {
  const AdminDeliveredSalesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketAdminCubit>();
    final period = context.select((BasketAdminCubit c) => c.state.deliveredSalesPeriod);
    final report = context.select((BasketAdminCubit c) => c.state.deliveredSales);
    final loading = context.select((BasketAdminCubit c) => c.state.deliveredSalesLoading);
    final error = context.select((BasketAdminCubit c) => c.state.deliveredSalesError);
    // Only show a report that matches the selected tab — avoids flashing
    // last tab's numbers under the new tab's label while it loads.
    final shown = report?.period == period ? report : null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: adminGlassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AdminSectionTitle('Delivered sales'),
                  const SizedBox(height: 4),
                  Text(
                    shown == null ? 'Successfully delivered orders only' : '${_date(shown.start)} – ${_date(shown.end)} · delivered orders only',
                    style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w500, color: AdminColors.muted),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final p in _periods)
                    AdminPillButton(
                      label: p.$2,
                      selected: period == p.$1,
                      onTap: () => cubit.loadDeliveredSales(p.$1),
                    ),
                  FilledButton.icon(
                    onPressed: () => downloadAndShareBytes(
                      context,
                      fetch: () => cubit.api.reports.fetchDeliveredSalesExcel(period: period),
                      filename: 'delivered-sales-$period.xlsx',
                      mimeType: _xlsxMime,
                      preparingMessage: 'Preparing Excel report…',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1D6F42),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                    ),
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: Text('Download Excel', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (shown == null)
            SizedBox(
              height: 160,
              child: Center(
                child: loading || error == null
                    ? const CircularProgressIndicator()
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Couldn\'t load delivered sales', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Text(error, style: GoogleFonts.manrope(fontSize: 12, color: AdminColors.muted)),
                          const SizedBox(height: 12),
                          OutlinedButton(onPressed: cubit.loadDeliveredSales, child: const Text('Retry')),
                        ],
                      ),
              ),
            )
          else
            AnimatedOpacity(
              opacity: loading ? 0.5 : 1,
              duration: const Duration(milliseconds: 200),
              child: _ReportBody(report: shown),
            ),
        ],
      ),
    );
  }
}

class _ReportBody extends StatelessWidget {
  const _ReportBody({required this.report});

  final DeliveredSalesReport report;

  @override
  Widget build(BuildContext context) {
    final stats = [
      ('Revenue', adminMoney(report.revenue), 'COD ${adminMoney(report.codRevenue)} · Online ${adminMoney(report.onlineRevenue)}'),
      ('Delivered orders', indianGroup(report.orders), '${indianGroup(report.items)} items sold'),
      ('Avg order value', adminMoney(report.avgOrderValue), 'Per delivered order'),
      ('Best ${_unit(report.period)}', report.bestPeriod ?? '—', 'GST collected ${adminMoney(report.gst)}'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminResponsiveGrid(children: [for (final s in stats) AdminStatCard(label: s.$1, value: s.$2, sub: s.$3)]),
        const SizedBox(height: 18),
        _RevenueChart(rows: report.rows, period: report.period),
        const SizedBox(height: 18),
        _PeriodTable(rows: report.rows),
      ],
    );
  }
}

class _RevenueChart extends StatelessWidget {
  const _RevenueChart({required this.rows, required this.period});

  final List<DeliveredSalesRow> rows;
  final String period;

  @override
  Widget build(BuildContext context) {
    if (rows.every((r) => r.revenue == 0)) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Center(
          child: Text('No delivered sales in this range yet.',
              style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600, color: AdminColors.muted)),
        ),
      );
    }
    final max = rows.map((r) => r.revenue).reduce((a, b) => a > b ? a : b);
    return LayoutBuilder(builder: (context, constraints) {
      const gap = 6.0;
      const minBar = 18.0;
      final fitted = (constraints.maxWidth - gap * (rows.length - 1)) / rows.length;
      final barWidth = fitted < minBar ? minBar : fitted;
      final chartWidth = barWidth * rows.length + gap * (rows.length - 1);
      final chart = SizedBox(
        width: chartWidth,
        height: 190,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const SizedBox(width: gap),
              SizedBox(
                width: barWidth,
                child: Tooltip(
                  message: '${rows[i].label}\n${adminMoney(rows[i].revenue)} · ${rows[i].orders} orders',
                  child: Column(
                    children: [
                      Expanded(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(end: max == 0 ? 0 : rows[i].revenue / max),
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOutCubic,
                          builder: (context, v, _) => FractionallySizedBox(
                            heightFactor: v,
                            alignment: Alignment.bottomCenter,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: rows[i].revenue == max ? AdminColors.ink : AdminColors.ink.withValues(alpha: 0.22),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _shortLabel(rows[i], period),
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: GoogleFonts.manrope(fontSize: 9.5, fontWeight: FontWeight.w600, color: AdminColors.faint),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      );
      if (chartWidth <= constraints.maxWidth) return chart;
      // Too many bars to fit (e.g. 30 days on a phone) — scroll, starting
      // at the most recent end.
      return SingleChildScrollView(scrollDirection: Axis.horizontal, reverse: true, child: chart);
    });
  }
}

class _PeriodTable extends StatelessWidget {
  const _PeriodTable({required this.rows});

  final List<DeliveredSalesRow> rows;

  static const _flex = [2.4, 1.0, 1.0, 1.3, 1.5];

  @override
  Widget build(BuildContext context) {
    final cell = GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600);
    final strong = GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w800);
    // Newest first, and only periods that actually had sales.
    final visible = rows.where((r) => r.orders > 0).toList().reversed.toList();
    return Column(
      children: [
        const AdminTableHeader(flex: _flex, labels: ['Period', 'Orders', 'Items', 'GST', 'Revenue']),
        if (visible.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Text('Nothing delivered in this range.', style: GoogleFonts.manrope(fontSize: 12, color: AdminColors.muted)),
          ),
        for (final r in visible)
          AdminTableRow(
            flex: _flex,
            children: [
              Text(r.label, style: cell),
              Text(indianGroup(r.orders), style: cell),
              Text(indianGroup(r.items), style: cell),
              Text(adminMoney(r.gst), style: cell),
              Text(adminMoney(r.revenue), style: strong),
            ],
          ),
      ],
    );
  }
}

String _unit(String period) => switch (period) {
      'daily' => 'day',
      'weekly' => 'week',
      'monthly' => 'month',
      _ => 'year',
    };

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String _date(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

String _shortLabel(DeliveredSalesRow r, String period) {
  final d = r.periodStart;
  return switch (period) {
    'daily' => '${d.day}',
    'weekly' => '${d.day} ${_months[d.month - 1]}',
    'monthly' => _months[d.month - 1],
    _ => '${d.year}',
  };
}
