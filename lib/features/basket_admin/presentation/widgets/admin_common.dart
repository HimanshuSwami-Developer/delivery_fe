import 'package:fastswipe/features/basket_admin/presentation/basket_admin_style.dart';
import 'package:flutter/material.dart';
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
  const AdminTableRow({super.key, required this.flex, required this.children, this.onTap});

  final List<double> flex;
  final List<Widget> children;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AdminColors.ink.withValues(alpha: 0.06)))),
      child: AdminGridRow(flex: flex, children: children),
    );
    if (onTap == null) return row;
    return InkWell(onTap: onTap, child: row);
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
