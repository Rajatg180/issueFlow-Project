import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// DashboardPage (UI-only v1)
/// - Shows quick stats cards
/// - Shows "Recent Activity" list
/// - Shows "My Work" section placeholders
///
/// Later:
/// - Replace dummy numbers with API data
/// - Wire actions to Projects/Issues tab via ShellBloc
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page header
                Text('Dashboard', style: t.textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(
                  'Overview of your projects and issues (UI-only for now).',
                  style: t.textTheme.bodySmall,
                ),
                const SizedBox(height: 18),

                // Stats row
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 900;

                    final cards = <Widget>[
                      _StatCard(
                        title: 'Open Issues',
                        value: '12',
                        subtitle: 'Across all projects',
                        icon: Icons.bug_report_outlined,
                      ),
                      _StatCard(
                        title: 'In Progress',
                        value: '5',
                        subtitle: 'Assigned to you',
                        icon: Icons.play_circle_outline,
                      ),
                      _StatCard(
                        title: 'Due Soon',
                        value: '3',
                        subtitle: 'Next 7 days',
                        icon: Icons.event_outlined,
                      ),
                      _StatCard(
                        title: 'Projects',
                        value: '2',
                        subtitle: 'You own / joined',
                        icon: Icons.workspaces_outline,
                      ),
                    ];

                    if (isNarrow) {
                      // On small width, show cards in 2 columns
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: cards
                            .map(
                              (c) => SizedBox(
                                width: (constraints.maxWidth - 12) / 2,
                                child: c,
                              ),
                            )
                            .toList(),
                      );
                    }

                    // On wide, show in a row
                    return Row(
                      children: cards
                          .map((c) => Expanded(child: Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: c,
                              )))
                          .toList()
                        ..removeLast(), // remove last extra padding
                    );
                  },
                ),

                const SizedBox(height: 18),

                // Main grid: Activity + My Work
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 900;

                    final left = _SectionCard(
                      title: 'Recent Activity',
                      subtitle: 'Latest changes (dummy for now)',
                      child: Column(
                        children: const [
                          _ActivityTile(
                            title: 'IF-12 • Fix login validation',
                            subtitle: 'Moved to In Progress • 2h ago',
                            icon: Icons.bolt_outlined,
                          ),
                          _ActivityTile(
                            title: 'IF-11 • Create onboarding flow',
                            subtitle: 'Marked Done • Yesterday',
                            icon: Icons.check_circle_outline,
                          ),
                          _ActivityTile(
                            title: 'IF-10 • Setup project keys',
                            subtitle: 'Created • 2 days ago',
                            icon: Icons.add_circle_outline,
                          ),
                        ],
                      ),
                    );

                    final right = _SectionCard(
                      title: 'My Work',
                      subtitle: 'What you should focus on next',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _PillRow(
                            pills: const [
                              _Pill(label: 'Assigned: 5'),
                              _Pill(label: 'Mentions: 0'),
                              _Pill(label: 'Watching: 2'),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _EmptyHint(
                            title: 'No smart filters yet',
                            subtitle:
                                'Later we will add Jira-like filters, search, and quick actions.',
                          ),
                          const SizedBox(height: 12),
                          _QuickActionsRow(
                            actions: [
                              _QuickAction(
                                icon: Icons.add,
                                label: 'Create Issue',
                                onTap: () {
                                  // Later: open create issue dialog/page
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Create Issue (coming soon)'),
                                    ),
                                  );
                                },
                              ),
                              _QuickAction(
                                icon: Icons.workspaces_outline,
                                label: 'Go to Projects',
                                onTap: () {
                                  // Later: switch tab via ShellBloc
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Projects tab (use ShellBloc later)'),
                                    ),
                                  );
                                },
                              ),
                              _QuickAction(
                                icon: Icons.bug_report_outlined,
                                label: 'Go to Issues',
                                onTap: () {
                                  // Later: switch tab via ShellBloc
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Issues tab (use ShellBloc later)'),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    );

                    if (isNarrow) {
                      return Column(
                        children: [
                          left,
                          const SizedBox(height: 12),
                          right,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: left),
                        const SizedBox(width: 12),
                        Expanded(flex: 2, child: right),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ---------- Small reusable UI widgets below ----------

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(icon, color: AppColors.textSecondary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: t.textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(value, style: t.textTheme.titleLarge),
                const SizedBox(height: 2),
                Text(subtitle, style: t.textTheme.bodySmall),
              ],
            ),
          ),
        ],
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
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

class _ActivityTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _ActivityTile({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: t.textTheme.labelLarge),
                const SizedBox(height: 3),
                Text(subtitle, style: t.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyHint({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: t.textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(subtitle, style: t.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  final List<_QuickAction> actions;

  const _QuickActionsRow({required this.actions});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: actions,
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 18),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _PillRow extends StatelessWidget {
  final List<_Pill> pills;

  const _PillRow({required this.pills});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: pills,
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;

  const _Pill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
    );
  }
}
