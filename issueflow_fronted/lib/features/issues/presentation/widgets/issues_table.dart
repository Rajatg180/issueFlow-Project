import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/issue_entity.dart';
import '../../domain/entities/project_user_entity.dart';
import 'priority_badge.dart';
import 'status_badge.dart';

class IssuesTable extends StatelessWidget {
  final List<IssueEntity> issues;

  final List<ProjectUserEntity> projectUsers;

  const IssuesTable({
    super.key,
    required this.issues,
    required this.projectUsers,
  });

  bool _isOverdue(String dueDateStr) {
    try {
      final d = DateTime.parse(dueDateStr);
      final due = DateTime(d.year, d.month, d.day);

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

  Widget _calendarDateChip(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) {
      return const Text('-');
    }

    final d = _onlyDate(dateStr);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.calendar_month_rounded,
          size: 16,
          color: AppColors.mutedText,
        ),
        const SizedBox(width: 6),
        Text(d, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _dueChip(String? dueDate) {
    if (dueDate == null || dueDate.trim().isEmpty) {
      return const Text('-');
    }

    final dateOnly = _onlyDate(dueDate);
    final overdue = _isOverdue(dateOnly);

    if (!overdue) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_month_rounded,
              size: 16,
              color: AppColors.mutedText,
            ),
            const SizedBox(width: 6),
            Text(dateOnly, style: const TextStyle(fontSize: 12)),
          ],
        ),
      );
    }

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
            color: Color(0xFFFCA5A5),
          ),
          const SizedBox(width: 6),
          Text(
            dateOnly,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFCA5A5),
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
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }


  Widget _jiraUserCell({
    required String text,
    required bool allowUnassigned,
    required void Function(ProjectUserEntity? user) onSelected,
  }) {
    final display = text.trim().isEmpty ? '-' : text;

    return PopupMenuButton<ProjectUserEntity?>(
      tooltip: '',
      padding: EdgeInsets.zero,
      position: PopupMenuPosition.under,
      onSelected: onSelected,
      itemBuilder: (ctx) {
        if (projectUsers.isEmpty) {
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
          items.add(
            PopupMenuItem<ProjectUserEntity?>(
              value: null,
              child: Row(
                children: const [
                  Icon(Icons.person_off_outlined,
                      size: 18, color: AppColors.mutedText),
                  SizedBox(width: 10),
                  Text('Unassigned'),
                ],
              ),
            ),
          );
          items.add(const PopupMenuDivider(height: 8));
        }

        for (final u in projectUsers) {
          items.add(
            PopupMenuItem<ProjectUserEntity?>(
              value: u,
              child: Row(
                children: [
                  _avatar(u.username, size: 24),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      u.username,
                      overflow: TextOverflow.ellipsis,
                    ),
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
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
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
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: AppColors.mutedText,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (issues.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text("No issues in this project yet."),
      );
    }

    final hController = ScrollController();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
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

                final next =
                    (hController.offset + delta).clamp(minExtent, maxExtent);

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
                  child: DataTable(
                    headingRowColor:
                        const MaterialStatePropertyAll(AppColors.surface2),
                    columns: const [
                      DataColumn(label: Text('Key')),
                      DataColumn(label: Text('Title')),
                      DataColumn(label: Text('Type')),
                      DataColumn(label: Text('Priority')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Assignee')),
                      DataColumn(label: Text('Reporter')),
                      DataColumn(label: Text('Due')),
                      DataColumn(label: Text('Created At')),
                      DataColumn(label: Text('Updated At')),
                    ],
                    rows: issues.map((i) {
                      return DataRow(
                        cells: [
                          DataCell(Text(i.key)),
                          DataCell(
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 380),
                              child: Text(i.title,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ),
                          DataCell(Text(i.type)),
                          DataCell(PriorityBadge(priority: i.priority)),
                          DataCell(StatusBadge(status: i.status)),
                          DataCell(
                            _jiraUserCell(
                              text: i.assignee?.username ?? 'Unassigned',
                              allowUnassigned: true,
                              onSelected: (u) {
                              },
                            ),
                          ),

                          DataCell(
                            _jiraUserCell(
                              text: i.reporter.username,
                              allowUnassigned: false,
                              onSelected: (u) {
                              },
                            ),
                          ),

                          DataCell(_dueChip(i.dueDate)),
                          DataCell(_calendarDateChip(i.createdAt)),
                          DataCell(_calendarDateChip(i.updatedAt)),
                        ],
                      );
                    }).toList(),
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
