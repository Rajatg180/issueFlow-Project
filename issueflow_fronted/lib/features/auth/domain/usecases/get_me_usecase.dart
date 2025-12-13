import '../entities/user_me.dart';
import '../repositories/auth_repository.dart';

class GetMeUseCase {
  final AuthRepository repo;
  GetMeUseCase(this.repo);

  Future<UserMe> call() => repo.getMe();
}
