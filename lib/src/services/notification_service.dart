// lib/services/notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Request FCM permissions (iOS); Android 13+ needs runtime notifications permission
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // On Android 13+, request notifications permission via local notifications plugin
    final androidSpecific = _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidSpecific?.requestNotificationsPermission();

    // Get token (store later in Firestore via UI layer if needed)
    await _fcm.getToken();

    // Local notification setup for Android and iOS
    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _local.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // handle local notification tap
      },
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage msg) {
      _showLocalNotification(msg);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage msg) {
      // handle tap from system tray
    });
  }

  Future<void> _showLocalNotification(RemoteMessage msg) async {
    final notification = msg.notification;
    if (notification == null) return;
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'krave_channel',
      'Krave Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails);
    await _local.show(0, notification.title, notification.body, details);
  }
}
