import '../entities/project_entity.dart';

abstract class ProjectsRepository {
  Future<List<ProjectEntity>> listProjects();

  Future<ProjectEntity> createProject({
    required String name,
    required String key,
    String? description,
  });

  Future<void> deleteProject(String projectId);

  Future<ProjectEntity> updatePreference(
    String projectId, {
    bool? isFavorite,
    bool? isPinned,
  });

  // ✅ NEW: edit project
  Future<ProjectEntity> updateProject(
    String projectId, {
    String? name,
    String? key,
    String? description,
  });
}
