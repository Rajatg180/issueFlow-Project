import 'package:equatable/equatable.dart';
import '../../../domain/entities/project_entity.dart';

class ProjectsState extends Equatable {
  final bool loading;
  final bool creating;
  final String? error;

  final List<ProjectEntity> items;

  final String? deletingId;
  final String? updatingPrefId;

  // ✅ NEW
  final String? editingId;

  const ProjectsState({
    required this.loading,
    required this.creating,
    required this.items,
    this.error,
    this.deletingId,
    this.updatingPrefId,
    this.editingId,
  });

  factory ProjectsState.initial() => const ProjectsState(
        loading: false,
        creating: false,
        items: [],
      );

  ProjectsState copyWith({
    bool? loading,
    bool? creating,
    List<ProjectEntity>? items,
    String? error,
    String? deletingId,
    String? updatingPrefId,
    String? editingId,
  }) {
    return ProjectsState(
      loading: loading ?? this.loading,
      creating: creating ?? this.creating,
      items: items ?? this.items,
      error: error,
      deletingId: deletingId,
      updatingPrefId: updatingPrefId,
      editingId: editingId,
    );
  }

  @override
  List<Object?> get props => [
        loading,
        creating,
        error,
        items,
        deletingId,
        updatingPrefId,
        editingId,
      ];
}
