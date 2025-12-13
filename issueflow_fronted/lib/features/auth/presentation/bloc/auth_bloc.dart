import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:issueflow_fronted/features/auth/domain/usecases/firebase_login_usecase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/usecases/get_me_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  static const _kHasCompletedOnboarding = 'has_completed_onboarding';

  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final GetMeUseCase getMeUseCase;
  final LogoutUseCase logoutUseCase;
  final FirebaseLoginUseCase firebaseLoginUseCase;


  AuthBloc({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.firebaseLoginUseCase,
    required this.getMeUseCase,
    required this.logoutUseCase,
  }) : super(const AuthInitial()) {
    on<AuthAppStarted>(_onAppStarted);
    on<AuthLoginRequested>(_onLogin);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthOnboardingCompleted>(_onOnboardingCompleted);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthGoogleLoginRequested>(_onGoogleLogin);
  }

  bool _isValidEmail(String email) {
    final r = RegExp(r"^[^\s@]+@[^\s@]+\.[^\s@]+$");
    return r.hasMatch(email.trim());
  }

  String? _validateCredentials({required String email, required String password}) {
    if (!_isValidEmail(email)) return "Please enter a valid email address.";
    if (password.length < 6) return "Password must be at least 8 characters.";
    return null;
  }

  Future<void> _onAppStarted(AuthAppStarted event, Emitter<AuthState> emit) async {
    try {
      final me = await getMeUseCase();
      emit(Authenticated(email: me.email, hasCompletedOnboarding: me.hasCompletedOnboarding));
    } catch (_) {
      emit(const Unauthenticated());
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
    try {
      await loginUseCase(email: event.email.trim(), password: event.password);

      final prefs = await SharedPreferences.getInstance();
      final done = prefs.getBool(_kHasCompletedOnboarding) ?? false;

      emit(Authenticated(email: event.email.trim(), hasCompletedOnboarding: done));
    } catch (e) {
      emit(AuthFailure(e.toString().replaceFirst("Exception: ", "")));
      emit(const Unauthenticated());
    }
  }

  Future<void> _onRegister(AuthRegisterRequested event, Emitter<AuthState> emit) async {
    final err = _validateCredentials(email: event.email, password: event.password);
    if (err != null) {
      emit(AuthFailure(err));
      emit(const Unauthenticated());
      return;
    }

    emit(const AuthLoading());
    try {
      await registerUseCase(email: event.email.trim(), password: event.password);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kHasCompletedOnboarding, false);

      emit(Authenticated(email: event.email.trim(), hasCompletedOnboarding: false));
    } catch (e) {
      emit(AuthFailure(e.toString().replaceFirst("Exception: ", "")));
      emit(const Unauthenticated());
    }
  }

  Future<void> _onGoogleLogin(
    AuthGoogleLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final tokens = await firebaseLoginUseCase();
      // After google login success, user is authenticated.
      // onboarding false by default unless you set it locally.
      final prefs = await SharedPreferences.getInstance();
      final done = prefs.getBool(_kHasCompletedOnboarding) ?? false;

      // We don’t have email directly here unless we call getMe
      final me = await getMeUseCase();
      emit(Authenticated(email: me.email, hasCompletedOnboarding: done));
    } catch (e) {
      emit(AuthFailure(e.toString().replaceFirst("Exception: ", "")));
      emit(const Unauthenticated());
    }
  }


  Future<void> _onOnboardingCompleted(
    AuthOnboardingCompleted event,
    Emitter<AuthState> emit,
  ) async {
    final current = state;
    if (current is! Authenticated) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHasCompletedOnboarding, true);

    emit(Authenticated(email: current.email, hasCompletedOnboarding: true));
  }

  Future<void> _onLogout(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    await logoutUseCase();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kHasCompletedOnboarding);

    emit(const Unauthenticated());
  }
}
