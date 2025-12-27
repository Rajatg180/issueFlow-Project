import 'package:issueflow_fronted/features/issues/data/models/project_user_model.dart';
import 'package:issueflow_fronted/features/issues/domain/entities/project_user_entity.dart';

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
    DateTime? dueDate,
  });

  Future<List<ProjectUserEntity>> getProjectUsers({required String projectId});
}
