import 'dart:async';
import 'dart:convert';

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

  final SecureStorageService _storage = SecureStorageService();
  final LocalNotificationService _localNotifications =
      LocalNotificationService();

  StreamSubscription<String>? _tokenRefreshSubscription;
  FirebaseMessaging? _messaging;
  bool _initialized = false;
  bool _firebaseReady = false;

  Future<void> initialize() async {
    if (_initialized && _firebaseReady) return;

    try {
      await Firebase.initializeApp().timeout(const Duration(seconds: 8));
      _firebaseReady = true;
    } catch (error) {
      debugPrint('Firebase belum dikonfigurasi: $error');
      _initialized = false;
      _firebaseReady = false;
      return;
    }

    final messaging = FirebaseMessaging.instance;
    _messaging = messaging;

    if (_initialized) return;
    _initialized = true;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    try {
      await messaging
          .requestPermission(alert: true, badge: true, sound: true)
          .timeout(const Duration(seconds: 8));
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (error) {
      debugPrint('Izin notifikasi Firebase gagal diproses: $error');
    }

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);

    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = messaging.onTokenRefresh.listen(
      (_) => registerCurrentToken(),
    );
  }

  Future<void> registerCurrentToken() async {
    try {
      await initialize();
      if (!_firebaseReady || !await _storage.isLoggedIn()) return;

      final messaging = _messaging;
      if (messaging == null) return;

      final token = await messaging.getToken().timeout(
        const Duration(seconds: 10),
        onTimeout: () => null,
      );
      if (token == null || token.isEmpty) return;

      await DioClient().dio.post(
        ApiConstants.deviceTokens,
        data: {'token': token, 'platform': defaultTargetPlatform.name},
      );
    } catch (error) {
      debugPrint('Token FCM gagal didaftarkan: $error');
    }
  }

  Future<void> unregisterCurrentToken() async {
    try {
      await initialize();
      if (!_firebaseReady) return;

      final messaging = _messaging;
      if (messaging == null) return;

      final token = await messaging.getToken().timeout(
        const Duration(seconds: 10),
        onTimeout: () => null,
      );
      if (token == null || token.isEmpty) return;

      await DioClient().dio.delete(
        ApiConstants.deviceTokens,
        data: {'token': token},
      );
    } catch (error) {
      debugPrint('Token FCM gagal dihapus: $error');
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final currentUserId = await _currentUserId();
    final notificationUserId = int.tryParse(
      message.data['user_id']?.toString() ?? '',
    );
    if (currentUserId == null ||
        notificationUserId == null ||
        notificationUserId != currentUserId) {
      return;
    }

    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] ?? 'SIM PANLA';
    final body = notification?.body ?? message.data['body'] ?? '';
    if (body.isEmpty) return;

    await _localNotifications.show(
      AppNotification(
        id:
            int.tryParse(message.data['notification_id']?.toString() ?? '') ??
            DateTime.now().millisecondsSinceEpoch.remainder(1000000000),
        userId: currentUserId,
        type: message.data['type']?.toString() ?? 'push',
        title: title,
        body: body,
        data: message.data,
        isRead: false,
      ),
    );
  }

  Future<int?> _currentUserId() async {
    final raw = await _storage.getUserData();
    if (raw == null || raw.isEmpty) return null;

    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return null;

      return int.tryParse(json['id']?.toString() ?? '');
    } catch (_) {
      return null;
    }
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
  }
}
