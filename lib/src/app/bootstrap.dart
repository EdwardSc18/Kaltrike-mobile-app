import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:kaltrike_driver_app/src/app/kaltrike_app.dart';
import 'package:kaltrike_driver_app/src/core/services/local_notification_service.dart';
import 'package:kaltrike_driver_app/src/core/services/noti_service.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await LocalNotificationService.initialize();

  try {
    await NotiService().iniNotification();
  } catch (_) {
    // Keep app startup resilient even if notification setup fails.
  }

  runApp(const KaltrikeApp());
}
