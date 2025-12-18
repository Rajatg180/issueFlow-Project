abstract class ProjectsEvent {
  const ProjectsEvent();
}

class ProjectsFetchRequested extends ProjectsEvent {
  const ProjectsFetchRequested();
}

class ProjectsCreateRequested extends ProjectsEvent {
  const ProjectsCreateRequested({
    required this.name,
    required this.key,
    this.description,
  });

  final String name;
  final String key;
  final String? description;
}
