import '../entities/token_pair.dart';
import '../repositories/auth_repository.dart';

class FirebaseLoginUseCase {
  final AuthRepository repo;
  FirebaseLoginUseCase(this.repo);

  Future<TokenPair> call() => repo.firebaseLogin();
}
