import 'package:flutter_local_notifications/flutter_local_notifications.dart';


class NotiService {
  final notificationsPlugin = FlutterLocalNotificationsPlugin();

  bool _inInitialized = false;

  bool get isInitialized => _inInitialized;

  Future<void> iniNotification() async {
    if (_inInitialized) return;

    const initSettingsAndroid = AndroidInitializationSettings("@mipmap/ic_launcher");

    const initSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: initSettingsAndroid,
      iOS: initSettingsIOS,
    );

    await notificationsPlugin.initialize(initSettings);
  }


  // NOTIFICATIONS DETAIL SETUP
  NotificationDetails notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_channel_id',
        'Daily Notifications',
        channelDescription: 'Daily Notification Channel',
        importance: Importance.max,
        priority: Priority.high,
      ), // AndroidNotificationDetails
      iOS: DarwinNotificationDetails(),
// NotificationDetails
    );
  }

  // SHOW NOTIFICATION
  Future<void> showNotification({
    int id = 0,
    String? title,
    String? body,
  }) async {
    return notificationsPlugin.show(
      id,
      title,
      body,
      const NotificationDetails(),
    );
  }
}