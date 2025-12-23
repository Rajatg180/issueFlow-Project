import '../../domain/entities/project_with_issues_entity.dart';
import 'issue_model.dart';

class ProjectWithIssuesModel extends ProjectWithIssuesEntity {
  const ProjectWithIssuesModel({
    required super.id,
    required super.name,
    required super.key,
    required super.description,
    required super.role,
    required super.issues,
  });

  factory ProjectWithIssuesModel.fromJson(Map<String, dynamic> json) {
    final issuesList = (json['issues'] as List?) ?? const [];
    return ProjectWithIssuesModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      key: (json['key'] ?? '').toString(),
      description: json['description']?.toString(),
      role: (json['role'] ?? '').toString(),
      issues: issuesList
          .whereType<Map>()
          .map((e) => IssueModel.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }
}
