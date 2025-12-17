import '../entities/onboarding_payload.dart';
import '../entities/onboarding_result.dart';
import '../repositories/onboarding_repository.dart';


class SetupOnboardingUseCase {
  final OnboardingRepository repo;

  SetupOnboardingUseCase(this.repo);

  /// Call with payload created from UI.
  Future<OnboardingResult> call(OnboardingPayload payload) {
    return repo.setup(payload);
  }
}
