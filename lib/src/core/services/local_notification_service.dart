import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static Function(String)? onNotificationClick;

  static Future<void> initialize({Function(String)? onNotificationClicked}) async {
    onNotificationClick = onNotificationClicked;

    const AndroidInitializationSettings androidInit =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosInit = DarwinInitializationSettings();

    const InitializationSettings settings =
    InitializationSettings(android: androidInit, iOS: iosInit);

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null && onNotificationClick != null) {
          onNotificationClick!(response.payload!);
        }
      },
    );
  }

  static Future<void> showNotification({
    required String title,
    required String body,
    required String payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'ride_channel',
      'Ride Requests',
      channelDescription: 'Notifications for ride requests',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('beep'),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      sound: 'default',
    );

    const NotificationDetails details =
    NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  // Clear all ride notifications when a ride is accepted
  static Future<void> clearAllRideNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}