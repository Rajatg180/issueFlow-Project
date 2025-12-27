import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:issueflow_fronted/features/issues/domain/usecase/create_issue_usecase.dart';
import 'package:issueflow_fronted/features/issues/domain/usecase/delete_issue_usecase.dart';
import 'package:issueflow_fronted/features/issues/domain/usecase/get_projects_with_issues_usecase.dart';
import 'package:issueflow_fronted/features/issues/domain/usecase/get_project_users_usecase.dart';
import 'package:issueflow_fronted/features/issues/domain/usecase/update_issue_usecase.dart';

import '../../../../core/errors/app_exception.dart';
import 'issues_event.dart';
import 'issues_state.dart';

class IssuesBloc extends Bloc<IssuesEvent, IssuesState> {
  final GetProjectsWithIssuesUseCase getProjectsWithIssues;
  final CreateIssueUseCase createIssue;
  final GetProjectUsersUseCase getProjectUsers;
  final UpdateIssueUseCase updateIssue; 
  final DeleteIssueUsecase deleteIssue;
  
  IssuesBloc({
    required this.getProjectsWithIssues,
    required this.createIssue,
    required this.getProjectUsers,
    required this.updateIssue,
    required this.deleteIssue,
  }) : super(const IssuesInitial()) {
    on<IssuesLoadRequested>(_onLoad);
    on<IssuesProjectToggled>(_onToggle);
    on<IssueCreateRequested>(_onCreateIssue);
    on<ProjectUsersRequested>(_onProjectUsersRequested);
    on<IssueUpdateRequested>(_onUpdateIssue);
    on<IssueDeleteRequested>(_onDeleteIssue);
  }

  Future<void> _onLoad(IssuesLoadRequested event, Emitter<IssuesState> emit) async {
    emit(const IssuesLoading());
    try {
      final projects = await getProjectsWithIssues();
      emit(IssuesLoaded(projects: projects, expandedProjectIds: <String>{}));
    } on AppException catch (e) {
      emit(IssuesFailure(e.message));
    } catch (e) {
      emit(IssuesFailure(e.toString()));
    }
  }

  void _onToggle(IssuesProjectToggled event, Emitter<IssuesState> emit) {
    final s = state;
    if (s is! IssuesLoaded) return;

    final next = Set<String>.from(s.expandedProjectIds);
    final isExpanding = !next.contains(event.projectId);

    if (next.contains(event.projectId)) {
      next.remove(event.projectId);
    } else {
      next.add(event.projectId);
    }

    emit(s.copyWith(expandedProjectIds: next));

    if (isExpanding && !s.projectUsers.containsKey(event.projectId)) {
      add(ProjectUsersRequested(event.projectId));
    }
  }

  Future<void> _onCreateIssue(IssueCreateRequested event, Emitter<IssuesState> emit) async {
    final s = state;
    if (s is! IssuesLoaded) return;

    emit(s.copyWith(isCreating: true));

    try {
      await createIssue(
        projectId: event.projectId,
        title: event.title,
        description: event.description,
        type: event.type,
        priority: event.priority,
        dueDate: event.dueDate,
      );

      final updated = await getProjectsWithIssues();
      emit(s.copyWith(projects: updated, isCreating: false));
    } on AppException catch (e) {
      emit(s.copyWith(isCreating: false));
      emit(IssuesFailure(e.message));

      final stable = await getProjectsWithIssues();
      emit(IssuesLoaded(
        projects: stable,
        expandedProjectIds: s.expandedProjectIds,
        projectUsers: s.projectUsers,
      ));
    } catch (e) {
      emit(s.copyWith(isCreating: false));
      emit(IssuesFailure(e.toString()));

      final stable = await getProjectsWithIssues();
      emit(IssuesLoaded(
        projects: stable,
        expandedProjectIds: s.expandedProjectIds,
        projectUsers: s.projectUsers,
      ));
    }
  }

  Future<void> _onProjectUsersRequested(
    ProjectUsersRequested event,
    Emitter<IssuesState> emit,
  ) async {
    final s = state;
    if (s is! IssuesLoaded) return;

    try {
      final users = await getProjectUsers(projectId: event.projectId);
      final next = Map<String, dynamic>.from(s.projectUsers);
      next[event.projectId] = users;

      emit(s.copyWith(projectUsers: next.cast()));
    } catch (_) {
      // silent
    }
  }

  Future<void> _onUpdateIssue(IssueUpdateRequested event, Emitter<IssuesState> emit) async {
    final s = state;
    if (s is! IssuesLoaded) return;

    emit(s.copyWith(isUpdating: true));

    try {
      await updateIssue(
        projectId: event.projectId,
        issueId: event.issueId,
        title: event.title,
        description: event.description,
        type: event.type,
        priority: event.priority,
        status: event.status,
        dueDate: event.dueDate,
        assigneeId: event.assigneeId,
        reporterId: event.reporterId,
      );

      final updated = await getProjectsWithIssues();

      // show toast
      emit(s.copyWith(
        projects: updated,
        isUpdating: false,
        toastMessage: "Issue updated",
      ));

      // clear toast after emitting (so it doesn't re-show)
      emit((state as IssuesLoaded).copyWith(clearToast: true));
    } on AppException catch (e) {
      emit(s.copyWith(isUpdating: false));
      emit(IssuesFailure(e.message));

      final stable = await getProjectsWithIssues();
      emit(IssuesLoaded(
        projects: stable,
        expandedProjectIds: s.expandedProjectIds,
        projectUsers: s.projectUsers,
      ));
    } catch (e) {
      emit(s.copyWith(isUpdating: false));
      emit(IssuesFailure(e.toString()));

      final stable = await getProjectsWithIssues();
      emit(IssuesLoaded(
        projects: stable,
        expandedProjectIds: s.expandedProjectIds,
        projectUsers: s.projectUsers,
      ));
    }
  }

  Future<void> _onDeleteIssue(IssueDeleteRequested event, Emitter<IssuesState> emit) async {
    final s = state;
    if (s is! IssuesLoaded) return;

    emit(s.copyWith(isUpdating: true));

    try {
      await deleteIssue(
        projectId: event.projectId,
        issueId: event.issueId,
      );

      final updated = await getProjectsWithIssues();

      // show toast
      emit(s.copyWith(
        projects: updated,
        isUpdating: false,
        toastMessage: "Issue deleted",
      ));

      // clear toast after emitting (so it doesn't re-show)
      emit((state as IssuesLoaded).copyWith(clearToast: true));
    } on AppException catch (e) {
      emit(s.copyWith(isUpdating: false));
      emit(IssuesFailure(e.message));

      final stable = await getProjectsWithIssues();
      emit(IssuesLoaded(
        projects: stable,
        expandedProjectIds: s.expandedProjectIds,
        projectUsers: s.projectUsers,
      ));
    } catch (e) {
      emit(s.copyWith(isUpdating: false));
      emit(IssuesFailure(e.toString()));

      final stable = await getProjectsWithIssues();
      emit(IssuesLoaded(
        projects: stable,
        expandedProjectIds: s.expandedProjectIds,
        projectUsers: s.projectUsers,
      ));
    }
  }
}
