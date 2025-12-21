import '../entities/invite_entity.dart';

abstract class InvitesRepository {
  Future<List<InviteEntity>> listMyInvites();
  Future<void> acceptInvite(String token);

  /// owner action
  Future<Map<String, dynamic>> inviteMembersToProject(String projectId, List<String> emails);
}
