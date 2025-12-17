import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/onboarding_payload.dart';
import '../../domain/usecase/setup_onboarding_usecase.dart';
import '../../domain/usecase/complete_onboarding_usecase.dart';
import 'onboarding_event.dart';
import 'onboarding_state.dart';

/// BLoC for onboarding setup + skip.
///
/// IMPORTANT:
/// - This bloc does NOT navigate.
/// - UI listens to success states and triggers AuthBloc refresh / navigation indirectly via AppGate.
class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final SetupOnboardingUseCase setupOnboardingUseCase;
  final CompleteOnboardingUseCase completeOnboardingUseCase;

  OnboardingBloc({
    required this.setupOnboardingUseCase,
    required this.completeOnboardingUseCase,
  }) : super(const OnboardingInitial()) {
    on<OnboardingSetupRequested>(_onSetup);
    on<OnboardingSkipRequested>(_onSkip);
  }

  Future<void> _onSetup(
    OnboardingSetupRequested event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(const OnboardingLoading());

    try {
      final result = await setupOnboardingUseCase(event.payload);
      emit(OnboardingSuccess(result));
    } on AppException catch (e) {
      emit(OnboardingFailure(e.message));
      emit(const OnboardingInitial());
    } catch (e) {
      emit(OnboardingFailure(e.toString().replaceFirst("Exception: ", "")));
      emit(const OnboardingInitial());
    }
  }

  Future<void> _onSkip(
    OnboardingSkipRequested event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(const OnboardingLoading());

    try {
      await completeOnboardingUseCase();
      emit(const OnboardingSkipSuccess());
    } on AppException catch (e) {
      emit(OnboardingFailure(e.message));
      emit(const OnboardingInitial());
    } catch (e) {
      emit(OnboardingFailure(e.toString().replaceFirst("Exception: ", "")));
      emit(const OnboardingInitial());
    }
  }
}
