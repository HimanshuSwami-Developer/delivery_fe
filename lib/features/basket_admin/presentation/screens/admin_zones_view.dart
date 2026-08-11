import 'package:fastswipe/core/basket_api/models/zone_models.dart';
import 'package:fastswipe/features/basket_admin/cubit/basket_admin_cubit.dart';
import 'package:fastswipe/features/basket_admin/presentation/basket_admin_style.dart';
import 'package:fastswipe/features/basket_admin/presentation/widgets/admin_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

/// Multi-location settings: dark-store cards with a real open/closed
/// toggle, 4 operational stats, and served pincodes.
class AdminZonesView extends StatelessWidget {
  const AdminZonesView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketAdminCubit>();
    final zones = context.select((BasketAdminCubit c) => c.state.apiZones);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: AdminSectionTitle('Dark stores & delivery zones')),
              FilledButton(
                onPressed: cubit.openAddZone,
                style: FilledButton.styleFrom(
                  backgroundColor: AdminColors.ink,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                ),
                child: Text('+ Add location', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (zones.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Text('No zones configured yet.', style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600, color: AdminColors.muted)),
            ),
          LayoutBuilder(builder: (context, constraints) {
            final cols = constraints.maxWidth < 760 ? 1 : 2;
            return GridView.count(
              crossAxisCount: cols,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.5,
              children: [
                for (final z in zones) _ZoneCard(zone: z, onToggle: () => cubit.toggleZoneStore(z.id, !z.isOpen)),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _ZoneCard extends StatelessWidget {
  const _ZoneCard({required this.zone, required this.onToggle});

  final ApiZone zone;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final on = zone.isOpen;
    return Container(
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
                    Text(zone.name, style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(zone.address, style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w500, height: 1.55, color: AdminColors.muted)),
                  ],
                ),
              ),
              InkWell(
                onTap: onToggle,
                child: Row(
                  children: [
                    AdminToggle(on: on, onTap: onToggle),
                    const SizedBox(width: 8),
                    Text(on ? 'Open' : 'Closed',
                        style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w700, color: on ? AdminColors.ink : AdminColors.faint)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: AdminMiniStat(label: 'Orders/day', value: '${zone.ordersToday}')),
              Expanded(child: AdminMiniStat(label: 'Avg ETA', value: '${zone.avgEtaMinutes} min')),
              Expanded(child: AdminMiniStat(label: 'Riders', value: '${zone.ridersCount}')),
              Expanded(child: AdminMiniStat(label: 'Fill rate', value: zone.fillRatePct == null ? '—' : '${zone.fillRatePct!.toStringAsFixed(1)}%')),
            ],
          ),
          const SizedBox(height: 15),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final p in zone.pincodes)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                  decoration: BoxDecoration(border: Border.all(color: AdminColors.ink.withValues(alpha: 0.12)), borderRadius: BorderRadius.circular(99)),
                  child: Text(p, style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              if (zone.pincodes.isEmpty)
                Text('No pincodes mapped', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w500, color: AdminColors.faint)),
            ],
          ),
        ],
      ),
    );
  }
}
