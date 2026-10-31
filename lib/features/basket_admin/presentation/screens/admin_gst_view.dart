import 'package:fastswipe/core/basket_api/models/catalog_models.dart';
import 'package:fastswipe/core/basket_api/models/report_models.dart';
import 'package:fastswipe/core/files/file_download_actions.dart';
import 'package:fastswipe/features/basket_admin/cubit/basket_admin_cubit.dart';
import 'package:fastswipe/features/basket_admin/data/basket_admin_data.dart';
import 'package:fastswipe/features/basket_admin/presentation/admin_ui.dart';
import 'package:fastswipe/features/basket_admin/presentation/basket_admin_style.dart';
import 'package:fastswipe/features/basket_admin/presentation/widgets/admin_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
          const _GstRatesCard(),
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
                AdminStatCard(label: 'Taxable turnover', value: adminMoneyPaise(report.taxableTurnover), sub: '$monthLabel · B2C + B2B'),
                AdminStatCard(label: 'Output GST', value: adminMoneyPaise(report.outputGst), sub: 'CGST + SGST'),
                AdminStatCard(label: 'Input credit', value: adminMoneyPaise(report.inputCredit), sub: 'On purchases'),
                AdminStatCard(label: 'Net payable', value: adminMoneyPaise(report.netPayable), sub: 'Due 20 $dueMonth'),
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
                            Text(adminMoneyPaise(g.taxableValue), style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600, color: AdminColors.muted)),
                            Text(adminMoneyPaise(g.cgst), style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600, color: AdminColors.muted)),
                            Text(adminMoneyPaise(g.sgst), style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600, color: AdminColors.muted)),
                            Text(adminMoneyPaise(g.totalTax), style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w800)),
                            Text(indianGroup(g.invoices), style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600, color: AdminColors.muted)),
                          ],
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(AdminSpace.sm, AdminSpace.md, AdminSpace.sm, 0),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text('Net GST payable · ${adminMoneyPaise(report.netPayable)}', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800)),
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
  final _prefixCtrl = TextEditingController();
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
    _prefixCtrl.text = settings.invoicePrefix;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _gstinCtrl.dispose();
    _prefixCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final ok = await widget.onSave(
      StoreGstSettings(
        businessName: _nameCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        gstin: _gstinCtrl.text.trim().toUpperCase(),
        invoicePrefix: _prefixCtrl.text.trim().toUpperCase(),
      ),
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
          Text('Printed on every invoice, GSTR-1 and GSTR-3B export — editing these takes effect immediately. '
              'Invoices are numbered <prefix>/<financial year>/0001, e.g. LTC/26-27/0001, restarting every April.',
              style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w500, color: AdminColors.muted)),
          const SizedBox(height: AdminSpace.md),
          LayoutBuilder(builder: (context, constraints) {
            final narrow = constraints.maxWidth < 640;
            final fields = [
              _field('Business name', _nameCtrl),
              _field('GSTIN', _gstinCtrl),
              _field('Address', _addressCtrl, maxLines: 2),
              _field('Invoice prefix', _prefixCtrl),
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
                const SizedBox(width: AdminSpace.sm),
                Expanded(child: fields[3]),
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


/// Admin-defined GST rates (CGST % + SGST %). Each product picks one on
/// the product form; the customer price is base price + CGST + SGST.
class _GstRatesCard extends StatelessWidget {
  const _GstRatesCard();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketAdminCubit>();
    final rates = context.select((BasketAdminCubit c) => c.state.gstRates);

    return Container(
      padding: const EdgeInsets.all(AdminSpace.card),
      decoration: adminCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: AdminSectionTitle('GST rates')),
              AdminButton(
                label: '+ Add GST rate',
                size: AdminButtonSize.small,
                onPressed: () => _showGstRateDialog(context, cubit),
              ),
            ],
          ),
          const SizedBox(height: AdminSpace.xxs),
          Text('Choose one of these on each product. Customer price = selling price + CGST + SGST.',
              style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w500, color: AdminColors.muted)),
          const SizedBox(height: AdminSpace.md),
          if (rates.isEmpty)
            Text('No GST rates yet — add one to start using it on products.',
                style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600, color: AdminColors.muted))
          else
            Wrap(
              spacing: AdminSpace.sm,
              runSpacing: AdminSpace.sm,
              children: [
                for (final r in rates)
                  Container(
                    width: 240,
                    padding: const EdgeInsets.all(AdminSpace.sm),
                    decoration: BoxDecoration(
                      color: AdminSurface.subtle,
                      border: Border.all(color: AdminSurface.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.name, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(
                          'CGST ${gstPctLabel(r.cgstPct)}% + SGST ${gstPctLabel(r.sgstPct)}% = ${gstPctLabel(r.totalPct)}%',
                          style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w600, color: AdminColors.muted),
                        ),
                        Text(
                          '${r.productCount} product${r.productCount == 1 ? '' : 's'}',
                          style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w500, color: AdminColors.muted),
                        ),
                        const SizedBox(height: AdminSpace.xs),
                        Row(
                          children: [
                            AdminButton(
                              label: 'Edit',
                              variant: AdminButtonVariant.tonal,
                              size: AdminButtonSize.small,
                              onPressed: () => _showGstRateDialog(context, cubit, rate: r),
                            ),
                            const SizedBox(width: AdminSpace.xs),
                            AdminButton(
                              label: 'Delete',
                              variant: AdminButtonVariant.danger,
                              size: AdminButtonSize.small,
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final error = await cubit.deleteGstRate(r.id);
                                messenger.showSnackBar(SnackBar(content: Text(error ?? '${r.name} deleted.')));
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

Future<void> _showGstRateDialog(BuildContext context, BasketAdminCubit cubit, {ApiGstRate? rate}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _GstRateDialog(cubit: cubit, rate: rate),
  );
}

class _GstRateDialog extends StatefulWidget {
  const _GstRateDialog({required this.cubit, this.rate});

  final BasketAdminCubit cubit;
  final ApiGstRate? rate;

  @override
  State<_GstRateDialog> createState() => _GstRateDialogState();
}

class _GstRateDialogState extends State<_GstRateDialog> {
  late final _name = TextEditingController(text: widget.rate?.name ?? '');
  late final _cgst = TextEditingController(text: widget.rate == null ? '' : gstPctLabel(widget.rate!.cgstPct));
  late final _sgst = TextEditingController(text: widget.rate == null ? '' : gstPctLabel(widget.rate!.sgstPct));
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _cgst.dispose();
    _sgst.dispose();
    super.dispose();
  }

  double? get _cgstValue => double.tryParse(_cgst.text.trim());
  double? get _sgstValue => double.tryParse(_sgst.text.trim());

  Future<void> _save() async {
    final cgst = _cgstValue;
    final sgst = _sgstValue;
    if (cgst == null || sgst == null || cgst < 0 || sgst < 0 || cgst > 50 || sgst > 50) {
      setState(() => _error = 'Enter CGST and SGST as percentages between 0 and 50.');
      return;
    }
    final name = _name.text.trim().isEmpty ? 'GST ${gstPctLabel(cgst + sgst)}%' : _name.text.trim();
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await widget.cubit.saveGstRate(id: widget.rate?.id, name: name, cgstPct: cgst, sgstPct: sgst);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _saving = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pctFormatter = [FilteringTextInputFormatter.allow(RegExp(r'^\d{0,2}(\.\d{0,2})?'))];
    final total = (_cgstValue ?? 0) + (_sgstValue ?? 0);
    return AlertDialog(
      backgroundColor: AdminSurface.card,
      title: Text(widget.rate == null ? 'Add GST rate' : 'Edit GST rate',
          style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800)),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminEditField(label: 'Name', controller: _name, hint: 'e.g. GST 5%'),
            const SizedBox(height: AdminSpace.sm),
            Row(
              children: [
                Expanded(
                  child: AdminEditField(
                    label: 'CGST %',
                    controller: _cgst,
                    hint: '2.5',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: pctFormatter,
                  ),
                ),
                const SizedBox(width: AdminSpace.sm),
                Expanded(
                  child: AdminEditField(
                    label: 'SGST %',
                    controller: _sgst,
                    hint: '2.5',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: pctFormatter,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AdminSpace.sm),
            ListenableBuilder(
              listenable: Listenable.merge([_cgst, _sgst]),
              builder: (_, _) => Text(
                'Total GST: ${gstPctLabel((_cgstValue ?? 0) + (_sgstValue ?? 0))}% · ₹100 → ₹${sellingPriceFor(100, (_cgstValue ?? 0) + (_sgstValue ?? 0))}',
                style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: AdminColors.muted),
              ),
            ),
            if (widget.rate != null && widget.rate!.productCount > 0 && total >= 0) ...[
              const SizedBox(height: AdminSpace.xs),
              Text('Changing this updates the customer price of ${widget.rate!.productCount} product(s). Past orders keep their old tax.',
                  style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w600, color: AdminColors.muted)),
            ],
            if (_error != null) ...[
              const SizedBox(height: AdminSpace.sm),
              Text(_error!, style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w600, color: AdminSurface.error)),
            ],
          ],
        ),
      ),
      actions: [
        AdminButton.secondary(label: 'Cancel', onPressed: _saving ? null : () => Navigator.of(context).pop()),
        AdminButton(label: 'Save', loading: _saving, onPressed: _saving ? null : _save),
      ],
    );
  }
}
