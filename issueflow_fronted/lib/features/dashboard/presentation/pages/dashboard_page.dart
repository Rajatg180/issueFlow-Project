import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/di/service_locator.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    return BlocProvider(
      create: (_) => sl<DashboardBloc>()..add(LoadDashboardHome()),
      child: BlocListener<DashboardBloc, DashboardState>(
        listener: (context, state) {
          if (state is DashboardError) {
            AppToast.show(context, message: state.message, isError: true);
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dashboard', style: t.textTheme.titleLarge),
                    const SizedBox(height: 6),
                    Text(
                      'Overview of your projects and issues.',
                      style: t.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 18),

                    BlocBuilder<DashboardBloc, DashboardState>(
                      builder: (context, state) {
                        if (state is DashboardInitial || state is DashboardLoading) {
                          return const _LoadingBox();
                        }

                        if (state is DashboardError) {
                          return _ErrorBox(
                            message: state.message,
                            onRetry: () => context.read<DashboardBloc>().add(LoadDashboardHome()),
                          );
                        }

                        final data = (state as DashboardLoaded).data;

                        final openIssues =
                            (data.summary.byStatus['todo'] ?? 0) + (data.summary.byStatus['in_progress'] ?? 0);

                        final inProgressAssigned =
                            data.myAssigned.where((i) => i.status == 'in_progress').length;

                        final dueSoonCount = data.dueSoon.length;
                        final projectsCount = data.summary.projectsCount;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Stats row
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isNarrow = constraints.maxWidth < 900;

                                final cards = <Widget>[
                                  _StatCard(
                                    title: 'Open Issues',
                                    value: '$openIssues',
                                    subtitle: 'Across all projects',
                                    icon: Icons.bug_report_outlined,
                                  ),
                                  _StatCard(
                                    title: 'In Progress',
                                    value: '$inProgressAssigned',
                                    subtitle: 'Assigned to you',
                                    icon: Icons.play_circle_outline,
                                  ),
                                  _StatCard(
                                    title: 'Due Soon',
                                    value: '$dueSoonCount',
                                    subtitle: 'Next 7 days',
                                    icon: Icons.event_outlined,
                                  ),
                                  _StatCard(
                                    title: 'Projects',
                                    value: '$projectsCount',
                                    subtitle: 'You own / joined',
                                    icon: Icons.workspaces_outline,
                                  ),
                                ];

                                if (isNarrow) {
                                  return Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: cards
                                        .map((c) => SizedBox(
                                              width: (constraints.maxWidth - 12) / 2,
                                              child: c,
                                            ))
                                        .toList(),
                                  );
                                }

                                return Row(
                                  children: [
                                    Expanded(child: Padding(padding: const EdgeInsets.only(right: 12), child: cards[0])),
                                    Expanded(child: Padding(padding: const EdgeInsets.only(right: 12), child: cards[1])),
                                    Expanded(child: Padding(padding: const EdgeInsets.only(right: 12), child: cards[2])),
                                    Expanded(child: cards[3]),
                                  ],
                                );
                              },
                            ),

                            const SizedBox(height: 18),

                            // Activity + My Work
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isNarrow = constraints.maxWidth < 900;

                                final left = _SectionCard(
                                  title: 'Recent Activity',
                                  subtitle: 'Latest comments across your projects',
                                  child: data.recentActivity.isEmpty
                                      ? const _EmptyHint(
                                          title: 'No activity yet',
                                          subtitle: 'Once comments are added, they will show up here.',
                                        )
                                      : _ActivityPager(
                                          activities: data.recentActivity,
                                          pageSize: 4,
                                        ),
                                );

                                final right = _SectionCard(
                                  title: 'My Work',
                                  subtitle: 'Assigned issues (quick view)',
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _PillRow(
                                        pills: [
                                          _Pill(label: 'Assigned: ${data.myAssigned.length}'),
                                          _Pill(label: 'Due Soon: ${data.dueSoon.length}'),
                                          _Pill(label: 'Overdue: ${data.overdue.length}'),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      if (data.overdue.isNotEmpty)
                                        _EmptyHint(
                                          title: 'Overdue',
                                          subtitle: data.overdue
                                              .take(3)
                                              .map((e) => '${e.key} • ${e.title}')
                                              .join('\n'),
                                        )
                                      else
                                        const _EmptyHint(
                                          title: 'No overdue issues',
                                          subtitle: 'Nice. Keep it up.',
                                        ),
                                      const SizedBox(height: 12),
                                      _QuickActionsRow(
                                        actions: [
                                          _QuickAction(
                                            icon: Icons.refresh,
                                            label: 'Refresh',
                                            onTap: () => context.read<DashboardBloc>().add(RefreshDashboardHome()),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );

                                if (isNarrow) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
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
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}

/// ✅ Client-side pagination for Recent Activity (no backend change)
class _ActivityPager extends StatefulWidget {
  final List<dynamic> activities; // keep dynamic so no extra imports required
  final int pageSize;

  const _ActivityPager({
    required this.activities,
    this.pageSize = 4,
  });

  @override
  State<_ActivityPager> createState() => _ActivityPagerState();
}

class _ActivityPagerState extends State<_ActivityPager> {
  int _page = 0;

  int get _totalPages {
    final total = widget.activities.length;
    final size = widget.pageSize;
    final pages = (total / size).ceil();
    return pages <= 0 ? 1 : pages;
  }

  List<dynamic> get _currentItems {
    final start = _page * widget.pageSize;
    final end = (start + widget.pageSize).clamp(0, widget.activities.length);
    if (start >= widget.activities.length) return const [];
    return widget.activities.sublist(start, end);
  }

  void _next() {
    if (_page < _totalPages - 1) {
      setState(() => _page++);
    }
  }

  void _prev() {
    if (_page > 0) {
      setState(() => _page--);
    }
  }

  @override
  void didUpdateWidget(covariant _ActivityPager oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If list changes (refresh), ensure page stays valid
    final maxPage = _totalPages - 1;
    if (_page > maxPage) {
      setState(() => _page = maxPage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = Theme.of(context);

    final items = _currentItems;

    return Column(
      children: [
        Column(
          children: items.map((a) {
            return _ActivityTile(
              title: '${a.issueKey} • ${a.issueTitle}',
              subtitle: '${a.authorUsername}: ${a.body}\n${_timeAgo(a.createdAt)}',
              icon: Icons.chat_bubble_outline,
            );
          }).toList(),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              'Page ${_page + 1} of $_totalPages',
              style: t.textTheme.bodySmall?.copyWith(color: c.textSecondary),
            ),
            const Spacer(),
            OutlinedButton(
              onPressed: _page == 0 ? null : _prev,
              child: const Text('Prev'),
            ),
            const SizedBox(width: 10),
            OutlinedButton(
              onPressed: _page >= _totalPages - 1 ? null : _next,
              child: const Text('Next'),
            ),
          ],
        ),
      ],
    );
  }
}

/// --- small helpers ---

class _LoadingBox extends StatelessWidget {
  const _LoadingBox();

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: c.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Loading dashboard...',
              style: TextStyle(color: c.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBox({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: c.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: c.textPrimary),
            ),
          ),
          const SizedBox(width: 10),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

/// ✅ Reuse your existing UI widgets below (same as your UI-only v1)

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
    final c = context.c;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: c.surface2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.border),
            ),
            child: Icon(icon, color: c.textSecondary, size: 20),
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
    final c = context.c;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: c.textSecondary, size: 18),
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
    final c = context.c;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
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
    return Wrap(spacing: 10, runSpacing: 10, children: actions);
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
    final c = context.c;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: c.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: c.textSecondary, size: 18),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: c.textPrimary, fontSize: 13)),
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
    return Wrap(spacing: 8, runSpacing: 8, children: pills);
  }
}

class _Pill extends StatelessWidget {
  final String label;

  const _Pill({required this.label});

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.border),
      ),
      child: Text(label, style: TextStyle(color: c.textSecondary, fontSize: 12)),
    );
  }
}
