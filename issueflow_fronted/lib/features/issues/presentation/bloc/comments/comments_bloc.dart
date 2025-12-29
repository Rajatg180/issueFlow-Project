import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/errors/app_exception.dart';
import '../../../domain/usecase/get_issue_comments_usecase.dart';
import '../../../domain/usecase/create_issue_comment_usecase.dart';
import 'comments_event.dart';
import 'comments_state.dart';

class CommentsBloc extends Bloc<CommentsEvent, CommentsState> {
  final GetIssueCommentsUseCase getComments;
  final CreateIssueCommentUseCase createComment;

  CommentsBloc({
    required this.getComments,
    required this.createComment,
  }) : super(const CommentsInitial()) {
    on<CommentsOpenRequested>(_onOpen);
    on<CommentSendRequested>(_onSend);
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
}
