import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/local_notification_service.dart';
import '../../data/models/app_notification.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/services/realtime_notification_service.dart';

part 'notification_event.dart';
part 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository _repository;
  final RealtimeNotificationService _realtime;
  final LocalNotificationService _localNotifications;
  final Set<int> _knownNotificationIds = <int>{};
  int? _activeUserId;
  Timer? _pollTimer;

  NotificationBloc({
    NotificationRepository? repository,
    RealtimeNotificationService? realtime,
    LocalNotificationService? localNotifications,
  }) : _repository = repository ?? NotificationRepository(),
       _realtime = realtime ?? RealtimeNotificationService(),
       _localNotifications = localNotifications ?? LocalNotificationService(),
       super(NotificationState.initial()) {
    on<NotificationStarted>(_onStarted);
    on<NotificationUnreadRequested>(_onUnreadRequested);
    on<NotificationPollRequested>(_onPollRequested);
    on<NotificationRealtimeReceived>(_onRealtimeReceived);
    on<NotificationMarkedAllRead>(_onMarkedAllRead);
    on<NotificationStopped>(_onStopped);
  }

  Future<void> _onStarted(
    NotificationStarted event,
    Emitter<NotificationState> emit,
  ) async {
    await _localNotifications.initialize();
    _activeUserId = event.userId;

    var realtimeConnected = false;
    try {
      await _realtime.connect(
        userId: event.userId,
        onNotification: (notification) {
          add(NotificationRealtimeReceived(notification));
        },
      );
      realtimeConnected = true;
    } catch (_) {
      realtimeConnected = false;
    }

    final notifications = (await _repository.getNotifications(limit: 50))
        .where(_belongsToActiveUser)
        .toList();
    _knownNotificationIds
      ..clear()
      ..addAll(notifications.map((item) => item.id));

    final count = notifications.where((item) => !item.isRead).length;
    emit(state.copyWith(unreadCount: count, connected: realtimeConnected));

    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => add(const NotificationPollRequested()),
    );
  }

  Future<void> _onUnreadRequested(
    NotificationUnreadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    final count = await _repository.getUnreadCount();
    emit(state.copyWith(unreadCount: count));
  }

  Future<void> _onPollRequested(
    NotificationPollRequested event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final notifications = (await _repository.getNotifications(limit: 50))
          .where(_belongsToActiveUser)
          .toList();
      final newNotifications = notifications
          .where((item) => !_knownNotificationIds.contains(item.id))
          .toList()
          .reversed;

      for (final notification in newNotifications) {
        _knownNotificationIds.add(notification.id);
        await _localNotifications.show(notification);
      }

      emit(
        state.copyWith(
          unreadCount: notifications.where((item) => !item.isRead).length,
        ),
      );
    } catch (_) {
      // Polling is a fallback; temporary network errors should not disrupt UI.
    }
  }

  Future<void> _onRealtimeReceived(
    NotificationRealtimeReceived event,
    Emitter<NotificationState> emit,
  ) async {
    if (!_belongsToActiveUser(event.notification)) return;
    if (!_knownNotificationIds.add(event.notification.id)) return;

    await _localNotifications.show(event.notification);
    emit(state.copyWith(unreadCount: state.unreadCount + 1));
  }

  Future<void> _onMarkedAllRead(
    NotificationMarkedAllRead event,
    Emitter<NotificationState> emit,
  ) async {
    await _repository.markAllRead();
    emit(state.copyWith(unreadCount: 0));
  }

  Future<void> _onStopped(
    NotificationStopped event,
    Emitter<NotificationState> emit,
  ) async {
    _pollTimer?.cancel();
    _pollTimer = null;
    _activeUserId = null;
    _knownNotificationIds.clear();
    await _realtime.disconnect();
    emit(state.copyWith(connected: false));
  }

  bool _belongsToActiveUser(AppNotification notification) {
    final activeUserId = _activeUserId;
    return activeUserId != null && notification.userId == activeUserId;
  }

  @override
  Future<void> close() async {
    _pollTimer?.cancel();
    await _realtime.disconnect();
    return super.close();
  }
}
