import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:issueflow_fronted/features/issues/data/realtime/comments_ws_client.dart';

import '../../../../../core/errors/app_exception.dart';
import '../../../domain/entities/issue_comment_entity.dart';
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
  final CommentsWsClient wsClient;

  CommentsBloc({
    required this.getComments,
    required this.createComment,
    required this.updateComment,
    required this.deleteComment,
    required this.wsClient,
  }) : super(const CommentsInitial()) {
    on<CommentsOpenRequested>(_onOpen);
    on<CommentsCloseRequested>(_onClose);

    on<CommentSendRequested>(_onSend);
    on<CommentEditRequested>(_onEdit);
    on<CommentDeleteRequested>(_onDelete);

    on<CommentsWsEventReceived>(_onWsEvent);
  }

  Future<void> _onOpen(CommentsOpenRequested e, Emitter<CommentsState> emit) async {
    emit(const CommentsLoading());

    try {
      final list = await getComments(projectId: e.projectId, issueId: e.issueId);

      emit(CommentsLoaded(
        projectId: e.projectId,
        issueId: e.issueId,
        comments: list,
      ));

      // 2) Connect WebSocket for realtime updates
      await wsClient.connect(
        projectId: e.projectId,
        issueId: e.issueId,
        onEvent: (evt) {
          add(CommentsWsEventReceived(evt));
        },
      );
    } on AppException catch (ex) {
      emit(CommentsFailure(ex.message));
    } catch (ex) {
      emit(CommentsFailure(ex.toString()));
    }
  }

  Future<void> _onClose(CommentsCloseRequested e, Emitter<CommentsState> emit) async {
    await wsClient.disconnect();
    // keep last state as-is (no need to reset unless you want)
  }

  Future<void> _onSend(CommentSendRequested e, Emitter<CommentsState> emit) async {
    final s = state;
    if (s is! CommentsLoaded) return;

    emit(s.copyWith(sending: true));
    try {
      // HTTP creates comment -> backend broadcasts -> WS will update others.
      final created = await createComment(projectId: e.projectId, issueId: e.issueId, body: e.body);

      // ✅ Avoid duplicates:
      // If WS event arrives quickly, it might already exist.
      final exists = s.comments.any((c) => c.id == created.id);
      final next = exists ? s.comments : (List.of(s.comments)..add(created));

      emit(s.copyWith(comments: next, sending: false));
    } on AppException catch (ex) {
      emit(s.copyWith(sending: false));
      emit(CommentsFailure(ex.message));
      emit(s);
    } catch (ex) {
      emit(s.copyWith(sending: false));
      emit(CommentsFailure(ex.toString()));
      emit(s);
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

  void _onWsEvent(CommentsWsEventReceived e, Emitter<CommentsState> emit) {
    final s = state;
    if (s is! CommentsLoaded) return;

    final evt = e.event;
    final type = (evt["type"] ?? "").toString();

    // Ensure it belongs to same room
    final projectId = (evt["project_id"] ?? "").toString();
    final issueId = (evt["issue_id"] ?? "").toString();
    if (projectId != s.projectId || issueId != s.issueId) return;

    // snapshot message optional (your backend sends it)
    if (type == "snapshot") {
      final list = evt["comments"];
      if (list is List) {
        // Convert into IssueCommentEntity using your existing model factory logic is ideal,
        // but since this is domain entity, simplest is: keep HTTP as source of truth.
        // So we can ignore snapshot, OR you can map it if you want.
      }
      return;
    }

    // comment_created
    if (type == "comment_created") {
      final c = evt["comment"];
      if (c is Map) {
        final id = (c["id"] ?? "").toString();
        if (id.isEmpty) return;

        // De-dupe
        if (s.comments.any((x) => x.id == id)) return;

        // Since WS payload matches your model json keys,
        // easiest is to create a lightweight entity:
        final created = IssueCommentEntity(
          id: id,
          projectId: (c["project_id"] ?? "").toString(),
          issueId: (c["issue_id"] ?? "").toString(),
          authorId: (c["author_id"] ?? "").toString(),
          authorUsername: (c["author_username"] ?? "").toString(),
          body: (c["body"] ?? "").toString(),
          edited: (c["edited"] ?? false) == true,
          createdAt: DateTime.tryParse((c["created_at"] ?? "").toString()) ?? DateTime.fromMillisecondsSinceEpoch(0),
          updatedAt: DateTime.tryParse((c["updated_at"] ?? "").toString()) ?? DateTime.fromMillisecondsSinceEpoch(0),
        );

        emit(s.copyWith(comments: List.of(s.comments)..add(created)));
      }
      return;
    }

    // comment_updated
    if (type == "comment_updated") {
      final c = evt["comment"];
      if (c is Map) {
        final id = (c["id"] ?? "").toString();
        if (id.isEmpty) return;

        final updated = IssueCommentEntity(
          id: id,
          projectId: (c["project_id"] ?? "").toString(),
          issueId: (c["issue_id"] ?? "").toString(),
          authorId: (c["author_id"] ?? "").toString(),
          authorUsername: (c["author_username"] ?? "").toString(),
          body: (c["body"] ?? "").toString(),
          edited: (c["edited"] ?? false) == true,
          createdAt: DateTime.tryParse((c["created_at"] ?? "").toString()) ?? DateTime.fromMillisecondsSinceEpoch(0),
          updatedAt: DateTime.tryParse((c["updated_at"] ?? "").toString()) ?? DateTime.fromMillisecondsSinceEpoch(0),
        );

        final next = s.comments.map((x) => x.id == id ? updated : x).toList();
        emit(s.copyWith(comments: next));
      }
      return;
    }

    // comment_deleted
    if (type == "comment_deleted") {
      final id = (evt["comment_id"] ?? "").toString();
      if (id.isEmpty) return;

      final next = s.comments.where((x) => x.id != id).toList();
      emit(s.copyWith(comments: next));
      return;
    }
  }

  @override
  Future<void> close() async {
    await wsClient.disconnect();
    return super.close();
  }
}
