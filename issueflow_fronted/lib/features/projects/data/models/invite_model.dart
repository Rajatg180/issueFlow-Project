import '../../domain/entities/invite_entity.dart';

class InviteModel extends InviteEntity {
  const InviteModel({
    required super.id,
    required super.projectId,
    required super.projectName, // ✅ NEW
    required super.email,
    required super.token,
    required super.status,
    required super.invitedByUserId, // ✅ NEW
    required super.invitedByEmail, // ✅ NEW
    required super.createdAt,
    required super.expiresAt,
  });

  factory InviteModel.fromJson(Map<String, dynamic> json) {
    return InviteModel(
      id: (json["id"] ?? "").toString(),
      projectId: (json["project_id"] ?? "").toString(),

      // ✅ NEW
      projectName: (json["project_name"] ?? "").toString(),

      email: (json["email"] ?? "").toString(),
      token: (json["token"] ?? "").toString(),
      status: (json["status"] ?? "").toString(),

      // ✅ NEW
      invitedByUserId: (json["invited_by_user_id"] ?? "").toString(),
      invitedByEmail: (json["invited_by_username"] ?? "").toString(),

      createdAt: DateTime.parse((json["created_at"] ?? "").toString()),
      expiresAt: DateTime.parse((json["expires_at"] ?? "").toString()),
    );
  }

  static List<InviteModel> listFromJson(dynamic json) {
    if (json is Map && json["invites"] is List) {
      return (json["invites"] as List)
          .map((e) => InviteModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
