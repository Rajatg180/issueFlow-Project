import '../../domain/entities/user_me.dart';

class UserMeModel extends UserMe {
  const UserMeModel({
    required super.id,
    required super.email,
    required super.hasCompletedOnboarding,
  });

  factory UserMeModel.fromJson(Map<String, dynamic> json) {
    return UserMeModel(
      id: json["id"] as String,
      email: json["email"] as String,
      hasCompletedOnboarding: json["has_completed_onboarding"] as bool,
    );
  }
}
