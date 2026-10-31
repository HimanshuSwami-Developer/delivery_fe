import 'dart:async';

import 'package:fastswipe/app.dart';
import 'package:fastswipe/core/notifications/push_notifications.dart';
import 'package:fastswipe/features/auth/data/auth_repository.dart';
import 'package:fastswipe/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fastswipe/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // White status-bar icons from the very first frame (the root
  // `AnnotatedRegion` in app.dart keeps them white after that).
  SystemChrome.setSystemUIOverlayStyle(AppTheme.statusBarStyle);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(FastSwipeApp(authRepository: MockAuthRepository()));
  // Not awaited before `runApp` — this requests the notification-permission
  // dialog and fetches an FCM token, both of which can be slow or hang on a
  // flaky connection/Play Services hiccup. Blocking on it here meant NO UI
  // (not even the app's own splash) rendered until it resolved, which is
  // exactly what looked like "stuck on splash". Firing it after `runApp`
  // lets the real splash show immediately; the permission dialog then
  // appears on top of visible UI instead of a blank screen.
  unawaited(PushNotifications.init());
}
