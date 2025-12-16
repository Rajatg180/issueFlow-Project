import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/shell/presentation/pages/shell_page.dart';

/// AppGate decides which screen to show:
/// - Login/Register (not authenticated)
/// - Onboarding (authenticated but first-time)
/// - Shell (authenticated and onboarding done)
class AppGate extends StatelessWidget {
  const AppGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        // ✅ Show a loader while any auth request is running
        if (state is AuthInitial || state is AuthLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is Unauthenticated) {
          return const LoginPage();
        }

        if (state is Authenticated) {
          if (!state.hasCompletedOnboarding) {
            return const OnboardingPage();
          }
          return const ShellPage();
        }

        // Fallback
        return const LoginPage();
      },
    );
  }
}
