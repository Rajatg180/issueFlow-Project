import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../projects/presentation/bloc/project/projects_bloc.dart';
import '../../../projects/presentation/bloc/project/projects_state.dart';
import '../../nav_items.dart';
import '../bloc/shell_bloc.dart';
import '../bloc/shell_event.dart';
import '../bloc/shell_state.dart';

class SideNav extends StatelessWidget {
  final bool extended;
  final VoidCallback? onItemSelected;

  const SideNav({super.key, required this.extended, this.onItemSelected});

  @override
  Widget build(BuildContext context) {
    // ✅ Tablet: compact NavigationRail (icons only)
    if (!extended) {
      return _CompactRail(onItemSelected: onItemSelected);
    }

    // ✅ Desktop/Mobile Drawer: full sidebar with Pinned/Favorites/All Tabs
    return _FullSidebar(onItemSelected: onItemSelected);
  }
}

/// ------------------------------
/// Compact Rail (tablet)
/// ------------------------------
class _CompactRail extends StatelessWidget {
  final VoidCallback? onItemSelected;
  const _CompactRail({this.onItemSelected});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShellBloc, ShellState>(
      builder: (context, state) {
        final selectedIndex = navItems.indexWhere((e) => e.tab == state.selected);

        return NavigationRail(
          extended: false,
          backgroundColor: AppColors.surface,
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) {
            context.read<ShellBloc>().add(ShellTabSelected(navItems[index].tab));
            onItemSelected?.call();
          },
          leading: const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Icon(Icons.view_kanban_outlined, color: AppColors.textPrimary),
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

/// ------------------------------
/// Full Sidebar (desktop + mobile drawer)
/// ------------------------------
class _FullSidebar extends StatelessWidget {
  final VoidCallback? onItemSelected;
  const _FullSidebar({this.onItemSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      color: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            _BrandHeader(),
            const SizedBox(height: 10),
            Expanded(
              child: BlocBuilder<ProjectsBloc, ProjectsState>(
                builder: (context, pState) {
                  final projects = pState.items;

                  final pinned = projects.where((p) => p.isPinned == true).toList();
                  final favorites = projects.where((p) => p.isFavorite == true).toList();

                  // Optional: sort pinned/fav nicely
                  pinned.sort((a, b) => a.name.compareTo(b.name));
                  favorites.sort((a, b) => a.name.compareTo(b.name));

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    children: [
                      if (pinned.isNotEmpty) ...[
                        _SectionTitle("Pinned"),
                        const SizedBox(height: 6),
                        _PinnedReorderList(
                          pinned: pinned,
                          onProjectTap: (id) {
                            context.read<ShellBloc>().add(ShellProjectSelected(id));
                            onItemSelected?.call();
                          },
                        ),
                        const SizedBox(height: 14),
                      ],

                      if (favorites.isNotEmpty) ...[
                        _SectionTitle("Favorites"),
                        const SizedBox(height: 6),
                        ...favorites.map((p) => _ProjectRow(
                              title: p.name,
                              subtitle: p.key,
                              leading: Icons.star_rounded,
                              leadingColor: const Color(0xFFFFC107), // gold
                              onTap: () {
                                context.read<ShellBloc>().add(ShellProjectSelected(p.id));
                                onItemSelected?.call();
                              },
                            )),
                        const SizedBox(height: 14),
                      ],

                      _SectionTitle("Workspace"),
                      const SizedBox(height: 6),

                      BlocBuilder<ShellBloc, ShellState>(
                        builder: (context, sState) {
                          return Column(
                            children: [
                              for (final item in navItems)
                                _NavRow(
                                  label: item.label,
                                  icon: item.icon,
                                  selected: sState.selected == item.tab,
                                  onTap: () {
                                    context.read<ShellBloc>().add(ShellTabSelected(item.tab));
                                    onItemSelected?.call();
                                  },
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.view_kanban_outlined, color: AppColors.textPrimary),
          ),
          const SizedBox(width: 10),
          const Text(
            "IssueFlow",
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

/// Pinned list supports reorder visually.
/// ✅ This is UI-only reorder for now.
/// If you want server persistence, tell me your backend shape and we’ll add it.
class _PinnedReorderList extends StatefulWidget {
  final List pinned;
  final ValueChanged<String> onProjectTap;

  const _PinnedReorderList({
    required this.pinned,
    required this.onProjectTap,
  });

  @override
  State<_PinnedReorderList> createState() => _PinnedReorderListState();
}

class _PinnedReorderListState extends State<_PinnedReorderList> {
  late List _items;

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.pinned);
  }

  @override
  void didUpdateWidget(covariant _PinnedReorderList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep in sync if bloc updates
    _items = List.of(widget.pinned);
  }

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _items.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex -= 1;
          final item = _items.removeAt(oldIndex);
          _items.insert(newIndex, item);
        });

        // ✅ Optional: persist order later via bloc/repo endpoint
        // context.read<ProjectsBloc>().add(ProjectsPinnedOrderChanged(...));
      },
      itemBuilder: (context, index) {
        final p = _items[index];
        return _ProjectRow(
          key: ValueKey(p.id),
          title: p.name,
          subtitle: p.key,
          leading: Icons.push_pin_rounded,
          leadingColor: Colors.red, // soft gold
          trailing: const Icon(Icons.drag_handle, color: AppColors.textSecondary, size: 18),
          onTap: () => widget.onProjectTap(p.id),
        );
      },
    );
  }
}

class _ProjectRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData leading;
  final Color leadingColor;
  final Widget? trailing;
  final VoidCallback onTap;

  const _ProjectRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.leading,
    required this.leadingColor,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(leading, color: leadingColor, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _NavRow({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.surface2 : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.border : Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? AppColors.textPrimary : AppColors.textSecondary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
