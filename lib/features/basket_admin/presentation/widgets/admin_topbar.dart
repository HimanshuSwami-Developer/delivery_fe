import 'package:fastswipe/features/basket_admin/cubit/basket_admin_cubit.dart';
import 'package:fastswipe/features/basket_admin/data/basket_admin_data.dart';
import 'package:fastswipe/features/basket_admin/presentation/basket_admin_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

/// Sticky header: page title/subtitle, a decorative search field, the zone
/// switcher (cycles through the real dark stores on tap), and a theme button.
class AdminTopBar extends StatelessWidget {
  const AdminTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketAdminCubit>();
    final page = context.select((BasketAdminCubit c) => c.state.page);
    final zone = context.select((BasketAdminCubit c) => c.state.zone);
    final zones = context.select((BasketAdminCubit c) => c.state.apiZones);
    final zoneLabel = zones.isNotEmpty && zone < zones.length ? zones[zone].name : 'All zones';
    final title = kAdminTitles[page]!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.62),
        border: Border(bottom: BorderSide(color: AdminColors.ink.withValues(alpha: 0.07))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title.title, style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: AdminColors.ink, letterSpacing: -0.3)),
                const SizedBox(height: 4),
                Text(title.subtitle, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w500, color: AdminColors.muted)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 260,
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AdminColors.ink.withValues(alpha: 0.1)),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              children: [
                const Text('⌕', style: TextStyle(fontSize: 12, color: AdminColors.faint)),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Search orders, SKUs, partners',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600, color: AdminColors.faint),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 9),
          InkWell(
            onTap: cubit.cycleZone,
            borderRadius: BorderRadius.circular(11),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AdminColors.ink.withValues(alpha: 0.1)),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Text('◈ $zoneLabel ▾', style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w700, color: AdminColors.ink)),
            ),
          ),
          const SizedBox(width: 9),
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AdminColors.ink, borderRadius: BorderRadius.circular(11)),
            child: const Text('◑', style: TextStyle(fontSize: 13, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
