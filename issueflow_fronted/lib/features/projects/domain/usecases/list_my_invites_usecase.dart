import '../entities/invite_entity.dart';
import '../repositories/invites_repository.dart';

class ListMyInvitesUseCase {
  final InvitesRepository repo;
  ListMyInvitesUseCase(this.repo);

  Future<List<InviteEntity>> call() => repo.listMyInvites();
}
