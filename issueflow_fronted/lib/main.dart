import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:issueflow_fronted/core/network/backend_wrmup.dart';
import 'core/di/service_locator.dart';
import 'core/routing/app_gate.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/shell/presentation/bloc/shell_bloc.dart';
import 'package:issueflow_fronted/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:issueflow_fronted/features/issues/presentation/bloc/comments/comments_bloc.dart';
import 'package:issueflow_fronted/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:issueflow_fronted/features/projects/presentation/bloc/invite/invites_bloc.dart';
import 'package:issueflow_fronted/features/projects/presentation/cubit/invite_members_cubit.dart';
import 'package:issueflow_fronted/features/projects/presentation/bloc/project/projects_bloc.dart';
import 'package:issueflow_fronted/features/issues/presentation/bloc/issues/issues_bloc.dart';
import 'firebase_options.dart';
import 'dart:async';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await setupServiceLocator();

  // Warm up backend connection do start the backend early
  unawaited(BackendWarmup.ping());

  runApp(const IssueFlowApp());
}

class IssueFlowApp extends StatelessWidget {
  const IssueFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => sl<AuthBloc>()..add(const AuthAppStarted()),
        ),
        BlocProvider(create: (_) => ShellBloc()),
        BlocProvider(create: (_) => sl<OnboardingBloc>()),
        BlocProvider(create: (_) => sl<ProjectsBloc>()),
        BlocProvider(create: (_) => sl<InvitesBloc>()),
        BlocProvider(create: (_) => sl<InviteMembersCubit>()),
        BlocProvider(create: (_) => sl<IssuesBloc>()),
        BlocProvider(create: (_) => sl<CommentsBloc>()),
        BlocProvider(create: (_) => sl<DashboardBloc>()),
        BlocProvider(create: (_) => sl<ThemeCubit>()..load()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, mode) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(), 
            themeMode: mode, 
            home: const AppGate(),
          );
        },
      ),
    );
  }
}
