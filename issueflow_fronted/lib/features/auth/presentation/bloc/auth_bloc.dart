import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_me_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/firebase_login_usecase.dart';

import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
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
    on<AuthLogoutRequested>(_onLogout);
    on<AuthGoogleLoginRequested>(_onGoogleLogin);
  }

  bool _isValidEmail(String email) {
    final r = RegExp(r"^[^\s@]+@[^\s@]+\.[^\s@]+$");
    return r.hasMatch(email.trim());
  }

  String? _validateUsername(String username) {
    final u = username.trim();
    if (u.isEmpty) return "Username is required.";
    if (u.length < 3) return "Username must be at least 3 characters.";
    if (u.length > 32) return "Username must be at most 32 characters.";
    final r = RegExp(r"^[a-zA-Z0-9_]+$");
    if (!r.hasMatch(u)) {
      return "Username can only contain letters, numbers, and underscore.";
    }
    return null;
  }

  String? _validateCredentials({
    required String email,
    required String password,
  }) {
    if (!_isValidEmail(email)) return "Please enter a valid email address.";
    if (password.length < 6) return "Password must be at least 6 characters.";
    return null;
  }

  Future<void> _emitMe(Emitter<AuthState> emit) async {
    final me = await getMeUseCase();
    emit(
      Authenticated(
        email: me.email,
        hasCompletedOnboarding: me.hasCompletedOnboarding,
      ),
    );
  }

  Future<void> _onAppStarted(
    AuthAppStarted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _emitMe(emit);
    } catch (_) {
      emit(const Unauthenticated());
    }
  }

  Future<void> _onLogin(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    final err = _validateCredentials(
      email: event.email,
      password: event.password,
    );
    if (err != null) {
      emit(AuthFailure(err)); 
      return;
    }

    emit(const AuthLoading());
    try {
      await loginUseCase(email: event.email.trim(), password: event.password);
      await _emitMe(emit);
    } catch (e) {
      emit(
        AuthFailure(e.toString().replaceFirst("Exception: ", "")),
      ); 
    }
  }

  Future<void> _onRegister(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    final usernameErr = _validateUsername(event.username);
    if (usernameErr != null) {
      emit(AuthFailure(usernameErr));
      return;
    }

    final err = _validateCredentials(
      email: event.email,
      password: event.password,
    );
    if (err != null) {
      emit(AuthFailure(err));
      return;
    }

    emit(const AuthLoading());
    try {
      await registerUseCase(
        username: event.username.trim(),
        email: event.email.trim(),
        password: event.password,
      );
      await _emitMe(emit);
    } catch (e) {
      emit(AuthFailure(e.toString().replaceFirst("Exception: ", "")));
    }
  }

  Future<void> _onGoogleLogin(
    AuthGoogleLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await firebaseLoginUseCase();
      await _emitMe(emit);
    } catch (e) {
      emit(
        AuthFailure(e.toString().replaceFirst("Exception: ", "")),
      ); // ✅ keep failure
    }
  }

  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await logoutUseCase();
    emit(const Unauthenticated());
  }
}
