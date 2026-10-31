import 'package:fastswipe/features/basket_admin/cubit/basket_admin_cubit.dart';
import 'package:fastswipe/features/basket_admin/data/basket_admin_data.dart';
import 'package:fastswipe/features/basket_admin/presentation/admin_ui.dart';
import 'package:fastswipe/features/basket_admin/presentation/basket_admin_style.dart';
import 'package:fastswipe/features/basket_admin/presentation/widgets/admin_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

const _kStatusTabs = ['All', 'New', 'Packed', 'Out for delivery', 'Delivered', 'Cancelled'];
const _kFlex = [1.0, 1.4, 1.6, 0.8, 0.9, 1.1, 0.9];

/// Order list with a status filter, a data table (order/customer/address/
/// items/value/partner/status), and decorative pagination.
class AdminOrdersView extends StatelessWidget {
  const AdminOrdersView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketAdminCubit>();
    final status = context.select((BasketAdminCubit c) => c.state.status);
    final rows = context.select((BasketAdminCubit c) => c.state.apiOrders);
    final loading = context.select((BasketAdminCubit c) => c.state.ordersLoading);

    if (loading && rows.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AdminPillTabs<String>(
                  tabs: [for (final s in _kStatusTabs) (s, s)],
                  selected: status,
                  onSelected: cubit.setStatus,
                ),
              ),
              const SizedBox(width: AdminSpace.xs),
              const AdminButton.secondary(label: '⤓ Export CSV', onPressed: null),
              const SizedBox(width: AdminSpace.xs),
              const AdminButton(label: 'Bulk assign', onPressed: null),
            ],
          ),
          const SizedBox(height: AdminSpace.section),
          Container(
            padding: const EdgeInsets.all(AdminSpace.md),
            decoration: adminCard(),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 1000,
                child: Column(
                  children: [
                    const AdminTableHeader(flex: _kFlex, labels: ['Order', 'Customer', 'Address', 'Items', 'Value', 'Partner', 'Status']),
                    for (final o in rows)
                      AdminTableRow(
                        flex: _kFlex,
                        onTap: () => cubit.openOrder(o.id.toString()),
                        children: [
                          Text(o.orderNumber, style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w800)),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(o.customerName ?? o.customerMobile ?? '—', style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 3),
                              Text(_timeOf(o.createdAt), style: GoogleFonts.manrope(fontSize: 10.5, fontWeight: FontWeight.w500, color: AdminColors.faint)),
                            ],
                          ),
                          Text(o.address, style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w500, height: 1.45, color: AdminColors.muted)),
                          Text('${o.itemCount}', style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600, color: AdminColors.muted)),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(adminMoney(o.total), style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 3),
                              Text(o.paymentMode.toUpperCase(), style: GoogleFonts.manrope(fontSize: 10.5, fontWeight: FontWeight.w500, color: AdminColors.faint)),
                            ],
                          ),
                          Text(o.deliveryPartnerName ?? '—', style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600, color: AdminColors.muted)),
                          Align(alignment: Alignment.centerLeft, child: AdminChipBadge(kOrderStatusFromCode[o.status] ?? o.status)),
                        ],
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AdminSpace.sm, AdminSpace.md, AdminSpace.sm, 0),
                      child: Text('Showing ${rows.length} order${rows.length == 1 ? '' : 's'}',
                          style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w500, color: AdminColors.faint)),
                    ),
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

String _timeOf(DateTime dt) {
  final local = dt.toLocal();
  final hh = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final mm = local.minute.toString().padLeft(2, '0');
  final ap = local.hour >= 12 ? 'PM' : 'AM';
  return '$hh:$mm $ap';
}
