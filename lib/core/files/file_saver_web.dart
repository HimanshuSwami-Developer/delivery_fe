import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Web: there's no filesystem/share-sheet to hand a file to, so trigger the
/// browser's native "Save As" download instead — an object-URL `<a
/// download>` click, which every browser treats as a real file download.
/// (`path_provider`/`share_plus`'s temp-file+share-sheet flow used on
/// mobile/desktop has no web implementation, so calling it here throws and
/// is why invoice/report downloads previously failed silently on the web
/// admin console.)
Future<void> saveOrShareBytes({required List<int> bytes, required String filename, required String mimeType}) async {
  final blob = web.Blob([Uint8List.fromList(bytes).toJS].toJS, web.BlobPropertyBag(type: mimeType));
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = filename;
  anchor.click();
  web.URL.revokeObjectURL(url);
}
