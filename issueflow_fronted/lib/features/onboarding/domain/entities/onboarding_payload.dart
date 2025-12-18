class OnboardingPayload {
  final String projectName;
  final String projectKey;
  final String? projectDescription;

  final List<String> invites; // optional, can be empty

  final String issueTitle;
  final String? issueDescription;
  final String issueType; // "task" | "bug" | "feature"
  final String issuePriority; // "low" | "medium" | "high"

  /// Optional due date for the first issue.
  /// If null => user didn't set it.
  final DateTime? dueDate;

  const OnboardingPayload({
    required this.projectName,
    required this.projectKey,
    this.projectDescription,
    this.invites = const [],
    required this.issueTitle,
    this.issueDescription,
    required this.issueType,
    required this.issuePriority,
    this.dueDate,
  });
}
