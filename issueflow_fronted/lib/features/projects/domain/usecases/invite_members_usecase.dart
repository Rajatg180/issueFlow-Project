import '../repositories/invites_repository.dart';

class InviteMembersUseCase {
  final InvitesRepository repo;
  InviteMembersUseCase(this.repo);

  Future<Map<String, dynamic>> call(String projectId, List<String> emails) {
    return repo.inviteMembersToProject(projectId, emails);
  }
}
