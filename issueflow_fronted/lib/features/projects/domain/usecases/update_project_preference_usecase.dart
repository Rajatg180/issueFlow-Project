import '../entities/project_entity.dart';
import '../repositories/projects_repository.dart';

class UpdateProjectPreferenceUseCase {
  final ProjectsRepository repo;
  UpdateProjectPreferenceUseCase(this.repo);

  Future<ProjectEntity> call(
    String projectId, {
    bool? isFavorite,
    bool? isPinned,
  }) {
    return repo.updatePreference(
      projectId,
      isFavorite: isFavorite,
      isPinned: isPinned,
    );
  }
}
