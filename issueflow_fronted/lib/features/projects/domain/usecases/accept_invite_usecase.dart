import '../repositories/invites_repository.dart';

class AcceptInviteUseCase {
  final InvitesRepository repo;
  AcceptInviteUseCase(this.repo);

  Future<void> call(String token) => repo.acceptInvite(token);
}
