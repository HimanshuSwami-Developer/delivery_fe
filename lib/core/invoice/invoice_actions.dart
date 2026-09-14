import 'package:fastswipe/core/basket_api/repositories/orders_repository.dart';
import 'package:fastswipe/core/files/file_download_actions.dart';
import 'package:flutter/material.dart';

/// Fetches order [orderId]'s GST invoice PDF and hands it to the OS share
/// sheet — "Open in ..." a PDF viewer, save to Files, print, or share
/// straight from there, so this one action covers both "view" and
/// "download" without the app needing its own PDF viewer. Shared by the
/// customer, delivery-partner, and admin order-detail screens — each
/// passes its own already-authenticated [OrdersRepository] (customer/
/// delivery share one; the admin console has its own).
Future<void> downloadOrderInvoice(
  BuildContext context, {
  required OrdersRepository orders,
  required int orderId,
  required String orderNumber,
}) async {
  await downloadAndShareBytes(
    context,
    fetch: () => orders.fetchInvoicePdf(orderId),
    filename: 'invoice-$orderNumber.pdf',
    mimeType: 'application/pdf',
    preparingMessage: 'Preparing invoice…',
  );
}
