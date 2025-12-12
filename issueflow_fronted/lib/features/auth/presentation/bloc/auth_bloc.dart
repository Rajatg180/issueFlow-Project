import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  static const _kLoggedInEmail = 'logged_in_email';
  static const _kHasCompletedOnboarding = 'has_completed_onboarding';

  AuthBloc() : super(const AuthInitial()) {
    on<AuthAppStarted>(_onAppStarted);
    on<AuthLoginRequested>(_onLogin);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthOnboardingCompleted>(_onOnboardingCompleted);
    on<AuthLogoutRequested>(_onLogout);
  }

  bool _isValidEmail(String email) {
    // Simple email regex good enough for UI validation
    final r = RegExp(r"^[^\s@]+@[^\s@]+\.[^\s@]+$");
    return r.hasMatch(email.trim());
  }

  String? _validateCredentials({required String email, required String password}) {
    if (!_isValidEmail(email)) return "Please enter a valid email address.";
    if (password.length < 8) return "Password must be at least 8 characters.";
    return null;
  }

  Future<void> _onAppStarted(AuthAppStarted event, Emitter<AuthState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_kLoggedInEmail);
    final done = prefs.getBool(_kHasCompletedOnboarding) ?? false;

    if (email == null) {
      emit(const Unauthenticated());
    } else {
      emit(Authenticated(email: email, hasCompletedOnboarding: done));
    }
  }

  Future<void> _onLogin(AuthLoginRequested event, Emitter<AuthState> emit) async {
    final err = _validateCredentials(email: event.email, password: event.password);
    if (err != null) {
      emit(AuthFailure(err));
      emit(const Unauthenticated());
      return;
    }

    emit(const AuthLoading());

    // UI-only delay to mimic network request.
    await Future.delayed(const Duration(milliseconds: 600));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLoggedInEmail, event.email.trim());

    final done = prefs.getBool(_kHasCompletedOnboarding) ?? false;
    emit(Authenticated(email: event.email.trim(), hasCompletedOnboarding: done));
  }

  Future<void> _onRegister(AuthRegisterRequested event, Emitter<AuthState> emit) async {
    final err = _validateCredentials(email: event.email, password: event.password);
    if (err != null) {
      emit(AuthFailure(err));
      emit(const Unauthenticated());
      return;
    }

    emit(const AuthLoading());
    await Future.delayed(const Duration(milliseconds: 700));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLoggedInEmail, event.email.trim());

    // Register => first-time => onboarding not completed
    await prefs.setBool(_kHasCompletedOnboarding, false);

    emit(Authenticated(email: event.email.trim(), hasCompletedOnboarding: false));
  }

  Future<void> _onOnboardingCompleted(AuthOnboardingCompleted event, Emitter<AuthState> emit) async {
    final current = state;
    if (current is! Authenticated) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHasCompletedOnboarding, true);

    emit(Authenticated(email: current.email, hasCompletedOnboarding: true));
  }

  Future<void> _onLogout(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLoggedInEmail);
    emit(const Unauthenticated());
  }
}
