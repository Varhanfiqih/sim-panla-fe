import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/teacher_attendance.dart';

class AttendanceRepository {
  final DioClient _dioClient;

  AttendanceRepository({DioClient? dioClient})
    : _dioClient = dioClient ?? DioClient();

  /// Check if teacher has checked in today
  Future<CheckInStatusResponse> getCheckInStatus() async {
    try {
      final response = await _dioClient.dio.get('/teacher/check-in-status');

      if (response.data['status'] == 'success') {
        return CheckInStatusResponse.fromJson(response.data['data']);
      } else {
        throw Exception(
          response.data['message'] ?? 'Failed to get check-in status',
        );
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Gagal mengecek status kehadiran',
      );
    }
  }

  /// Submit check-in (hadir or tidak_hadir)
  Future<TeacherAttendance> submitCheckIn({
    required String status,
    String? reason,
    String? description,
  }) async {
    try {
      final data = <String, dynamic>{
        'status': status,
        'reason': reason,
        'description': description,
      }..removeWhere((_, value) => value == null);

      final response = await _dioClient.dio.post(
        '/teacher/check-in',
        data: data,
      );

      if (response.data['status'] == 'success') {
        return TeacherAttendance.fromJson(response.data['data']);
      } else {
        throw Exception(
          response.data['message'] ?? 'Failed to submit check-in',
        );
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Gagal menyimpan konfirmasi kehadiran',
      );
    }
  }
}
