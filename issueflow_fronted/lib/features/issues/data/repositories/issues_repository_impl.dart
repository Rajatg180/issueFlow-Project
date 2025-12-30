import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/issue_comment_entity.dart';
import '../../domain/entities/issue_entity.dart';
import '../../domain/entities/project_user_entity.dart';
import '../../domain/entities/project_with_issues_entity.dart';
import '../../domain/repositories/issues_repository.dart';
import '../datasources/issues_remote_datasource.dart';

class IssuesRepositoryImpl implements IssuesRepository {
  final IssuesRemoteDataSource remote;

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

  @override
  Future<List<ProjectUserEntity>> getProjectUsers({required String projectId}) async {
    try {
      return await remote.getProjectUsers(projectId: projectId);
    } on AppException {
      rethrow;
    } catch (_) {
      throw const AppException("Something went wrong while loading project users");
    }
  }

  @override
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
  }) async {
    try {
      await remote.updateIssue(
        projectId: projectId,
        issueId: issueId,
        title: title,
        description: description,
        type: type,
        priority: priority,
        status: status,
        dueDate: dueDate,
        assigneeId: assigneeId,
        reporterId: reporterId,
      );
    } on AppException {
      rethrow;
    } catch (_) {
      throw const AppException("Something went wrong while updating issue");
    }
  }

  @override
  Future<void> deleteIssue({
    required String projectId,
    required String issueId,
  }) async {
    try {
      await remote.deleteIssue(
        projectId: projectId,
        issueId: issueId,
      );
    } on AppException {
      rethrow;
    } catch (_) {
      throw const AppException("Something went wrong while deleting issue");
    }
  }

  @override
  Future<List<IssueCommentEntity>> getIssueComments({
    required String projectId,
    required String issueId,
  }) async {
    try {
      return await remote.getIssueComments(projectId: projectId, issueId: issueId);
    } on AppException {
      rethrow;
    } catch (_) {
      throw const AppException("Something went wrong while loading comments");
    }
  }

  @override
  Future<IssueCommentEntity> createIssueComment({
    required String projectId,
    required String issueId,
    required String body,
  }) async {
    try {
      return await remote.createIssueComment(
        projectId: projectId,
        issueId: issueId,
        body: body,
      );
    } on AppException {
      rethrow;
    } catch (_) {
      throw const AppException("Something went wrong while creating comment");
    }
  }

  @override
  Future<IssueCommentEntity> updateIssueComment({
    required String projectId,
    required String issueId,
    required String commentId,
    required String body,
  }) async {
    try {
      return await remote.updateIssueComment(
        projectId: projectId,
        issueId: issueId,
        commentId: commentId,
        body: body,
      );
    } on AppException {
      rethrow;
    } catch (_) {
      throw const AppException("Something went wrong while editing comment");
    }
  }


  @override
  Future<void> deleteIssueComment({
    required String projectId,
    required String issueId,
    required String commentId,
  }) async {
    try {
      await remote.deleteIssueComment(
        projectId: projectId,
        issueId: issueId,
        commentId: commentId,
      );
    } on AppException {
      rethrow;
    } catch (_) {
      throw const AppException("Something went wrong while deleting comment");
    }
  }
}
