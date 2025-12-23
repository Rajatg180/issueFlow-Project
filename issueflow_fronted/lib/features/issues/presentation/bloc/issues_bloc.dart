import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:issueflow_fronted/features/issues/domain/usecase/create_issue_usecase.dart';
import 'package:issueflow_fronted/features/issues/domain/usecase/get_projects_with_issues_usecase.dart';

import '../../../../core/errors/app_exception.dart';
import 'issues_event.dart';
import 'issues_state.dart';

class IssuesBloc extends Bloc<IssuesEvent, IssuesState> {
  final GetProjectsWithIssuesUseCase getProjectsWithIssues;
  final CreateIssueUseCase createIssue;

  IssuesBloc({
    required this.getProjectsWithIssues,
    required this.createIssue,
  }) : super(const IssuesInitial()) {
    on<IssuesLoadRequested>(_onLoad);
    on<IssuesProjectToggled>(_onToggle);
    on<IssueCreateRequested>(_onCreateIssue);
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
    if (next.contains(event.projectId)) {
      next.remove(event.projectId);
    } else {
      next.add(event.projectId);
    }

    emit(s.copyWith(expandedProjectIds: next));
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
        dueDate: event.dueDate, // ✅ DateTime
      );

      // refresh list to show updated issues (and reporter/assignee enrichment)
      final updated = await getProjectsWithIssues();
      emit(s.copyWith(projects: updated, isCreating: false));
    } on AppException catch (e) {
      emit(s.copyWith(isCreating: false));
      emit(IssuesFailure(e.message));

      final stable = await getProjectsWithIssues();
      emit(IssuesLoaded(projects: stable, expandedProjectIds: s.expandedProjectIds));
    } catch (e) {
      emit(s.copyWith(isCreating: false));
      emit(IssuesFailure(e.toString()));

      final stable = await getProjectsWithIssues();
      emit(IssuesLoaded(projects: stable, expandedProjectIds: s.expandedProjectIds));
    }
  }
}
