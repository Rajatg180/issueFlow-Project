class ProjectEntity {
  final String id;
  final String name;
  final String key;
  final String? description;
  final DateTime createdAt;

  final bool isFavorite;
  final bool isPinned;

  const ProjectEntity({
    required this.id,
    required this.name,
    required this.key,
    this.description,
    required this.createdAt,
    required this.isFavorite,
    required this.isPinned,
  });

  ProjectEntity copyWith({
    String? id,
    String? name,
    String? key,
    String? description,
    DateTime? createdAt,
    bool? isFavorite,
    bool? isPinned,
  }) {
    return ProjectEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      key: key ?? this.key,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}
