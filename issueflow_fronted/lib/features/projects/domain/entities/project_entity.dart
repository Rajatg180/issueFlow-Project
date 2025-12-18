class ProjectEntity {
  final String id;
  final String name;
  final String key;
  final String? description;

  const ProjectEntity({
    required this.id,
    required this.name,
    required this.key,
    this.description,
  });
}
