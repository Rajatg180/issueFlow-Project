import 'package:flutter/material.dart';
import '../../../../core/theme/app_palette.dart';
import '../../domain/entities/project_user_entity.dart';
import '../../domain/entities/project_with_issues_entity.dart';
import 'issues_table.dart';

class ProjectIssuesTile extends StatefulWidget {
  final ProjectWithIssuesEntity project;
  final bool expanded;
  final VoidCallback onToggle;

  final VoidCallback onCreateIssue;
  final bool isCreating;

  final List<ProjectUserEntity> projectUsers;

  const ProjectIssuesTile({
    super.key,
    required this.project,
    required this.expanded,
    required this.onToggle,
    required this.onCreateIssue,
    required this.isCreating,
    required this.projectUsers,
  });

  @override
  State<ProjectIssuesTile> createState() => _ProjectIssuesTileState();
}

class _ProjectIssuesTileState extends State<ProjectIssuesTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 220),
    );

    _curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    if (widget.expanded) _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(covariant ProjectIssuesTile oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.expanded != oldWidget.expanded) {
      if (widget.expanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _expandedBody(BuildContext context) {
    return Column(
      children: [
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: widget.isCreating ? null : widget.onCreateIssue,
                icon: widget.isCreating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
                label: const Text('Create issue'),
              ),
              const Spacer(),
              Text(
                'Issues',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        IssuesTable(
          projectId: widget.project.id, // ✅ NEW
          issues: widget.project.issues,
          projectUsers: widget.projectUsers,
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Card(
      color: c.surface,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: c.border),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: widget.onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: c.surface2,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: c.border),
                    ),
                    child: Text(
                      widget.project.key,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.project.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.project.role} • ${widget.project.issues.length} issues',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: widget.expanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    child: Icon(
                      Icons.expand_more,
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ClipRect(
            child: SizeTransition(
              sizeFactor: _curve,
              axisAlignment: -1.0,
              child: FadeTransition(
                opacity: _curve,
                child: _expandedBody(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
