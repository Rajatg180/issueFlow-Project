import '../../domain/entities/project_entity.dart';
import '../../domain/repositories/projects_repository.dart';
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
}
