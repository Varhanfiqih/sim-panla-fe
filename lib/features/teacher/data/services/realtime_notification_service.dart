import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../../core/constants/api_constants.dart';
import '../models/app_notification.dart';

class RealtimeNotificationService {
  RealtimeNotificationService._();
  static final RealtimeNotificationService _instance =
      RealtimeNotificationService._();
  factory RealtimeNotificationService() => _instance;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  int? _userId;

  Future<void> connect({
    required int userId,
    required void Function(AppNotification notification) onNotification,
  }) async {
    if (_userId == userId && _channel != null) return;

    await disconnect();
    _userId = userId;

    final uri = Uri.parse(
      '${ApiConstants.reverbUseTls ? 'wss' : 'ws'}://'
      '${ApiConstants.reverbHost}:${ApiConstants.reverbPort}'
      '/app/${ApiConstants.reverbAppKey}?protocol=7&client=flutter&version=1.0&flash=false',
    );

    _channel = WebSocketChannel.connect(uri);

    _subscription = _channel!.stream.listen(
      (raw) {
        final payload = _toMap(raw);
        if (payload == null) return;

        final event = payload['event']?.toString();
        if (event == 'pusher:connection_established') {
          _subscribeToUserChannel(userId);
          return;
        }

        if (event == 'pusher:ping') {
          _send({'event': 'pusher:pong', 'data': {}});
          return;
        }

        if (event == 'notification.pushed') {
          final data = payload['data'];
          final dataMap = data is Map
              ? Map<String, dynamic>.from(data)
              : _toMap(data);
          if (dataMap != null) {
            onNotification(AppNotification.fromJson(dataMap));
          }
        }
      },
      onError: (_) => disconnect(),
      onDone: () {
        _channel = null;
        _subscription = null;
        _userId = null;
      },
      cancelOnError: true,
    );
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
    _userId = null;
  }

  void _subscribeToUserChannel(int userId) {
    _send({
      'event': 'pusher:subscribe',
      'data': {'channel': 'notifications.$userId'},
    });
  }

  void _send(Map<String, dynamic> payload) {
    _channel?.sink.add(jsonEncode(payload));
  }

  Map<String, dynamic>? _toMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is String) {
      try {
        final parsed = jsonDecode(raw);
        if (parsed is Map<String, dynamic>) {
          final data = parsed['data'];
          if (data is String && data.trim().startsWith('{')) {
            parsed['data'] = jsonDecode(data);
          }
          return parsed;
        }
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
