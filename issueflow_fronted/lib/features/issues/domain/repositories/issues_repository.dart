import '../entities/issue_entity.dart';
import '../entities/project_with_issues_entity.dart';

abstract class IssuesRepository {
  Future<List<ProjectWithIssuesEntity>> getProjectsWithIssues();

  Future<IssueEntity> createIssue({
    required String projectId,
    required String title,
    String? description,
    String type, // task/bug/feature
    String priority, // low/medium/high
    DateTime? dueDate, // ✅ DateTime
  });
}
