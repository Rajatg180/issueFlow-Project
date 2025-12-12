// this is a file defining navigation items for the shell of the application
import 'package:flutter/material.dart';

enum ShellTab { dashboard, projects, issues, settings }

class NavItem {
  final ShellTab tab;
  final String label;
  final IconData icon;

  const NavItem({required this.tab, required this.label, required this.icon});
}

const navItems = <NavItem>[
  NavItem(tab: ShellTab.dashboard, label: 'Dashboard', icon: Icons.dashboard_outlined),
  NavItem(tab: ShellTab.projects, label: 'Projects', icon: Icons.workspaces_outline),
  NavItem(tab: ShellTab.issues, label: 'Issues', icon: Icons.bug_report_outlined),
  NavItem(tab: ShellTab.settings, label: 'Settings', icon: Icons.settings_outlined),
];
