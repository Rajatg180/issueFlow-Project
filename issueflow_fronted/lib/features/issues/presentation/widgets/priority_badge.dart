import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class PriorityBadge extends StatelessWidget {
  final String priority; // low/medium/high

  const PriorityBadge({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    final p = priority.toLowerCase();

    Color bg;
    Color border;
    String label;

    switch (p) {
      case 'high':
        bg = AppColors.warning.withOpacity(0.18);
        border = AppColors.warning.withOpacity(0.6);
        label = 'High';
        break;
      case 'low':
        bg = AppColors.surface2;
        border = AppColors.border;
        label = 'Low';
        break;
      default:
        bg = AppColors.info.withOpacity(0.15);
        border = AppColors.info.withOpacity(0.5);
        label = 'Medium';
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
