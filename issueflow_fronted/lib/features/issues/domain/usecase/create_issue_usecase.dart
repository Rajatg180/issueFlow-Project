import '../entities/issue_entity.dart';
import '../repositories/issues_repository.dart';

class CreateIssueUseCase {
  final IssuesRepository repo;

  const CreateIssueUseCase(this.repo);

  Future<IssueEntity> call({
    required String projectId,
    required String title,
    String? description,
    String type = 'task',
    String priority = 'medium',
    DateTime? dueDate, // ✅ DateTime
  }) {
    return repo.createIssue(
      projectId: projectId,
      title: title,
      description: description,
      type: type,
      priority: priority,
      dueDate: dueDate,
    );
  }
}
