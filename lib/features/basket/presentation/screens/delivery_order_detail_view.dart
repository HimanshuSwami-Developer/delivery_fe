import 'package:fastswipe/core/invoice/invoice_actions.dart';
import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:fastswipe/features/basket/presentation/basket_ui.dart';
import 'package:fastswipe/features/basket/presentation/widgets/glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// One assigned delivery: the customer's drop-pin on a real map, their
/// contact details, and the "advance status" action — reached by tapping a
/// card on [DeliveryBoyView].
///
/// The map is a plain Google Maps *embed* page loaded in a [WebView]
/// (`maps.google.com/maps?q=...&output=embed`) rather than the native Maps
/// SDK — it needs no API key/billing at all, unlike the SDK route the
/// customer-facing order-tracking map hit earlier in this project.
class DeliveryOrderDetailView extends StatelessWidget {
  const DeliveryOrderDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketCubit>();
    final order = context.select((BasketCubit c) => c.state.currentOrder);
    final actionLoading = context.select((BasketCubit c) => c.state.deliveryActionLoading);
    final actionError = context.select((BasketCubit c) => c.state.deliveryActionError);

    if (order == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final hasLocation = order.latitude != null && order.longitude != null;
    final done = order.status == 'delivered' || order.status == 'cancelled';

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(BasketSpace.gutter, MediaQuery.paddingOf(context).top + BasketSpace.sm, BasketSpace.gutter, BasketSpace.md),
          decoration: darkHeaderDecoration(),
          child: Row(
            children: [
              InkWell(
                onTap: cubit.back,
                borderRadius: BorderRadius.circular(BasketRadius.pill),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Color(0xFFFFFBF2).withValues(alpha: 0.1),
                    border: Border.all(color: Color(0xFFFFFBF2).withValues(alpha: 0.14)),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.arrow_back, color: Color(0xFFFFFBF2), size: 16),
                ),
              ),
              const SizedBox(width: BasketSpace.xs),
              Text(order.orderNumber, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFFFFBF2))),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(BasketSpace.gutter, BasketSpace.md, BasketSpace.gutter, BasketSpace.lg),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(BasketRadius.lg),
                child: SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: hasLocation
                      ? _MapPreview(
                          key: ValueKey('${order.latitude},${order.longitude}'),
                          latitude: order.latitude!,
                          longitude: order.longitude!,
                        )
                      : Container(
                          color: BasketColors.divider,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'Exact location not available for this order — use the address below.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: BasketColors.muted),
                          ),
                        ),
                ),
              ),
              if (hasLocation) ...[
                const SizedBox(height: 8),
                BasketButton.secondary(
                  icon: Icons.map_outlined,
                  label: 'Open in Google Maps',
                  size: BasketButtonSize.medium,
                  onPressed: () => launchUrl(
                    Uri.parse('https://www.google.com/maps/search/?api=1&query=${order.latitude},${order.longitude}'),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ],
              const SizedBox(height: BasketSpace.section),
              Container(
                padding: const EdgeInsets.all(BasketSpace.md),
                decoration: basketCard(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Customer', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800)),
                    const SizedBox(height: BasketSpace.sm),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.customerName?.isNotEmpty == true ? order.customerName! : 'Customer',
                                style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                order.customerMobile ?? '—',
                                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500, color: BasketColors.muted),
                              ),
                            ],
                          ),
                        ),
                        if (order.customerMobile != null)
                          InkWell(
                            onTap: () => launchUrl(Uri(scheme: 'tel', path: order.customerMobile)),
                            borderRadius: BorderRadius.circular(BasketRadius.pill),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: const BoxDecoration(color: BasketColors.ink, shape: BoxShape.circle),
                              alignment: Alignment.center,
                              child: const Icon(Icons.call_outlined, color: Color(0xFFFFFBF2), size: 16),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_outlined, size: 16, color: BasketColors.muted),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            [order.addressLine1, order.addressLine2, order.city, order.state, order.pincode]
                                .where((p) => p != null && p.isNotEmpty)
                                .join(', '),
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500, height: 1.5, color: BasketColors.muted),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: BasketSpace.section),
              Container(
                padding: const EdgeInsets.all(BasketSpace.md),
                decoration: basketCard(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800)),
                    const SizedBox(height: BasketSpace.sm),
                    _SummaryRow('Items', '${order.itemCount}'),
                    const SizedBox(height: BasketSpace.xs),
                    _SummaryRow('Payment', '${order.paymentMode.toUpperCase()} · ${order.paymentStatus}'),
                    const SizedBox(height: BasketSpace.xs),
                    _SummaryRow('Total', '₹${order.total}'),
                  ],
                ),
              ),
              if (order.status != 'cancelled') ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: BasketButton.secondary(
                        icon: Icons.receipt_long_outlined,
                        label: 'GST invoice',
                        size: BasketButtonSize.medium,
                        onPressed: () => downloadOrderInvoice(context, orders: cubit.api.orders, orderId: order.id, orderNumber: order.orderNumber),
                      ),
                    ),
                    const SizedBox(width: BasketSpace.xs),
                    Expanded(
                      child: BasketButton.secondary(
                        icon: Icons.print_outlined,
                        label: 'Print receipt',
                        size: BasketButtonSize.medium,
                        onPressed: () => downloadOrderReceipt(context, orders: cubit.api.orders, orderId: order.id, orderNumber: order.orderNumber),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: BasketSpace.xl),
              if (done)
                Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(color: BasketColors.divider, borderRadius: BorderRadius.circular(BasketRadius.md)),
                  alignment: Alignment.center,
                  child: Text(
                    order.status == 'delivered' ? 'Delivered ✓' : 'Cancelled',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: BasketColors.muted),
                  ),
                )
              else
                BasketButton(
                  label: order.status == 'packed' ? 'Start delivery' : 'Mark delivered',
                  onPressed: () => cubit.updateDeliveryStatus(order.status == 'packed' ? 'out_for_delivery' : 'delivered'),
                  loading: actionLoading,
                ),
              if (actionError != null) ...[
                const SizedBox(height: BasketSpace.xs),
                Text(actionError, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: BasketColors.error)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500, color: BasketColors.muted)),
        Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

/// Holds the [WebViewController] so it's created once per order (keyed by
/// lat/lng on the parent) instead of on every rebuild — e.g. when the
/// status-update button's loading spinner toggles.
class _MapPreview extends StatefulWidget {
  const _MapPreview({super.key, required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  @override
  State<_MapPreview> createState() => _MapPreviewState();
}

class _MapPreviewState extends State<_MapPreview> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    final mapUrl = 'https://maps.google.com/maps?q=${widget.latitude},${widget.longitude}&z=16&output=embed';
    // Google's embed endpoint now refuses to render ("must be used in an
    // iframe") when loaded directly as the WebView's top-level document —
    // it has to actually sit inside an <iframe> element.
    final html = '''
<!DOCTYPE html>
<html><head><meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>html,body,iframe{margin:0;padding:0;width:100%;height:100%;border:0;}</style>
</head><body><iframe src="$mapUrl" allowfullscreen></iframe></body></html>
''';
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString(html, baseUrl: 'https://maps.google.com');
  }

  @override
  Widget build(BuildContext context) => WebViewWidget(controller: _controller);
}
