import 'package:issueflow_fronted/features/issues/domain/entities/issue_comment_entity.dart';

import '../entities/issue_entity.dart';
import '../entities/project_user_entity.dart';
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

  Future<void> updateIssue({
    required String projectId,
    required String issueId,
    required String title,
    String? description,
    required String type,
    required String priority,
    required String status,
    DateTime? dueDate,
    String? assigneeId,
    required String reporterId,
  });

  Future<void> deleteIssue({
    required String projectId,
    required String issueId,
  });

   Future<List<IssueCommentEntity>> getIssueComments({
    required String projectId,
    required String issueId,
  });

  Future<IssueCommentEntity> createIssueComment({
    required String projectId,
    required String issueId,
    required String body,
  });

   Future<IssueCommentEntity> updateIssueComment({
    required String projectId,
    required String issueId,
    required String commentId,
    required String body,
  });


  Future<void> deleteIssueComment({
    required String projectId,
    required String issueId,
    required String commentId,
  });
  
}
