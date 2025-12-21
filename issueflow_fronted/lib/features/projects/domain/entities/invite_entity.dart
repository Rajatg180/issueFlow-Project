class InviteEntity {
  final String id;
  final String projectId;

  // ✅ NEW
  final String projectName;

  final String email;
  final String token;
  final String status;

  // ✅ NEW
  final String invitedByUserId;
  final String invitedByEmail;

  final DateTime createdAt;
  final DateTime expiresAt;

  const InviteEntity({
    required this.id,
    required this.projectId,
    required this.projectName, // ✅ NEW
    required this.email,
    required this.token,
    required this.status,
    required this.invitedByUserId, // ✅ NEW
    required this.invitedByEmail, // ✅ NEW
    required this.createdAt,
    required this.expiresAt,
  });
}
