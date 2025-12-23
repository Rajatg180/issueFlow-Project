import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/issue_entity.dart';
import '../../domain/entities/project_with_issues_entity.dart';
import '../../domain/repositories/issues_repository.dart';
import '../datasources/issues_remote_datasource.dart';

class IssuesRepositoryImpl implements IssuesRepository {
  final IssuesRemoteDataSource remote;

  // ✅ Require remote from DI (do NOT create it here)
  IssuesRepositoryImpl({required this.remote});

  @override
  Future<List<ProjectWithIssuesEntity>> getProjectsWithIssues() async {
    try {
      return await remote.getProjectsWithIssues();
    } on AppException {
      rethrow;
    } catch (_) {
      throw const AppException("Something went wrong while loading issues");
    }
  }

  @override
  Future<IssueEntity> createIssue({
    required String projectId,
    required String title,
    String? description,
    String type = 'task',
    String priority = 'medium',
    DateTime? dueDate,
  }) async {
    try {
      return await remote.createIssue(
        projectId: projectId,
        title: title,
        description: description,
        type: type,
        priority: priority,
        dueDate: dueDate,
      );
    } on AppException {
      rethrow;
    } catch (_) {
      throw const AppException("Something went wrong while creating issue");
    }
  }
}
