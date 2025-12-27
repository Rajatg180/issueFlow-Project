import '../../domain/entities/user_mini_entity.dart';

class UserMiniModel extends UserMiniEntity {
  const UserMiniModel({
    required super.id,
    required super.username,
  });

  factory UserMiniModel.fromJson(Map<String, dynamic> json) {
    return UserMiniModel(
      id: (json['id'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
    );
  }
}
