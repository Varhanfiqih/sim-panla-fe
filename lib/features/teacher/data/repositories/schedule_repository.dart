import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/schedule.dart';

class ScheduleRepository {
  final DioClient _dioClient;

  ScheduleRepository({DioClient? dioClient})
    : _dioClient = dioClient ?? DioClient();

  /// Fetch teacher's schedules for a specific date
  /// [date] format: 'yyyy-MM-dd', defaults to today if null
  Future<ScheduleResponse> getSchedules({String? date}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (date != null) {
        queryParams['date'] = date;
      }

      final response = await _dioClient.get(
        '/schedules',
        queryParameters: queryParams,
      );

      return ScheduleResponse.fromJson(response.data);
    } on DioException catch (e) {
      final error = e.error;
      if (error is ApiException) throw error;
      throw Exception('Gagal memuat jadwal');
    } catch (e) {
      throw Exception('Gagal memuat jadwal: $e');
    }
  }
}
