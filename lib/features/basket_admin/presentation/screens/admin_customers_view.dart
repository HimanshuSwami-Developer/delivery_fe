import 'package:fastswipe/core/basket_api/models/report_models.dart';
import 'package:fastswipe/features/basket/presentation/widgets/image_slot.dart';
import 'package:fastswipe/features/basket_admin/cubit/basket_admin_cubit.dart';
import 'package:fastswipe/features/basket_admin/data/basket_admin_data.dart';
import 'package:fastswipe/features/basket_admin/presentation/basket_admin_style.dart';
import 'package:fastswipe/features/basket_admin/presentation/widgets/admin_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

const _kFlex = [1.8, 1.1, 0.9, 1.0, 1.0, 0.8];

/// Customer directory: avatar/name/mobile, order count, lifetime value,
/// last order, and a tier chip — all from the real customer report.
class AdminCustomersView extends StatelessWidget {
  const AdminCustomersView({super.key});

  @override
  Widget build(BuildContext context) {
    final customers = context.select((BasketAdminCubit c) => c.state.apiCustomers);
    final loading = context.select((BasketAdminCubit c) => c.state.customersLoading);

    if (loading && customers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 14),
        decoration: adminGlassCard(),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: 980,
            child: Column(
              children: [
                const AdminTableHeader(flex: _kFlex, labels: ['Customer', 'Phone', 'Orders', 'Lifetime value', 'Last order', 'Tier']),
                if (customers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text('No customers yet.', style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600, color: AdminColors.muted)),
                  ),
                for (final c in customers) _CustomerRow(c: c),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomerRow extends StatelessWidget {
  const _CustomerRow({required this.c});
  final AdminCustomerRow c;

  @override
  Widget build(BuildContext context) {
    return AdminTableRow(
      flex: _kFlex,
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
                  Text(c.name ?? c.mobileNumber, overflow: TextOverflow.ellipsis, style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('Customer #${c.id}', overflow: TextOverflow.ellipsis, style: GoogleFonts.manrope(fontSize: 10.5, fontWeight: FontWeight.w500, color: AdminColors.faint)),
                ],
              ),
            ),
          ],
        ),
        Text(c.mobileNumber, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: AdminColors.muted)),
        Text('${c.ordersCount}', style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w700)),
        Text(adminMoney(c.ltv), style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w800)),
        Text(c.lastOrderAt == null ? '—' : _dateLabel(c.lastOrderAt!), style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: AdminColors.muted)),
        Align(alignment: Alignment.centerLeft, child: AdminChipBadge(c.tier)),
      ],
    );
  }
}

String _dateLabel(DateTime dt) {
  final local = dt.toLocal();
  final now = DateTime.now();
  final isToday = local.year == now.year && local.month == now.month && local.day == now.day;
  if (isToday) return 'Today';
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${local.day} ${months[local.month - 1]}';
}
