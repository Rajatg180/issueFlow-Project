import 'package:issueflow_fronted/features/issues/domain/repositories/issues_repository.dart';

class DeleteIssueUsecase {
  final IssuesRepository repository;
  DeleteIssueUsecase(this.repository);

  Future<void> call({
    required String projectId,
    required String issueId,
  }) async {
    await repository.deleteIssue(projectId: projectId, issueId: issueId);
  }
}
