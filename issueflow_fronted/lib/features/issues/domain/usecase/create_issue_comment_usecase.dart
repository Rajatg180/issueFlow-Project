import '../entities/issue_comment_entity.dart';
import '../repositories/issues_repository.dart';

class CreateIssueCommentUseCase {
  final IssuesRepository repo;
  CreateIssueCommentUseCase(this.repo);

  Future<IssueCommentEntity> call({
    required String projectId,
    required String issueId,
    required String body,
  }) {
    return repo.createIssueComment(projectId: projectId, issueId: issueId, body: body);
  }
}
