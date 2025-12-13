import '../entities/token_pair.dart';
import '../entities/user_me.dart';

abstract class AuthRepository {
  Future<TokenPair> login({required String email, required String password});
  Future<TokenPair> register({required String email, required String password});
  Future<TokenPair> firebaseLogin();
  Future<UserMe> getMe(); 
  Future<void> logout();       
}
