import '../../domain/entities/issue_entity.dart';
import 'user_mini_model.dart';

class IssueModel extends IssueEntity {
  const IssueModel({
    required super.id,
    required super.key,
    required super.title,
    required super.description,
    required super.type,
    required super.priority,
    required super.status,
    required super.dueDate,
    required super.reporter,
    required super.createdAt,
    required super.updatedAt,
    required super.assignee,
    required super.commentsCount,
  });

  factory IssueModel.fromJson(Map<String, dynamic> json) {
    final reporterJson = (json['reporter'] as Map?)?.cast<String, dynamic>() ?? {};
    final assigneeRaw = json['assignee'];

    return IssueModel(
      id: (json['id'] ?? '').toString(),
      key: (json['key'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: json['description']?.toString(),
      type: (json['type'] ?? '').toString(),
      priority: (json['priority'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      dueDate: json['due_date']?.toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      updatedAt: (json['updated_at'] ?? '').toString(),
      reporter: UserMiniModel.fromJson(reporterJson),
      assignee: (assigneeRaw is Map)
          ? UserMiniModel.fromJson(assigneeRaw.cast<String, dynamic>())
          : null,
      commentsCount: (json['comments_count'] is int)
        ? (json['comments_count'] as int)
        : int.tryParse((json['comments_count'] ?? '0').toString()) ?? 0,
    );
  }
}
