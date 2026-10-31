import 'package:fastswipe/core/basket_api/models/catalog_models.dart';
import 'package:fastswipe/core/basket_api/models/order_models.dart';
import 'package:fastswipe/core/invoice/invoice_actions.dart';
import 'package:fastswipe/features/basket/presentation/widgets/image_slot.dart';
import 'package:fastswipe/features/basket_admin/cubit/basket_admin_cubit.dart';
import 'package:fastswipe/features/basket_admin/data/basket_admin_data.dart';
import 'package:fastswipe/features/basket_admin/presentation/admin_ui.dart';
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
          AdminButton(
            label: '← All orders',
            variant: AdminButtonVariant.text,
            size: AdminButtonSize.small,
            onPressed: cubit.goOrders,
          ),
          const SizedBox(height: AdminSpace.sm),
          LayoutBuilder(builder: (context, constraints) {
            final narrow = constraints.maxWidth < 900;

            final left = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(AdminSpace.card),
                  decoration: adminCard(),
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
                                const SizedBox(height: AdminSpace.xxs),
                                Text('${_timeOf(order.createdAt)} · ${order.paymentMode.toUpperCase()}',
                                    style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w500, color: AdminColors.muted)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AdminSpace.sm, vertical: AdminSpace.xxs),
                            decoration: BoxDecoration(color: AdminColors.ink, borderRadius: BorderRadius.circular(AdminRadius.pill)),
                            child: Text(orderStatus, style: GoogleFonts.manrope(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFFFFFBF2))),
                          ),
                        ],
                      ),
                      const SizedBox(height: AdminSpace.lg),
                      Row(
                        children: [
                          for (var i = 0; i < steps.length; i++) ...[
                            if (i > 0) const SizedBox(width: AdminSpace.xxs),
                            Expanded(child: _StepTile(index: i, label: steps[i], order: order, cancelled: cancelled, stageIdx: stageIdx)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AdminSpace.section),
                Container(
                  padding: const EdgeInsets.all(AdminSpace.card),
                  decoration: adminCard(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AdminSectionTitle('Items'),
                      const SizedBox(height: AdminSpace.sm),
                      const AdminTableHeader(flex: [2.4, 0.6, 0.9, 0.9], labels: ['Product', 'Qty', 'Price', 'Amount']),
                      for (final line in order.items)
                        AdminTableRow(
                          flex: const [2.4, 0.6, 0.9, 0.9],
                          children: [
                            Row(
                              children: [
                                const SizedBox(
                                  width: 36,
                                  height: 36,
                                  child: ImageSlot(shape: ImageSlotShape.rounded, radius: AdminRadius.sm, mini: true),
                                ),
                                const SizedBox(width: AdminSpace.sm),
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
                                      const SizedBox(height: 2),
                                      Text(
                                        line.unitPrice == null
                                            ? 'Taxable ${adminMoneyPaise(line.amount)} · GST ${line.gstSlab}%'
                                            : 'Taxable ${adminMoneyPaise(line.amount)} · CGST ${gstPctLabel(line.cgstPct)}% ${adminMoneyPaise(line.cgst)} · SGST ${gstPctLabel(line.sgstPct)}% ${adminMoneyPaise(line.sgst)}',
                                        style: GoogleFonts.manrope(fontSize: 10.5, fontWeight: FontWeight.w500, color: AdminColors.muted),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Text('×${line.qty}', style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600)),
                            Text(adminMoney(line.unitPrice ?? line.rate), style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600, color: AdminColors.muted)),
                            Text(adminMoney(line.lineTotal), style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(top: AdminSpace.md),
                          child: SizedBox(
                            width: 280,
                            child: Column(
                              children: [
                                _SummaryLine('Item selling amount', adminMoneyPaise(_taxableValue(order))),
                                const SizedBox(height: AdminSpace.xs),
                                _SummaryLine('CGST', adminMoneyPaise(order.cgst)),
                                const SizedBox(height: AdminSpace.xs),
                                _SummaryLine('SGST', adminMoneyPaise(order.sgst)),
                                const SizedBox(height: AdminSpace.xs),
                                _SummaryLine('Delivery', adminMoney(order.deliveryFee)),
                                if (order.discount > 0) ...[
                                  const SizedBox(height: AdminSpace.xs),
                                  _SummaryLine('Discount${order.couponCode != null ? ' (${order.couponCode})' : ''}', '− ${adminMoney(order.discount)}'),
                                ],
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: AdminSpace.sm),
                                  child: const Divider(height: 1, color: AdminSurface.border),
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
                  padding: const EdgeInsets.all(AdminSpace.card),
                  decoration: adminDarkCard(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Delivery partner', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFFFFFBF2))),
                      if (assign != null) ...[
                        const SizedBox(height: AdminSpace.md),
                        Row(
                          children: [
                            const SizedBox(width: 42, height: 42, child: ImageSlot(shape: ImageSlotShape.circle, mini: true)),
                            const SizedBox(width: AdminSpace.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(assign.name, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFFFFBF2))),
                                  const SizedBox(height: 3),
                                  Text('${assign.partnerCode} · ${assign.vehicle} · ★ ${assign.rating}',
                                      style: GoogleFonts.manrope(fontSize: 10.5, fontWeight: FontWeight.w500, color: Color(0xFFFFFBF2).withValues(alpha: 0.5))),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AdminSpace.md),
                        // Secondary (white fill) on this dark ink card — a
                        // primary ink button would vanish against it.
                        AdminButton.secondary(label: 'Reassign partner', expand: true, onPressed: cubit.openAssign),
                      ] else ...[
                        const SizedBox(height: AdminSpace.xs),
                        Text('No partner assigned yet.',
                            style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w500, height: 1.6, color: Color(0xFFFFFBF2).withValues(alpha: 0.5))),
                        const SizedBox(height: AdminSpace.md),
                        AdminButton.secondary(label: 'Assign partner', expand: true, onPressed: cubit.openAssign),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AdminSpace.section),
                Container(
                  padding: const EdgeInsets.all(AdminSpace.card),
                  decoration: adminCard(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Update status', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800)),
                      const SizedBox(height: AdminSpace.sm),
                      for (final s in [..._kStatusFlow, 'Cancelled'])
                        Padding(
                          padding: const EdgeInsets.only(bottom: AdminSpace.xs),
                          child: InkWell(
                            onTap: () => cubit.setOrderStatus(s),
                            borderRadius: BorderRadius.circular(AdminRadius.md),
                            child: Container(
                              padding: const EdgeInsets.all(AdminSpace.sm),
                              decoration: adminCard(selected: orderStatus == s),
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
                                  const SizedBox(width: AdminSpace.sm),
                                  Text(s, style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AdminSpace.section),
                Container(
                  padding: const EdgeInsets.all(AdminSpace.card),
                  decoration: adminCard(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Customer', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800)),
                      const SizedBox(height: AdminSpace.sm),
                      Text(order.customerName ?? order.customerMobile ?? '—', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700)),
                      const SizedBox(height: AdminSpace.xxs),
                      Text(order.address, style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w500, height: 1.6, color: AdminColors.muted)),
                      const SizedBox(height: AdminSpace.xs),
                      Text(
                        'GSTIN: ${(order.gstin ?? '').isEmpty ? '—  (B2C supply)' : order.gstin}',
                        style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w500, color: AdminColors.muted),
                      ),
                      const SizedBox(height: AdminSpace.md),
                      Row(
                        children: [
                          if (!cancelled)
                            Expanded(
                              child: AdminButton(
                                label: 'GST invoice ↓',
                                expand: true,
                                onPressed: () => downloadOrderInvoice(context, orders: cubit.api.orders, orderId: order.id, orderNumber: order.orderNumber),
                              ),
                            ),
                          if (!cancelled) const SizedBox(width: AdminSpace.xs),
                          Expanded(
                            child: AdminButton.secondary(label: cancelled ? 'Refund issued ✓' : 'Refund', expand: true, onPressed: null),
                          ),
                        ],
                      ),
                      if (!cancelled) ...[
                        const SizedBox(height: AdminSpace.xs),
                        AdminButton.secondary(
                          label: 'Printable receipt (POS) ↓',
                          icon: Icons.print_outlined,
                          expand: true,
                          onPressed: () => downloadOrderReceipt(context, orders: cubit.api.orders, orderId: order.id, orderNumber: order.orderNumber),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );

            if (narrow) {
              return Column(children: [left, const SizedBox(height: AdminSpace.section), right]);
            }
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 170, child: left),
                  const SizedBox(width: AdminSpace.section),
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
    final dotColor = reached ? AdminColors.ink : Color(0xFFFFFBF2);
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
          const SizedBox(height: AdminSpace.xs),
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


/// Pre-GST value of the items. Stored on new orders; summed from the lines
/// for orders placed before GST-inclusive pricing.
double _taxableValue(ApiOrder order) {
  if (order.taxableValue > 0) return order.taxableValue;
  return order.items.fold(0.0, (sum, i) => sum + i.amount);
}
