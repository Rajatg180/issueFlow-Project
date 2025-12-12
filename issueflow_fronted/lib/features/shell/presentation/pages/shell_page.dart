import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/responsive/responsive.dart';
import '../../../dashboard/presentation/pages/dashboard_page.dart';
import '../../../issues/presentation/pages/issues_page.dart';
import '../../../projects/presentation/pages/projects_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../nav_items.dart';
import '../bloc/shell_bloc.dart';
import '../bloc/shell_state.dart';
import '../widgets/side_nav.dart';
import '../widgets/top_bar.dart';

/// App shell is the base frame (sidebar + topbar + content area).
/// We keep it in its own feature so it stays clean and reusable.
class ShellPage extends StatefulWidget {
  const ShellPage({super.key});

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  // Needed to open Drawer programmatically on mobile (hamburger button)
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  /// Maps selected tab to the page widget.
  /// Later we can replace with router, but this is simple and clean now.
  Widget _pageForTab(ShellTab tab) {
    return switch (tab) {
      ShellTab.dashboard => const DashboardPage(),
      ShellTab.projects => const ProjectsPage(),
      ShellTab.issues => const IssuesPage(),
      ShellTab.settings => const SettingsPage(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isDesktop = Responsive.isDesktop(context);

    return BlocBuilder<ShellBloc, ShellState>(
      builder: (context, state) {
        // The main content area changes depending on selected tab
        final content = Container(
          color: AppColors.bg,
          child: _pageForTab(state.selected),
        );

        /// MOBILE LAYOUT:
        /// - Drawer navigation
        /// - TopBar has hamburger icon
        if (isMobile) {
          return Scaffold(
            key: _scaffoldKey,
            appBar: TopBar(
              onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            drawer: Drawer(
              child: SafeArea(
                // We reuse SideNav inside Drawer
                child: SideNav(
                  extended: true,
                  // After selecting an item, close drawer
                  onItemSelected: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            body: content,
          );
        }

        /// TABLET / DESKTOP LAYOUT:
        /// - Left NavigationRail
        /// - Desktop uses extended rail (icons + labels)
        return Scaffold(
          appBar: const TopBar(),
          body: Row(
            children: [
              SideNav(extended: isDesktop),
              const VerticalDivider(width: 1, thickness: 1),
              Expanded(child: content),
            ],
          ),
        );
      },
    );
  }
}
