import '../../domain/repositories/onboarding_repository.dart';
import '../datasources/onboarding_remote_datasource.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  final OnboardingRemoteDataSource remote;

  OnboardingRepositoryImpl(this.remote);

  @override
  Future<void> completeOnboarding() => remote.completeOnboarding();
}
