import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/project_entity.dart';
import '../../../domain/usecases/create_project_usecase.dart';
import '../../../domain/usecases/delete_project_usecase.dart';
import '../../../domain/usecases/list_projects_usecase.dart';
import '../../../domain/usecases/update_project_preference_usecase.dart';
import 'projects_event.dart';
import 'projects_state.dart';

class ProjectsBloc extends Bloc<ProjectsEvent, ProjectsState> {
  final ListProjectsUseCase listProjectsUseCase;
  final CreateProjectUseCase createProjectUseCase;
  final DeleteProjectUseCase deleteProjectUseCase;

  // ✅ NEW
  final UpdateProjectPreferenceUseCase updateProjectPreferenceUseCase;

  ProjectsBloc({
    required this.listProjectsUseCase,
    required this.createProjectUseCase,
    required this.deleteProjectUseCase,
    required this.updateProjectPreferenceUseCase,
  }) : super(ProjectsState.initial()) {
    on<ProjectsFetchRequested>(_onFetch);
    on<ProjectsCreateRequested>(_onCreate);
    on<ProjectsDeleteRequested>(_onDelete);

    // ✅ NEW
    on<ProjectsFavoriteToggled>(_onToggleFavorite);
    on<ProjectsPinnedToggled>(_onTogglePinned);
  }

  Future<void> _onFetch(ProjectsFetchRequested event, Emitter<ProjectsState> emit) async {
    emit(state.copyWith(loading: true, error: null, deletingId: null, updatingPrefId: null));
    try {
      final items = await listProjectsUseCase();
      emit(state.copyWith(loading: false, items: _sorted(items), error: null));
    } catch (e) {
      emit(state.copyWith(loading: false, error: _cleanErr(e)));
    }
  }

  Future<void> _onCreate(ProjectsCreateRequested event, Emitter<ProjectsState> emit) async {
    emit(state.copyWith(creating: true, error: null));
    try {
      await createProjectUseCase(name: event.name, key: event.key, description: event.description);
      final items = await listProjectsUseCase();
      emit(state.copyWith(creating: false, items: _sorted(items), error: null));
    } catch (e) {
      emit(state.copyWith(creating: false, error: _cleanErr(e)));
    }
  }

  Future<void> _onDelete(ProjectsDeleteRequested event, Emitter<ProjectsState> emit) async {
    emit(state.copyWith(deletingId: event.projectId, error: null));
    try {
      await deleteProjectUseCase(event.projectId);
      final newItems = state.items.where((p) => p.id != event.projectId).toList();
      emit(state.copyWith(deletingId: null, items: _sorted(newItems), error: null));
    } catch (e) {
      emit(state.copyWith(deletingId: null, error: _cleanErr(e)));
    }
  }

  Future<void> _onToggleFavorite(ProjectsFavoriteToggled event, Emitter<ProjectsState> emit) async {
    final prev = state.items;
    final next = _patchLocal(prev, event.projectId, (p) => p.copyWith(isFavorite: event.value));
    emit(state.copyWith(items: _sorted(next), updatingPrefId: event.projectId, error: null));

    try {
      final updated = await updateProjectPreferenceUseCase(
        event.projectId,
        isFavorite: event.value,
      );

      final merged = _replaceOne(state.items, updated);
      emit(state.copyWith(items: _sorted(merged), updatingPrefId: null, error: null));
    } catch (e) {
      // revert
      emit(state.copyWith(items: _sorted(prev), updatingPrefId: null, error: _cleanErr(e)));
    }
  }

  Future<void> _onTogglePinned(ProjectsPinnedToggled event, Emitter<ProjectsState> emit) async {
    final prev = state.items;
    final next = _patchLocal(prev, event.projectId, (p) => p.copyWith(isPinned: event.value));
    emit(state.copyWith(items: _sorted(next), updatingPrefId: event.projectId, error: null));

    try {
      final updated = await updateProjectPreferenceUseCase(
        event.projectId,
        isPinned: event.value,
      );

      final merged = _replaceOne(state.items, updated);
      emit(state.copyWith(items: _sorted(merged), updatingPrefId: null, error: null));
    } catch (e) {
      emit(state.copyWith(items: _sorted(prev), updatingPrefId: null, error: _cleanErr(e)));
    }
  }

  // ---------- helpers ----------

  String _cleanErr(Object e) => e.toString().replaceFirst("Exception: ", "");

  List<ProjectEntity> _replaceOne(List<ProjectEntity> items, ProjectEntity updated) {
    return items.map((p) => p.id == updated.id ? updated : p).toList();
  }

  List<ProjectEntity> _patchLocal(
    List<ProjectEntity> items,
    String id,
    ProjectEntity Function(ProjectEntity p) fn,
  ) {
    return items.map((p) => p.id == id ? fn(p) : p).toList();
  }

  // Jira-like ordering:
  // pinned first, then favorite, then newest created
  List<ProjectEntity> _sorted(List<ProjectEntity> items) {
    final sorted = [...items];
    sorted.sort((a, b) {
      final pin = (b.isPinned ? 1 : 0) - (a.isPinned ? 1 : 0);
      if (pin != 0) return pin;

      final fav = (b.isFavorite ? 1 : 0) - (a.isFavorite ? 1 : 0);
      if (fav != 0) return fav;

      return b.createdAt.compareTo(a.createdAt);
    });
    return sorted;
  }
}
