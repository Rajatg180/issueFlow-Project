import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Top bar similar to Jira: title + search + profile badge.
/// On mobile, we show a hamburger icon to open drawer.
class TopBar extends StatelessWidget implements PreferredSizeWidget {
  /// If provided, we show a menu button (used on mobile).
  final VoidCallback? onMenuTap;

  const TopBar({super.key, this.onMenuTap});

  /// Required by PreferredSizeWidget: tells Scaffold the appbar height.
  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      // Simple brand title for now
      title: const Text('IssueFlow'),
      backgroundColor: AppColors.surface,

      // Mobile only: menu icon that opens drawer
      leading: onMenuTap == null
          ? null
          : IconButton(
              icon: const Icon(Icons.menu),
              onPressed: onMenuTap,
            ),

      // Right side actions (search + avatar)
      actions: [
        IconButton(
          onPressed: () {}, // later -> open search page/dialog
          icon: const Icon(Icons.search),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.surface2,
            child: Text(
              'RG', // placeholder initials; later from user profile
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        ),
      ],
    );
  }
}
