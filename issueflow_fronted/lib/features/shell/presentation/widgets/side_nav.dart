import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../nav_items.dart';
import '../bloc/shell_bloc.dart';
import '../bloc/shell_event.dart';
import '../bloc/shell_state.dart';

/// Left navigation for desktop/tablet (NavigationRail).
/// On mobile we reuse the same widget inside a Drawer.
class SideNav extends StatelessWidget {
  /// When true, NavigationRail shows icons + labels (desktop style).
  /// When false, it shows only icons (tablet style).
  final bool extended;

  /// On mobile Drawer: after selecting an item, we should close drawer.
  final VoidCallback? onItemSelected;

  const SideNav({super.key, required this.extended, this.onItemSelected});

  @override
  Widget build(BuildContext context) {
    // BlocBuilder rebuilds only when ShellState changes (selected tab changes).
    return BlocBuilder<ShellBloc, ShellState>(
      builder: (context, state) {
        // Find which index should be selected in the rail based on current state
        final selectedIndex = navItems.indexWhere((e) => e.tab == state.selected);

        return NavigationRail(
          extended: extended,
          backgroundColor: AppColors.surface,

          selectedIndex: selectedIndex,

          // Triggered when user clicks a destination
          onDestinationSelected: (index) {
            // Tell bloc: user selected this tab
            context.read<ShellBloc>().add(ShellTabSelected(navItems[index].tab));

            // If this is inside a Drawer (mobile), close the drawer
            onItemSelected?.call();
          },

          // Top brand row in sidebar
          leading: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 8),
                const Icon(Icons.view_kanban_outlined, color: AppColors.textPrimary),
                if (extended) ...[
                  const SizedBox(width: 8),
                  Text('IssueFlow', style: Theme.of(context).textTheme.titleMedium),
                ],
              ],
            ),
          ),

          destinations: [
            for (final item in navItems)
              NavigationRailDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.icon, color: AppColors.textPrimary),
                label: Text(item.label),
              ),
          ],
        );
      },
    );
  }
}
