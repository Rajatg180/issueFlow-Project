import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/issue_entity.dart';
import 'priority_badge.dart';
import 'status_badge.dart';

class IssuesTable extends StatelessWidget {
  final List<IssueEntity> issues;

  const IssuesTable({super.key, required this.issues});

  bool _isOverdue(String dueDateStr) {
    // dueDateStr expected format: "YYYY-MM-DD" (from your backend)
    try {
      final d = DateTime.parse(dueDateStr); // parses yyyy-mm-dd correctly
      final due = DateTime(d.year, d.month, d.day);

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      return due.isBefore(today); // strictly overdue (yesterday or earlier)
    } catch (_) {
      return false; // if format unexpected, don't mark overdue
    }
  }

  Widget _dueChip(String? dueDate) {
    if (dueDate == null || dueDate.trim().isEmpty) {
      return const Text('-');
    }

    final overdue = _isOverdue(dueDate);

    if (!overdue) {
      // normal (not overdue)
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(dueDate, style: const TextStyle(fontSize: 12)),
      );
    }

    // overdue -> RED CHIP
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF7F1D1D).withOpacity(0.35),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFB91C1C).withOpacity(0.8)),
      ),
      child: Text(
        dueDate,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFFFCA5A5),
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: const MaterialStatePropertyAll(AppColors.surface2),
            columns: const [
              DataColumn(label: Text('Key')),
              DataColumn(label: Text('Title')),
              DataColumn(label: Text('Type')),
              DataColumn(label: Text('Priority')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Assignee')),
              DataColumn(label: Text('Reporter')),
              DataColumn(label: Text('Due')),
            ],
            rows: issues.map((i) {
              return DataRow(
                cells: [
                  DataCell(Text(i.key)),
                  DataCell(
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 380),
                      child: Text(i.title, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  DataCell(Text(i.type)),
                  DataCell(PriorityBadge(priority: i.priority)),
                  DataCell(StatusBadge(status: i.status)),
                  DataCell(Text(i.assignee?.email ?? 'Unassigned')),
                  DataCell(Text(i.reporter.email)),
                  DataCell(_dueChip(i.dueDate)),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
