import 'package:fastswipe/core/basket_api/models/order_models.dart';
import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:fastswipe/features/basket/presentation/widgets/glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

/// The "Deliveries" tab — only shown for role='delivery_boy' accounts (see
/// `BasketBottomNav`). Lists orders assigned to this delivery partner
/// (`GET /api/orders/` is scoped server-side by `OrderViewSet.get_queryset`,
/// same call the customer app's own Orders screen makes — the backend is
/// what makes this "just work" with no separate endpoint).
class DeliveryBoyView extends StatelessWidget {
  const DeliveryBoyView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketCubit>();
    final loading = context.select((BasketCubit c) => c.state.ordersLoading);
    final orders = context.select((BasketCubit c) => c.state.apiOrders);
    final active = orders.where((o) => o.status == 'packed' || o.status == 'out_for_delivery').toList();
    final done = orders.where((o) => o.status == 'delivered' || o.status == 'cancelled').toList();

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(18, MediaQuery.paddingOf(context).top + 12, 18, 20),
          decoration: darkHeaderDecoration(),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('My deliveries', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFFFFFBF2))),
                    const SizedBox(height: 4),
                    Text(
                      active.isEmpty ? 'Nothing assigned right now' : '${active.length} active · ${done.length} completed',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w500, color: Color(0xFFFFFBF2).withValues(alpha: 0.55)),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: cubit.loadOrders,
                borderRadius: BorderRadius.circular(99),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: Color(0xFFFFFBF2).withValues(alpha: 0.14), shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: const Icon(Icons.refresh_rounded, color: Color(0xFFFFFBF2), size: 18),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: loading && orders.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : orders.isEmpty
                  ? Center(
                      child: Text(
                        'No deliveries assigned yet.',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: BasketColors.muted),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: cubit.loadOrders,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
                        children: [
                          if (active.isNotEmpty) ...[
                            _SectionLabel('Active'),
                            const SizedBox(height: 8),
                            for (final o in active)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _DeliveryCard(order: o, onTap: () => cubit.openDeliveryDetail(o.id.toString())),
                              ),
                            const SizedBox(height: 8),
                          ],
                          if (done.isNotEmpty) ...[
                            _SectionLabel('Completed'),
                            const SizedBox(height: 8),
                            for (final o in done)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _DeliveryCard(order: o, onTap: () => cubit.openDeliveryDetail(o.id.toString())),
                              ),
                          ],
                        ],
                      ),
                    ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: BasketColors.faint, letterSpacing: 0.6),
    );
  }
}

const _statusLabels = {
  'new': 'New',
  'packed': 'Ready for pickup',
  'out_for_delivery': 'On the way',
  'delivered': 'Delivered',
  'cancelled': 'Cancelled',
};

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({required this.order, required this.onTap});

  final ApiOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final done = order.status == 'delivered' || order.status == 'cancelled';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: glassCard(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(order.orderNumber, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w800)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: done ? BasketColors.divider : BasketColors.primary,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    _statusLabels[order.status] ?? order.status,
                    style: GoogleFonts.plusJakartaSans(fontSize: 9.5, fontWeight: FontWeight.w700, color: done ? BasketColors.muted : BasketColors.onPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(order.customerName?.isNotEmpty == true ? order.customerName! : (order.customerMobile ?? 'Customer'),
                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            Text(
              order.address,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w500, color: BasketColors.muted),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${order.itemCount} ${order.itemCount == 1 ? 'item' : 'items'} · ₹${order.total}',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: BasketColors.muted)),
                Text('View ›', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: BasketColors.primary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
