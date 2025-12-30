import 'package:flutter/material.dart';
import '../../../../core/theme/app_palette.dart';

class PriorityBadge extends StatelessWidget {
  final String priority; // low/medium/high

  const PriorityBadge({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final p = priority.toLowerCase();

    Color bg;
    Color border;
    String label;

    switch (p) {
      case 'high':
        bg = c.warning.withOpacity(0.18);
        border = c.warning.withOpacity(0.6);
        label = 'High';
        break;
      case 'low':
        bg = c.surface2;
        border = c.border;
        label = 'Low';
        break;
      default:
        bg = c.info.withOpacity(0.15);
        border = c.info.withOpacity(0.5);
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
