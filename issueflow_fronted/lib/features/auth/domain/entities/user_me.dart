class UserMe {
  final String id;
  final String email;
  final String username; // ✅ NEW
  final bool hasCompletedOnboarding;

  const UserMe({
    required this.id,
    required this.email,
    required this.username,
    required this.hasCompletedOnboarding,
  });
}
