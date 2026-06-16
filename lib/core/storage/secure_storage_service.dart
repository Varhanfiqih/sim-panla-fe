import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Secure storage wrapper for managing sensitive data (tokens)
/// and non-sensitive data (preferences)
class SecureStorageService {
  static final SecureStorageService _instance =
      SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  // Secure storage for sensitive data (tokens, passwords)
  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // Shared preferences for non-sensitive data
  SharedPreferences? _prefs;

  // ========== INITIALIZATION ==========

  /// Initialize the storage service
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ========== SECURE STORAGE (Sensitive Data) ==========

  /// Save access token
  Future<void> saveAccessToken(String token) async {
    await _secureStorage.write(key: _Keys.accessToken, value: token);
  }

  /// Get access token
  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: _Keys.accessToken);
  }

  /// Delete access token
  Future<void> deleteAccessToken() async {
    await _secureStorage.delete(key: _Keys.accessToken);
  }

  /// Save refresh token
  Future<void> saveRefreshToken(String token) async {
    await _secureStorage.write(key: _Keys.refreshToken, value: token);
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _Keys.refreshToken);
  }

  /// Delete refresh token
  Future<void> deleteRefreshToken() async {
    await _secureStorage.delete(key: _Keys.refreshToken);
  }

  /// Save user data as JSON string
  Future<void> saveUserData(String userData) async {
    await _secureStorage.write(key: _Keys.userData, value: userData);
  }

  /// Get user data JSON string
  Future<String?> getUserData() async {
    return await _secureStorage.read(key: _Keys.userData);
  }

  /// Delete user data
  Future<void> deleteUserData() async {
    await _secureStorage.delete(key: _Keys.userData);
  }

  /// Check if user is logged in (has access token)
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> saveRememberedLogin({
    required String nip,
    required String password,
  }) async {
    await saveBool(_Keys.rememberLogin, true);
    await saveString(_Keys.rememberedNip, nip);
    await _secureStorage.write(key: _Keys.rememberedPassword, value: password);
  }

  String? getRememberedNip() {
    return getString(_Keys.rememberedNip);
  }

  Future<String?> getRememberedPassword() async {
    return await _secureStorage.read(key: _Keys.rememberedPassword);
  }

  bool shouldRememberLogin() {
    return getBool(_Keys.rememberLogin) ?? false;
  }

  Future<void> clearRememberedLogin() async {
    await remove(_Keys.rememberLogin);
    await remove(_Keys.rememberedNip);
    await _secureStorage.delete(key: _Keys.rememberedPassword);
  }

  /// Clear all secure data (logout)
  Future<void> clearSecureData() async {
    await deleteAccessToken();
    await deleteRefreshToken();
    await deleteUserData();
  }

  /// Clear ALL storage data (secure + preferences)
  Future<void> clearAllData() async {
    await clearSecureData();
    await _prefs?.clear();
  }

  // ========== SHARED PREFERENCES (Non-Sensitive Data) ==========

  /// Save string value
  Future<bool> saveString(String key, String value) async {
    return await _prefs?.setString(key, value) ?? false;
  }

  /// Get string value
  String? getString(String key) {
    return _prefs?.getString(key);
  }

  /// Save int value
  Future<bool> saveInt(String key, int value) async {
    return await _prefs?.setInt(key, value) ?? false;
  }

  /// Get int value
  int? getInt(String key) {
    return _prefs?.getInt(key);
  }

  /// Save bool value
  Future<bool> saveBool(String key, bool value) async {
    return await _prefs?.setBool(key, value) ?? false;
  }

  /// Get bool value
  bool? getBool(String key) {
    return _prefs?.getBool(key);
  }

  /// Save double value
  Future<bool> saveDouble(String key, double value) async {
    return await _prefs?.setDouble(key, value) ?? false;
  }

  /// Get double value
  double? getDouble(String key) {
    return _prefs?.getDouble(key);
  }

  /// Save string list
  Future<bool> saveStringList(String key, List<String> value) async {
    return await _prefs?.setStringList(key, value) ?? false;
  }

  /// Get string list
  List<String>? getStringList(String key) {
    return _prefs?.getStringList(key);
  }

  /// Remove a key from preferences
  Future<bool> remove(String key) async {
    return await _prefs?.remove(key) ?? false;
  }

  /// Check if key exists in preferences
  bool containsKey(String key) {
    return _prefs?.containsKey(key) ?? false;
  }

  // ========== APP-SPECIFIC HELPERS ==========

  /// Save last sync timestamp
  Future<bool> saveLastSyncTime(DateTime dateTime) async {
    return await saveString(_Keys.lastSyncTime, dateTime.toIso8601String());
  }

  /// Get last sync timestamp
  DateTime? getLastSyncTime() {
    final timeString = getString(_Keys.lastSyncTime);
    if (timeString == null) return null;
    return DateTime.tryParse(timeString);
  }

  /// Save app language
  Future<bool> saveLanguage(String languageCode) async {
    return await saveString(_Keys.language, languageCode);
  }

  /// Get app language
  String? getLanguage() {
    return getString(_Keys.language);
  }

  /// Save theme mode (light/dark)
  Future<bool> saveThemeMode(String mode) async {
    return await saveString(_Keys.themeMode, mode);
  }

  /// Get theme mode
  String? getThemeMode() {
    return getString(_Keys.themeMode);
  }

  /// Save onboarding completed flag
  Future<bool> saveOnboardingCompleted(bool completed) async {
    return await saveBool(_Keys.onboardingCompleted, completed);
  }

  /// Check if onboarding is completed
  bool isOnboardingCompleted() {
    return getBool(_Keys.onboardingCompleted) ?? false;
  }

  /// Save last selected class filter
  Future<bool> saveLastSelectedClass(String className) async {
    return await saveString(_Keys.lastSelectedClass, className);
  }

  /// Get last selected class filter
  String? getLastSelectedClass() {
    return getString(_Keys.lastSelectedClass);
  }

  /// Save last selected date filter
  Future<bool> saveLastSelectedDate(DateTime date) async {
    return await saveString(_Keys.lastSelectedDate, date.toIso8601String());
  }

  /// Get last selected date filter
  DateTime? getLastSelectedDate() {
    final dateString = getString(_Keys.lastSelectedDate);
    if (dateString == null) return null;
    return DateTime.tryParse(dateString);
  }
}

/// Storage keys constants
class _Keys {
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String userData = 'user_data';
  static const String rememberLogin = 'remember_login';
  static const String rememberedNip = 'remembered_nip';
  static const String rememberedPassword = 'remembered_password';
  static const String lastSyncTime = 'last_sync_time';
  static const String language = 'language';
  static const String themeMode = 'theme_mode';
  static const String onboardingCompleted = 'onboarding_completed';
  static const String lastSelectedClass = 'last_selected_class';
  static const String lastSelectedDate = 'last_selected_date';
}
