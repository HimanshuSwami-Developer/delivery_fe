import 'package:fastswipe/core/basket_api/models/delivery_models.dart';
import 'package:fastswipe/features/basket/presentation/widgets/image_slot.dart';
import 'package:fastswipe/features/basket_admin/cubit/basket_admin_cubit.dart';
import 'package:fastswipe/features/basket_admin/data/basket_admin_data.dart';
import 'package:fastswipe/features/basket_admin/presentation/basket_admin_style.dart';
import 'package:fastswipe/features/basket_admin/presentation/widgets/admin_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

const _kFlex = [1.8, 0.8, 0.9, 0.9, 1.0, 1.1];

/// Delivery-partner roster: 4 fleet stats + a table with a status chip and
/// an inline "Assign" action for partners who are currently available.
class AdminPartnersView extends StatelessWidget {
  const AdminPartnersView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketAdminCubit>();
    final partners = context.select((BasketAdminCubit c) => c.state.apiPartners);
    final loading = context.select((BasketAdminCubit c) => c.state.partnersLoading);

    final active = partners.where((p) => p.status != 'off_duty').length;
    final onTrip = partners.where((p) => p.status == 'on_trip').length;
    final tripsToday = partners.fold<int>(0, (a, p) => a + p.tripsToday);
    final payout = partners.fold<int>(0, (a, p) => a + p.earningsThisMonthRupees);
    final stats = [
      ('Partners active', '$active', 'of ${partners.length} registered'),
      ('On a trip now', '$onTrip', 'Currently delivering'),
      ('Trips today', '$tripsToday', 'Across the fleet'),
      ('Payout this month', adminMoney(payout), 'Settles every Monday'),
    ];

    if (loading && partners.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: AdminSectionTitle('Delivery partners')),
              FilledButton(
                onPressed: cubit.openPartnerForm,
                style: FilledButton.styleFrom(
                  backgroundColor: AdminColors.ink,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                ),
                child: Text('+ Add partner', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFFFFBF2))),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AdminResponsiveGrid(children: [for (final s in stats) AdminStatCard(label: s.$1, value: s.$2, sub: s.$3)]),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 14),
            decoration: adminGlassCard(),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 980,
                child: Column(
                  children: [
                    const AdminTableHeader(flex: _kFlex, labels: ['Partner', 'Rating', 'Trips today', 'On time', 'Earnings (mo)', 'Status']),
                    if (partners.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text('No delivery partners yet.', style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600, color: AdminColors.muted)),
                      ),
                    for (final p in partners) _PartnerRow(p: p, cubit: cubit),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PartnerRow extends StatelessWidget {
  const _PartnerRow({required this.p, required this.cubit});
  final ApiDeliveryPartner p;
  final BasketAdminCubit cubit;

  @override
  Widget build(BuildContext context) {
    final status = kPartnerStatusFromCode[p.status] ?? p.status;
    return AdminTableRow(
      flex: _kFlex,
      onTap: () => cubit.openPartnerForm(partner: p),
      children: [
        Row(
          children: [
            const SizedBox(width: 34, height: 34, child: ImageSlot(shape: ImageSlotShape.circle, mini: true)),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(p.name, overflow: TextOverflow.ellipsis, style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('${p.partnerCode} · ${p.vehicle}',
                      overflow: TextOverflow.ellipsis, style: GoogleFonts.manrope(fontSize: 10.5, fontWeight: FontWeight.w500, color: AdminColors.faint)),
                ],
              ),
            ),
          ],
        ),
        Text('★ ${p.rating.toStringAsFixed(1)}', style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w700)),
        Text('${p.tripsToday}', style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w700)),
        Text(p.onTimePct == null ? '—' : '${p.onTimePct!.round()}%', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: AdminColors.muted)),
        Text(adminMoney(p.earningsThisMonthRupees), style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w800)),
        Wrap(
          spacing: 9,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AdminChipBadge(status),
            if (p.status == 'available')
              InkWell(
                onTap: () => cubit.assignPartnerFromRow(p),
                borderRadius: BorderRadius.circular(99),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(border: Border.all(color: AdminColors.ink.withValues(alpha: 0.16)), borderRadius: BorderRadius.circular(99)),
                  child: Text('Assign', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: AdminColors.ink)),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
