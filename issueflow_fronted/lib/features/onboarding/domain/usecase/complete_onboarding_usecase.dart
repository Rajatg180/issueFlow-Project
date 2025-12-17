import '../repositories/onboarding_repository.dart';

class CompleteOnboardingUseCase {
  final OnboardingRepository repo;

  CompleteOnboardingUseCase(this.repo);

  Future<void> call() => repo.complete();
}
