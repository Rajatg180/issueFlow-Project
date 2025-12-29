import '../entities/issue_comment_entity.dart';
import '../repositories/issues_repository.dart';

class GetIssueCommentsUseCase {
  final IssuesRepository repo;
  GetIssueCommentsUseCase(this.repo);

  Future<List<IssueCommentEntity>> call({
    required String projectId,
    required String issueId,
  }) {
    return repo.getIssueComments(projectId: projectId, issueId: issueId);
  }
}
