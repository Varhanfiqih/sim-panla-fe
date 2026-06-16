part of 'notification_bloc.dart';

abstract class NotificationEvent {
  const NotificationEvent();
}

class NotificationStarted extends NotificationEvent {
  final int userId;

  const NotificationStarted(this.userId);
}

class NotificationRealtimeReceived extends NotificationEvent {
  final AppNotification notification;

  const NotificationRealtimeReceived(this.notification);
}

class NotificationUnreadRequested extends NotificationEvent {
  const NotificationUnreadRequested();
}

class NotificationPollRequested extends NotificationEvent {
  const NotificationPollRequested();
}

class NotificationMarkedAllRead extends NotificationEvent {
  const NotificationMarkedAllRead();
}

class NotificationStopped extends NotificationEvent {
  const NotificationStopped();
}
