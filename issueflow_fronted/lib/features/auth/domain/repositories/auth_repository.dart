import 'package:issueflow_fronted/features/auth/domain/entities/token_pair.dart';
import 'package:issueflow_fronted/features/auth/domain/entities/user_me.dart';

abstract class AuthRepository {
  Future<TokenPair> login({required String email, required String password});
  Future<TokenPair> register({
    required String username, // ✅ NEW
    required String email,
    required String password,
  });
  Future<TokenPair> firebaseLogin();
  Future<UserMe> getMe();
  Future<void> logout();
}
