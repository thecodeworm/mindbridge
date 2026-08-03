import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final _plugin = FlutterLocalNotificationsPlugin();
bool _initialized = false;

Future<void> initNotifications() async {
  if (_initialized) return;
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const ios = DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );
  await _plugin.initialize(const InitializationSettings(android: android, iOS: ios));
  _initialized = true;
}

Future<bool> requestNotificationPermission() async {
  final iosResult = await _plugin
      .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(alert: true, badge: true, sound: true);
  if (iosResult != null) return iosResult;

  final androidResult = await _plugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();
  return androidResult ?? false;
}

Future<void> scheduleDailyReminder() async {
  await _plugin.cancelAll();
  const details = NotificationDetails(
    android: AndroidNotificationDetails(
      'mindbridge_daily',
      'Daily check-in',
      channelDescription: 'Daily reminder to log your mood',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
    iOS: DarwinNotificationDetails(),
  );
  await _plugin.periodicallyShow(
    0,
    'Time to check in 🌿',
    'How are you feeling today?',
    RepeatInterval.daily,
    details,
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
  );
}

Future<void> cancelAllReminders() => _plugin.cancelAll();
