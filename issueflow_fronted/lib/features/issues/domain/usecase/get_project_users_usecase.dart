import 'package:issueflow_fronted/features/issues/domain/entities/project_user_entity.dart';
import '../repositories/issues_repository.dart';

class GetProjectUsersUseCase {
  final IssuesRepository repo;
  GetProjectUsersUseCase(this.repo);

  Future<List<ProjectUserEntity>> call({required String projectId}) {
    return repo.getProjectUsers(projectId: projectId);
  }
}
