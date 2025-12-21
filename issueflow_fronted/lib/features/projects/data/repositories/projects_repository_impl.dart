import '../../domain/entities/project_entity.dart';
import '../../domain/repositories/projects_repository.dart';
import '../datasources/projects_remote_datasource.dart';
import '../../domain/entities/invite_entity.dart';
import '../datasources/projects_remote_datasource.dart';

class ProjectsRepositoryImpl implements ProjectsRepository {
  final ProjectsRemoteDataSource remote;
  ProjectsRepositoryImpl({required this.remote});

  @override
  Future<List<ProjectEntity>> listProjects() => remote.listProjects();

  @override
  Future<ProjectEntity> createProject({
    required String name,
    required String key,
    String? description,
  }) {
    return remote.createProject(name: name, key: key, description: description);
  }

  @override
  Future<void> deleteProject(String projectId) => remote.deleteProject(projectId);

  @override
  Future<ProjectEntity> updatePreference(
    String projectId, {
    bool? isFavorite,
    bool? isPinned,
  }) {
    return remote.updatePreference(
      projectId,
      isFavorite: isFavorite,
      isPinned: isPinned,
    );
  }
}
