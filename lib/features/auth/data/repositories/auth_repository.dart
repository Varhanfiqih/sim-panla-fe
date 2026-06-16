import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/user.dart';
import '../models/login_response.dart';

/// Auth Repository for handling authentication API calls
class AuthRepository {
  static const Duration autoLogoutTimeout = Duration(hours: 1);
  static const String autoLogoutBackgroundedAtKey =
      'auto_logout_backgrounded_at';

  final DioClient _dioClient;
  final SecureStorageService _storage;

  AuthRepository({DioClient? dioClient, SecureStorageService? storage})
    : _dioClient = dioClient ?? DioClient(),
      _storage = storage ?? SecureStorageService();

  /// Login with NIP and password
  /// Returns LoginData containing user and token
  /// Throws ApiException on error
  Future<LoginData> login({
    required String nip,
    required String password,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.login,
        data: {'nip': nip, 'password': password},
      );

      // Parse response
      final apiResponse = ApiResponse<LoginData>.fromJson(
        response.data,
        (json) => LoginData.fromJson(json as Map<String, dynamic>),
      );

      if (!apiResponse.success || apiResponse.data == null) {
        throw ApiException(
          message: apiResponse.message,
          statusCode: response.statusCode ?? 0,
          type: ApiExceptionType.serverError,
        );
      }

      final loginData = apiResponse.data!;

      // Save token and user data to secure storage
      await clearBackgroundedAt();
      await _storage.saveAccessToken(loginData.token);
      await _storage.saveUserData(jsonEncode(loginData.user.toJson()));

      return loginData;
    } on DioException catch (e) {
      if (e.error is ApiException) {
        rethrow;
      }
      throw ApiException(
        message: ApiConstants.errorUnknown,
        statusCode: e.response?.statusCode ?? 0,
        type: ApiExceptionType.unknown,
      );
    }
  }

  /// Logout - revoke token and clear storage
  Future<void> logout() async {
    try {
      // Call logout API to revoke token
      await _dioClient.dio.post(ApiConstants.logout);
    } catch (e) {
      // Continue with logout even if API call fails
    } finally {
      // Always clear local storage
      await _storage.clearSecureData();
      await clearBackgroundedAt();
    }
  }

  Future<bool> hasExpiredBackgroundSession() async {
    final storedAt = _storage.getString(autoLogoutBackgroundedAtKey);
    final backgroundedAt = DateTime.tryParse(storedAt ?? '');
    if (backgroundedAt == null) return false;

    return DateTime.now().difference(backgroundedAt) >= autoLogoutTimeout;
  }

  Future<void> markBackgroundedAt(DateTime dateTime) async {
    await _storage.saveString(
      autoLogoutBackgroundedAtKey,
      dateTime.toIso8601String(),
    );
  }

  Future<void> clearBackgroundedAt() async {
    await _storage.remove(autoLogoutBackgroundedAtKey);
  }

  /// Get current user from storage
  Future<User?> getCurrentUser() async {
    try {
      final userDataString = await _storage.getUserData();
      if (userDataString == null || userDataString.isEmpty) {
        return null;
      }

      final userJson = jsonDecode(userDataString) as Map<String, dynamic>;
      return User.fromJson(userJson);
    } catch (e) {
      return null;
    }
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    return await _storage.isLoggedIn();
  }

  /// Get user profile from API (refresh user data)
  Future<User> getProfile() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.me);

      final apiResponse = ApiResponse<User>.fromJson(
        response.data,
        (json) => User.fromJson(json as Map<String, dynamic>),
      );

      if (!apiResponse.success || apiResponse.data == null) {
        throw ApiException(
          message: apiResponse.message,
          statusCode: response.statusCode ?? 0,
          type: ApiExceptionType.serverError,
        );
      }

      final user = apiResponse.data!;

      // Update user data in storage
      await _storage.saveUserData(jsonEncode(user.toJson()));

      return user;
    } on DioException catch (e) {
      if (e.error is ApiException) {
        rethrow;
      }
      throw ApiException(
        message: ApiConstants.errorUnknown,
        statusCode: e.response?.statusCode ?? 0,
        type: ApiExceptionType.unknown,
      );
    }
  }

  Future<User> updateProfilePhoto(String filePath) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.profileUpdate,
        data: FormData.fromMap({
          'photo': await MultipartFile.fromFile(
            filePath,
            filename: filePath.split(RegExp(r'[/\\]')).last,
          ),
        }),
      );

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw ApiException(
          message: _responseMessage(response.data),
          statusCode: response.statusCode ?? 0,
          type: ApiExceptionType.validation,
        );
      }

      final user = User.fromJson(response.data['data'] as Map<String, dynamic>);
      await _storage.saveUserData(jsonEncode(user.toJson()));
      return user;
    } on DioException catch (e) {
      if (e.error is ApiException) rethrow;
      throw ApiException(
        message: _responseMessage(e.response?.data),
        statusCode: e.response?.statusCode ?? 0,
        type: ApiExceptionType.unknown,
      );
    }
  }

  Future<User> deleteProfilePhoto() async {
    try {
      final response = await _dioClient.dio.delete(ApiConstants.profilePhoto);

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw ApiException(
          message: _responseMessage(response.data),
          statusCode: response.statusCode ?? 0,
          type: ApiExceptionType.serverError,
        );
      }

      final user = User.fromJson(response.data['data'] as Map<String, dynamic>);
      await _storage.saveUserData(jsonEncode(user.toJson()));
      return user;
    } on DioException catch (e) {
      if (e.error is ApiException) rethrow;
      throw ApiException(
        message: _responseMessage(e.response?.data),
        statusCode: e.response?.statusCode ?? 0,
        type: ApiExceptionType.unknown,
      );
    }
  }

  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmation,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.profileChangePassword,
        data: {
          'current_password': currentPassword,
          'password': newPassword,
          'password_confirmation': confirmation,
        },
      );

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw ApiException(
          message: _responseMessage(response.data),
          statusCode: response.statusCode ?? 0,
          type: ApiExceptionType.validation,
        );
      }

      return response.data['message']?.toString() ??
          'Password berhasil diperbarui.';
    } on DioException catch (e) {
      if (e.error is ApiException) rethrow;
      throw ApiException(
        message: _responseMessage(e.response?.data),
        statusCode: e.response?.statusCode ?? 0,
        type: ApiExceptionType.unknown,
      );
    }
  }

  String _responseMessage(dynamic data) {
    if (data is Map) {
      if (data['errors'] is Map) {
        final errors = data['errors'] as Map;
        if (errors.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) return first.first.toString();
        }
      }
      if (data['message'] != null) return data['message'].toString();
    }
    return ApiConstants.errorUnknown;
  }
}
