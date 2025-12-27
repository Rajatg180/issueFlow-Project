import 'package:issueflow_fronted/features/auth/data/datasources/firebase_auth_service.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/token_pair.dart';
import '../../domain/entities/user_me.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remote;
  final TokenStorage tokenStorage;
  final FirebaseAuthService firebaseAuthService;

  AuthRepositoryImpl({
    required this.remote,
    required this.tokenStorage,
    required this.firebaseAuthService,
  });

  @override
  Future<TokenPair> login({
    required String email,
    required String password,
  }) async {
    final tokens = await remote.login(email, password);
    await tokenStorage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
    return tokens;
  }

  @override
  @override
  Future<TokenPair> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final tokens = await remote.register(username, email, password);
    await tokenStorage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
    return tokens;
  }

  @override
  Future<UserMe> getMe() async {
    final access = await tokenStorage.readAccessToken();
    final refresh = await tokenStorage.readRefreshToken();

    if (access == null || refresh == null) {
      throw const AppException("Not authenticated", statusCode: 401);
    }

    try {
      return await remote.me(access);
    } on AppException catch (e) {
      if (e.statusCode != 401) rethrow;

      try {
        final newAccess = await remote.refreshAccessToken(refresh);

        await tokenStorage.saveTokens(
          accessToken: newAccess,
          refreshToken: refresh,
        );

        return await remote.me(newAccess);
      } catch (_) {
        await tokenStorage.clear();
        throw const AppException(
          "Session expired. Please login again.",
          statusCode: 401,
        );
      }
    }
  }

  @override
  Future<void> logout() async {
    final refresh = await tokenStorage.readRefreshToken();
    if (refresh != null) {
      await remote.logout(refresh);
    }
    await tokenStorage.clear();
    await firebaseAuthService.signOut();
  }

  @override
  Future<TokenPair> firebaseLogin() async {
    final firebaseIdToken = await firebaseAuthService
        .signInWithGoogleAndGetIdToken();
    final tokens = await remote.firebaseLogin(firebaseIdToken);

    await tokenStorage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );

    return tokens;
  }
}
