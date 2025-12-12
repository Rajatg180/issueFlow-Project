import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:issueflow_fronted/features/shell/presentation/bloc/shell_bloc.dart';

import 'core/theme/app_theme.dart';
import 'core/routing/app_gate.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';

void main() {
  runApp(const IssueFlowApp());
}

class IssueFlowApp extends StatelessWidget {
  const IssueFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc()..add(const AuthAppStarted()),
        ),
        BlocProvider(create: (_) => ShellBloc() )
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        home: const AppGate(),
      ),
    );
  }
}
