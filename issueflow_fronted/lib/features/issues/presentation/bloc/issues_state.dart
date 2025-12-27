import '../../domain/entities/project_with_issues_entity.dart';
import 'package:issueflow_fronted/features/issues/domain/entities/project_user_entity.dart';

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

  final bool isCreating;

  final Map<String, List<ProjectUserEntity>> projectUsers;

  const IssuesLoaded({
    required this.projects,
    required this.expandedProjectIds,
    this.isCreating = false,
    this.projectUsers = const {},
  });

  bool isExpanded(String projectId) => expandedProjectIds.contains(projectId);

  IssuesLoaded copyWith({
    List<ProjectWithIssuesEntity>? projects,
    Set<String>? expandedProjectIds,
    bool? isCreating,
    Map<String, List<ProjectUserEntity>>? projectUsers,
  }) {
    return IssuesLoaded(
      projects: projects ?? this.projects,
      expandedProjectIds: expandedProjectIds ?? this.expandedProjectIds,
      isCreating: isCreating ?? this.isCreating,
      projectUsers: projectUsers ?? this.projectUsers,
    );
  }
}

class IssuesFailure extends IssuesState {
  final String message;
  const IssuesFailure(this.message);
}
