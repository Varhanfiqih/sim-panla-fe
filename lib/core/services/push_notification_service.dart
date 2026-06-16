import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../constants/api_constants.dart';
import '../network/dio_client.dart';
import '../storage/secure_storage_service.dart';
import '../../features/teacher/data/models/app_notification.dart';
import 'local_notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await PushNotificationService().initialize();
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService _instance = PushNotificationService._();

  factory PushNotificationService() => _instance;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final SecureStorageService _storage = SecureStorageService();
  final LocalNotificationService _localNotifications =
      LocalNotificationService();

  StreamSubscription<String>? _tokenRefreshSubscription;
  bool _initialized = false;
  bool _firebaseReady = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await Firebase.initializeApp();
      _firebaseReady = true;
    } catch (error) {
      debugPrint('Firebase belum dikonfigurasi: $error');
      return;
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);

    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen(
      (_) => registerCurrentToken(),
    );
  }

  Future<void> registerCurrentToken() async {
    await initialize();
    if (!_firebaseReady || !await _storage.isLoggedIn()) return;

    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;

    await DioClient().dio.post(
      ApiConstants.deviceTokens,
      data: {'token': token, 'platform': defaultTargetPlatform.name},
    );
  }

  Future<void> unregisterCurrentToken() async {
    await initialize();
    if (!_firebaseReady) return;

    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;

    await DioClient().dio.delete(
      ApiConstants.deviceTokens,
      data: {'token': token},
    );
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] ?? 'SIM PANLA';
    final body = notification?.body ?? message.data['body'] ?? '';
    if (body.isEmpty) return;

    await _localNotifications.show(
      AppNotification(
        id:
            int.tryParse(message.data['notification_id']?.toString() ?? '') ??
            DateTime.now().millisecondsSinceEpoch.remainder(1000000000),
        userId: 0,
        type: message.data['type']?.toString() ?? 'push',
        title: title,
        body: body,
        data: message.data,
        isRead: false,
      ),
    );
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
  }
}
