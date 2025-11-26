import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/alert.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Request permissions for iOS
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    // Initialize Firebase Messaging
    await _initFirebaseMessaging();
  }

  static Future<void> _initFirebaseMessaging() async {
    final messaging = FirebaseMessaging.instance;

    // Request permission
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: true,
    );

    // Get FCM token
    final token = await messaging.getToken();
    print('FCM Token: $token');

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    print('Received foreground message: ${message.notification?.title}');

    if (message.notification != null) {
      showLocalNotification(
        title: message.notification!.title ?? 'ACM Alert',
        body: message.notification!.body ?? '',
        payload: message.data.toString(),
      );
    }
  }

  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print('Received background message: ${message.notification?.title}');
  }

  static void _handleMessageOpenedApp(RemoteMessage message) {
    print('Message opened app: ${message.data}');
    // Navigate to alert detail if alert ID is present
  }

  static void _onNotificationTap(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // Handle navigation based on payload
  }

  // Show local notification
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
    bool critical = false,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      critical ? 'critical_alerts' : 'alerts',
      critical ? 'Critical Alerts' : 'Alerts',
      channelDescription: 'ACM fraud detection alerts',
      importance: critical ? Importance.max : Importance.high,
      priority: critical ? Priority.max : Priority.high,
      playSound: true,
      enableVibration: true,
      color: critical ? const Color(0xFFEF4444) : const Color(0xFF2563EB),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  // Show alert notification
  static Future<void> showAlertNotification(Alert alert) async {
    final isCritical = alert.severity == 'CRITICAL';

    await showLocalNotification(
      title: '${alert.severity} Alert',
      body: '${alert.callCount} suspicious calls to ${alert.bNumber}',
      payload: alert.id,
      critical: isCritical,
    );
  }

  // Cancel all notifications
  static Future<void> cancelAll() async {
    await _localNotifications.cancelAll();
  }
}

// Required for handling color import
class Color {
  final int value;
  const Color(this.value);
}
