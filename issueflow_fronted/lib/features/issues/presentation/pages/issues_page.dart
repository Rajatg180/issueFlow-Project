import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/app_toast.dart';
import '../bloc/issues_bloc.dart';
import '../bloc/issues_event.dart';
import '../bloc/issues_state.dart';
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
    // fire once
    print("Loading issues page");
    // WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IssuesBloc>().add(const IssuesLoadRequested());
    // });
  }

  @override
  Widget build(BuildContext context) {
    return const _IssuesView();
  }
}

class _IssuesView extends StatelessWidget {
  const _IssuesView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<IssuesBloc, IssuesState>(
      listener: (context, state) {
        if (state is IssuesFailure) {
          AppToast.show(context, message: state.message, isError: true);
        }
      },
      builder: (context, state) {
        if (state is IssuesInitial || state is IssuesLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is IssuesFailure) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(state.message),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () =>
                      context.read<IssuesBloc>().add(const IssuesLoadRequested()),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final s = state as IssuesLoaded;

        if (s.projects.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('No projects found.'),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () =>
                      context.read<IssuesBloc>().add(const IssuesLoadRequested()),
                  child: const Text('Refresh'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            context.read<IssuesBloc>().add(const IssuesLoadRequested());
          },
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

                onToggle: () =>
                    context.read<IssuesBloc>().add(IssuesProjectToggled(p.id)),
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
    );
  }
}
