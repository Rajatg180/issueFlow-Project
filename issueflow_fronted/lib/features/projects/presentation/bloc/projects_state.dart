import 'package:equatable/equatable.dart';
import '../../domain/entities/project_entity.dart';

class ProjectsState extends Equatable {
  final bool loading;
  final bool creating;
  final String? deletingId;

  // ✅ optional: show spinner on tile when toggling
  final String? updatingPrefId;

  final List<ProjectEntity> items;
  final String? error;

  const ProjectsState({
    required this.loading,
    required this.creating,
    required this.items,
    this.deletingId,
    this.updatingPrefId,
    this.error,
  });

  factory ProjectsState.initial() => const ProjectsState(
        loading: false,
        creating: false,
        items: [],
        deletingId: null,
        updatingPrefId: null,
        error: null,
      );

  ProjectsState copyWith({
    bool? loading,
    bool? creating,
    List<ProjectEntity>? items,
    String? deletingId,
    String? updatingPrefId,
    String? error,
  }) {
    return ProjectsState(
      loading: loading ?? this.loading,
      creating: creating ?? this.creating,
      items: items ?? this.items,
      deletingId: deletingId,
      updatingPrefId: updatingPrefId,
      error: error,
    );
  }

  @override
  List<Object?> get props => [loading, creating, deletingId, updatingPrefId, items, error];
}
