import 'dart:io';

import 'package:fastswipe/core/api/api_exception.dart';
import 'package:fastswipe/core/basket_api/repositories/orders_repository.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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
  final messenger = ScaffoldMessenger.of(context);
  messenger.showSnackBar(const SnackBar(content: Text('Preparing invoice…'), duration: Duration(seconds: 20)));
  try {
    final bytes = await orders.fetchInvoicePdf(orderId);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/invoice-$orderNumber.pdf');
    await file.writeAsBytes(bytes, flush: true);
    messenger.hideCurrentSnackBar();
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path, mimeType: 'application/pdf')], fileNameOverrides: ['invoice-$orderNumber.pdf']));
  } on ApiException catch (e) {
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text('Could not load invoice: ${e.message}')));
  } catch (_) {
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(const SnackBar(content: Text('Could not load invoice.')));
  }
}
