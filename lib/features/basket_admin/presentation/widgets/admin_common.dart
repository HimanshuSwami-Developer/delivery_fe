import 'package:fastswipe/features/basket_admin/presentation/basket_admin_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Wraps [children] (each a naturally-sized, self-contained card — no
/// internal `Expanded`) into rows of as many columns as fit at least
/// [minTileWidth] each. Used for every KPI/stat tile row in the console
/// instead of `GridView.count` + a fixed `childAspectRatio`: a rigid aspect
/// ratio overflows the moment a sub-line wraps to an extra line at some
/// viewport width, where letting each tile size to its own content never
/// can.
class AdminResponsiveGrid extends StatelessWidget {
  const AdminResponsiveGrid({
    super.key,
    required this.children,
    this.minTileWidth = 260,
    this.spacing = 14,
    this.runSpacing = 14,
  });

  final List<Widget> children;
  final double minTileWidth;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final maxWidth = constraints.maxWidth;
      var cols = ((maxWidth + spacing) / (minTileWidth + spacing)).floor();
      if (cols < 1) cols = 1;
      if (cols > children.length) cols = children.length;
      final tileWidth = (maxWidth - spacing * (cols - 1)) / cols;
      return Wrap(
        spacing: spacing,
        runSpacing: runSpacing,
        children: [for (final c in children) SizedBox(width: tileWidth, child: c)],
      );
    });
  }
}

/// Lays out [children] with widths proportional to [flex], approximating
/// the source design's `grid-template-columns: 1.1fr 1.5fr ...` tables —
/// every data table/header row in the console is built from this.
class AdminGridRow extends StatelessWidget {
  const AdminGridRow({
    super.key,
    required this.flex,
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  final List<double> flex;
  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    assert(flex.length == children.length, 'flex/children length mismatch');
    return Row(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(flex: (flex[i] * 100).round(), child: children[i]),
        ],
      ],
    );
  }
}

TextStyle _tableHeaderStyle() => GoogleFonts.manrope(
      fontSize: 10.5,
      fontWeight: FontWeight.w700,
      color: AdminColors.faint,
      letterSpacing: 0.6,
    );

/// A table header row: uppercase, faint, bottom-bordered — matches every
/// data table's header in the source design.
class AdminTableHeader extends StatelessWidget {
  const AdminTableHeader({super.key, required this.flex, required this.labels});

  final List<double> flex;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AdminColors.ink.withValues(alpha: 0.09)))),
      child: AdminGridRow(
        flex: flex,
        children: [for (final l in labels) Text(l.toUpperCase(), style: _tableHeaderStyle())],
      ),
    );
  }
}

/// A tappable, bottom-bordered table data row.
class AdminTableRow extends StatelessWidget {
  const AdminTableRow({super.key, required this.flex, required this.children, this.onTap, this.backgroundColor, this.boundHeight = false});

  final List<double> flex;
  final List<Widget> children;
  final VoidCallback? onTap;

  /// Row tint — e.g. a light red wash for a low/out-of-stock inventory row.
  final Color? backgroundColor;

  /// When a cell holds its own tappable control (e.g. a live/pause toggle)
  /// that only wraps its own content, the rest of that cell's height — up
  /// to whatever the tallest cell in the row needs — falls through to
  /// [onTap] instead, so a tap just off the control fires the wrong action.
  /// Set true to measure the row's real (intrinsic) height and give every
  /// cell that constraint, so a cell can fill it (e.g. via
  /// `SizedBox(height: double.infinity)`) and claim its whole area. Opt-in
  /// (not the default) since `IntrinsicHeight` requires every cell to
  /// support computing intrinsic height.
  final bool boundHeight;

  @override
  Widget build(BuildContext context) {
    final grid = AdminGridRow(flex: flex, children: children);
    final row = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(bottom: BorderSide(color: AdminColors.ink.withValues(alpha: 0.06))),
      ),
      child: boundHeight ? IntrinsicHeight(child: grid) : grid,
    );
    if (onTap == null) return row;
    return InkWell(onTap: onTap, child: row);
  }
}

/// A small square bordered icon button for row-level actions (edit,
/// delete) — a fixed, proper touch target with the same border/radius
/// language as the topbar's menu button, instead of a bare unbounded icon.
class AdminIconActionButton extends StatelessWidget {
  const AdminIconActionButton({super.key, required this.icon, required this.onTap, this.color = AdminColors.faint, this.size = 32});

  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: AdminColors.ink.withValues(alpha: 0.12)),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

