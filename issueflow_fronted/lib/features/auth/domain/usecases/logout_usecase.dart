import '../repositories/auth_repository.dart';

class LogoutUseCase {
  final AuthRepository repo;
  LogoutUseCase(this.repo);

  Future<void> call() => repo.logout();
}
