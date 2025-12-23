import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status; // todo/in_progress/done

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();

    Color bg;
    Color border;
    String label;

    switch (s) {
      case 'done':
        bg = AppColors.success.withOpacity(0.15);
        border = AppColors.success.withOpacity(0.5);
        label = 'Done';
        break;
      case 'in_progress':
        bg = AppColors.info.withOpacity(0.15);
        border = AppColors.info.withOpacity(0.5);
        label = 'In Progress';
        break;
      default:
        bg = AppColors.surface2;
        border = AppColors.border;
        label = 'To Do';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}
