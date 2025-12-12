import 'package:equatable/equatable.dart';

sealed class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// When user is logging in/registering (disable buttons + spinner)
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// For showing validation/server errors on UI
class AuthFailure extends AuthState {
  final String message;
  const AuthFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class Authenticated extends AuthState {
  final String email;
  final bool hasCompletedOnboarding;

  const Authenticated({
    required this.email,
    required this.hasCompletedOnboarding,
  });

  @override
  List<Object?> get props => [email, hasCompletedOnboarding];
}
