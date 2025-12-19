import '../../domain/entities/project_entity.dart';

class ProjectModel extends ProjectEntity {
  const ProjectModel({
    required super.id,
    required super.name,
    required super.key,
    super.description,
    required super.createdAt,
    required super.isFavorite,
    required super.isPinned,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    final createdRaw = json["created_at"];

    return ProjectModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      key: (json['key'] ?? '').toString(),
      description: json['description']?.toString(),
      createdAt: createdRaw is String && createdRaw.isNotEmpty
          ? DateTime.parse(createdRaw)
          : DateTime.fromMillisecondsSinceEpoch(0),
      isFavorite: (json["is_favorite"] as bool?) ?? false,
      isPinned: (json["is_pinned"] as bool?) ?? false,
    );
  }

  static List<ProjectModel> listFromJson(dynamic json) {
    if (json is! List) return [];
    return json.map((e) => ProjectModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
