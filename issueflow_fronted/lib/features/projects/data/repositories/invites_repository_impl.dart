import '../../domain/entities/invite_entity.dart';
import '../../domain/repositories/invites_repository.dart';
import '../datasources/projects_remote_datasource.dart';

class InvitesRepositoryImpl implements InvitesRepository {
  final ProjectsRemoteDataSource remote;
  InvitesRepositoryImpl({required this.remote});

  @override
  Future<List<InviteEntity>> listMyInvites() => remote.listMyInvites();

  @override
  Future<void> acceptInvite(String token) => remote.acceptInvite(token);

  @override
  Future<Map<String, dynamic>> inviteMembersToProject(String projectId, List<String> emails) {
    return remote.inviteMembersToProject(projectId, emails);
  }
}
