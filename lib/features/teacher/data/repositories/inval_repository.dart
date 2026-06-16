import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/inval_class.dart';
import '../models/inval_history_item.dart';

class InvalRepository {
  final _dio = DioClient().dio;

  Future<List<InvalClass>> getAvailableInvalClasses() async {
    try {
      final response = await _dio.get('/journal/inval-classes');

      if (response.data['status'] == 'success') {
        final List<dynamic> rawData = response.data['data'];
        return rawData.map((e) => InvalClass.fromJson(e)).toList();
      } else {
        throw Exception(
          response.data['message'] ?? 'Failed to load inval classes',
        );
      }
    } on DioException catch (e) {
      final error = e.error;
      if (error is ApiException) throw error;
      throw Exception('Gagal memuat jadwal inval');
    } catch (e) {
      throw Exception('Gagal memuat jadwal inval: $e');
    }
  }

  Future<String> claimInvalClass(List<int> scheduleIds) async {
    try {
      final response = await _dio.post(
        '/journal/inval-claim',
        data: {'schedule_ids': scheduleIds},
      );

      if (response.data['status'] == 'success') {
        return response.data['message'] ?? 'Berhasil klaim kelas';
      } else {
        throw Exception(response.data['message'] ?? 'Gagal klaim kelas');
      }
    } on DioException catch (e) {
      final error = e.error;
      if (error is ApiException) throw error;
      throw Exception('Gagal klaim kelas');
    } catch (e) {
      throw Exception('Gagal klaim kelas: $e');
    }
  }

  Future<List<InvalHistoryItem>> getInvalHistory() async {
    try {
      final response = await _dio.get('/journal/inval-history');

      if (response.data['status'] == 'success') {
        final List<dynamic> rawData = response.data['data'];
        return rawData.map((e) => InvalHistoryItem.fromJson(e)).toList();
      }

      throw Exception(
        response.data['message'] ?? 'Failed to load inval history',
      );
    } on DioException catch (e) {
      final error = e.error;
      if (error is ApiException) throw error;
      throw Exception('Gagal memuat riwayat klaim inval');
    } catch (e) {
      throw Exception('Gagal memuat riwayat klaim inval: $e');
    }
  }
}
