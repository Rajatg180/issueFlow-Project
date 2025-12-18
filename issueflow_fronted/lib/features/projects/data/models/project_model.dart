import '../../domain/entities/project_entity.dart';

class ProjectModel extends ProjectEntity {
  const ProjectModel({
    required super.id,
    required super.name,
    required super.key,
    super.description,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      key: (json['key'] ?? '').toString(),
      description: json['description']?.toString(),
    );
  }

  static List<ProjectModel> listFromJson(dynamic json) {
    if (json is! List) return [];
    return json
        .map((e) => ProjectModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
