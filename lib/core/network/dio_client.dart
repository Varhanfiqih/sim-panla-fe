import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../constants/api_constants.dart';
import '../storage/secure_storage_service.dart';

/// HTTP Client using Dio with interceptors for:
/// - Authentication (Bearer token)
/// - Logging
/// - Error handling
class DioClient {
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;
  DioClient._internal();

  late Dio _dio;
  final _storage = SecureStorageService();
  void Function()? onUnauthorized;
  final _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 75,
      colors: true,
      printEmojis: true,
    ),
  );

  Dio get dio => _dio;

  /// Initialize Dio client with base configuration
  void init() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.apiBaseUrl,
        connectTimeout: const Duration(
          milliseconds: ApiConstants.connectTimeout,
        ),
        receiveTimeout: const Duration(
          milliseconds: ApiConstants.receiveTimeout,
        ),
        sendTimeout: const Duration(milliseconds: ApiConstants.sendTimeout),
        headers: {
          ApiConstants.headerContentType: ApiConstants.contentTypeJson,
          ApiConstants.headerAccept: ApiConstants.contentTypeJson,
        },
        validateStatus: (status) => status != null && status < 400,
      ),
    );

    // Add interceptors
    _dio.interceptors.addAll([
      _authInterceptor(),
      _loggingInterceptor(),
      _errorInterceptor(),
    ]);
  }

  /// Authentication Interceptor
  /// Automatically adds Bearer token to requests
  Interceptor _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Get token from storage
        final token = await _storage.getAccessToken();

        // Add token to header if available
        if (token != null && token.isNotEmpty) {
          options.headers[ApiConstants.headerAuthorization] =
              ApiConstants.buildAuthHeader(token);
        }

        return handler.next(options);
      },
      onError: (error, handler) async {
        await _handleUnauthorizedResponse(error.response?.statusCode);

        return handler.next(error);
      },
    );
  }

  /// Logging Interceptor
  /// Logs all requests and responses for debugging
  Interceptor _loggingInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        _logger.d(
          '╔══════════════════════════════════════════════════════════════\n'
          '║ REQUEST\n'
          '╠══════════════════════════════════════════════════════════════\n'
          '║ Method: ${options.method}\n'
          '║ URL: ${options.uri}\n'
          '║ Headers: ${options.headers}\n'
          '║ Body: ${options.data}\n'
          '╚══════════════════════════════════════════════════════════════',
        );
        return handler.next(options);
      },
      onResponse: (response, handler) {
        _logger.i(
          '╔══════════════════════════════════════════════════════════════\n'
          '║ RESPONSE\n'
          '╠══════════════════════════════════════════════════════════════\n'
          '║ Status Code: ${response.statusCode}\n'
          '║ URL: ${response.requestOptions.uri}\n'
          '║ Body: ${response.data}\n'
          '╚══════════════════════════════════════════════════════════════',
        );
        return handler.next(response);
      },
      onError: (error, handler) {
        _logger.e(
          '╔══════════════════════════════════════════════════════════════\n'
          '║ ERROR\n'
          '╠══════════════════════════════════════════════════════════════\n'
          '║ Status Code: ${error.response?.statusCode}\n'
          '║ URL: ${error.requestOptions.uri}\n'
          '║ Message: ${error.message}\n'
          '║ Response: ${error.response?.data}\n'
          '╚══════════════════════════════════════════════════════════════',
        );
        return handler.next(error);
      },
    );
  }

  /// Error Interceptor
  /// Converts DioException to custom ApiException with friendly messages
  Interceptor _errorInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) async {
        await _handleUnauthorizedResponse(error.response?.statusCode);
        final apiException = _handleError(error);
        return handler.reject(
          DioException(
            requestOptions: error.requestOptions,
            error: apiException,
            response: error.response,
            type: error.type,
          ),
        );
      },
    );
  }

  Future<void> _handleUnauthorizedResponse(int? statusCode) async {
    if (statusCode != ApiConstants.statusUnauthorized) return;

    final hadToken = await _storage.isLoggedIn();
    if (!hadToken) return;

    _logger.w('Token expired, clearing session');
    await _storage.clearSecureData();
    onUnauthorized?.call();
  }

  /// Handle and convert DioException to ApiException
  ApiException _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: ApiConstants.errorTimeout,
          statusCode: 0,
          type: ApiExceptionType.timeout,
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 0;
        final responseData = error.response?.data;

        // Try to extract error message from response
        String message = ApiConstants.errorUnknown;

        if (responseData is Map<String, dynamic>) {
          // Laravel validation errors format
          if (responseData.containsKey('errors') &&
              responseData['errors'] is Map) {
            final errors = responseData['errors'] as Map<String, dynamic>;
            final firstError = errors.values.first;
            if (firstError is List && firstError.isNotEmpty) {
              message = firstError.first.toString();
            }
          }
          // Simple error message format
          else if (responseData.containsKey('message')) {
            message = responseData['message'].toString();
          } else if (responseData.containsKey('error')) {
            message = responseData['error'].toString();
          }
        }

        // Map status codes to error types
        switch (statusCode) {
          case ApiConstants.statusUnauthorized:
            return ApiException(
              message: _unauthorizedMessage(message),
              statusCode: statusCode,
              type: ApiExceptionType.unauthorized,
            );

          case ApiConstants.statusForbidden:
            return ApiException(
              message: ApiConstants.errorForbidden,
              statusCode: statusCode,
              type: ApiExceptionType.forbidden,
            );

          case ApiConstants.statusNotFound:
            return ApiException(
              message: ApiConstants.errorNotFound,
              statusCode: statusCode,
              type: ApiExceptionType.notFound,
            );

          case ApiConstants.statusUnprocessableEntity:
            return ApiException(
              message: message.isEmpty ? ApiConstants.errorValidation : message,
              statusCode: statusCode,
              type: ApiExceptionType.validation,
            );

          default:
            return ApiException(
              message: message.isEmpty
                  ? ApiConstants.errorServerError
                  : message,
              statusCode: statusCode,
              type: ApiExceptionType.serverError,
            );
        }

      case DioExceptionType.cancel:
        return ApiException(
          message: 'Request dibatalkan',
          statusCode: 0,
          type: ApiExceptionType.cancel,
        );

      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
      default:
        return ApiException(
          message: ApiConstants.errorNoInternet,
          statusCode: 0,
          type: ApiExceptionType.network,
        );
    }
  }

  String _unauthorizedMessage(String message) {
    final normalized = message.trim();
    if (normalized.isNotEmpty &&
        normalized != ApiConstants.errorUnknown &&
        normalized.toLowerCase() != 'unauthenticated.') {
      return normalized;
    }

    return ApiConstants.errorUnauthorized;
  }

  // ==========================================================================
  // HTTP Helper Methods
  // ==========================================================================

  /// GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.get(path, queryParameters: queryParameters, options: options);
  }

  /// POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.delete(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}

/// Custom API Exception with friendly error messages
class ApiException implements Exception {
  final String message;
  final int statusCode;
  final ApiExceptionType type;

  ApiException({
    required this.message,
    required this.statusCode,
    required this.type,
  });

  @override
  String toString() => message;
}

/// API Exception Types for better error handling
enum ApiExceptionType {
  network,
  timeout,
  unauthorized,
  forbidden,
  notFound,
  validation,
  serverError,
  cancel,
  unknown,
}
