import 'user_mini_entity.dart';

class IssueEntity {
  final String id;
  final String key;
  final String title;
  final String? description;

  final String type;     // task/bug/feature
  final String priority; // low/medium/high
  final String status;   // todo/in_progress/done

  final String? dueDate; // "YYYY-MM-DD" or null
  final String createdAt;
  final String updatedAt;
  final UserMiniEntity reporter;
  final UserMiniEntity? assignee;
  final int commentsCount;
  const IssueEntity({
    required this.id,
    required this.key,
    required this.title,
    required this.description,
    required this.type,
    required this.priority,
    required this.status,
    required this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    required this.reporter,
    required this.assignee,
    required this.commentsCount,
  });
}
