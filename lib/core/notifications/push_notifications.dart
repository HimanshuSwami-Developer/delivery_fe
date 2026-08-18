import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Web Push needs a VAPID key (Project settings → Cloud Messaging → Web
/// configuration → "Web Push certificates" → generate/copy the key pair in
/// the Firebase console — the CLI has no way to create this). Token
/// retrieval on web is skipped until this is filled in; Android/iOS don't
/// need it.
const _webVapidKey = String.fromEnvironment('FCM_VAPID_KEY');

/// Must be a top-level (or static) function, and re-registered via
/// `@pragma('vm:entry-point')` so the engine can find it when the app is
/// launched fresh in the background just to handle a push.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No app UI is guaranteed to be running here — FCM/the OS already shows
  // the system notification for a `notification`-payload message on
  // Android/iOS, so there's nothing else required for the common case.
  debugPrint('[push] background message: ${message.messageId}');
}

/// Requests permission, registers the background handler, shows a local
/// (heads-up) notification for messages that arrive while the app is in the
/// foreground — platforms only display push notifications automatically
/// when backgrounded — and logs the device's FCM token.
class PushNotifications {
  PushNotifications._();

  static final _local = FlutterLocalNotificationsPlugin();

  static const _androidChannel = AndroidNotificationChannel(
    'high_importance_channel',
    'Important notifications',
    description: 'Order updates and other important alerts.',
    importance: Importance.high,
  );

  static Future<void> init() async {
    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(alert: true, badge: true, sound: true);

    if (!kIsWeb) {
      await _local
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_androidChannel);

      await _local.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/launcher_icon'),
          iOS: DarwinInitializationSettings(),
        ),
        onDidReceiveNotificationResponse: (_) {},
      );
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;

      if (kIsWeb) {
        debugPrint('[push] foreground message: ${notification.title}');
        return;
      }

      _local.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    });

    // Fires when the user taps a notification and the app opens/resumes
    // from it — wire navigation off `message.data` here once the app has
    // routes that map to specific notification types (e.g. order detail).
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('[push] opened from notification: ${message.messageId}');
    });

    final token = await currentToken();
    debugPrint('[push] FCM token: $token');
  }

  /// The device's current FCM registration token, or `null` on web until
  /// `_webVapidKey` is configured (see comment above). Safe to call
  /// anytime after [init] — callers (e.g. `BasketCubit`, to register the
  /// token against the signed-in user) don't need to cache it themselves.
  static Future<String?> currentToken() {
    if (kIsWeb && _webVapidKey.isEmpty) return Future.value(null);
    return FirebaseMessaging.instance.getToken(vapidKey: kIsWeb ? _webVapidKey : null);
  }

  /// Fires whenever the OS/browser rotates the token — callers should
  /// re-register it against the signed-in user when this fires.
  static Stream<String> get onTokenRefresh => FirebaseMessaging.instance.onTokenRefresh;

  /// `accounts.DeviceToken.Platform` value for this device.
  static String get platformName {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
  }
}
