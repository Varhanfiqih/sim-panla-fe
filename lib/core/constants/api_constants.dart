/// API Configuration and Constants
class ApiConstants {
  ApiConstants._();

  // ========== BASE URLs ==========

  /// Local API Base URL for device testing.
  /// Use your LAN IP for a physical device, or 10.0.2.2 for the Android emulator.
  /// You can still override it with --dart-define=API_BASE_URL=... .
  static String get baseUrl => const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://sim-panla.my.id',
  );

  /// Production API Base URL (Commented out for local testing)
  // static const String baseUrl = 'https://smpn8.my.id';

  /// API Version prefix
  static const String apiVersion = 'v1';

  /// Full API Base URL with version
  static String get apiBaseUrl => '$baseUrl/api/$apiVersion';

  // ========== ENDPOINTS ==========

  // Auth Endpoints
  static const String login = '/login';
  static const String logout = '/logout';
  static const String me = '/user';

  // Dashboard Endpoints
  static const String dashboardStats = '/dashboard/stats';
  static const String scheduleToday = '/schedules/today';

  // Schedule Endpoints
  static const String schedules = '/schedules';
  static const String schedulesByDate = '/schedules/by-date';

  // Journal Endpoints
  static const String journals = '/journals';
  static const String journalDetail = '/journals/{id}';
  static const String journalCheckIn = '/journals/check-in';
  static const String journalAddStudent = '/journals/{id}/students';
  static const String journalRemoveStudent =
      '/journals/{id}/students/{studentId}';
  static const String journalUpdateAttendance = '/journals/{id}/attendances';
  static const String journalFinalize = '/journals/{id}/finalize';
  static const String journalClosed = '/journals/closed';

  // Attendance Endpoints
  static const String attendances = '/attendances';
  static const String attendanceStats = '/attendances/stats';
  static const String attendanceByClass = '/attendances/by-class';
  static const String attendanceSummary = '/attendances/summary';

  // Permission Endpoints
  static const String permissions = '/permissions';
  static const String permissionCreate = '/permissions';
  static const String permissionUpdate = '/permissions/{id}';
  static const String permissionApprove = '/permissions/{id}/approve';
  static const String permissionReject = '/permissions/{id}/reject';

  // BK (Bimbingan Konseling) Endpoints
  static const String bkCases = '/bk/cases';
  static const String bkCaseCreate = '/bk/cases';
  static const String bkCaseDetail = '/bk/cases/{id}';
  static const String bkCaseUpdate = '/bk/cases/{id}';
  static const String bkCaseAddNote = '/bk/cases/{id}/notes';

  // Student Endpoints
  static const String students = '/students';
  static const String studentDetail = '/students/{id}';
  static const String studentsByClass = '/students/by-class/{class}';
  static const String studentSearch = '/students/search';

  // User/Profile Endpoints
  static const String profile = '/profile';
  static const String profileUpdate = '/profile';
  static const String profilePhoto = '/profile/photo';
  static const String profileChangePassword = '/profile/change-password';

  // Notification Endpoints
  static const String notifications = '/notifications';
  static const String notificationUnreadCount = '/notifications/unread-count';
  static const String notificationMarkRead = '/notifications/{id}/read';
  static const String notificationMarkAllRead = '/notifications/mark-all-read';
  static const String notificationDelete = '/notifications/{id}';
  static const String notificationClearAll = '/notifications/clear-all';

  // Grade Endpoints
  static const String gradesMeta = '/grades/meta';
  static const String gradesStudents = '/grades/students';
  static const String gradesScores = '/grades/scores';
  static const String gradesSummary = '/grades/summary';
  static const String gradesBulkUpsert = '/grades/scores/bulk-upsert';
  static const String gradesFinishLock = '/grades/finish-lock';

  // Realtime (Laravel Reverb)
  static const String reverbAppKey = 'pwbsq25fnsp4avv7psnl';
  static const String reverbHost = String.fromEnvironment(
    'REVERB_HOST',
    defaultValue: '10.0.2.2',
  );
  static const int reverbPort = 8080;
  static const bool reverbUseTls = false;

  // ========== HTTP TIMEOUTS ==========

  /// Connect timeout in milliseconds (30 seconds)
  static const int connectTimeout = 30000;

  /// Receive timeout in milliseconds (30 seconds)
  static const int receiveTimeout = 30000;

  /// Send timeout in milliseconds (30 seconds)
  static const int sendTimeout = 30000;

  // ========== HEADERS ==========

  static const String headerContentType = 'Content-Type';
  static const String headerAccept = 'Accept';
  static const String headerAuthorization = 'Authorization';
  static const String headerUserAgent = 'User-Agent';

  static const String contentTypeJson = 'application/json';
  static const String contentTypeFormData = 'multipart/form-data';

  /// Bearer token prefix
  static const String bearerPrefix = 'Bearer';

  // ========== RESPONSE CODES ==========

  static const int statusOk = 200;
  static const int statusCreated = 201;
  static const int statusNoContent = 204;
  static const int statusBadRequest = 400;
  static const int statusUnauthorized = 401;
  static const int statusForbidden = 403;
  static const int statusNotFound = 404;
  static const int statusUnprocessableEntity = 422;
  static const int statusInternalServerError = 500;
  static const int statusServiceUnavailable = 503;

  // ========== CACHE KEYS ==========

  static const String cacheKeyAccessToken = 'access_token';
  static const String cacheKeyRefreshToken = 'refresh_token';
  static const String cacheKeyUser = 'user';
  static const String cacheKeyLastSync = 'last_sync';

  // ========== PAGINATION ==========

  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  static const String queryParamPage = 'page';
  static const String queryParamPerPage = 'per_page';
  static const String queryParamSearch = 'search';
  static const String queryParamSort = 'sort';
  static const String queryParamOrder = 'order';
  static const String queryParamDate = 'date';
  static const String queryParamStartDate = 'start_date';
  static const String queryParamEndDate = 'end_date';
  static const String queryParamClass = 'class';
  static const String queryParamStatus = 'status';

  // ========== ERROR MESSAGES ==========

  static const String errorNoInternet = 'Tidak ada koneksi internet';
  static const String errorTimeout = 'Koneksi timeout, silakan coba lagi';
  static const String errorServerError = 'Terjadi kesalahan pada server';
  static const String errorUnknown = 'Terjadi kesalahan, silakan coba lagi';
  static const String errorUnauthorized =
      'Sesi Anda telah berakhir, silakan login kembali';
  static const String errorForbidden = 'Anda tidak memiliki akses';
  static const String errorNotFound = 'Data tidak ditemukan';
  static const String errorValidation = 'Data yang Anda masukkan tidak valid';

  // ========== TEST CREDENTIALS (from UserSeeder.php) ==========

  /// Test Account - Admin (Kepala Sekolah)
  static const String testAdminNip = '198106202009041003';
  static const String testAdminPassword = '1';
  static const String testAdminName = 'ARIF SYAIFURROHMAN, S.Pd';

  /// Test Account - Guru / Wali Kelas
  static const String testGuruNip = '196912111997031009';
  static const String testGuruPassword = '1';
  static const String testGuruName = 'ABD HALIM, S.Pd';

  /// Test Account - Guru BK
  static const String testGuruBkNip = '198508042022212022';
  static const String testGuruBkPassword = '1';
  static const String testGuruBkName = 'AGUSTIN NUR HIDAYATI, S.Psi';

  // ========== HELPER METHODS ==========

  /// Build full URL from endpoint
  static String buildUrl(String endpoint) {
    return '$apiBaseUrl$endpoint';
  }

  /// Replace path parameters in endpoint
  /// Example: replacePathParams('/journals/{id}', {'id': '123'}) -> '/journals/123'
  static String replacePathParams(
    String endpoint,
    Map<String, dynamic> params,
  ) {
    String result = endpoint;
    params.forEach((key, value) {
      result = result.replaceAll('{$key}', value.toString());
    });
    return result;
  }

  /// Build authorization header value
  static String buildAuthHeader(String token) {
    return '$bearerPrefix $token';
  }
}
