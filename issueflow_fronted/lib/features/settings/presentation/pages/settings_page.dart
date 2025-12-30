import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Settings', style: t.textTheme.titleLarge),
                const SizedBox(height: 6),
                Text('Account and preferences', style: t.textTheme.bodySmall),
                const SizedBox(height: 18),

                _SectionCard(
                  title: 'Account',
                  subtitle: 'Signed-in user',
                  child: BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final email = state is Authenticated ? state.email : "-";
                      final username = state is Authenticated ? state.username : "-";

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.alternate_email_outlined,
                                color: context.c.textSecondary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  username.toString(),
                                  style: t.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                color: context.c.textSecondary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  email,
                                  style: t.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),

                _SectionCard(
                  title: 'Appearance',
                  subtitle: 'Theme mode',
                  child: BlocBuilder<ThemeCubit, ThemeMode>(
                    builder: (context, mode) {
                      final isDark = mode == ThemeMode.dark;
                      return Row(
                        children: [
                          Icon(
                            isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                            color: context.c.textSecondary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isDark ? "Dark" : "Light",
                              style: t.textTheme.bodyMedium,
                            ),
                          ),
                          Switch(
                            value: isDark,
                            onChanged: (_) async {
                              await context.read<ThemeCubit>().toggleDarkLight();
                              AppToast.show(context, message: "Theme updated");
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),

                _SectionCard(
                  title: 'Session',
                  subtitle: 'Sign out of IssueFlow',
                  child: SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                      onPressed: () {
                        context.read<AuthBloc>().add(const AuthLogoutRequested());
                        AppToast.show(context, message: "Logged out");
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final c = context.c;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: t.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(subtitle, style: t.textTheme.bodySmall),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
