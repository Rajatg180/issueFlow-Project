import '../entities/project_entity.dart';
import '../repositories/projects_repository.dart';

class UpdateProjectUseCase {
  final ProjectsRepository repo;
  UpdateProjectUseCase(this.repo);

  Future<ProjectEntity> call(
    String projectId, {
    String? name,
    String? key,
    String? description,
  }) {
    return repo.updateProject(
      projectId,
      name: name,
      key: key,
      description: description,
    );
  }
}
