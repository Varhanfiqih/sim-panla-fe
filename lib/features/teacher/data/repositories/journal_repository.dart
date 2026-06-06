import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/journal.dart';
import '../models/journal_history.dart';

/// Repository for Journal API interactions
class JournalRepository {
  final DioClient _client;

  JournalRepository({DioClient? client}) : _client = client ?? DioClient();

  /// Get students list for journal attendance
  /// GET /journal/students/{schedule_id}
  Future<JournalStudentsData> getStudents(int scheduleId) async {
    try {
      final response = await _client.get('/journal/students/$scheduleId');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'success') {
          return JournalStudentsData.fromJson(data['data']);
        }
        throw Exception(data['message'] ?? 'Gagal mengambil data siswa');
      }

      throw Exception('Gagal mengambil data siswa: ${response.statusCode}');
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw Exception((e.error as ApiException).message);
      }
      throw Exception('Terjadi kesalahan jaringan');
    }
  }

  /// Submit journal with attendance data
  /// POST /journal/store (multipart/form-data)
  Future<JournalSubmitResponse> submitJournal(
    JournalSubmitRequest request, {
    File? attachment,
  }) async {
    try {
      // Build form data
      final attendancePayload = request.attendances
          .map((e) => e.toJson())
          .toList(growable: false);

      final formData = FormData.fromMap({
        'schedule_id': request.scheduleId,
        'materi': request.materi,
        'kebersihan_kelas': request.kebersihanKelas ?? '',
        'koordinat': request.koordinat ?? '',
        'is_inval': request.isInval ? 1 : 0,
        'attendances': attendancePayload,
      });

      // Add attachment if provided
      if (attachment != null) {
        formData.files.add(
          MapEntry(
            'attachment',
            await MultipartFile.fromFile(
              attachment.path,
              filename: attachment.path.split(RegExp(r'[/\\]')).last,
            ),
          ),
        );
      }

      final response = await _client.post(
        '/journal/store',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return JournalSubmitResponse.fromJson(response.data);
      }

      // Handle error responses
      final errorMessage = response.data['message'] ?? 'Gagal menyimpan jurnal';
      throw Exception(errorMessage);
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw Exception((e.error as ApiException).message);
      }
      // Check for specific error responses
      if (e.response?.data != null) {
        final errorData = e.response!.data;
        if (errorData is Map && errorData.containsKey('message')) {
          throw Exception(errorData['message']);
        }
      }
      throw Exception('Terjadi kesalahan jaringan');
    }
  }

  /// Get Journal History Detail
  /// GET /journal/history/{journal_id}
  Future<JournalHistoryResponse> getJournalHistory(int journalId) async {
    try {
      final response = await _client.get('/journal/history/$journalId');

      if (response.statusCode == 200) {
        return JournalHistoryResponse.fromJson(response.data);
      }

      throw Exception(
        'Gagal mengambil data riwayat jurnal: ${response.statusCode}',
      );
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw Exception((e.error as ApiException).message);
      }
      if (e.response?.data != null) {
        final errorData = e.response!.data;
        if (errorData is Map && errorData.containsKey('message')) {
          throw Exception(errorData['message']);
        }
      }
      throw Exception('Terjadi kesalahan jaringan');
    }
  }
}
