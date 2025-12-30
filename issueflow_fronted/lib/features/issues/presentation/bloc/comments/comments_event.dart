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


class CommentEditRequested extends CommentsEvent {
  final String projectId;
  final String issueId;
  final String commentId;
  final String body;
  const CommentEditRequested({
    required this.projectId,
    required this.issueId,
    required this.commentId,
    required this.body,
  });
}

class CommentDeleteRequested extends CommentsEvent {
  final String projectId;
  final String issueId;
  final String commentId;
  const CommentDeleteRequested({
    required this.projectId,
    required this.issueId,
    required this.commentId,
  });
}