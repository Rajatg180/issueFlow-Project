import '../../domain/entities/project_with_issues_entity.dart';

abstract class IssuesState {
  const IssuesState();
}

class IssuesInitial extends IssuesState {
  const IssuesInitial();
}

class IssuesLoading extends IssuesState {
  const IssuesLoading();
}

class IssuesLoaded extends IssuesState {
  final List<ProjectWithIssuesEntity> projects;
  final Set<String> expandedProjectIds;

  // ✅ NEW: used to disable "Create issue" button while request running
  final bool isCreating;

  const IssuesLoaded({
    required this.projects,
    required this.expandedProjectIds,
    this.isCreating = false,
  });

  bool isExpanded(String projectId) => expandedProjectIds.contains(projectId);

  IssuesLoaded copyWith({
    List<ProjectWithIssuesEntity>? projects,
    Set<String>? expandedProjectIds,
    bool? isCreating,
  }) {
    return IssuesLoaded(
      projects: projects ?? this.projects,
      expandedProjectIds: expandedProjectIds ?? this.expandedProjectIds,
      isCreating: isCreating ?? this.isCreating,
    );
  }
}

class IssuesFailure extends IssuesState {
  final String message;
  const IssuesFailure(this.message);
}
