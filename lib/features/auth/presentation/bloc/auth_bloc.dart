import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/dio_client.dart';
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
      final isLoggedIn = await _authRepository.isLoggedIn();

      if (isLoggedIn) {
        final user = await _authRepository.getCurrentUser();
        if (user != null) {
          // Check if user is Admin - force logout on mobile
          if (user.isAdmin) {
            await _authRepository.logout();
            emit(const AuthUnauthenticated());
            return;
          }

          emit(AuthAuthenticated(user: user));
        } else {
          emit(const AuthUnauthenticated());
        }
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
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

      // Check if user is Admin - reject login on mobile
      if (loginData.user.isAdmin) {
        // Logout to clear token
        await _authRepository.logout();

        emit(
          const AuthLoginFailure(
            message:
                'Admin hanya dapat mengakses sistem melalui Web. Silakan gunakan browser untuk login.',
          ),
        );

        await Future.delayed(const Duration(milliseconds: 100));
        emit(const AuthUnauthenticated());
        return;
      }

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
