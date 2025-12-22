import 'package:equatable/equatable.dart';

sealed class ProjectsEvent extends Equatable {
  const ProjectsEvent();
  @override
  List<Object?> get props => [];
}

class ProjectsFetchRequested extends ProjectsEvent {
  const ProjectsFetchRequested();
}

class ProjectsCreateRequested extends ProjectsEvent {
  final String name;
  final String key;
  final String? description;

  const ProjectsCreateRequested({
    required this.name,
    required this.key,
    this.description,
  });

  @override
  List<Object?> get props => [name, key, description];
}

class ProjectsDeleteRequested extends ProjectsEvent {
  final String projectId;
  const ProjectsDeleteRequested(this.projectId);

  @override
  List<Object?> get props => [projectId];
}

// ✅ NEW
class ProjectsFavoriteToggled extends ProjectsEvent {
  final String projectId;
  final bool value;
  const ProjectsFavoriteToggled({required this.projectId, required this.value});

  @override
  List<Object?> get props => [projectId, value];
}

class ProjectsPinnedToggled extends ProjectsEvent {
  final String projectId;
  final bool value;
  const ProjectsPinnedToggled({required this.projectId, required this.value});

  @override
  List<Object?> get props => [projectId, value];
}


class ProjectsEditRequested extends ProjectsEvent {
  final String projectId;
  final String? name;
  final String? key;
  final String? description;

  const ProjectsEditRequested({
    required this.projectId,
    this.name,
    this.key,
    this.description,
  });

  @override
  List<Object?> get props => [projectId, name, key, description];
}