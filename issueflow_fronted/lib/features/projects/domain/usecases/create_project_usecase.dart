import '../entities/project_entity.dart';
import '../repositories/projects_repository.dart';

class CreateProjectUseCase {
  final ProjectsRepository repo;
  CreateProjectUseCase(this.repo);

  Future<ProjectEntity> call({
    required String name,
    required String key,
    String? description,
  }) {
    return repo.createProject(name: name, key: key, description: description);
  }
}
