import '../entities/onboarding_payload.dart';
import '../entities/onboarding_result.dart';

abstract class OnboardingRepository {
  Future<OnboardingResult> setup(OnboardingPayload payload);
  Future<void> complete();
}
