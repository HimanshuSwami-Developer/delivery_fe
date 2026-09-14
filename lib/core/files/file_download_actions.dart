import 'dart:io';

import 'package:fastswipe/core/api/api_exception.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Fetches arbitrary file bytes and hands them to the OS share sheet —
/// "Open in ...", save to Files, print, or share straight from there.
/// Shared by every "download this report" button in the admin console
/// (GST invoice, GSTR-1/3B exports, sales CSV) so each one only has to
/// supply its own fetch call, filename and mime type.
Future<void> downloadAndShareBytes(
  BuildContext context, {
  required Future<List<int>> Function() fetch,
  required String filename,
  required String mimeType,
  String preparingMessage = 'Preparing file…',
}) async {
  final messenger = ScaffoldMessenger.of(context);
  messenger.showSnackBar(SnackBar(content: Text(preparingMessage), duration: const Duration(seconds: 20)));
  try {
    final bytes = await fetch();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    messenger.hideCurrentSnackBar();
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path, mimeType: mimeType)], fileNameOverrides: [filename]));
  } on ApiException catch (e) {
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text('Could not load file: ${e.message}')));
  } catch (_) {
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(const SnackBar(content: Text('Could not load file.')));
  }
}
