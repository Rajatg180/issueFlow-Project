import '../../../../core/errors/app_exception.dart';
import '../repositories/issues_repository.dart';

class UpdateIssueUseCase {
  final IssuesRepository repo;

  UpdateIssueUseCase(this.repo);

  Future<void> call({
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
      await repo.updateIssue(
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
    }
  }
}
