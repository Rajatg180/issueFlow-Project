import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:issueflow_fronted/features/projects/presentation/bloc/project/projects_bloc.dart';
import 'package:issueflow_fronted/features/projects/presentation/bloc/project/projects_event.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/responsive/responsive.dart';
import '../../../dashboard/presentation/pages/dashboard_page.dart';
import '../../../issues/presentation/pages/issues_page.dart';
import '../../../projects/presentation/pages/projects/projects_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../nav_items.dart';
import '../bloc/shell_bloc.dart';
import '../bloc/shell_event.dart';
import '../bloc/shell_state.dart';
import '../widgets/side_nav.dart';
import '../widgets/top_bar.dart';

class ShellPage extends StatefulWidget {
  const ShellPage({super.key});

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _drawerOpen = false; // mobile drawer state
  bool _sidebarCollapsed = false; // desktop/tablet sidebar state

  // Keep pages alive => avoids reloading/re-fetching when switching tabs.
  late final List<Widget> _pages = const [
    DashboardPage(),
    ProjectsPage(),
    IssuesTablePage(),
    SettingsPage(),
  ];

  int _indexForTab(ShellTab tab) {
    return switch (tab) {
      ShellTab.dashboard => 0,
      ShellTab.projects => 1,
      ShellTab.issues => 2,
      ShellTab.settings => 3,
    };
  }

  void _toggleMobileDrawer() {
    final scaffold = _scaffoldKey.currentState;
    if (scaffold == null) return;

    if (_drawerOpen) {
      Navigator.of(context).pop(); // closes drawer
    } else {
      scaffold.openDrawer();
    }
  }

  void _toggleDesktopSidebar() {
    setState(() => _sidebarCollapsed = !_sidebarCollapsed);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isDesktop = Responsive.isDesktop(context);

    final c = context.c;

    return BlocBuilder<ShellBloc, ShellState>(
      builder: (context, state) {
        final idx = _indexForTab(state.selected);

        final content = Container(
          color: c.bg,
          child: IndexedStack(
            index: idx,
            children: _pages,
          ),
        );

        // ---------------- MOBILE (Drawer) ----------------
        if (isMobile) {
          return Scaffold(
            key: _scaffoldKey,
            onDrawerChanged: (isOpen) => setState(() => _drawerOpen = isOpen),
            appBar: TopBar(
              isMobile: true,
              drawerOpen: _drawerOpen,
              onNavToggle: _toggleMobileDrawer,
            ),
            drawer: Drawer(
              child: SafeArea(
                child: SideNav(
                  extended: true,
                  onItemSelected: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            body: content,
          );
        }

        // ---------------- TABLET / DESKTOP (Collapsible rail) ----------------
        // You can decide:
        // - Desktop default expanded
        // - Tablet default collapsed
        final extended = isDesktop && !_sidebarCollapsed;

        return Scaffold(
          appBar: TopBar(
            isMobile: false,
            sidebarCollapsed: _sidebarCollapsed,
            onNavToggle: _toggleDesktopSidebar,
          ),
          body: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                width: _sidebarCollapsed ? 72 : 280, // smooth collapse
                child: ClipRect(
                  child: SideNav(
                    extended: extended,
                    onItemSelected: null,
                  ),
                ),
              ),
              VerticalDivider(width: 1, thickness: 1, color: c.border),
              Expanded(child: content),
            ],
          ),
        );
      },
    );
  }
}
