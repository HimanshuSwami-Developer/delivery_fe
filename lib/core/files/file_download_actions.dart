import 'package:fastswipe/core/api/api_exception.dart';
import 'package:fastswipe/core/files/file_saver.dart';
import 'package:flutter/material.dart';

/// Fetches arbitrary file bytes and hands them to the user — the OS share
/// sheet on mobile/desktop, a browser download on web (see `file_saver.dart`
/// for why these need to differ). Shared by every "download this report"
/// button in the admin console (GST invoice, GSTR-1/3B exports, sales CSV)
/// so each one only has to supply its own fetch call, filename and mime
/// type.
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
    await saveOrShareBytes(bytes: bytes, filename: filename, mimeType: mimeType);
    messenger.hideCurrentSnackBar();
  } on ApiException catch (e) {
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text('Could not load file: ${e.message}')));
  } catch (_) {
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(const SnackBar(content: Text('Could not load file.')));
  }
}
