import '../entities/issue_comment_entity.dart';
import '../repositories/issues_repository.dart';

class UpdateIssueCommentUseCase {
  final IssuesRepository repo;
  UpdateIssueCommentUseCase(this.repo);

  Future<IssueCommentEntity> call({
    required String projectId,
    required String issueId,
    required String commentId,
    required String body,
  }) {
    return repo.updateIssueComment(
      projectId: projectId,
      issueId: issueId,
      commentId: commentId,
      body: body,
    );
  }
}
