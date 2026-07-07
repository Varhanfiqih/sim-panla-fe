import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// BLoC for managing authentication state
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({AuthRepository? authRepository})
    : _authRepository = authRepository ?? AuthRepository(),
      super(const AuthInitial()) {
    // Register event handlers
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthRefreshUserRequested>(_onAuthRefreshUserRequested);
    on<AuthUserUpdated>((event, emit) {
      emit(AuthAuthenticated(user: event.user));
    });
  }

  /// Handle auth check on app start
  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthChecking());

    try {
      if (await _authRepository.hasExpiredBackgroundSession()) {
        await _authRepository.clearBackgroundedAt();
        await _authRepository.logout();
        emit(const AuthUnauthenticated());
        return;
      }

      final isLoggedIn = await _authRepository.isLoggedIn();

      if (isLoggedIn) {
        final user = await _authRepository.getProfile();
        await _authRepository.clearBackgroundedAt();
        // Only teacher-facing roles can access the mobile app.
        if (!user.canAccessMobile) {
          await _authRepository.logout();
          emit(const AuthUnauthenticated());
          return;
        }

        await PushNotificationService().registerCurrentToken();
        emit(AuthAuthenticated(user: user));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      if (e is ApiException && e.type == ApiExceptionType.unauthorized) {
        await _authRepository.logout();
        emit(const AuthUnauthenticated());
        return;
      }

      final cachedUser = await _authRepository.getCurrentUser();
      if (cachedUser != null && cachedUser.canAccessMobile) {
        emit(AuthAuthenticated(user: cachedUser));
        return;
      }

      emit(const AuthUnauthenticated());
    }
  }

  /// Handle login request
  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoginInProgress());

    try {
      final loginData = await _authRepository.login(
        nip: event.nip,
        password: event.password,
      );

      // Reject web panel roles on mobile.
      if (!loginData.user.canAccessMobile) {
        // Logout to clear token
        await _authRepository.logout();

        emit(
          const AuthLoginFailure(
            message:
                'Akun ini hanya dapat mengakses sistem melalui Web Panel. Silakan login mobile menggunakan akun Guru Mapel, Wali Kelas, atau Guru BK.',
          ),
        );

        await Future.delayed(const Duration(milliseconds: 100));
        emit(const AuthUnauthenticated());
        return;
      }

      await PushNotificationService().registerCurrentToken();
      emit(AuthAuthenticated(user: loginData.user));
    } catch (e) {
      String errorMessage = 'Login gagal';

      if (e is ApiException) {
        errorMessage = e.message;
      }

      emit(AuthLoginFailure(message: errorMessage));

      // After showing error, return to unauthenticated state
      await Future.delayed(const Duration(milliseconds: 100));
      emit(const AuthUnauthenticated());
    }
  }

  /// Handle logout request
  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLogoutInProgress());

    try {
      await PushNotificationService().unregisterCurrentToken();
      await _authRepository.logout();
      emit(const AuthUnauthenticated());
    } catch (e) {
      // Even if logout API fails, still clear local data
      emit(const AuthUnauthenticated());
    }
  }

  /// Handle user refresh request
  Future<void> _onAuthRefreshUserRequested(
    AuthRefreshUserRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Get current user first
    final currentState = state;
    if (currentState is! AuthAuthenticated) return;

    emit(AuthRefreshingUser(currentUser: currentState.user));

    try {
      final user = await _authRepository.getProfile();
      emit(AuthAuthenticated(user: user));
    } catch (e) {
      // If refresh fails, keep current user
      emit(AuthAuthenticated(user: currentState.user));
    }
  }
}
