import '../../domain/entities/user_mini_entity.dart';

class UserMiniModel extends UserMiniEntity {
  const UserMiniModel({
    required super.id,
    required super.email,
  });

  factory UserMiniModel.fromJson(Map<String, dynamic> json) {
    return UserMiniModel(
      id: (json['id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
    );
  }
}
