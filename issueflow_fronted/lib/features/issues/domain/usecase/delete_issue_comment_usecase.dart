import '../repositories/issues_repository.dart';

class DeleteIssueCommentUseCase {
  final IssuesRepository repo;
  DeleteIssueCommentUseCase(this.repo);

  Future<void> call({
    required String projectId,
    required String issueId,
    required String commentId,
  }) {
    return repo.deleteIssueComment(
      projectId: projectId,
      issueId: issueId,
      commentId: commentId,
    );
  }
}