/// Small status/state pill badge (order status, stock state, tier,
/// partner status, live/paused) — reads its colors from [adminChipStyle].
class AdminChipBadge extends StatelessWidget {
  const AdminChipBadge(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    final s = adminChipStyle(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: s.bg, border: Border.all(color: s.border), borderRadius: BorderRadius.circular(99)),
      child: Text(label, style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w800, color: s.fg)),
    );
  }
}

/// The pill-shaped filter/tab button used for status tabs, category tabs,
/// chart ranges, and GST month/slab pickers.
class AdminPillButton extends StatelessWidget {
  const AdminPillButton({super.key, required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = adminPillStyle(selected);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
        decoration: BoxDecoration(color: s.bg, border: Border.all(color: s.border), borderRadius: BorderRadius.circular(99)),
        child: Text(label, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: s.fg)),
      ),
    );
  }
}

/// Dashboard-style stat tile with a label, a colored delta chip, a big
/// value, and a sub-line — used for the 4 KPI cards on the dashboard.
class AdminKpiCard extends StatelessWidget {
  const AdminKpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.sub,
    required this.delta,
    required this.chipBg,
    required this.chipFg,
  });

  final String label;
  final String value;
  final String sub;
  final String delta;
  final Color chipBg;
  final Color chipFg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: adminGlassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: GoogleFonts.manrope(fontSize: 10.5, fontWeight: FontWeight.w600, color: AdminColors.faint, letterSpacing: 0.6),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: chipBg, borderRadius: BorderRadius.circular(99)),
                child: Text(delta, style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w800, color: chipFg)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.manrope(fontSize: 27, fontWeight: FontWeight.w800, letterSpacing: -0.4, color: AdminColors.ink)),
          const SizedBox(height: 6),
          Text(sub, style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w500, color: AdminColors.muted)),
        ],
      ),
    );
  }
}

/// Simpler stat tile (label + big value + sub-line, no delta chip) — used
/// on Inventory/Partners/Sales/GST report pages.
class AdminStatCard extends StatelessWidget {
  const AdminStatCard({super.key, required this.label, required this.value, required this.sub});

  final String label;
  final String value;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: adminGlassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.manrope(fontSize: 10.5, fontWeight: FontWeight.w600, color: AdminColors.faint, letterSpacing: 0.6),
          ),
          const SizedBox(height: 11),
          Text(value, style: GoogleFonts.manrope(fontSize: 25, fontWeight: FontWeight.w800, letterSpacing: -0.4, color: AdminColors.ink)),
          const SizedBox(height: 5),
          Text(sub, style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w500, color: AdminColors.muted)),
        ],
      ),
    );
  }
}

/// The track/knob toggle switch used for coupon/banner/zone live-paused
/// states and per-zone SKU availability.
class AdminToggle extends StatelessWidget {
  const AdminToggle({super.key, required this.on, required this.onTap, this.width = 34, this.height = 18});

  final bool on;
  final VoidCallback onTap;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final knob = height - 4;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: width,
        height: height,
        padding: const EdgeInsets.all(2),
        alignment: on ? Alignment.centerRight : Alignment.centerLeft,
        decoration: BoxDecoration(
          color: on ? AdminColors.ink : AdminColors.ink.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Container(width: knob, height: knob, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
      ),
    );
  }
}

/// A labeled tile used for the small "Order/Redeemed/Ends"-style metric
/// groups inside coupon/zone cards.
class AdminMiniStat extends StatelessWidget {
  const AdminMiniStat({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.manrope(fontSize: 9.5, fontWeight: FontWeight.w600, color: AdminColors.faint, letterSpacing: 0.6),
        ),
        const SizedBox(height: 5),
        Text(value, style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w800, color: AdminColors.ink)),
      ],
    );
  }
}

/// A boxed key/value field used on the Add Product form.
class AdminFieldBox extends StatelessWidget {
  const AdminFieldBox({super.key, required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AdminColors.ink.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w600, color: AdminColors.faint, letterSpacing: 0.6),
          ),
          const SizedBox(height: 5),
          Text(value, style: GoogleFonts.manrope(fontSize: 13.5, fontWeight: FontWeight.w700, color: valueColor ?? AdminColors.ink)),
        ],
      ),
    );
  }
}

/// Section title used above most glass cards ("Sales · last 14 days",
/// "Recent orders", etc.).
class AdminSectionTitle extends StatelessWidget {
  const AdminSectionTitle(this.text, {super.key, this.size = 15});
  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: GoogleFonts.manrope(fontSize: size, fontWeight: FontWeight.w800, color: AdminColors.ink));
  }
}

