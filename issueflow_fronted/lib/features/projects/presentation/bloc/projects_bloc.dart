import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/create_project_usecase.dart';
import '../../domain/usecases/list_projects_usecase.dart';
import 'projects_event.dart';
import 'projects_state.dart';

class ProjectsBloc extends Bloc<ProjectsEvent, ProjectsState> {
  final ListProjectsUseCase listProjectsUseCase;
  final CreateProjectUseCase createProjectUseCase;

  ProjectsBloc({
    required this.listProjectsUseCase,
    required this.createProjectUseCase,
  }) : super(ProjectsState.initial()) {
    on<ProjectsFetchRequested>(_onFetch);
    on<ProjectsCreateRequested>(_onCreate);
  }

  Future<void> _onFetch(
    ProjectsFetchRequested event,
    Emitter<ProjectsState> emit,
  ) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final items = await listProjectsUseCase();
      emit(state.copyWith(loading: false, items: items, error: null));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> _onCreate(
    ProjectsCreateRequested event,
    Emitter<ProjectsState> emit,
  ) async {
    emit(state.copyWith(creating: true, error: null));
    try {
      await createProjectUseCase(
        name: event.name,
        key: event.key,
        description: event.description,
      );

      emit(state.copyWith(creating: false));
      add(const ProjectsFetchRequested());
    } catch (e) {
      emit(state.copyWith(creating: false, error: e.toString()));
    }
  }
}
