import 'package:equatable/equatable.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

/// App start: load persisted auth + onboarding flags.
class AuthAppStarted extends AuthEvent {
  const AuthAppStarted();
}

/// User clicks Login
class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  const AuthLoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

/// User clicks Register
class AuthRegisterRequested extends AuthEvent {
  final String email;
  final String password;
  const AuthRegisterRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

/// Onboarding completed
class AuthOnboardingCompleted extends AuthEvent {
  const AuthOnboardingCompleted();
}

class AuthGoogleLoginRequested extends AuthEvent {
  const AuthGoogleLoginRequested();
}


/// Logout
class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}
