import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/errors/app_exception.dart';
import '../../../domain/usecase/get_issue_comments_usecase.dart';
import '../../../domain/usecase/create_issue_comment_usecase.dart';
import '../../../domain/usecase/update_issue_comment_usecase.dart';
import '../../../domain/usecase/delete_issue_comment_usecase.dart';
import 'comments_event.dart';
import 'comments_state.dart';

class CommentsBloc extends Bloc<CommentsEvent, CommentsState> {
  final GetIssueCommentsUseCase getComments;
  final CreateIssueCommentUseCase createComment;


  final UpdateIssueCommentUseCase updateComment;
  final DeleteIssueCommentUseCase deleteComment;

  CommentsBloc({
    required this.getComments,
    required this.createComment,
    required this.updateComment,
    required this.deleteComment,
  }) : super(const CommentsInitial()) {
    on<CommentsOpenRequested>(_onOpen);
    on<CommentSendRequested>(_onSend);


    on<CommentEditRequested>(_onEdit);
    on<CommentDeleteRequested>(_onDelete);
  }

  Future<void> _onOpen(CommentsOpenRequested e, Emitter<CommentsState> emit) async {
    emit(const CommentsLoading());
    try {
      final list = await getComments(projectId: e.projectId, issueId: e.issueId);
      emit(CommentsLoaded(projectId: e.projectId, issueId: e.issueId, comments: list));
    } on AppException catch (ex) {
      emit(CommentsFailure(ex.message));
    } catch (ex) {
      emit(CommentsFailure(ex.toString()));
    }
  }

  Future<void> _onSend(CommentSendRequested e, Emitter<CommentsState> emit) async {
    final s = state;
    if (s is! CommentsLoaded) return;

    emit(s.copyWith(sending: true));
    try {
      final created = await createComment(projectId: e.projectId, issueId: e.issueId, body: e.body);
      final next = List.of(s.comments)..add(created);
      emit(s.copyWith(comments: next, sending: false));
    } on AppException catch (ex) {
      emit(s.copyWith(sending: false));
      emit(CommentsFailure(ex.message));
      emit(s); // restore
    } catch (ex) {
      emit(s.copyWith(sending: false));
      emit(CommentsFailure(ex.toString()));
      emit(s); // restore
    }
  }

  Future<void> _onEdit(CommentEditRequested e, Emitter<CommentsState> emit) async {
    final s = state;
    if (s is! CommentsLoaded) return;
    if (s.issueId != e.issueId || s.projectId != e.projectId) return;

    emit(s.copyWith(savingEdit: true, editingCommentId: e.commentId));
    try {
      final updated = await updateComment(
        projectId: e.projectId,
        issueId: e.issueId,
        commentId: e.commentId,
        body: e.body,
      );

      final next = s.comments.map((c) => c.id == updated.id ? updated : c).toList();
      emit(s.copyWith(comments: next, savingEdit: false, editingCommentId: null));
    } on AppException catch (ex) {
      emit(s.copyWith(savingEdit: false, editingCommentId: null));
      emit(CommentsFailure(ex.message));
      emit(s);
    } catch (ex) {
      emit(s.copyWith(savingEdit: false, editingCommentId: null));
      emit(CommentsFailure(ex.toString()));
      emit(s);
    }
  }

  Future<void> _onDelete(CommentDeleteRequested e, Emitter<CommentsState> emit) async {
    final s = state;
    if (s is! CommentsLoaded) return;
    if (s.issueId != e.issueId || s.projectId != e.projectId) return;

    emit(s.copyWith(deleting: true));
    try {
      await deleteComment(projectId: e.projectId, issueId: e.issueId, commentId: e.commentId);

      final next = s.comments.where((c) => c.id != e.commentId).toList();
      emit(s.copyWith(comments: next, deleting: false));
    } on AppException catch (ex) {
      emit(s.copyWith(deleting: false));
      emit(CommentsFailure(ex.message));
      emit(s);
    } catch (ex) {
      emit(s.copyWith(deleting: false));
      emit(CommentsFailure(ex.toString()));
      emit(s);
    }
  }
}
