import 'package:equatable/equatable.dart';
import '../../domain/entities/onboarding_payload.dart';

/// Events for onboarding flow UI.
sealed class OnboardingEvent extends Equatable {
  const OnboardingEvent();

  @override
  List<Object?> get props => [];
}

/// User clicks "Finish setup" -> send full payload to backend
class OnboardingSetupRequested extends OnboardingEvent {
  final OnboardingPayload payload;

  const OnboardingSetupRequested(this.payload);

  @override
  List<Object?> get props => [payload];
}

/// User clicks "Skip" -> mark onboarding completed on backend
class OnboardingSkipRequested extends OnboardingEvent {
  const OnboardingSkipRequested();
}
