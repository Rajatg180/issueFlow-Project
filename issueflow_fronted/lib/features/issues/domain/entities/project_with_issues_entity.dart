import 'issue_entity.dart';

class ProjectWithIssuesEntity {
  final String id;
  final String name;
  final String key;
  final String? description;
  final String role;
  final List<IssueEntity> issues;

  const ProjectWithIssuesEntity({
    required this.id,
    required this.name,
    required this.key,
    required this.description,
    required this.role,
    required this.issues,
  });
}
