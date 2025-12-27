import '../entities/token_pair.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repo;
  RegisterUseCase(this.repo);

  Future<TokenPair> call({
    required String username,
    required String email,
    required String password,
  }) {
    return repo.register(username: username, email: email, password: password);
  }
}

