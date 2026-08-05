import 'package:fastswipe/core/basket_api/models/order_models.dart';
import 'package:fastswipe/features/basket/presentation/widgets/image_slot.dart';
import 'package:fastswipe/features/basket_admin/cubit/basket_admin_cubit.dart';
import 'package:fastswipe/features/basket_admin/data/basket_admin_data.dart';
import 'package:fastswipe/features/basket_admin/presentation/basket_admin_style.dart';
import 'package:fastswipe/features/basket_admin/presentation/widgets/admin_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

const _kStatusFlow = ['New', 'Packed', 'Out for delivery', 'Delivered'];

/// Order detail: status timeline + line items + GST breakup on the left,
/// delivery-partner / status / customer panels on the right. Ported from
/// the source design's `pgOrderDet` block.
class AdminOrderDetailView extends StatelessWidget {
  const AdminOrderDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketAdminCubit>();
    final orderStatus = context.select((BasketAdminCubit c) => c.state.orderStatus);
    final assign = context.select((BasketAdminCubit c) => c.state.assign);
    final order = context.select((BasketAdminCubit c) => c.state.currentOrder);

    if (order == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final cancelled = orderStatus == 'Cancelled';
    final stageIdx = cancelled ? -1 : _kStatusFlow.indexOf(orderStatus).clamp(0, _kStatusFlow.length - 1);
    final steps = cancelled ? const ['New', 'Cancelled'] : _kStatusFlow;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton(
            onPressed: cubit.goOrders,
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            child: Text('← All orders', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: AdminColors.muted)),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(builder: (context, constraints) {
            final narrow = constraints.maxWidth < 900;

            final left = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
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
                                Text(order.orderNumber, style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                                const SizedBox(height: 6),
                                Text('${_timeOf(order.createdAt)} · ${order.paymentMode.toUpperCase()} · ${order.zoneName ?? '—'}',
                                    style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w500, color: AdminColors.muted)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: AdminColors.ink, borderRadius: BorderRadius.circular(99)),
                            child: Text(orderStatus, style: GoogleFonts.manrope(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          for (var i = 0; i < steps.length; i++) ...[
                            if (i > 0) const SizedBox(width: 4),
                            Expanded(child: _StepTile(index: i, label: steps[i], order: order, cancelled: cancelled, stageIdx: stageIdx)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: adminGlassCard(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AdminSectionTitle('Items'),
                      const SizedBox(height: 8),
                      const AdminTableHeader(flex: [2.4, 0.7, 0.8, 0.8], labels: ['Product', 'Qty', 'Rate', 'Amount']),
                      for (final line in order.items)
                        AdminTableRow(
                          flex: const [2.4, 0.7, 0.8, 0.8],
                          children: [
                            Row(
                              children: [
                                const SizedBox(
                                  width: 36,
                                  height: 36,
                                  child: ImageSlot(shape: ImageSlotShape.rounded, radius: 9, mini: true),
                                ),
                                const SizedBox(width: 11),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(line.productName,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 2),
                                      Text(line.pack, style: GoogleFonts.manrope(fontSize: 10.5, fontWeight: FontWeight.w500, color: AdminColors.faint)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Text('×${line.qty}', style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600)),
                            Text(adminMoney(line.rate), style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600, color: AdminColors.muted)),
                            Text(adminMoney(line.amount), style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: SizedBox(
                            width: 280,
                            child: Column(
                              children: [
                                _SummaryLine('Taxable value', adminMoney(order.subtotal)),
                                const SizedBox(height: 8),
                                _SummaryLine('CGST', adminMoney(order.cgst)),
                                const SizedBox(height: 8),
                                _SummaryLine('SGST', adminMoney(order.sgst)),
                                const SizedBox(height: 8),
                                _SummaryLine('Delivery', adminMoney(order.deliveryFee)),
                                if (order.discount > 0) ...[
                                  const SizedBox(height: 8),
                                  _SummaryLine('Discount${order.couponCode != null ? ' (${order.couponCode})' : ''}', '− ${adminMoney(order.discount)}'),
                                ],
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 11),
                                  child: Divider(height: 1, color: AdminColors.ink.withValues(alpha: 0.1)),
                                ),
                                _SummaryLine('Order total', adminMoney(order.total), bold: true),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );

            final right = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: adminDarkCard(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Delivery partner', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                      if (assign != null) ...[
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const SizedBox(width: 42, height: 42, child: ImageSlot(shape: ImageSlotShape.circle, mini: true)),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(assign.name, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                                  const SizedBox(height: 3),
                                  Text('${assign.partnerCode} · ${assign.vehicle} · ★ ${assign.rating}',
                                      style: GoogleFonts.manrope(fontSize: 10.5, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.5))),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: cubit.openAssign,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.35), width: 1.4),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text('Reassign partner', style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white)),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 10),
                        Text('No partner assigned yet.',
                            style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w500, height: 1.6, color: Colors.white.withValues(alpha: 0.5))),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: cubit.openAssign,
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text('Assign partner', style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w800, color: AdminColors.ink)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: adminGlassCard(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Update status', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 13),
                      for (final s in [..._kStatusFlow, 'Cancelled'])
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            onTap: () => cubit.setOrderStatus(s),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                              decoration: BoxDecoration(
                                color: orderStatus == s ? AdminColors.ink.withValues(alpha: 0.05) : Colors.white,
                                border: Border.all(color: orderStatus == s ? AdminColors.ink : AdminColors.ink.withValues(alpha: 0.12), width: 1.4),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 15,
                                    height: 15,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: orderStatus == s ? AdminColors.ink : Colors.transparent,
                                      border: Border.all(color: AdminColors.ink, width: 1.5),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(s, style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: adminGlassCard(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Customer', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 11),
                      Text(order.customerName ?? order.customerMobile ?? '—', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text(order.address, style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w500, height: 1.6, color: AdminColors.muted)),
                      const SizedBox(height: 8),
                      Text(
                        'GSTIN: ${(order.gstin ?? '').isEmpty ? '—  (B2C supply)' : order.gstin}',
                        style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w500, color: AdminColors.muted),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          if (!cancelled)
                            Expanded(
                              child: FilledButton(
                                onPressed: null,
                                style: FilledButton.styleFrom(
                                  backgroundColor: AdminColors.ink,
                                  disabledBackgroundColor: AdminColors.ink,
                                  padding: const EdgeInsets.symmetric(vertical: 11),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                                ),
                                child: Text('GST invoice ↓', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                              ),
                            ),
                          if (!cancelled) const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: null,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AdminColors.ink, width: 1.4),
                                disabledForegroundColor: AdminColors.ink,
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                              ),
                              child: Text(cancelled ? 'Refund issued ✓' : 'Refund', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: AdminColors.ink)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );

            if (narrow) {
              return Column(children: [left, const SizedBox(height: 14), right]);
            }
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 170, child: left),
                  const SizedBox(width: 14),
                  Expanded(flex: 100, child: right),
                ],
              ),
            );
          }),
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

class _StepTile extends StatelessWidget {
  const _StepTile({required this.index, required this.label, required this.order, required this.cancelled, required this.stageIdx});

  final int index;
  final String label;
  final ApiOrder order;
  final bool cancelled;
  final int stageIdx;

  DateTime? get _stageTime => switch (index) {
        0 => order.createdAt,
        1 => order.packedAt,
        2 => order.outForDeliveryAt,
        3 => order.deliveredAt,
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final reached = cancelled || index <= stageIdx;
    final stageTime = cancelled ? (index == 0 ? order.createdAt : order.cancelledAt) : _stageTime;
    final time = reached && stageTime != null ? _timeOf(stageTime) : '—';
    final dotColor = reached ? AdminColors.ink : Colors.white;
    final lineColor = cancelled
        ? (index == 0 ? AdminColors.ink : AdminColors.ink.withValues(alpha: 0.14))
        : (index < stageIdx ? AdminColors.ink : AdminColors.ink.withValues(alpha: 0.14));
    final opacity = reached ? 1.0 : 0.42;

    return Opacity(
      opacity: opacity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor, border: Border.all(color: AdminColors.ink, width: 2)),
              ),
              Expanded(child: Container(height: 2, color: lineColor)),
            ],
          ),
          const SizedBox(height: 9),
          Text(label, style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(time, style: GoogleFonts.manrope(fontSize: 10.5, fontWeight: FontWeight.w500, color: AdminColors.faint)),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine(this.label, this.value, {this.bold = false});
  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w800)
        : GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF4A4A52));
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: style), Text(value, style: style)]);
  }
}
