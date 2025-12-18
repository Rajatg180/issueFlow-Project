import '../entities/project_entity.dart';
import '../repositories/projects_repository.dart';

class ListProjectsUseCase {
  final ProjectsRepository repo;
  ListProjectsUseCase(this.repo);

  Future<List<ProjectEntity>> call() => repo.listProjects();
}
