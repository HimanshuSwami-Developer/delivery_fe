import 'package:fastswipe/core/files/file_download_actions.dart';
import 'package:fastswipe/features/basket_admin/cubit/basket_admin_cubit.dart';
import 'package:fastswipe/features/basket_admin/data/basket_admin_data.dart';
import 'package:fastswipe/features/basket_admin/presentation/basket_admin_style.dart';
import 'package:fastswipe/features/basket_admin/presentation/widgets/admin_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

/// key -> pill label. Order matters: it's the pill order (Aug, Jul, Jun),
/// matching the source design's `Object.keys` iteration; must line up with
/// `BasketAdminCubit.gstMonthCodes`.
const _kGstMonths = {'aug': 'Aug 2026', 'jul': 'Jul 2026', 'jun': 'Jun 2026'};

const _kFlex = [1.0, 1.2, 1.0, 1.0, 1.0, 1.1];

/// GST reports: month picker, 4 headline stats, and a slab-wise tax
/// breakdown table — all sourced from the real GST report endpoint.
class AdminGstView extends StatelessWidget {
  const AdminGstView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketAdminCubit>();
    final month = context.select((BasketAdminCubit c) => c.state.month);
    final report = context.select((BasketAdminCubit c) => c.state.gstReport);
    final error = context.select((BasketAdminCubit c) => c.state.gstError);
    final monthLabel = _kGstMonths[month] ?? month;
    final dueMonth = month == 'aug' ? 'Sep' : (month == 'jul' ? 'Aug' : 'Jul');

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 9,
                  runSpacing: 9,
                  children: [
                    for (final entry in _kGstMonths.entries)
                      AdminPillButton(label: entry.value, selected: month == entry.key, onTap: () => cubit.setMonth(entry.key)),
                  ],
                ),
              ),
              const SizedBox(width: 9),
              OutlinedButton(
                onPressed: () => downloadAndShareBytes(
                  context,
                  fetch: () => cubit.api.reports.fetchGstr1Json(month: BasketAdminCubit.gstMonthCodes[month]),
                  filename: 'gstr1-${BasketAdminCubit.gstMonthCodes[month]}.json',
                  mimeType: 'application/json',
                  preparingMessage: 'Preparing GSTR-1…',
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AdminColors.ink.withValues(alpha: 0.12)),
                  backgroundColor: Color(0xFFFFFBF2),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                ),
                child: Text('⤓ GSTR-1 (JSON)', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: AdminColors.ink)),
              ),
              const SizedBox(width: 9),
              FilledButton(
                onPressed: () => downloadAndShareBytes(
                  context,
                  fetch: () => cubit.api.reports.fetchGstr3bPdf(month: BasketAdminCubit.gstMonthCodes[month]),
                  filename: 'gstr3b-${BasketAdminCubit.gstMonthCodes[month]}.pdf',
                  mimeType: 'application/pdf',
                  preparingMessage: 'Preparing GSTR-3B summary…',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AdminColors.ink,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                ),
                child: Text('⤓ GSTR-3B summary', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFFFFBF2))),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (report == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: error == null
                    ? const CircularProgressIndicator()
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Couldn\'t load the GST report', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Text(error, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w500, color: AdminColors.muted)),
                          const SizedBox(height: 14),
                          OutlinedButton(
                            onPressed: cubit.loadGst,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
              ),
            )
          else ...[
            AdminResponsiveGrid(
              children: [
                AdminStatCard(label: 'Taxable turnover', value: adminMoney(report.taxableTurnover), sub: '$monthLabel · B2C + B2B'),
                AdminStatCard(label: 'Output GST', value: adminMoney(report.outputGst), sub: 'CGST + SGST'),
                AdminStatCard(label: 'Input credit', value: adminMoney(report.inputCredit), sub: 'On purchases'),
                AdminStatCard(label: 'Net payable', value: adminMoney(report.netPayable), sub: 'Due 20 $dueMonth'),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 14),
              decoration: adminGlassCard(),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 780,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 16, 10, 12),
                        child: AdminSectionTitle('Tax slab breakdown · $monthLabel'),
                      ),
                      const AdminTableHeader(flex: _kFlex, labels: ['Slab', 'Taxable value', 'CGST', 'SGST', 'Total tax', 'Invoices']),
                      if (report.slabs.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text('No invoices this month.', style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600, color: AdminColors.muted)),
                        ),
                      for (final g in report.slabs)
                        AdminTableRow(
                          flex: _kFlex,
                          children: [
                            Text('GST ${g.slab}', style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w800)),
                            Text(adminMoney(g.taxableValue), style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600, color: AdminColors.muted)),
                            Text(adminMoney(g.cgst), style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600, color: AdminColors.muted)),
                            Text(adminMoney(g.sgst), style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600, color: AdminColors.muted)),
                            Text(adminMoney(g.totalTax), style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w800)),
                            Text(indianGroup(g.invoices), style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600, color: AdminColors.muted)),
                          ],
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 14, 10, 4),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text('Net GST payable · ${adminMoney(report.netPayable)}', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
