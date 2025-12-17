import 'package:equatable/equatable.dart';
import '../../domain/entities/onboarding_result.dart';

/// States for onboarding flow.
sealed class OnboardingState extends Equatable {
  const OnboardingState();

  @override
  List<Object?> get props => [];
}

class OnboardingInitial extends OnboardingState {
  const OnboardingInitial();
}

class OnboardingLoading extends OnboardingState {
  const OnboardingLoading();
}

/// Setup succeeded -> backend returned ids/keys
class OnboardingSuccess extends OnboardingState {
  final OnboardingResult result;

  const OnboardingSuccess(this.result);

  @override
  List<Object?> get props => [result];
}

/// Skip succeeded
class OnboardingSkipSuccess extends OnboardingState {
  const OnboardingSkipSuccess();
}

class OnboardingFailure extends OnboardingState {
  final String message;

  const OnboardingFailure(this.message);

  @override
  List<Object?> get props => [message];
}
