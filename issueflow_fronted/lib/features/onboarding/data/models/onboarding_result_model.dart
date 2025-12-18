import '../../domain/entities/onboarding_result.dart';

class OnboardingResultModel extends OnboardingResult {
  const OnboardingResultModel({
    required super.projectId,
    required super.projectKey,
    required super.firstIssueId,
    required super.firstIssueKey,
    required super.hasCompletedOnboarding,
    super.dueDate,
  });

  factory OnboardingResultModel.fromJson(Map<String, dynamic> json) {
    final due = json['due_date']; // backend sends "YYYY-MM-DD" or null

    return OnboardingResultModel(
      projectId: json['project_id'] as String,
      projectKey: json['project_key'] as String,
      firstIssueId: json['first_issue_id'] as String,
      firstIssueKey: json['first_issue_key'] as String,
      hasCompletedOnboarding: json['has_completed_onboarding'] as bool,
      dueDate: due == null ? null : DateTime.tryParse(due as String),
    );
  }
}
