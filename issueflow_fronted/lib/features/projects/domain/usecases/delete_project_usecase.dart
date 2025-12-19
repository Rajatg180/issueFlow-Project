import '../repositories/projects_repository.dart';

class DeleteProjectUseCase {
  final ProjectsRepository repo;
  DeleteProjectUseCase(this.repo);

  Future<void> call(String projectId) => repo.deleteProject(projectId);
}
