import 'package:fastswipe/core/basket_api/models/report_models.dart';
import 'package:fastswipe/core/files/file_download_actions.dart';
import 'package:fastswipe/features/basket_admin/cubit/basket_admin_cubit.dart';
import 'package:fastswipe/features/basket_admin/data/basket_admin_data.dart';
import 'package:fastswipe/features/basket_admin/presentation/admin_ui.dart';
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
    final storeSettings = context.select((BasketAdminCubit c) => c.state.storeSettings);
    final storeSettingsSaving = context.select((BasketAdminCubit c) => c.state.storeSettingsSaving);
    final storeSettingsError = context.select((BasketAdminCubit c) => c.state.storeSettingsError);
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
                  spacing: AdminSpace.xs,
                  runSpacing: AdminSpace.xs,
                  children: [
                    for (final entry in _kGstMonths.entries)
                      AdminPillButton(label: entry.value, selected: month == entry.key, onTap: () => cubit.setMonth(entry.key)),
                  ],
                ),
              ),
              const SizedBox(width: AdminSpace.xs),
              AdminButton.secondary(
                label: '⤓ GSTR-1 (JSON)',
                onPressed: () => downloadAndShareBytes(
                  context,
                  fetch: () => cubit.api.reports.fetchGstr1Json(month: BasketAdminCubit.gstMonthCodes[month]),
                  filename: 'gstr1-${BasketAdminCubit.gstMonthCodes[month]}.json',
                  mimeType: 'application/json',
                  preparingMessage: 'Preparing GSTR-1…',
                ),
              ),
              const SizedBox(width: AdminSpace.xs),
              AdminButton(
                label: '⤓ GSTR-3B summary',
                onPressed: () => downloadAndShareBytes(
                  context,
                  fetch: () => cubit.api.reports.fetchGstr3bPdf(month: BasketAdminCubit.gstMonthCodes[month]),
                  filename: 'gstr3b-${BasketAdminCubit.gstMonthCodes[month]}.pdf',
                  mimeType: 'application/pdf',
                  preparingMessage: 'Preparing GSTR-3B summary…',
                ),
              ),
            ],
          ),
          const SizedBox(height: AdminSpace.section),
          _GstSettingsCard(
            settings: storeSettings,
            saving: storeSettingsSaving,
            error: storeSettingsError,
            onSave: cubit.saveStoreSettings,
          ),
          const SizedBox(height: AdminSpace.section),
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
                          const SizedBox(height: AdminSpace.xs),
                          Text(error, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w500, color: AdminColors.muted)),
                          const SizedBox(height: AdminSpace.md),
                          AdminButton.secondary(label: 'Retry', onPressed: cubit.loadGst),
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
            const SizedBox(height: AdminSpace.section),
            Container(
              padding: const EdgeInsets.all(AdminSpace.md),
              decoration: adminCard(),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 780,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(AdminSpace.sm, AdminSpace.xxs, AdminSpace.sm, AdminSpace.sm),
                        child: AdminSectionTitle('Tax slab breakdown · $monthLabel'),
                      ),
                      const AdminTableHeader(flex: _kFlex, labels: ['Slab', 'Taxable value', 'CGST', 'SGST', 'Total tax', 'Invoices']),
                      if (report.slabs.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: AdminSpace.lg),
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
                        padding: const EdgeInsets.fromLTRB(AdminSpace.sm, AdminSpace.md, AdminSpace.sm, 0),
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

/// Editable seller GST profile (business name/address/GSTIN) — saved via
/// `BasketAdminCubit.saveStoreSettings`, takes effect on the next
/// invoice/GSTR-1/GSTR-3B generated. A local form so typing doesn't fight
/// with the cubit's state on every keystroke; it only re-syncs its
/// controllers when a freshly-*loaded* (not saved-back) settings object
/// arrives.
class _GstSettingsCard extends StatefulWidget {
  const _GstSettingsCard({required this.settings, required this.saving, required this.error, required this.onSave});

  final StoreGstSettings? settings;
  final bool saving;
  final String? error;
  final Future<bool> Function(StoreGstSettings) onSave;

  @override
  State<_GstSettingsCard> createState() => _GstSettingsCardState();
}

class _GstSettingsCardState extends State<_GstSettingsCard> {
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _gstinCtrl = TextEditingController();
  StoreGstSettings? _synced;

  @override
  void initState() {
    super.initState();
    _syncFrom(widget.settings);
  }

  @override
  void didUpdateWidget(covariant _GstSettingsCard old) {
    super.didUpdateWidget(old);
    if (widget.settings != null && widget.settings != _synced) _syncFrom(widget.settings);
  }

  void _syncFrom(StoreGstSettings? settings) {
    if (settings == null) return;
    _synced = settings;
    _nameCtrl.text = settings.businessName;
    _addressCtrl.text = settings.address;
    _gstinCtrl.text = settings.gstin;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _gstinCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final ok = await widget.onSave(
      StoreGstSettings(businessName: _nameCtrl.text.trim(), address: _addressCtrl.text.trim(), gstin: _gstinCtrl.text.trim()),
    );
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('GST settings saved.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AdminSpace.card),
      decoration: adminCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSectionTitle('GST settings'),
          const SizedBox(height: AdminSpace.xxs),
          Text('Printed on every invoice, GSTR-1 and GSTR-3B export — editing these takes effect immediately.',
              style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w500, color: AdminColors.muted)),
          const SizedBox(height: AdminSpace.md),
          LayoutBuilder(builder: (context, constraints) {
            final narrow = constraints.maxWidth < 640;
            final fields = [
              _field('Business name', _nameCtrl),
              _field('GSTIN', _gstinCtrl),
              _field('Address', _addressCtrl, maxLines: 2),
            ];
            if (narrow) {
              return Column(children: [for (final f in fields) Padding(padding: const EdgeInsets.only(bottom: AdminSpace.sm), child: f)]);
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: fields[0]),
                const SizedBox(width: AdminSpace.sm),
                Expanded(child: fields[1]),
                const SizedBox(width: AdminSpace.sm),
                Expanded(flex: 2, child: fields[2]),
              ],
            );
          }),
          if (widget.error != null) ...[
            const SizedBox(height: AdminSpace.sm),
            Text(widget.error!, style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w600, color: AdminSurface.error)),
          ],
          const SizedBox(height: AdminSpace.md),
          Align(
            alignment: Alignment.centerRight,
            child: AdminButton(label: 'Save GST settings', loading: widget.saving, onPressed: _save),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, {int maxLines = 1}) {
    return AdminEditField(label: label, controller: controller, maxLines: maxLines);
  }
}
