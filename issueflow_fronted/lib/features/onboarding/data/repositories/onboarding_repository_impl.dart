import 'package:issueflow_fronted/features/onboarding/domain/entities/onboarding_payload.dart';

import 'package:issueflow_fronted/features/onboarding/domain/entities/onboarding_result.dart';

import '../../domain/repositories/onboarding_repository.dart';
import '../datasources/onboarding_remote_datasource.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  final OnboardingRemoteDataSource remote;

  OnboardingRepositoryImpl(this.remote);

   @override
  Future<OnboardingResult> setup(OnboardingPayload payload) async {
    // NOTE:
    // For onboarding endpoints we assume caller already has valid access token.
    // If you want auto-refresh here too, we can reuse the same refresh logic pattern.
    return remote.setup(
      projectName: payload.projectName,
      projectKey: payload.projectKey,
      projectDescription: payload.projectDescription,
      invites: payload.invites,
      issueTitle: payload.issueTitle,
      issueDescription: payload.issueDescription,
      issueType: payload.issueType,
      issuePriority: payload.issuePriority,
    );
  }

  @override
  Future<void> complete() => remote.completeOnboarding();

}
