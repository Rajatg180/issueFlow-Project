import '../entities/project_with_issues_entity.dart';
import '../repositories/issues_repository.dart';

class GetProjectsWithIssuesUseCase {
  final IssuesRepository repo;

  const GetProjectsWithIssuesUseCase(this.repo);

  Future<List<ProjectWithIssuesEntity>> call() {
    return repo.getProjectsWithIssues();
  }
}
