class UserMiniEntity {
  final String id;
  final String username;

  const UserMiniEntity({
    required this.id,
    required this.username,
  });

  String get displayName => username; 
}
