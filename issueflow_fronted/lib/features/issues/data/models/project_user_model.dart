import 'package:issueflow_fronted/features/issues/domain/entities/project_user_entity.dart';

class ProjectUserModel  extends ProjectUserEntity{

  ProjectUserModel({
    required super.id,
    required super.username,
  });

  factory ProjectUserModel.fromJson(Map<String, dynamic> json) {
    return ProjectUserModel(
      id: (json['id'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
    );
  }
}
