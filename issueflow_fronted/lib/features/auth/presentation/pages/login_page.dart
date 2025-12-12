import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:issueflow_fronted/core/widgets/app_toast.dart';

import '../../../../core/theme/app_colors.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/auth_text_field.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<AuthBloc, AuthState>(
      // Listen for failures and show SnackBar (optional)
      listener: (context, state) {
        if (state is AuthFailure) {
          AppToast.show(context, message: state.message, isError: true);
        }
      },
      child: Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    final isLoading = state is AuthLoading;

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Sign in', style: theme.textTheme.titleLarge),
                        const SizedBox(height: 6),
                        Text(
                          'Welcome back to IssueFlow',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 18),

                        AuthTextField(
                          controller: email,
                          label: 'Email',
                          hintText: 'you@example.com',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 12),

                        AuthTextField(
                          controller: password,
                          label: 'Password',
                          hintText: 'Min 8 characters',
                          isPassword: true,
                        ),

                        const SizedBox(height: 16),

                        SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            onPressed: isLoading
                                ? null
                                : () {
                                    context.read<AuthBloc>().add(
                                      AuthLoginRequested(
                                        email: email.text,
                                        password: password.text,
                                      ),
                                    );
                                  },
                            child: isLoading
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Login'),
                          ),
                        ),

                        const SizedBox(height: 10),

                        SizedBox(
                          height: 44,
                          child: OutlinedButton(
                            onPressed: isLoading
                                ? null
                                : () {
                                    AppToast.show(
                                      context,
                                      message:
                                          "Google OAuth comes next (Firebase).",
                                    );
                                  },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Real Google icon
                                SvgPicture.asset(
                                  'assets/icons/google.svg',
                                  height: 18,
                                  width: 18,
                                ),
                                const SizedBox(width: 10),
                                const Text('Continue with Google'),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('New here?', style: theme.textTheme.bodySmall),
                            TextButton(
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const RegisterPage(),
                                        ),
                                      );
                                    },
                              child: const Text('Create account'),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
