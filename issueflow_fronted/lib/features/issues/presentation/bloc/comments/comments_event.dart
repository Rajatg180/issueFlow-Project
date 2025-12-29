abstract class CommentsEvent {
  const CommentsEvent();
}

class CommentsOpenRequested extends CommentsEvent {
  final String projectId;
  final String issueId;
  const CommentsOpenRequested({required this.projectId, required this.issueId});
}

class CommentSendRequested extends CommentsEvent {
  final String projectId;
  final String issueId;
  final String body;
  const CommentSendRequested({
    required this.projectId,
    required this.issueId,
    required this.body,
  });
}
