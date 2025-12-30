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

  final bool savingEdit;
  final bool deleting;
  final String? editingCommentId;

  const CommentsLoaded({
    required this.projectId,
    required this.issueId,
    required this.comments,
    this.sending = false,
    this.savingEdit = false,
    this.deleting = false,
    this.editingCommentId,
  });

  CommentsLoaded copyWith({
    List<IssueCommentEntity>? comments,
    bool? sending,
    bool? savingEdit,
    bool? deleting,
    String? editingCommentId,
  }) {
    return CommentsLoaded(
      projectId: projectId,
      issueId: issueId,
      comments: comments ?? this.comments,
      sending: sending ?? this.sending,
      savingEdit: savingEdit ?? this.savingEdit,
      deleting: deleting ?? this.deleting,
      editingCommentId: editingCommentId,
    );
  }
}

class CommentsFailure extends CommentsState {
  final String message;
  const CommentsFailure(this.message);
}
