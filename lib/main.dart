import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/constants/app_colors.dart';
import 'core/constants/app_dimensions.dart';
import 'core/network/dio_client.dart';
import 'core/services/local_notification_service.dart';
import 'core/storage/secure_storage_service.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/bloc/bloc.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/teacher/data/repositories/attendance_repository.dart';
import 'features/teacher/data/repositories/schedule_repository.dart';
import 'features/teacher/data/repositories/inval_repository.dart';
import 'features/teacher/data/repositories/notification_repository.dart';
import 'features/teacher/data/repositories/permission_repository.dart';
import 'features/teacher/presentation/bloc/bloc.dart';
import 'features/teacher/presentation/pages/teacher_main_page.dart';
import 'features/bk/presentation/pages/bk_dashboard_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize intl localization data (untuk format tanggal ID)
  await initializeDateFormatting('id_ID', null);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize DioClient (singleton)
  await SecureStorageService().init();
  DioClient().init();
  await LocalNotificationService().initialize();

  // Initialize repositories
  final authRepository = AuthRepository();
  final attendanceRepository = AttendanceRepository();
  final scheduleRepository = ScheduleRepository();
  final invalRepository = InvalRepository();
  final notificationRepository = NotificationRepository();
  final permissionRepository = PermissionRepository();

  runApp(
    SimPanlaApp(
      authRepository: authRepository,
      attendanceRepository: attendanceRepository,
      scheduleRepository: scheduleRepository,
      invalRepository: invalRepository,
      notificationRepository: notificationRepository,
      permissionRepository: permissionRepository,
    ),
  );
}

class SimPanlaApp extends StatelessWidget {
  final AuthRepository authRepository;
  final AttendanceRepository attendanceRepository;
  final ScheduleRepository scheduleRepository;
  final InvalRepository invalRepository;
  final NotificationRepository notificationRepository;
  final PermissionRepository permissionRepository;

  const SimPanlaApp({
    super.key,
    required this.authRepository,
    required this.attendanceRepository,
    required this.scheduleRepository,
    required this.invalRepository,
    required this.notificationRepository,
    required this.permissionRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authRepository),
        RepositoryProvider.value(value: attendanceRepository),
        RepositoryProvider.value(value: scheduleRepository),
        RepositoryProvider.value(value: invalRepository),
        RepositoryProvider.value(value: notificationRepository),
        RepositoryProvider.value(value: permissionRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) =>
                AuthBloc(authRepository: authRepository)
                  ..add(AuthCheckRequested()),
          ),
          BlocProvider(
            create: (context) =>
                AttendanceBloc(repository: attendanceRepository),
          ),
          BlocProvider(
            create: (context) => ScheduleBloc(repository: scheduleRepository),
          ),
          BlocProvider(
            create: (context) => InvalBloc(repository: invalRepository),
          ),
          BlocProvider(
            create: (context) =>
                NotificationBloc(repository: notificationRepository),
          ),
          BlocProvider(
            create: (context) =>
                PermissionBloc(repository: permissionRepository),
          ),
        ],
        child: MaterialApp(
          title: 'SIM PANLA',
          debugShowCheckedModeBanner: false,
          theme: _buildTheme(),
          builder: (context, child) {
            return SafeArea(
              top: true,
              bottom: true,
              left: true,
              right: true,
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const AuthNavigator(),
        ),
      ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.surface,
      // Typography using Google Fonts
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.manrope(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: AppColors.onSurface,
        ),
        displayMedium: GoogleFonts.manrope(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.25,
          color: AppColors.onSurface,
        ),
        headlineLarge: GoogleFonts.manrope(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
          color: AppColors.onSurface,
        ),
        headlineMedium: GoogleFonts.manrope(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
        headlineSmall: GoogleFonts.manrope(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.onSurface,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.onSurface,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.onSurfaceVariant,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          color: AppColors.onSurface,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: AppColors.onSurfaceVariant,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: AppColors.onSurfaceVariant,
        ),
      ),
      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.onSurface),
        titleTextStyle: GoogleFonts.manrope(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurface,
        ),
      ),
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacing4,
          vertical: AppDimensions.spacing4,
        ),
      ),
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacing6,
            vertical: AppDimensions.spacing4,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      // Card Theme
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        color: AppColors.surfaceContainerLowest,
      ),
      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.onSurface,
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.surface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
      ),
    );
  }
}

/// Navigator widget that handles authentication state routing
class AuthNavigator extends StatelessWidget {
  const AuthNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        // Handle navigation side effects
        if (state is AuthUnauthenticated) {
          // Could show a message if logged out
        }
      },
      builder: (context, state) {
        // Show loading indicator while checking auth status
        if (state is AuthInitial || state is AuthChecking) {
          return const _SplashScreen();
        }

        // Show login page if unauthenticated
        if (state is AuthUnauthenticated || state is AuthLoginFailure) {
          return const LoginPage();
        }

        // Show dashboard based on user role if authenticated
        if (state is AuthAuthenticated) {
          final user = state.user;

          // Route based on role
          if (user.isGuruBK) {
            return const BkDashboardPage();
          } else {
            // Default to Teacher Dashboard for Guru
            return const TeacherMainPage();
          }
        }

        // Show login during login process (to show loading on button)
        if (state is AuthLoginInProgress) {
          return const LoginPage();
        }

        // Default to login page
        return const LoginPage();
      },
    );
  }
}

/// Splash screen shown while checking authentication status
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowPrimary,
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: const Icon(Icons.school, color: Colors.white, size: 48),
            ),
            const SizedBox(height: AppDimensions.spacing6),
            // App Name
            Text(
              'SIM PANLA',
              style: GoogleFonts.manrope(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: AppDimensions.spacing2),
            Text(
              'Digital Academy Ecosystem',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppDimensions.spacing10),
            // Loading indicator
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primary.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
