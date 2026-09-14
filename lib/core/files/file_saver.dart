// Platform-specific "hand these bytes to the user as a file" step —
// mobile/desktop gets the OS share sheet, web gets a browser download.
// See `file_saver_io.dart` / `file_saver_web.dart`.
export 'file_saver_io.dart' if (dart.library.html) 'file_saver_web.dart';
