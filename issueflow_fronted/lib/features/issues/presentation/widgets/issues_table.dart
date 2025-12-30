import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_palette.dart';

import '../../domain/entities/issue_entity.dart';
import '../../domain/entities/project_user_entity.dart';
import '../../domain/entities/issue_comment_entity.dart';

import '../bloc/issues/issues_bloc.dart';
import '../bloc/issues/issues_event.dart';
import '../bloc/issues/issues_state.dart';

import '../bloc/comments/comments_bloc.dart';
import '../bloc/comments/comments_event.dart';
import '../bloc/comments/comments_state.dart';

import 'priority_badge.dart';
import 'status_badge.dart';

class IssuesTable extends StatefulWidget {
  final String projectId;
  final List<IssueEntity> issues;
  final List<ProjectUserEntity> projectUsers;

  const IssuesTable({
    super.key,
    required this.projectId,
    required this.issues,
    required this.projectUsers,
  });

  @override
  State<IssuesTable> createState() => _IssuesTableState();
}

class _IssuesTableState extends State<IssuesTable> {
  String? _editingIssueId;

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _type = 'task';
  String _priority = 'medium';
  String _status = 'todo';

  DateTime? _due;
  String? _assigneeId;
  String _reporterId = '';

  static const String _kUnassignedSentinelId = '__UNASSIGNED__';

  static const String _kFilterAll = '__ALL__';
  String _typeFilter = _kFilterAll; // all | task | bug | feature
  String _priorityFilter = _kFilterAll; // all | low | medium | high
  String _statusFilter = _kFilterAll; // all | todo | in_progress | done

  static const String _kAssigneeAll = '__ASSIGNEE_ALL__';
  static const String _kAssigneeUnassigned = '__ASSIGNEE_UNASSIGNED__';
  String _assigneeFilter = _kAssigneeAll;

  // ✅ Comments composer controller
  final TextEditingController _chatCtrl = TextEditingController();

