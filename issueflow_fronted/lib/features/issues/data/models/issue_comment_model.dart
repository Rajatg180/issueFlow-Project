import '../../domain/entities/issue_comment_entity.dart';

class IssueCommentModel extends IssueCommentEntity {
  const IssueCommentModel({
    required super.id,
    required super.projectId,
    required super.issueId,
    required super.authorId,
    required super.authorUsername,
    required super.body,
    required super.edited,
    required super.createdAt,
    required super.updatedAt,
  });

  factory IssueCommentModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDt(dynamic v) {
      final s = (v ?? '').toString().trim();
      if (s.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);
      // backend likely returns ISO; DateTime.parse handles it
      return DateTime.parse(s);
    }

    return IssueCommentModel(
      id: (json['id'] ?? '').toString(),
      projectId: (json['project_id'] ?? '').toString(),
      issueId: (json['issue_id'] ?? '').toString(),
      authorId: (json['author_id'] ?? '').toString(),
      authorUsername: (json['author_username'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      edited: (json['edited'] ?? false) == true,
      createdAt: parseDt(json['created_at']),
      updatedAt: parseDt(json['updated_at']),
    );
  }
}
