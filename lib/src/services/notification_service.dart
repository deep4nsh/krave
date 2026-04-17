// lib/services/notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Request FCM permissions
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _local.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Handle notification tap
      },
    );

    // Create a high-priority channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'krave_handshake',
      'Krave Live Handshake',
      description: 'Real-time order updates for Krave students and riders.',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    FirebaseMessaging.onMessage.listen((RemoteMessage msg) {
      final notification = msg.notification;
      if (notification != null) {
        showInstantNotification(notification.title ?? 'Krave', notification.body ?? '');
      }
    });
  }

  Future<void> showInstantNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'krave_handshake',
      'Krave Live Handshake',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(''),
    );
    
    const NotificationDetails details = NotificationDetails(android: androidDetails);
    await _local.show(
      DateTime.now().millisecond, 
      title, 
      body, 
      details,
    );
  }
}
