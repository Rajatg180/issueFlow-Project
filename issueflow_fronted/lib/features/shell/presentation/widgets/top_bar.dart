import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Top bar similar to Jira.
/// - Mobile: animated hamburger <-> back arrow (drawer open/close)
/// - Desktop/Tablet: animated chevron (collapse/expand sidebar)
class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onNavToggle;

  /// True when drawer is open (mobile)
  final bool drawerOpen;

  /// True when sidebar is collapsed (desktop/tablet)
  final bool sidebarCollapsed;

  /// Whether we are in mobile mode (controls which icon pair to use)
  final bool isMobile;

  const TopBar({
    super.key,
    this.onNavToggle,
    this.drawerOpen = false,
    this.sidebarCollapsed = false,
    this.isMobile = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final showLeading = onNavToggle != null;

    IconData leadingIcon() {
      if (isMobile) {
        return drawerOpen ? Icons.arrow_back : Icons.menu;
      }
      return sidebarCollapsed ? Icons.chevron_right : Icons.chevron_left;
    }

    String leadingTooltip() {
      if (isMobile) return drawerOpen ? "Close menu" : "Open menu";
      return sidebarCollapsed ? "Expand sidebar" : "Collapse sidebar";
    }

    return AppBar(
      title: const Text('IssueFlow'),
      backgroundColor: AppColors.surface,
      elevation: 0,

      leading: !showLeading
          ? null
          : IconButton(
              tooltip: leadingTooltip(),
              onPressed: onNavToggle,
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, anim) {
                  return RotationTransition(
                    turns: Tween<double>(begin: 0.90, end: 1.0).animate(anim),
                    child: FadeTransition(opacity: anim, child: child),
                  );
                },
                child: Icon(
                  leadingIcon(),
                  key: ValueKey("${isMobile}_${drawerOpen}_${sidebarCollapsed}"),
                ),
              ),
            ),

      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.search),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.surface2,
            child: Text(
              'RG',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        ),
      ],
    );
  }
}
