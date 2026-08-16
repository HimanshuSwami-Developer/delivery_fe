import 'package:fastswipe/app.dart';
import 'package:fastswipe/core/notifications/push_notifications.dart';
import 'package:fastswipe/features/auth/data/auth_repository.dart';
import 'package:fastswipe/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await PushNotifications.init();
  runApp(FastSwipeApp(authRepository: MockAuthRepository()));
}