  // ✅ Track which issue comments panel is currently opened.
  // This is the key fix: state handling becomes stable and doesn't "jump" between issues.
  String? _activeCommentsIssueId;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _chatCtrl.dispose();
    super.dispose();
  }

  // ---------- DATE HELPERS ----------
  bool _isOverdue(String dueDateStr) {
    try {
      final s = dueDateStr.trim();
      if (s.isEmpty) return false;

      final normalized = s.contains(' ') ? s.replaceFirst(' ', 'T') : s;

      final parsed = DateTime.parse(normalized);
      final due = DateTime(parsed.year, parsed.month, parsed.day);

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      return due.isBefore(today);
    } catch (_) {
      return false;
    }
  }

  String _onlyDate(String s) {
    final v = s.trim();
    if (v.isEmpty) return v;
    if (v.length >= 10) return v.substring(0, 10);
    return v;
  }

  DateTime? _parseDate(String? s) {
    if (s == null || s.trim().isEmpty) return null;
    try {
      final raw = s.trim();
      final normalized = raw.contains(' ') ? raw.replaceFirst(' ', 'T') : raw;
      final d = DateTime.parse(normalized);
      return DateTime(d.year, d.month, d.day);
    } catch (_) {
      try {
        final d = DateTime.parse(_onlyDate(s));
        return DateTime(d.year, d.month, d.day);
      } catch (_) {
        return null;
      }
    }
  }

  // ---------- UI HELPERS ----------
  Widget typeWidegt(String type) {
    switch (type) {
      case 'task':
        return const Text('Task');
      case 'bug':
        return const Text('Bug');
      case 'feature':
        return const Text('Feature');
      default:
        return Text(type);
    }
  }

  Widget _calendarDateChip(String? dateStr) {
    final c = context.c;

    if (dateStr == null || dateStr.trim().isEmpty) {
      return const Text('-');
    }

    final d = _onlyDate(dateStr);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.calendar_month_rounded,
          size: 16,
          color: c.textSecondary,
        ),
        const SizedBox(width: 6),
        Text(d, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _dueChip(String? dueDate) {
    final c = context.c;

    if (dueDate == null || dueDate.trim().isEmpty) {
      return const Text('-');
    }

    final dateOnly = _onlyDate(dueDate);
    final overdue = _isOverdue(dueDate);

    if (!overdue) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: c.surface2,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: c.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_month_rounded,
              size: 16,
              color: c.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(dateOnly, style: const TextStyle(fontSize: 12)),
          ],
        ),
      );
    }

    // keep your same overdue styling (works in both themes)
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF7F1D1D).withOpacity(0.35),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFB91C1C).withOpacity(0.8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.calendar_month_rounded,
            size: 16,
            color: Colors.red,
          ),
          const SizedBox(width: 6),
          Text(
            dateOnly,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  String _initial(String name) {
    final v = name.trim();
    if (v.isEmpty) return '?';
    return v[0].toUpperCase();
  }

  Widget _avatar(String name, {double size = 22}) {
    final c = context.c;

    final letter = _initial(name);

    final h = name.hashCode.abs();
    final base = 0xFF000000 | (h & 0x00FFFFFF);
    final bg = Color(base).withOpacity(0.18);
    final border = Color(base).withOpacity(0.35);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: border),
      ),
      child: Text(
        letter,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: c.textPrimary,
        ),
      ),
    );
  }

  ProjectUserEntity? _findUserById(String? id) {
    if (id == null) return null;
    for (final u in widget.projectUsers) {
      if (u.id == id) return u;
    }
    return null;
  }

  // ---------- POPUPS ----------
  void _showDescriptionPopup(String title, String description) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(title),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              child: SelectableText(
                description.trim().isEmpty ? '-' : description,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(IssueEntity issue) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text(
            'Are you sure you want to delete issue "${issue.title}"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.of(context).pop();
                context.read<IssuesBloc>().add(
                      IssueDeleteRequested(
                        projectId: widget.projectId,
                        issueId: issue.id,
                      ),
                    );
              },
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // ---------- EDIT MODE ONLY (dropdown) ----------
  Widget _jiraUserCell({
    required String text,
    required bool allowUnassigned,
    required void Function(ProjectUserEntity? user) onSelected,
  }) {
    final c = context.c;
    final display = text.trim().isEmpty ? '-' : text;

    return PopupMenuButton<ProjectUserEntity?>(
      tooltip: '',
      padding: EdgeInsets.zero,
      position: PopupMenuPosition.under,
      onSelected: onSelected,
      itemBuilder: (ctx) {
        if (widget.projectUsers.isEmpty) {
          return const [
            PopupMenuItem<ProjectUserEntity?>(
              enabled: false,
              value: null,
              child: Text('No users found'),
            ),
          ];
        }

        final items = <PopupMenuEntry<ProjectUserEntity?>>[];

        if (allowUnassigned) {
          final sentinel = ProjectUserEntity(
            id: _kUnassignedSentinelId,
            username: 'Unassigned',
          );

          items.add(
            PopupMenuItem<ProjectUserEntity?>(
              value: sentinel,
              child: Row(
                children: [
                  Icon(
                    Icons.person_off_outlined,
                    size: 18,
                    color: c.textSecondary,
                  ),
                  const SizedBox(width: 10),
                  const Text('Unassigned'),
                ],
              ),
            ),
          );
          items.add(const PopupMenuDivider(height: 8));
        }

        for (final u in widget.projectUsers) {
          items.add(
            PopupMenuItem<ProjectUserEntity?>(
              value: u,
              child: Row(
                children: [
                  _avatar(u.username, size: 24),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(u.username, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          );
        }

        return items;
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: c.surface2,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: c.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _avatar(display),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  display,
                  style: const TextStyle(fontSize: 12, height: 1.1),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: c.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _jiraUserCellReadOnly({
    required String text,
    bool showUnassignedIcon = false,
  }) {
    final c = context.c;
    final display = text.trim().isEmpty ? '-' : text;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showUnassignedIcon && display.toLowerCase() == 'unassigned') ...[
            Icon(
              Icons.person_off_outlined,
              size: 16,
              color: c.textSecondary,
            ),
            const SizedBox(width: 8),
          ] else ...[
            _avatar(display),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              display,
              style: const TextStyle(fontSize: 12, height: 1.1),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      initialDate: _due ?? now,
    );
    if (picked != null) {
      setState(() {
        _due = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  void _startEdit(IssueEntity issue) {
    setState(() {
      _editingIssueId = issue.id;

      _titleCtrl.text = issue.title;
      _descCtrl.text = issue.description ?? '';

      _type = issue.type;
      _priority = issue.priority;
      _status = issue.status;

      _due = _parseDate(issue.dueDate);

      _assigneeId = issue.assignee?.id; // null => Unassigned
      _reporterId = issue.reporter.id;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingIssueId = null;
      _titleCtrl.clear();
      _descCtrl.clear();
      _type = 'task';
      _priority = 'medium';
      _status = 'todo';
      _due = null;
      _assigneeId = null;
      _reporterId = '';
    });
  }

  void _doneEdit(String issueId) {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;

    context.read<IssuesBloc>().add(
          IssueUpdateRequested(
            projectId: widget.projectId,
            issueId: issueId,
            title: title,
            description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
            type: _type,
            priority: _priority,
            status: _status,
            dueDate: _due,
            assigneeId: _assigneeId,
            reporterId: _reporterId,
          ),
        );

    _cancelEdit();
  }

  // ---------- FILTER LOGIC ----------
  bool _matchesFilters(IssueEntity i) {
    if (_assigneeFilter != _kAssigneeAll) {
      if (_assigneeFilter == _kAssigneeUnassigned) {
        if (i.assignee != null) return false;
      } else {
        if (i.assignee?.id != _assigneeFilter) return false;
      }
    }

    final type = (i.type).trim();
    final priority = (i.priority).trim();
    final status = (i.status).trim();

    if (_typeFilter != _kFilterAll && type != _typeFilter) return false;
    if (_priorityFilter != _kFilterAll && priority != _priorityFilter) return false;
    if (_statusFilter != _kFilterAll && status != _statusFilter) return false;

    return true;
  }

  Widget _filterChip({
    required String label,
    required List<PopupMenuEntry<String>> items,
    required void Function(String v) onSelected,
  }) {
    final c = context.c;

    return PopupMenuButton<String>(
      tooltip: '',
      position: PopupMenuPosition.under,
      onSelected: onSelected,
      itemBuilder: (_) => items,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: c.surface2,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: c.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 6),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: c.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  String _typeLabel() {
    if (_typeFilter == _kFilterAll) return 'Type: All';
    return 'Type: ${_typeFilter[0].toUpperCase()}${_typeFilter.substring(1)}';
  }

  String _priorityLabel() {
    if (_priorityFilter == _kFilterAll) return 'Priority: All';
    return 'Priority: ${_priorityFilter[0].toUpperCase()}${_priorityFilter.substring(1)}';
  }

  String _statusLabel() {
    if (_statusFilter == _kFilterAll) return 'Status: All';
    switch (_statusFilter) {
      case 'in_progress':
        return 'Status: In Progress';
      case 'todo':
        return 'Status: Todo';
      case 'done':
        return 'Status: Done';
      default:
        return 'Status: $_statusFilter';
    }
  }

  int _activeFilterCount() {
    int c = 0;
    if (_assigneeFilter != _kAssigneeAll) c++;
    if (_typeFilter != _kFilterAll) c++;
    if (_priorityFilter != _kFilterAll) c++;
    if (_statusFilter != _kFilterAll) c++;
    return c;
  }

  // ---------- ASSIGNEE STRIP ----------
  Widget _assigneeStrip() {
    final c = context.c;
    final users = widget.projectUsers;

    const double size = 28;
    const double overlap = 18;
    final visibleCount = users.length > 4 ? 4 : users.length;
    final remaining = users.length - visibleCount;
    final stackCount = visibleCount + (remaining > 0 ? 1 : 0);

    final stackWidth = stackCount == 0 ? 0.0 : (size + (stackCount - 1) * overlap);

    List<PopupMenuEntry<String>> menuItems() {
      final items = <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(value: _kAssigneeAll, child: Text('All')),
        const PopupMenuItem<String>(value: _kAssigneeUnassigned, child: Text('Unassigned')),
        const PopupMenuDivider(),
      ];

      for (final u in users) {
        items.add(
          PopupMenuItem<String>(
            value: u.id,
            child: Row(
              children: [
                _avatar(u.username, size: 22),
                const SizedBox(width: 10),
                Flexible(child: Text(u.username, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
        );
      }

      return items;
    }

    Widget avatarCircle({required Widget child, required bool selected}) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? c.border : c.border.withOpacity(0.6),
            width: selected ? 2 : 1,
          ),
          color: c.surface2,
        ),
        child: ClipOval(child: child),
      );
    }

    final avatars = PopupMenuButton<String>(
      tooltip: '',
      position: PopupMenuPosition.under,
      itemBuilder: (_) => menuItems(),
      onSelected: (v) => setState(() => _assigneeFilter = v),
      child: SizedBox(
        width: stackWidth,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (int i = 0; i < visibleCount; i++)
              Positioned(
                left: i * overlap,
                child: Tooltip(
                  message: users[i].username,
                  child: avatarCircle(
                    selected: _assigneeFilter == users[i].id,
                    child: Center(child: _avatar(users[i].username, size: size)),
                  ),
                ),
              ),
            if (remaining > 0)
              Positioned(
                left: visibleCount * overlap,
                child: avatarCircle(
                  selected: false,
                  child: Center(
                    child: Text(
                      '+$remaining',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    final count = _activeFilterCount();

    final filterButton = Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.filter_list, size: 16, color: c.textSecondary),
          const SizedBox(width: 8),
          const Text('Filter', style: TextStyle(fontSize: 12)),
          if (count > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: c.border),
              ),
              child: Text(
                '$count',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ],
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [filterButton, const SizedBox(width: 10), avatars],
    );
  }

  // ---------- COMMENTS ----------
  bool _isMobileLike(BuildContext context) => MediaQuery.of(context).size.width < 720;

  void _openComments(IssueEntity issue) {
    _chatCtrl.clear();

    setState(() {
      _activeCommentsIssueId = issue.id;
    });

    context.read<CommentsBloc>().add(
          CommentsOpenRequested(projectId: widget.projectId, issueId: issue.id),
        );

    if (_isMobileLike(context)) {
      _openCommentsBottomSheet(issue);
    } else {
      _openCommentsSideDrawer(issue);
    }
  }

  // ✅ Always show the backend count on the table (no state-dependent "only after click" issue).
  Widget _commentsCell(IssueEntity issue) {
    final c = context.c;
    final count = issue.commentsCount;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _openComments(issue),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: c.surface2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 16, color: c.textSecondary),
            const SizedBox(width: 8),
            Text(
              count == 0 ? 'Add comment' : '$count comments',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, size: 18, color: c.textSecondary),
          ],
        ),
      ),
    );
  }

  void _openCommentsBottomSheet(IssueEntity issue) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final viewInsets = MediaQuery.of(ctx).viewInsets.bottom;
        return AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: viewInsets),
          child: BlocBuilder<CommentsBloc, CommentsState>(
            builder: (context, state) {
              final loading = state is CommentsLoading;
              final loaded = state is CommentsLoaded && state.issueId == issue.id;

              final comments = loaded ? state.comments : const <IssueCommentEntity>[];
              final sending = loaded ? state.sending : false;

              return IssueCommentsSheet(
                headerTitle: '${issue.key} • ${issue.title}',
                projectUsers: widget.projectUsers,
                comments: comments,
                controller: _chatCtrl,
                sending: sending,
                loading: loading && !loaded,
                onSend: (text) {
                  final t = text.trim();
                  if (t.isEmpty) return;
                  context.read<CommentsBloc>().add(
                        CommentSendRequested(
                          projectId: widget.projectId,
                          issueId: issue.id,
                          body: t,
                        ),
                      );
                },
                onClose: () => Navigator.of(ctx).pop(),
                isMobile: true,
              );
            },
          ),
        );
      },
    ).whenComplete(() {
      if (mounted) {
        setState(() {
          _activeCommentsIssueId = null;
        });
      }
    });
  }

  void _openCommentsSideDrawer(IssueEntity issue) {
    showGeneralDialog(
      context: context,
      barrierLabel: 'Comments',
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.35),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, a1, a2) {
        return Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: BlocBuilder<CommentsBloc, CommentsState>(
              builder: (context, state) {
                final loading = state is CommentsLoading;
                final loaded = state is CommentsLoaded && state.issueId == issue.id;

                final comments = loaded ? state.comments : const <IssueCommentEntity>[];
                final sending = loaded ? state.sending : false;

                return IssueCommentsSheet(
                  headerTitle: '${issue.key} • ${issue.title}',
                  projectUsers: widget.projectUsers,
                  comments: comments,
                  controller: _chatCtrl,
                  sending: sending,
                  loading: loading && !loaded,
                  onSend: (text) {
                    final t = text.trim();
                    if (t.isEmpty) return;
                    context.read<CommentsBloc>().add(
                          CommentSendRequested(
                            projectId: widget.projectId,
                            issueId: issue.id,
                            body: t,
                          ),
                        );
                  },
                  onClose: () => Navigator.of(ctx).pop(),
                  isMobile: false,
                );
              },
            ),
          ),
        );
      },
      transitionBuilder: (ctx, anim, _, child) {
        final slide = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));

        final fade = Tween<double>(begin: 0, end: 1).animate(anim);

        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        );
      },
    ).then((_) {
      if (mounted) {
        setState(() {
          _activeCommentsIssueId = null;
        });
      }
    });
  }

  // ---------- BUILD ----------
  @override
  Widget build(BuildContext context) {
    final c = context.c;

    if (widget.issues.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text("No issues in this project yet."),
      );
    }

    final filteredIssues = widget.issues.where(_matchesFilters).toList();
    final hController = ScrollController();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Scrollbar(
          controller: hController,
          thumbVisibility: true,
          notificationPredicate: (n) => n.metrics.axis == Axis.horizontal,
          child: Listener(
            onPointerSignal: (signal) {
              if (signal is PointerScrollEvent) {
                final delta = signal.scrollDelta.dy;
                if (!hController.hasClients) return;

                final maxExtent = hController.position.maxScrollExtent;
                final minExtent = hController.position.minScrollExtent;
                final next = (hController.offset + delta).clamp(minExtent, maxExtent);
                hController.jumpTo(next);
              }
            },
            child: SingleChildScrollView(
              controller: hController,
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: BlocBuilder<IssuesBloc, IssuesState>(
                    builder: (context, state) {
                      final isUpdating = state is IssuesLoaded ? state.isUpdating : false;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                            child: Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                _assigneeStrip(),
                                _filterChip(
                                  label: _typeLabel(),
                                  items: const [
                                    PopupMenuItem(value: _kFilterAll, child: Text('All')),
                                    PopupMenuItem(value: 'task', child: Text('Task')),
                                    PopupMenuItem(value: 'bug', child: Text('Bug')),
                                    PopupMenuItem(value: 'feature', child: Text('Feature')),
                                  ],
                                  onSelected: (v) => setState(() => _typeFilter = v),
                                ),
                                _filterChip(
                                  label: _priorityLabel(),
                                  items: const [
                                    PopupMenuItem(value: _kFilterAll, child: Text('All')),
                                    PopupMenuItem(value: 'low', child: Text('Low')),
                                    PopupMenuItem(value: 'medium', child: Text('Medium')),
                                    PopupMenuItem(value: 'high', child: Text('High')),
                                  ],
                                  onSelected: (v) => setState(() => _priorityFilter = v),
                                ),
                                _filterChip(
                                  label: _statusLabel(),
                                  items: const [
                                    PopupMenuItem(value: _kFilterAll, child: Text('All')),
                                    PopupMenuItem(value: 'todo', child: Text('Todo')),
                                    PopupMenuItem(value: 'in_progress', child: Text('In Progress')),
                                    PopupMenuItem(value: 'done', child: Text('Done')),
                                  ],
                                  onSelected: (v) => setState(() => _statusFilter = v),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _assigneeFilter = _kAssigneeAll;
                                      _typeFilter = _kFilterAll;
                                      _priorityFilter = _kFilterAll;
                                      _statusFilter = _kFilterAll;
                                    });
                                  },
                                  icon: const Icon(Icons.clear, size: 16),
                                  label: const Text('Clear'),
                                ),
                                Text(
                                  'Showing ${filteredIssues.length}/${widget.issues.length}',
                                  style: TextStyle(fontSize: 12, color: c.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          DataTable(
                            headingRowColor: MaterialStatePropertyAll(c.surface2),
                            columns: const [
                              DataColumn(label: Text('Key')),
                              DataColumn(label: Text('Title')),
                              DataColumn(label: Text('Description')),
                              DataColumn(label: Text('Type')),
                              DataColumn(label: Text('Priority')),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('Comments')),
                              DataColumn(label: Text('Assignee')),
                              DataColumn(label: Text('Reporter')),
                              DataColumn(label: Text('Due')),
                              DataColumn(label: Text('Created At')),
                              DataColumn(label: Text('Updated At')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: filteredIssues.map((i) {
                              final editing = _editingIssueId == i.id;

                              return DataRow(
                                cells: [
                                  DataCell(Text(i.key)),

                                  // Title
                                  DataCell(
                                    editing
                                        ? ConstrainedBox(
                                            constraints: const BoxConstraints(maxWidth: 280),
                                            child: TextField(
                                              controller: _titleCtrl,
                                              decoration: const InputDecoration(
                                                isDense: true,
                                                border: OutlineInputBorder(),
                                                contentPadding:
                                                    EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                              ),
                                            ),
                                          )
                                        : ConstrainedBox(
                                            constraints: const BoxConstraints(maxWidth: 280),
                                            child: Text(i.title, overflow: TextOverflow.ellipsis),
                                          ),
                                  ),

                                  // Description
                                  DataCell(
                                    editing
                                        ? ConstrainedBox(
                                            constraints: const BoxConstraints(maxWidth: 340),
                                            child: TextField(
                                              controller: _descCtrl,
                                              maxLines: 3,
                                              minLines: 1,
                                              decoration: const InputDecoration(
                                                isDense: true,
                                                border: OutlineInputBorder(),
                                                contentPadding:
                                                    EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                              ),
                                            ),
                                          )
                                        : ConstrainedBox(
                                            constraints: const BoxConstraints(maxWidth: 340),
                                            child: InkWell(
                                              onTap: () => _showDescriptionPopup(i.title, i.description ?? ''),
                                              child: Text(
                                                (i.description == null || i.description!.trim().isEmpty)
                                                    ? '-'
                                                    : i.description!.trim(),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(decoration: TextDecoration.underline),
                                              ),
                                            ),
                                          ),
                                  ),

                                  // Type
                                  DataCell(
                                    editing
                                        ? DropdownButtonFormField<String>(
                                            value: _type,
                                            decoration: const InputDecoration(
                                              isDense: true,
                                              border: OutlineInputBorder(),
                                              contentPadding:
                                                  EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                            ),
                                            items: const [
                                              DropdownMenuItem(value: 'task', child: Text('Task')),
                                              DropdownMenuItem(value: 'bug', child: Text('Bug')),
                                              DropdownMenuItem(value: 'feature', child: Text('Feature')),
                                            ],
                                            onChanged: (v) => setState(() => _type = v ?? 'task'),
                                          )
                                        : typeWidegt(i.type),
                                  ),

                                  // Priority
                                  DataCell(
                                    editing
                                        ? DropdownButtonFormField<String>(
                                            value: _priority,
                                            decoration: const InputDecoration(
                                              isDense: true,
                                              border: OutlineInputBorder(),
                                              contentPadding:
                                                  EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                            ),
                                            items: const [
                                              DropdownMenuItem(value: 'low', child: Text('Low')),
                                              DropdownMenuItem(value: 'medium', child: Text('Medium')),
                                              DropdownMenuItem(value: 'high', child: Text('High')),
                                            ],
                                            onChanged: (v) => setState(() => _priority = v ?? 'medium'),
                                          )
                                        : PriorityBadge(priority: i.priority),
                                  ),

                                  // Status
                                  DataCell(
                                    editing
                                        ? DropdownButtonFormField<String>(
                                            value: _status,
                                            decoration: const InputDecoration(
                                              isDense: true,
                                              border: OutlineInputBorder(),
                                              contentPadding:
                                                  EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                            ),
                                            items: const [
                                              DropdownMenuItem(value: 'todo', child: Text('Todo')),
                                              DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                                              DropdownMenuItem(value: 'done', child: Text('Done')),
                                            ],
                                            onChanged: (v) => setState(() => _status = v ?? 'todo'),
                                          )
                                        : StatusBadge(status: i.status),
                                  ),

                                  // ✅ Comments
                                  DataCell(_commentsCell(i)),

                                  // Assignee
                                  DataCell(
                                    editing
                                        ? _jiraUserCell(
                                            text: (_findUserById(_assigneeId)?.username) ?? 'Unassigned',
                                            allowUnassigned: true,
                                            onSelected: (u) {
                                              setState(() {
                                                if (u?.id == _kUnassignedSentinelId) {
                                                  _assigneeId = null;
                                                } else {
                                                  _assigneeId = u?.id;
                                                }
                                              });
                                            },
                                          )
                                        : _jiraUserCellReadOnly(
                                            text: i.assignee?.username ?? 'Unassigned',
                                            showUnassignedIcon: true,
                                          ),
                                  ),

                                  // Reporter
                                  DataCell(
                                    editing
                                        ? _jiraUserCell(
                                            text: (_findUserById(_reporterId)?.username) ?? i.reporter.username,
                                            allowUnassigned: false,
                                            onSelected: (u) {
                                              if (u == null) return;
                                              setState(() => _reporterId = u.id);
                                            },
                                          )
                                        : _jiraUserCellReadOnly(text: i.reporter.username),
                                  ),

                                  // Due
                                  DataCell(
                                    editing
                                        ? Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              InkWell(
                                                onTap: _pickDueDate,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: c.surface2,
                                                    borderRadius: BorderRadius.circular(999),
                                                    border: Border.all(color: c.border),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.calendar_month_rounded,
                                                          size: 16, color: c.textSecondary),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        _due == null
                                                            ? '-'
                                                            : '${_due!.year}-${_due!.month.toString().padLeft(2, '0')}-${_due!.day.toString().padLeft(2, '0')}',
                                                        style: const TextStyle(fontSize: 12),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              if (_due != null) ...[
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  tooltip: 'Clear',
                                                  onPressed: () => setState(() => _due = null),
                                                  icon: Icon(Icons.clear, size: 18, color: c.textSecondary),
                                                ),
                                              ],
                                            ],
                                          )
                                        : _dueChip(i.dueDate),
                                  ),

                                  DataCell(_calendarDateChip(i.createdAt)),
                                  DataCell(_calendarDateChip(i.updatedAt)),

                                  // Actions
                                  DataCell(
                                    editing
                                        ? Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              ElevatedButton(
                                                onPressed: isUpdating ? null : () => _doneEdit(i.id),
                                                child: const Text('Done'),
                                              ),
                                              const SizedBox(width: 8),
                                              OutlinedButton(
                                                onPressed: isUpdating ? null : _cancelEdit,
                                                child: const Text('Cancel'),
                                              ),
                                            ],
                                          )
                                        : Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              OutlinedButton(
                                                onPressed: isUpdating ? null : () => _startEdit(i),
                                                child: const Text('Edit'),
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                tooltip: 'Delete issue',
                                                onPressed: isUpdating ? null : () => _confirmDelete(i),
                                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                              ),
                                            ],
                                          ),
                                  ),
                                ],
                              );
                            }).toList(),
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
      ),
    );
  }
}

