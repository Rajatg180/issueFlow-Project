class IssueCommentEntity {
  final String id;
  final String projectId;
  final String issueId;

  final String authorId;
  final String authorUsername;

  final String body;
  final bool edited;

  final DateTime createdAt;
  final DateTime updatedAt;

  const IssueCommentEntity({
    required this.id,
    required this.projectId,
    required this.issueId,
    required this.authorId,
    required this.authorUsername,
    required this.body,
    required this.edited,
    required this.createdAt,
    required this.updatedAt,
  });
}
