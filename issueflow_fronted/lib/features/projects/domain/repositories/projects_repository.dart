import '../entities/project_entity.dart';

abstract class ProjectsRepository {
  Future<List<ProjectEntity>> listProjects();

  Future<ProjectEntity> createProject({
    required String name,
    required String key,
    String? description,
  });

  Future<void> deleteProject(String projectId);

  // ✅ New
  Future<ProjectEntity> updatePreference(
    String projectId, {
    bool? isFavorite,
    bool? isPinned,
  });
}
