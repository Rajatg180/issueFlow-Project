class OnboardingResult {
  final String projectId;
  final String projectKey;
  final String firstIssueId;
  final String firstIssueKey;
  final bool hasCompletedOnboarding;

  const OnboardingResult({
    required this.projectId,
    required this.projectKey,
    required this.firstIssueId,
    required this.firstIssueKey,
    required this.hasCompletedOnboarding,
  });
}