/// The editable twin of [AdminFieldBox] — same boxed "LABEL above value"
/// shape, but a real [TextField] instead of static text. Used by every
/// add/edit form in the console (product, category, zone, partner, coupon,
/// banner) so they all share one input look.
class AdminEditField extends StatelessWidget {
  const AdminEditField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.enabled = true,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AdminColors.ink.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              label.toUpperCase(),
              style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w600, color: AdminColors.faint, letterSpacing: 0.6),
            ),
          ),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            maxLines: maxLines,
            enabled: enabled,
            style: GoogleFonts.manrope(fontSize: 13.5, fontWeight: FontWeight.w700, color: AdminColors.ink),
            decoration: InputDecoration(
              isDense: true,
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 5),
              hintText: hint,
              hintStyle: GoogleFonts.manrope(fontSize: 13.5, fontWeight: FontWeight.w700, color: AdminColors.faint),
            ),
          ),
        ],
      ),
    );
  }
}

/// A labeled dropdown in the same boxed shape as [AdminEditField], for the
/// handful of form fields that pick from a fixed/loaded set (zone,
/// vehicle, status) instead of free text.
class AdminEditDropdown<T> extends StatelessWidget {
  const AdminEditDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AdminColors.ink.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              label.toUpperCase(),
              style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w600, color: AdminColors.faint, letterSpacing: 0.6),
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isDense: true,
              isExpanded: true,
              icon: const Icon(Icons.expand_more, size: 16, color: AdminColors.faint),
              style: GoogleFonts.manrope(fontSize: 13.5, fontWeight: FontWeight.w700, color: AdminColors.ink),
              items: [for (final item in items) DropdownMenuItem(value: item, child: Text(itemLabel(item)))],
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared backdrop + centered white card shell for every add/edit form
/// dialog (category, zone, partner, coupon, banner) — the same shape as
/// `AssignPartnerModal`, factored out so each form only supplies its own
/// fields instead of re-building the backdrop/header/footer each time.
class AdminFormModal extends StatelessWidget {
  const AdminFormModal({
    super.key,
    required this.title,
    required this.subtitle,
    required this.fields,
    required this.onCancel,
    required this.onSubmit,
    required this.submitLabel,
    this.loading = false,
    this.error,
    this.maxWidth = 480,
  });

  final String title;
  final String subtitle;
  final List<Widget> fields;
  final VoidCallback onCancel;
  final VoidCallback? onSubmit;
  final String submitLabel;
  final bool loading;
  final String? error;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: loading ? null : onCancel,
            child: ColoredBox(color: AdminColors.ink.withValues(alpha: 0.42)),
          ),
        ),
        Center(
          child: ConstrainedBox(
            // Bounded height too, not just width — without this the card
            // sizes to its content unconditionally, and a form with enough
            // fields (coupon, partner) overflows the bottom of any screen
            // shorter than that content, since nothing above ever imposed
            // a real ceiling. The fields region below turns scrollable
            // once it's the thing actually running out of room.
            constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: MediaQuery.sizeOf(context).height * 0.9),
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.98),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [BoxShadow(color: AdminColors.ink.withValues(alpha: 0.3), blurRadius: 60, offset: const Offset(0, 30))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                            const SizedBox(height: 6),
                            Text(subtitle, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w500, color: AdminColors.muted)),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: loading ? null : onCancel,
                        child: const Text('✕', style: TextStyle(fontSize: 15, color: AdminColors.faint)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // `ListView(shrinkWrap: true)`, not `SingleChildScrollView`
                  // — the latter has no shrinkWrap and always greedily
                  // fills whatever height `Flexible` offers, which would
                  // stretch even a 3-field form to the modal's max height.
                  // shrinkWrap sizes to content when it fits, and still
                  // scrolls+caps at the `Flexible` bound when it doesn't
                  // (coupon, partner — the forms with enough fields to
                  // actually run past that bound on a short screen).
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      children: [for (var i = 0; i < fields.length; i++) ...[if (i > 0) const SizedBox(height: 12), fields[i]]],
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(error!, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFC0392B))),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: loading ? null : onCancel,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AdminColors.ink, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                          ),
                          child: Text('Cancel', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AdminColors.ink)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: loading ? null : onSubmit,
                          style: FilledButton.styleFrom(
                            backgroundColor: AdminColors.ink,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                          ),
                          child: loading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                                )
                              : Text(submitLabel, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
                        ),
                      ),
                    ],
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