class IssueCommentsSheet extends StatefulWidget {
  final String headerTitle;
  final List<ProjectUserEntity> projectUsers;
  final List<IssueCommentEntity> comments;

  final TextEditingController controller;
  final bool sending;
  final bool loading;

  final void Function(String text) onSend;
  final VoidCallback onClose;
  final bool isMobile;

  const IssueCommentsSheet({
    super.key,
    required this.headerTitle,
    required this.projectUsers,
    required this.comments,
    required this.controller,
    required this.sending,
    required this.loading,
    required this.onSend,
    required this.onClose,
    required this.isMobile,
  });

  @override
  State<IssueCommentsSheet> createState() => _IssueCommentsSheetState();
}

class _IssueCommentsSheetState extends State<IssueCommentsSheet> {
  String? _myUserId;

  // ✅ local edit UI state
  String? _editingId;
  final TextEditingController _editCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMyUserId();
  }

  @override
  void dispose() {
    _editCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMyUserId() async {
    try {
      final storage = TokenStorage();
      final token = await storage.readAccessToken();
      if (token == null || token.isEmpty) return;

      final parts = token.split('.');
      if (parts.length < 2) return;

      String normalize(String s) {
        final mod = s.length % 4;
        if (mod == 2) return '$s==';
        if (mod == 3) return '$s=';
        return s;
      }

      final payload = utf8.decode(base64Url.decode(normalize(parts[1])));
      final j = jsonDecode(payload);
      if (j is! Map) return;

      final v = (j['user_id'] ?? j['sub'] ?? j['id'])?.toString();
      if (v == null || v.isEmpty) return;

      if (mounted) setState(() => _myUserId = v);
    } catch (_) {}
  }

  bool _isMine(IssueCommentEntity c) {
    final me = _myUserId;
    if (me == null || me.isEmpty) return false;
    return c.authorId == me;
  }

  void _startEdit(IssueCommentEntity c) {
    setState(() {
      _editingId = c.id;
      _editCtrl.text = c.body;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingId = null;
      _editCtrl.clear();
    });
  }

  Future<void> _confirmDelete(BuildContext context, IssueCommentEntity c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Delete comment?'),
          content: const Text('This action cannot be undone.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    context.read<CommentsBloc>().add(
          CommentDeleteRequested(
            projectId: c.projectId,
            issueId: c.issueId,
            commentId: c.id,
          ),
        );
  }

  String _initial(String name) {
    final v = name.trim();
    if (v.isEmpty) return '?';
    return v[0].toUpperCase();
  }

  Widget _avatar(String name, {double size = 28}) {
    final c = context.c;

    final letter = _initial(name);
    final h = name.hashCode.abs();
    final base = 0xFF000000 | (h & 0x00FFFFFF);
    final bg = Color(base).withOpacity(0.18);
    final border = Color(base).withOpacity(0.35);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: border),
      ),
      child: Text(
        letter,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: c.textPrimary,
        ),
      ),
    );
  }

  String _hhmm(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    final panelWidth = widget.isMobile ? w : math.min(420.0, w * 0.35);
    final panelHeight = widget.isMobile ? h * 0.92 : h * 0.90;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: panelWidth,
        height: panelHeight,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(widget.isMobile ? 18 : 14),
          border: Border.all(color: c.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              decoration: BoxDecoration(
                color: c.surface2,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.headerTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: widget.onClose,
                    icon: Icon(Icons.close_rounded, color: c.textSecondary),
                  ),
                ],
              ),
            ),

            if (widget.projectUsers.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Icon(Icons.group_outlined, size: 18, color: c.textSecondary),
                      const SizedBox(width: 10),
                      for (final u in widget.projectUsers) ...[
                        Tooltip(
                          message: u.username,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _avatar(u.username, size: 28),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

            Divider(height: 1, color: c.border),

            // Messages
            Expanded(
              child: widget.loading
                  ? const Center(child: CircularProgressIndicator())
                  : widget.comments.isEmpty
                      ? Center(
                          child: Text(
                            'No comments yet.\nBe the first to add one.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: c.textSecondary),
                          ),
                        )
                      : BlocBuilder<CommentsBloc, CommentsState>(
                          builder: (context, st) {
                            final savingEdit = st is CommentsLoaded ? st.savingEdit : false;
                            final deleting = st is CommentsLoaded ? st.deleting : false;

                            return ListView.builder(
                              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                              itemCount: widget.comments.length,
                              itemBuilder: (ctx, index) {
                                final cm = widget.comments[index];
                                final mine = _isMine(cm);

                                final align = mine ? Alignment.centerRight : Alignment.centerLeft;
                                final bubbleColor =
                                    mine ? c.surface2.withOpacity(0.95) : c.surface2.withOpacity(0.7);

                                final isEditingThis = _editingId == cm.id;

                                return Align(
                                  alignment: align,
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    constraints: BoxConstraints(maxWidth: math.min(520, w * 0.75)),
                                    decoration: BoxDecoration(
                                      color: bubbleColor,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: c.border),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            _avatar(cm.authorUsername, size: 22),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                cm.authorUsername,
                                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Text(
                                              _hhmm(cm.createdAt.toLocal()),
                                              style: TextStyle(fontSize: 11, color: c.textSecondary),
                                            ),
                                            if (cm.edited) ...[
                                              const SizedBox(width: 6),
                                              Text('(edited)',
                                                  style: TextStyle(fontSize: 11, color: c.textSecondary)),
                                            ],

                                            // ✅ Edit/Delete actions only for my comment
                                            if (mine) ...[
                                              const SizedBox(width: 6),
                                              PopupMenuButton<String>(
                                                tooltip: '',
                                                onSelected: (v) {
                                                  if (v == 'edit') {
                                                    _startEdit(cm);
                                                  } else if (v == 'delete') {
                                                    _confirmDelete(context, cm);
                                                  }
                                                },
                                                itemBuilder: (_) => const [
                                                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                                                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                                                ],
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                                  child: Icon(Icons.more_vert, size: 18, color: c.textSecondary),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 8),

                                        if (!isEditingThis) ...[
                                          const Text('', style: TextStyle(fontSize: 0)), // keeps structure unchanged
                                          Text(cm.body, style: const TextStyle(fontSize: 13, height: 1.25)),
                                        ] else ...[
                                          TextField(
                                            controller: _editCtrl,
                                            maxLines: null,
                                            decoration: const InputDecoration(
                                              isDense: true,
                                              border: OutlineInputBorder(),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              OutlinedButton(
                                                onPressed: savingEdit ? null : _cancelEdit,
                                                child: const Text('Cancel'),
                                              ),
                                              const SizedBox(width: 8),
                                              ElevatedButton(
                                                onPressed: (savingEdit || deleting)
                                                    ? null
                                                    : () {
                                                        final t = _editCtrl.text.trim();
                                                        if (t.isEmpty) return;
                                                        context.read<CommentsBloc>().add(
                                                              CommentEditRequested(
                                                                projectId: cm.projectId,
                                                                issueId: cm.issueId,
                                                                commentId: cm.id,
                                                                body: t,
                                                              ),
                                                            );
                                                        _cancelEdit();
                                                      },
                                                child: savingEdit
                                                    ? const SizedBox(
                                                        width: 16,
                                                        height: 16,
                                                        child: CircularProgressIndicator(strokeWidth: 2),
                                                      )
                                                    : const Text('Save'),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
            ),

            Divider(height: 1, color: c.border),

            // Composer
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (v) {
                        if (widget.sending) return;
                        final t = v.trim();
                        if (t.isEmpty) return;
                        widget.onSend(t);
                        widget.controller.clear();
                      },
                      decoration: InputDecoration(
                        hintText: 'Write a comment…',
                        isDense: true,
                        filled: true,
                        fillColor: c.surface2,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: c.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: c.border),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: widget.sending
                        ? null
                        : () {
                            final t = widget.controller.text.trim();
                            if (t.isEmpty) return;
                            widget.onSend(t);
                            widget.controller.clear();
                          },
                    icon: widget.sending
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send_rounded, size: 18),
                    label: const Text('Send'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
