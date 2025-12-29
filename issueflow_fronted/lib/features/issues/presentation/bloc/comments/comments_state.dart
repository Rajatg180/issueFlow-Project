import '../../../domain/entities/issue_comment_entity.dart';

abstract class CommentsState {
  const CommentsState();
}

class CommentsInitial extends CommentsState {
  const CommentsInitial();
}

class CommentsLoading extends CommentsState {
  const CommentsLoading();
}

class CommentsLoaded extends CommentsState {
  final String projectId;
  final String issueId;
  final List<IssueCommentEntity> comments;
  final bool sending;

  const CommentsLoaded({
    required this.projectId,
    required this.issueId,
    required this.comments,
    this.sending = false,
  });

  CommentsLoaded copyWith({
    List<IssueCommentEntity>? comments,
    bool? sending,
  }) {
    return CommentsLoaded(
      projectId: projectId,
      issueId: issueId,
      comments: comments ?? this.comments,
      sending: sending ?? this.sending,
    );
  }
}

class CommentsFailure extends CommentsState {
  final String message;
  const CommentsFailure(this.message);
}
