import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../bloc/issues/issues_bloc.dart';
import '../bloc/issues/issues_event.dart';
import '../bloc/issues/issues_state.dart';
import '../widgets/create_issue_dialog.dart';
import '../widgets/project_issues_tile.dart';

class IssuesTablePage extends StatefulWidget {
  const IssuesTablePage({super.key});

  @override
  State<IssuesTablePage> createState() => _IssuesTablePageState();
}

class _IssuesTablePageState extends State<IssuesTablePage> {
  @override
  void initState() {
    super.initState();
    context.read<IssuesBloc>().add(const IssuesLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return const _IssuesView();
  }
}

class _IssuesView extends StatelessWidget {
  const _IssuesView();

  Future<void> _refresh(BuildContext context) async {
    context.read<IssuesBloc>().add(const IssuesLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: Row(
            children: [
              const Spacer(),
              _QuickAction(
                icon: Icons.refresh,
                label: 'Refresh',
                onTap: () => _refresh(context),
              ),
            ],
          ),
        ),

        Expanded(
          child: BlocConsumer<IssuesBloc, IssuesState>(
            listener: (context, state) {
              if (state is IssuesFailure) {
                AppToast.show(context, message: state.message, isError: true);
              }

              if (state is IssuesLoaded && state.toastMessage != null) {
                AppToast.show(
                  context,
                  message: state.toastMessage!,
                  isError: false,
                );
              }
            },
            builder: (context, state) {
              if (state is IssuesInitial || state is IssuesLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is IssuesFailure) {
                return RefreshIndicator(
                  onRefresh: () => _refresh(context),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const SizedBox(height: 80),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(state.message),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: () => context.read<IssuesBloc>().add(
                                const IssuesLoadRequested(),
                              ),
                              child: const Text('Retry'),
                            ),
                            const SizedBox(height: 12),
                            const Text('Pull down to refresh'),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

              final s = state as IssuesLoaded;

              if (s.projects.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () => _refresh(context),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const SizedBox(height: 80),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('No projects found.'),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: () => context.read<IssuesBloc>().add(
                                const IssuesLoadRequested(),
                              ),
                              child: const Text('Refresh'),
                            ),
                            const SizedBox(height: 12),
                            const Text('Pull down to refresh'),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => _refresh(context),
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 10, bottom: 16),
                  itemCount: s.projects.length,
                  itemBuilder: (context, index) {
                    final p = s.projects[index];
                    final expanded = s.isExpanded(p.id);

                    return ProjectIssuesTile(
                      project: p,
                      expanded: expanded,
                      isCreating: s.isCreating,
                      projectUsers: s.projectUsers[p.id] ?? const [],
                      onToggle: () => context.read<IssuesBloc>().add(
                        IssuesProjectToggled(p.id),
                      ),
                      onCreateIssue: () async {
                        final result = await CreateIssueDialog.open(context);
                        if (result == null) return;

                        context.read<IssuesBloc>().add(
                          IssueCreateRequested(
                            projectId: p.id,
                            title: result.title,
                            description: result.description,
                            type: result.type,
                            priority: result.priority,
                            dueDate: result.dueDate,
                          ),
                        );
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// ✅ Dashboard-like pill button (same look as your dashboard quick actions)
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
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
