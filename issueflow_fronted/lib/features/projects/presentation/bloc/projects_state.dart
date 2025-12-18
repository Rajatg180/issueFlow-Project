import '../../domain/entities/project_entity.dart';

class ProjectsState {
  final bool loading;
  final bool creating;
  final List<ProjectEntity> items;
  final String? error;

  const ProjectsState({
    required this.loading,
    required this.creating,
    required this.items,
    this.error,
  });

  factory ProjectsState.initial() {
    return const ProjectsState(
      loading: false,
      creating: false,
      items: [],
      error: null,
    );
  }

  ProjectsState copyWith({
    bool? loading,
    bool? creating,
    List<ProjectEntity>? items,
    String? error,
  }) {
    return ProjectsState(
      loading: loading ?? this.loading,
      creating: creating ?? this.creating,
      items: items ?? this.items,
      error: error,
    );
  }
}
