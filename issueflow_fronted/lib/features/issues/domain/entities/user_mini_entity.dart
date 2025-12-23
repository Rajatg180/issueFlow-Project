class UserMiniEntity {
  final String id;
  final String email;

  const UserMiniEntity({
    required this.id,
    required this.email,
  });

  String get displayName => email; 
}
