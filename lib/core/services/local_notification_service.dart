import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../features/teacher/data/models/app_notification.dart';

class LocalNotificationService {
  LocalNotificationService._();

  static final LocalNotificationService _instance =
      LocalNotificationService._();

  factory LocalNotificationService() => _instance;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'sim_panla_notifications',
    'Notifikasi SIM PANLA',
    description: 'Notifikasi jurnal, inval, presensi, dan perizinan SIM PANLA.',
    importance: Importance.high,
  );

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _plugin.initialize(settings: settings);

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.createNotificationChannel(_channel);
    await androidPlugin?.requestNotificationsPermission();

    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  Future<void> show(AppNotification notification) async {
    await initialize();

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'sim_panla_notifications',
        'Notifikasi SIM PANLA',
        channelDescription:
            'Notifikasi jurnal, inval, presensi, dan perizinan SIM PANLA.',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _plugin.show(
      id: notification.id,
      title: notification.title,
      body: notification.body,
      notificationDetails: details,
      payload:
          notification.data?['permission_id']?.toString() ??
          notification.data?['journal_id']?.toString(),
    );
  }
}
