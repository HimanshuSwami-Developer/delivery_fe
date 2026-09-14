import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Mobile/desktop: write to a temp file and hand it to the OS share sheet
/// ("Open in ...", save to Files, print, or share straight from there).
Future<void> saveOrShareBytes({required List<int> bytes, required String filename, required String mimeType}) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsBytes(bytes, flush: true);
  await SharePlus.instance.share(ShareParams(files: [XFile(file.path, mimeType: mimeType)], fileNameOverrides: [filename]));
}
