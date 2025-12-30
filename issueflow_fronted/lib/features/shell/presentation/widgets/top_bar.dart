import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onNavToggle;
  final bool drawerOpen;
  final bool sidebarCollapsed;
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

  IconData _leadingIcon() {
    if (isMobile) return drawerOpen ? Icons.arrow_back : Icons.menu;
    return sidebarCollapsed ? Icons.chevron_right : Icons.chevron_left;
  }

  String _leadingTooltip() {
    if (isMobile) return drawerOpen ? "Close menu" : "Open menu";
    return sidebarCollapsed ? "Expand sidebar" : "Collapse sidebar";
  }

  String _initialsFromEmail(String email) {
    final e = email.trim();
    if (e.isEmpty) return "?";
    final namePart = e.split('@').first;
    if (namePart.isEmpty) return "?";
    final chunks = namePart
        .split(RegExp(r'[._\-\s]+'))
        .where((x) => x.isNotEmpty)
        .toList();

    if (chunks.length >= 2) {
      return (chunks[0][0] + chunks[1][0]).toUpperCase();
    }
    return namePart.length >= 2
        ? namePart.substring(0, 2).toUpperCase()
        : namePart[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final showLeading = onNavToggle != null;
    final c = context.c;

    return AppBar(
      title: const Text('IssueFlow'),
      backgroundColor: c.surface,
      elevation: 0,
      leading: !showLeading
          ? null
          : IconButton(
              tooltip: _leadingTooltip(),
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
                  _leadingIcon(),
                  key: ValueKey(
                    "${isMobile}_${drawerOpen}_${sidebarCollapsed}",
                  ),
                ),
              ),
            ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final email = state is Authenticated ? state.email : "";
              final initials = _initialsFromEmail(email);

              return Tooltip(
                message: email.isEmpty ? "Profile" : email,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: c.surface2,
                  child: Text(
                    initials,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
