import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/app_notification.dart';

class NotificationRepository {
  final DioClient _dioClient;

  NotificationRepository({DioClient? dioClient})
    : _dioClient = dioClient ?? DioClient();

  Future<List<AppNotification>> getNotifications({int limit = 20}) async {
    final response = await _dioClient.get(
      ApiConstants.notifications,
      queryParameters: {'limit': limit},
    );

    if (response.data['status'] != 'success') {
      throw Exception(response.data['message'] ?? 'Gagal memuat notifikasi');
    }

    final raw = response.data['data'] as List<dynamic>? ?? [];
    return raw
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> getUnreadCount() async {
    final response = await _dioClient.get(ApiConstants.notificationUnreadCount);

    if (response.data['status'] != 'success') {
      throw Exception(
        response.data['message'] ?? 'Gagal memuat jumlah notifikasi',
      );
    }

    return int.tryParse(response.data['data']?['count']?.toString() ?? '0') ??
        0;
  }

  Future<void> markRead(int id) async {
    final endpoint = ApiConstants.notificationMarkRead.replaceAll(
      '{id}',
      '$id',
    );
    final response = await _dioClient.post(endpoint);
    if (response.data['status'] != 'success') {
      throw Exception(
        response.data['message'] ?? 'Gagal menandai notifikasi sudah dibaca',
      );
    }
  }

  Future<void> markAllRead() async {
    final response = await _dioClient.post(
      ApiConstants.notificationMarkAllRead,
    );
    if (response.data['status'] != 'success') {
      throw Exception(
        response.data['message'] ?? 'Gagal menandai semua notifikasi',
      );
    }
  }

  Future<void> clearAll() async {
    final response = await _dioClient.delete(ApiConstants.notificationClearAll);
    if (response.data['status'] != 'success') {
      throw Exception(
        response.data['message'] ?? 'Gagal menghapus semua notifikasi',
      );
    }
  }
}
