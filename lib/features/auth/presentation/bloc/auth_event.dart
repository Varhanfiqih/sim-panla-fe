import 'package:equatable/equatable.dart';
import '../../data/models/user.dart';

/// Base class for Auth Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Event to check if user is already logged in (on app start)
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// Event to perform login
class AuthLoginRequested extends AuthEvent {
  final String nip;
  final String password;

  const AuthLoginRequested({required this.nip, required this.password});

  @override
  List<Object?> get props => [nip, password];
}

/// Event to perform logout
class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

/// Event to refresh user data
class AuthRefreshUserRequested extends AuthEvent {
  const AuthRefreshUserRequested();
}

class AuthUserUpdated extends AuthEvent {
  final User user;

  const AuthUserUpdated(this.user);

  @override
  List<Object?> get props => [user];
}
