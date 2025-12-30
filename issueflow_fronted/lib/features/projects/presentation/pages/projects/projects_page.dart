import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:issueflow_fronted/core/theme/app_palette.dart';
import 'package:issueflow_fronted/core/widgets/app_toast.dart';
import 'package:issueflow_fronted/core/widgets/responsive/responsive.dart';

import 'package:issueflow_fronted/features/projects/presentation/bloc/invite/invites_bloc.dart';
import 'package:issueflow_fronted/features/projects/presentation/bloc/invite/invites_event.dart';
import 'package:issueflow_fronted/features/projects/presentation/bloc/invite/invites_state.dart';

import 'package:issueflow_fronted/features/projects/presentation/bloc/project/projects_bloc.dart';
import 'package:issueflow_fronted/features/projects/presentation/bloc/project/projects_event.dart';
import 'package:issueflow_fronted/features/projects/presentation/bloc/project/projects_state.dart';

import 'package:issueflow_fronted/features/projects/presentation/cubit/invite_members_cubit.dart';

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  final _searchCtrl = TextEditingController();
  String _query = "";

  ProjectsState? _lastProjectsState;

  @override
  void initState() {
    super.initState();
    context.read<ProjectsBloc>().add(const ProjectsFetchRequested());

    try {
      context.read<InvitesBloc>().add(const InvitesFetchRequested());
    } catch (_) {}

    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openCreate(BuildContext context) async {
    final isMobile = Responsive.isMobile(context);
    final c = context.c;

    if (isMobile) {
      await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: c.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        builder: (_) => const _CreateProjectSheet(),
      );
      return;
    }

    await showDialog<bool>(
      context: context,
      builder: (_) => const _CreateProjectDialog(),
    );
  }

  Future<void> _openInvites(BuildContext context) async {
    final isMobile = Responsive.isMobile(context);
    final c = context.c;

    final invitesBloc = context.read<InvitesBloc>();

    invitesBloc.add(const InvitesFetchRequested());

    if (isMobile) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: c.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        builder: (_) => BlocProvider.value(
          value: invitesBloc,
          child: const _InvitesSheet(),
        ),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (_) =>
          BlocProvider.value(value: invitesBloc, child: const _InvitesDialog()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final c = context.c;

    final invitesCount = context.select(
      (InvitesBloc b) => b.state.invites.length,
    );

    return BlocConsumer<ProjectsBloc, ProjectsState>(
      listenWhen: (prev, curr) => true,
      listener: (context, state) {
        final prev = _lastProjectsState;

        if (state.error != null && (prev == null || prev.error != state.error)) {
          AppToast.show(
            context,
            message: state.error!.replaceFirst('Exception: ', ''),
            isError: true,
          );
        } else if (prev != null) {
          if (prev.creating && !state.creating && state.error == null) {
            AppToast.show(context, message: "Project created");
          }

          if (prev.deletingId != null && state.deletingId == null && state.error == null) {
            AppToast.show(context, message: "Project deleted");
          }

          if (prev.editingId != null && state.editingId == null && state.error == null) {
            AppToast.show(context, message: "Project updated");
          }
        }

        _lastProjectsState = state;
      },
      builder: (context, state) {
        final items = state.items.where((p) {
          if (_query.isEmpty) return true;
          final name = p.name.toLowerCase();
          final key = p.key.toLowerCase();
          final desc = (p.description ?? "").toLowerCase();
          return name.contains(_query) || key.contains(_query) || desc.contains(_query);
        }).toList();

        items.sort((a, b) {
          int byPin = (b.isPinned ? 1 : 0).compareTo(a.isPinned ? 1 : 0);
          if (byPin != 0) return byPin;
          int byFav = (b.isFavorite ? 1 : 0).compareTo(a.isFavorite ? 1 : 0);
          if (byFav != 0) return byFav;
          return b.createdAt.compareTo(a.createdAt);
        });

        return Container(
          color: c.bg,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 18,
                  vertical: isMobile ? 12 : 18,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(
                      searchCtrl: _searchCtrl,
                      creating: state.creating,
                      onCreate: () => _openCreate(context),
                      onInvites: () => _openInvites(context),
                      invitesCount: invitesCount,
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _Body(
                        loading: state.loading,
                        creating: state.creating,
                        deletingId: state.deletingId,
                        updatingPrefId: state.updatingPrefId,
                        editingId: state.editingId,
                        hasSearch: _query.isNotEmpty,
                        filteredCount: items.length,
                        allCount: state.items.length,
                        items: items,
                        onCreate: () => _openCreate(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatefulWidget {
  const _Header({
    required this.searchCtrl,
    required this.creating,
    required this.onCreate,
    required this.onInvites,
    required this.invitesCount,
  });

  final TextEditingController searchCtrl;
  final bool creating;
  final VoidCallback onCreate;
  final VoidCallback onInvites;
  final int invitesCount;

  @override
  State<_Header> createState() => _HeaderState();
}

class _HeaderState extends State<_Header> {
  bool _searchOpen = false;
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _openSearch() {
    if (_searchOpen) return;
    setState(() => _searchOpen = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  void _closeSearch() {
    if (!_searchOpen) return;
    setState(() => _searchOpen = false);
    widget.searchCtrl.clear();
    _focus.unfocus();
  }

  Widget _bellWithBadge({required bool hasInvites, required int count}) {
    final c = context.c;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.notifications_none),
        if (hasInvites)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: c.surface, width: 2),
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                count > 99 ? "99+" : "$count",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _squareButton({
    required VoidCallback? onTap,
    required Widget child,
    String? tooltip,
  }) {
    final c = context.c;

    return SizedBox(
      height: 44,
      width: 44,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.border),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Tooltip(
              message: tooltip ?? "",
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }

  Widget _mobileSearchField() {
    final c = context.c;

    return SizedBox(
      height: 44,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: c.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            IconButton(
              tooltip: "Close search",
              onPressed: _closeSearch,
              icon: Icon(
                Icons.close,
                color: c.textSecondary,
                size: 18,
              ),
            ),
            Expanded(
              child: TextField(
                controller: widget.searchCtrl,
                focusNode: _focus,
                decoration: const InputDecoration(
                  hintText: "Search projects…",
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.only(bottom: 2),
                ),
              ),
            ),
            if (widget.searchCtrl.text.isNotEmpty)
              IconButton(
                tooltip: "Clear",
                onPressed: () => widget.searchCtrl.clear(),
                icon: Icon(
                  Icons.backspace_outlined,
                  color: c.textSecondary,
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final hasInvites = widget.invitesCount > 0;
    final c = context.c;

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 720;

          final title = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.dashboard_customize_outlined,
                color: c.textSecondary,
              ),
              const SizedBox(width: 10),
              const _HeaderTitle(),
            ],
          );

          if (isMobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: title),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _squareButton(
                          tooltip: _searchOpen ? "Close search" : "Search",
                          onTap: _searchOpen ? _closeSearch : _openSearch,
                          child: Icon(
                            _searchOpen ? Icons.close : Icons.search,
                            color: c.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _squareButton(
                          tooltip: "Invites",
                          onTap: widget.onInvites,
                          child: _bellWithBadge(
                            hasInvites: hasInvites,
                            count: widget.invitesCount,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _squareButton(
                          tooltip: "Create project",
                          onTap: widget.creating ? null : widget.onCreate,
                          child: Icon(
                            Icons.add,
                            color: widget.creating ? c.textSecondary : c.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (_searchOpen) ...[
                  const SizedBox(height: 10),
                  _mobileSearchField(),
                ],
              ],
            );
          }

          final actions = SizedBox(
            width: isNarrow ? double.infinity : null,
            child: Row(
              mainAxisSize: isNarrow ? MainAxisSize.max : MainAxisSize.min,
              children: [
                Expanded(
                  flex: isNarrow ? 1 : 0,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      width: isNarrow ? double.infinity : (_searchOpen ? 340 : 44),
                      height: 44,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        decoration: BoxDecoration(
                          color: c.surface2,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: c.border),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              tooltip: _searchOpen ? "Close search" : "Search",
                              onPressed: _searchOpen ? _closeSearch : _openSearch,
                              icon: Icon(
                                _searchOpen ? Icons.close : Icons.search,
                                color: c.textSecondary,
                                size: 18,
                              ),
                            ),
                            if (_searchOpen) ...[
                              Expanded(
                                child: TextField(
                                  controller: widget.searchCtrl,
                                  focusNode: _focus,
                                  decoration: const InputDecoration(
                                    hintText: "Search projects…",
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.only(bottom: 2),
                                  ),
                                ),
                              ),
                              if (widget.searchCtrl.text.isNotEmpty)
                                IconButton(
                                  tooltip: "Clear",
                                  onPressed: () => widget.searchCtrl.clear(),
                                  icon: Icon(
                                    Icons.backspace_outlined,
                                    color: c.textSecondary,
                                    size: 18,
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: widget.onInvites,
                    icon: _bellWithBadge(
                      hasInvites: hasInvites,
                      count: widget.invitesCount,
                    ),
                    label: const Text("Project invites"),
                  ),
                ),
                const SizedBox(width: 8),
                if (isNarrow)
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: widget.creating ? null : widget.onCreate,
                        icon: const Icon(Icons.add),
                        label: const Text("Create project"),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: widget.creating ? null : widget.onCreate,
                      icon: const Icon(Icons.add),
                      label: const Text("Create project"),
                    ),
                  ),
              ],
            ),
          );

          return Wrap(
            runSpacing: 10,
            spacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (isNarrow) ...[
                SizedBox(width: double.infinity, child: title),
                actions,
              ] else ...[
                title,
                const SizedBox(width: 8),
                actions,
              ],
            ],
          );
        },
      ),
    );
  }
}

class _HeaderTitle extends StatelessWidget {
  const _HeaderTitle();

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final c = context.c;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "Projects",
          style: TextStyle(
            color: c.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (!isMobile)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              "Manage projects and jump into issues.",
              style: TextStyle(color: c.textSecondary, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.loading,
    required this.creating,
    required this.deletingId,
    required this.updatingPrefId,
    required this.editingId,
    required this.hasSearch,
    required this.filteredCount,
    required this.allCount,
    required this.items,
    required this.onCreate,
  });

  final bool loading;
  final bool creating;
  final String? deletingId;
  final String? updatingPrefId;
  final String? editingId;

  final bool hasSearch;
  final int filteredCount;
  final int allCount;
  final List items;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    if (loading) return const Center(child: CircularProgressIndicator());

    if (items.isEmpty) {
      return _EmptyState(
        hasSearch: hasSearch,
        creating: creating,
        onCreate: onCreate,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Text(
            hasSearch ? "Showing $filteredCount of $allCount projects" : "$allCount projects",
            style: TextStyle(
              color: c.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final p = items[index];

              return _ProjectTile(
                id: p.id,
                name: p.name,
                keyText: p.key,
                description: p.description,
                createdAt: p.createdAt,
                isFavorite: p.isFavorite,
                isPinned: p.isPinned,
                isDeleting: deletingId == p.id,
                isUpdatingPref: updatingPrefId == p.id,
                isEditing: editingId == p.id,
                role: p.role,
                onTap: () {},
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ProjectTile extends StatelessWidget {
  const _ProjectTile({
    required this.id,
    required this.name,
    required this.keyText,
    required this.description,
    required this.createdAt,
    required this.isFavorite,
    required this.isPinned,
    required this.isDeleting,
    required this.isUpdatingPref,
    required this.isEditing,
    required this.onTap,
    required this.role,
  });

  final String id;
  final String name;
  final String keyText;
  final String? description;
  final DateTime createdAt;
  final bool isFavorite;
  final bool isPinned;
  final String role;
  final bool isDeleting;
  final bool isUpdatingPref;
  final bool isEditing;
  final VoidCallback onTap;

  String _createdLabel(DateTime d) {
    String two(int v) => v < 10 ? "0$v" : "$v";
    return "${two(d.day)}/${two(d.month)}/${d.year}";
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final c = context.c;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          "Delete project?",
          style: TextStyle(
            color: c.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          "Project $keyText will be removed.\nAll issues in this project will also be deleted.",
          style: TextStyle(color: c.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7F1D1D),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (ok == true) {
      context.read<ProjectsBloc>().add(ProjectsDeleteRequested(id));
    }
  }

  void _toggleFavorite(BuildContext context) {
    if (isUpdatingPref || isDeleting || isEditing) return;
    context.read<ProjectsBloc>().add(
          ProjectsFavoriteToggled(projectId: id, value: !isFavorite),
        );
    AppToast.show(
      context,
      message: !isFavorite ? "Added to favorites" : "Removed from favorites",
    );
  }

  void _togglePin(BuildContext context) {
    if (isUpdatingPref || isDeleting || isEditing) return;
    context.read<ProjectsBloc>().add(
          ProjectsPinnedToggled(projectId: id, value: !isPinned),
        );
    AppToast.show(
      context,
      message: !isPinned ? "Pinned to sidebar" : "Unpinned",
    );
  }

  Future<void> _openInviteMembers(BuildContext context) async {
    if (isUpdatingPref || isDeleting || isEditing) return;

    InviteMembersCubit? cubit;
    try {
      cubit = context.read<InviteMembersCubit>();
    } catch (_) {
      cubit = null;
    }

    if (cubit == null) {
      AppToast.show(
        context,
        isError: true,
        message: "InviteMembersCubit not found. Provide it with BlocProvider.",
      );
      return;
    }

    final isMobile = Responsive.isMobile(context);
    final c = context.c;

    if (isMobile) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: c.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        builder: (_) => BlocProvider.value(
          value: cubit!,
          child: _InviteMembersSheet(
            projectId: id,
            projectName: name,
            projectKey: keyText,
          ),
        ),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: cubit!,
        child: _InviteMembersDialog(
          projectId: id,
          projectName: name,
          projectKey: keyText,
        ),
      ),
    );
  }

  Future<void> _openEditProject(BuildContext context) async {
    if (isUpdatingPref || isDeleting || isEditing) return;

    final isMobile = Responsive.isMobile(context);
    final c = context.c;

    if (isMobile) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: c.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        builder: (_) => _EditProjectSheet(
          projectId: id,
          initialName: name,
          initialKey: keyText,
          initialDescription: description,
        ),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (_) => _EditProjectDialog(
        projectId: id,
        initialName: name,
        initialKey: keyText,
        initialDescription: description,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cPal = context.c;

    final disabled = isDeleting || isUpdatingPref || isEditing;
    final canManage = role == "owner";

    return LayoutBuilder(
      builder: (context, c) {
        final narrow = c.maxWidth < 520;
        final veryNarrow = c.maxWidth < 380;

        final createdPill = Text(
          "Created ${_createdLabel(createdAt)}",
          style: TextStyle(
            color: cPal.textSecondary,
            fontSize: 8,
            fontWeight: FontWeight.w600,
          ),
        );

        Widget rightActionsInline() {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (canManage)
                IconButton(
                  tooltip: "Invite members",
                  onPressed: disabled ? null : () => _openInviteMembers(context),
                  icon: Icon(
                    Icons.person_add_alt_1,
                    color: cPal.textSecondary,
                  ),
                ),
              if (canManage)
                IconButton(
                  tooltip: "Edit project",
                  onPressed: disabled ? null : () => _openEditProject(context),
                  icon: Icon(
                    Icons.edit_outlined,
                    color: cPal.textSecondary,
                  ),
                ),
              IconButton(
                tooltip: isPinned ? "Unpin" : "Pin",
                onPressed: disabled ? null : () => _togglePin(context),
                icon: Icon(
                  isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  color: isPinned ? Colors.red : cPal.textSecondary,
                ),
              ),
              IconButton(
                tooltip: isFavorite ? "Unfavorite" : "Favorite",
                onPressed: disabled ? null : () => _toggleFavorite(context),
                icon: Icon(
                  isFavorite ? Icons.star : Icons.star_border,
                  color: isFavorite ? Colors.amber : cPal.textSecondary,
                ),
              ),
              PopupMenuButton<String>(
                tooltip: "Actions",
                color: cPal.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (v) {
                  if (v == "invite") _openInviteMembers(context);
                  if (v == "edit") _openEditProject(context);
                  if (v == "delete") _confirmDelete(context);
                  if (v == "fav") _toggleFavorite(context);
                  if (v == "pin") _togglePin(context);
                },
                itemBuilder: (_) => [
                  if (canManage)
                    PopupMenuItem(
                      value: "invite",
                      child: Text(
                        "Invite members",
                        style: TextStyle(color: cPal.textPrimary),
                      ),
                    ),
                  if (canManage)
                    PopupMenuItem(
                      value: "edit",
                      child: Text(
                        "Edit project",
                        style: TextStyle(color: cPal.textPrimary),
                      ),
                    ),
                  PopupMenuItem(
                    value: "pin",
                    child: Text(
                      "Pin/Unpin",
                      style: TextStyle(color: cPal.textPrimary),
                    ),
                  ),
                  PopupMenuItem(
                    value: "fav",
                    child: Text(
                      "Favorite/Unfavorite",
                      style: TextStyle(color: cPal.textPrimary),
                    ),
                  ),
                  if (canManage) const PopupMenuDivider(),
                  if (canManage)
                    PopupMenuItem(
                      value: "delete",
                      child: Text(
                        "Delete",
                        style: TextStyle(color: cPal.textPrimary),
                      ),
                    ),
                ],
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(Icons.more_vert, color: cPal.textSecondary),
                ),
              ),
            ],
          );
        }

        Widget rightActionsMenuOnly() {
          return PopupMenuButton<String>(
            tooltip: "Actions",
            color: cPal.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (v) {
              if (v == "invite") _openInviteMembers(context);
              if (v == "edit") _openEditProject(context);
              if (v == "fav") _toggleFavorite(context);
              if (v == "pin") _togglePin(context);
              if (v == "delete") _confirmDelete(context);
            },
            itemBuilder: (_) => [
              if (canManage)
                PopupMenuItem(
                  value: "invite",
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_add_alt_1,
                        size: 18,
                        color: cPal.textSecondary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Invite members",
                        style: TextStyle(color: cPal.textPrimary),
                      ),
                    ],
                  ),
                ),
              if (canManage)
                PopupMenuItem(
                  value: "edit",
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: cPal.textSecondary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Edit project",
                        style: TextStyle(color: cPal.textPrimary),
                      ),
                    ],
                  ),
                ),
              PopupMenuItem(
                value: "pin",
                child: Row(
                  children: [
                    Icon(
                      isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                      size: 18,
                      color: isPinned ? Colors.red : cPal.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isPinned ? "Unpin" : "Pin",
                      style: TextStyle(color: cPal.textPrimary),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: "fav",
                child: Row(
                  children: [
                    Icon(
                      isFavorite ? Icons.star : Icons.star_border,
                      size: 18,
                      color: isFavorite ? Colors.amber : cPal.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isFavorite ? "Unfavorite" : "Favorite",
                      style: TextStyle(color: cPal.textPrimary),
                    ),
                  ],
                ),
              ),
              if (canManage) const PopupMenuDivider(),
              if (canManage)
                const PopupMenuItem(
                  value: "delete",
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: Color(0xFFEF4444),
                      ),
                      SizedBox(width: 10),
                      Text("Delete"),
                    ],
                  ),
                ),
            ],
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(Icons.more_vert, color: cPal.textSecondary),
            ),
          );
        }

        Widget leadingRail() {
          return SizedBox(
            width: 56,
            child: Container(
              height: double.infinity,
              decoration: BoxDecoration(
                color: cPal.surface2,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cPal.border),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    keyText.length >= 2 ? keyText.substring(0, 2) : keyText,
                    style: TextStyle(
                      color: cPal.textPrimary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Opacity(
          opacity: disabled ? 0.75 : 1,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: disabled ? null : onTap,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cPal.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: cPal.border),
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    leadingRail(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: TextStyle(
                                        color: cPal.textPrimary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        height: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        Text(
                                          (description == null || description!.trim().isEmpty)
                                              ? "No description"
                                              : description!.trim(),
                                          style: TextStyle(
                                            color: cPal.textSecondary,
                                            fontSize: 12.5,
                                            height: 1.35,
                                          ),
                                          maxLines: veryNarrow ? 3 : 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (isDeleting || isEditing)
                                const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              else
                                (narrow || veryNarrow ? rightActionsMenuOnly() : rightActionsInline()),
                            ],
                          ),
                          const Spacer(),
                          createdPill,
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ========================
// ✅ NEW EDIT PROJECT UI
// ========================

class _EditProjectDialog extends StatelessWidget {
  const _EditProjectDialog({
    required this.projectId,
    required this.initialName,
    required this.initialKey,
    required this.initialDescription,
  });

  final String projectId;
  final String initialName;
  final String initialKey;
  final String? initialDescription;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Dialog(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: _EditProjectForm(
          projectId: projectId,
          initialName: initialName,
          initialKey: initialKey,
          initialDescription: initialDescription,
          isBottomSheet: false,
        ),
      ),
    );
  }
}

class _EditProjectSheet extends StatelessWidget {
  const _EditProjectSheet({
    required this.projectId,
    required this.initialName,
    required this.initialKey,
    required this.initialDescription,
  });

  final String projectId;
  final String initialName;
  final String initialKey;
  final String? initialDescription;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: SafeArea(
        top: false,
        child: _EditProjectForm(
          projectId: projectId,
          initialName: initialName,
          initialKey: initialKey,
          initialDescription: initialDescription,
          isBottomSheet: true,
        ),
      ),
    );
  }
}

class _EditProjectForm extends StatefulWidget {
  const _EditProjectForm({
    required this.projectId,
    required this.initialName,
    required this.initialKey,
    required this.initialDescription,
    required this.isBottomSheet,
  });

  final String projectId;
  final String initialName;
  final String initialKey;
  final String? initialDescription;
  final bool isBottomSheet;

  @override
  State<_EditProjectForm> createState() => _EditProjectFormState();
}

class _EditProjectFormState extends State<_EditProjectForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _keyCtrl;
  late final TextEditingController _descCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
    _keyCtrl = TextEditingController(text: widget.initialKey);
    _descCtrl = TextEditingController(text: widget.initialDescription ?? "");
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _keyCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final c = context.c;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        widget.isBottomSheet ? 16 : 18,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  "Edit project",
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: "Close",
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: c.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              "Update name, key, or description.",
              style: TextStyle(color: c.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 14),
            const _FieldLabel("Name"),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(hintText: "Project name"),
              validator: (v) => (v == null || v.trim().isEmpty) ? "Name is required" : null,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            const _FieldLabel("Key"),
            const SizedBox(height: 6),
            TextFormField(
              controller: _keyCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(hintText: "e.g. IF"),
              validator: (v) {
                final val = (v ?? "").trim();
                if (val.isEmpty) return "Key is required";
                if (val.length < 2) return "Min 2 characters";
                if (val.length > 10) return "Max 10 characters";
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            const _FieldLabel("Description (optional)"),
            const SizedBox(height: 6),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(hintText: "Short summary…"),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submit,
                    child: Text(isMobile ? "Save" : "Save changes"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;

    final name = _nameCtrl.text.trim();
    final key = _keyCtrl.text.trim();
    final desc = _descCtrl.text.trim();

    final String? sendName = name != widget.initialName ? name : null;
    final String? sendKey = key != widget.initialKey ? key : null;
    final String? sendDesc =
        (desc != (widget.initialDescription ?? "")) ? (desc.isEmpty ? "" : desc) : null;

    if (sendName == null && sendKey == null && sendDesc == null) {
      Navigator.pop(context);
      return;
    }

    context.read<ProjectsBloc>().add(
          ProjectsEditRequested(
            projectId: widget.projectId,
            name: sendName,
            key: sendKey,
            description: sendDesc,
          ),
        );

    Navigator.pop(context);
  }
}

class _InviteMembersDialog extends StatelessWidget {
  const _InviteMembersDialog({
    required this.projectId,
    required this.projectName,
    required this.projectKey,
  });

  final String projectId;
  final String projectName;
  final String projectKey;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Dialog(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: _InviteMembersForm(
          projectId: projectId,
          projectName: projectName,
          projectKey: projectKey,
          isBottomSheet: false,
        ),
      ),
    );
  }
}

class _InviteMembersSheet extends StatelessWidget {
  const _InviteMembersSheet({
    required this.projectId,
    required this.projectName,
    required this.projectKey,
  });

  final String projectId;
  final String projectName;
  final String projectKey;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: SafeArea(
        top: false,
        child: _InviteMembersForm(
          projectId: projectId,
          projectName: projectName,
          projectKey: projectKey,
          isBottomSheet: true,
        ),
      ),
    );
  }
}

class _InviteMembersForm extends StatefulWidget {
  const _InviteMembersForm({
    required this.projectId,
    required this.projectName,
    required this.projectKey,
    required this.isBottomSheet,
  });

  final String projectId;
  final String projectName;
  final String projectKey;
  final bool isBottomSheet;

  @override
  State<_InviteMembersForm> createState() => _InviteMembersFormState();
}

class _InviteMembersFormState extends State<_InviteMembersForm> {
  final _emailCtrl = TextEditingController();
  final _focus = FocusNode();

  final List<String> _emails = [];

  @override
  void dispose() {
    _emailCtrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  bool _isValidEmail(String v) {
    final s = v.trim();
    if (s.isEmpty) return false;
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s);
  }

  void _addEmail() {
    final raw = _emailCtrl.text.trim();
    if (!_isValidEmail(raw)) {
      AppToast.show(context, isError: true, message: "Enter a valid email");
      return;
    }

    final e = raw.toLowerCase();
    if (_emails.contains(e)) {
      AppToast.show(context, isError: true, message: "Already added");
      _emailCtrl.clear();
      _focus.requestFocus();
      return;
    }

    setState(() => _emails.add(e));
    _emailCtrl.clear();
    _focus.requestFocus();
  }

  void _removeEmail(String email) {
    setState(() => _emails.remove(email));
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final c = context.c;

    return BlocConsumer<InviteMembersCubit, InviteMembersState>(
      listenWhen: (p, cState) =>
          (p.error != cState.error && cState.error != null) ||
          (p.invited != cState.invited && cState.invited != null),
      listener: (context, state) {
        if (state.error != null) {
          AppToast.show(context, isError: true, message: state.error!);
          return;
        }
        if (state.invited != null) {
          final invited = state.invited ?? 0;
          final skipped = state.skipped ?? 0;
          AppToast.show(context, message: "Invited $invited, skipped $skipped");
          Navigator.pop(context);
        }
      },
      builder: (context, state) {
        final sending = state.sending;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            widget.isBottomSheet ? 16 : 18,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Invite members",
                          style: TextStyle(
                            color: c.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${widget.projectName} • ${widget.projectKey}",
                          style: TextStyle(
                            color: c.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: "Close",
                    onPressed: sending ? null : () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                "Add emails one by one. Tap Add to include them.",
                style: TextStyle(color: c.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _emailCtrl,
                      focusNode: _focus,
                      enabled: !sending,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _addEmail(),
                      decoration: const InputDecoration(
                        hintText: "Enter email",
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: sending ? null : _addEmail,
                      icon: const Icon(Icons.add),
                      label: const Text("Add"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_emails.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: c.surface2,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: c.border),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _emails
                        .map(
                          (e) => Chip(
                            label: Text(
                              e,
                              style: TextStyle(
                                color: c.textPrimary,
                              ),
                            ),
                            deleteIconColor: c.textSecondary,
                            onDeleted: sending ? null : () => _removeEmail(e),
                            backgroundColor: c.surface,
                            shape: StadiumBorder(
                              side: BorderSide(color: c.border),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 12),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: c.surface2,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: c.border),
                  ),
                  child: Text(
                    "No emails added yet.",
                    style: TextStyle(
                      color: c.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: sending ? null : () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: sending
                          ? null
                          : () {
                              if (_emails.isEmpty) {
                                AppToast.show(
                                  context,
                                  isError: true,
                                  message: "Add at least one email",
                                );
                                return;
                              }
                              context.read<InviteMembersCubit>().send(
                                    widget.projectId,
                                    _emails,
                                  );
                            },
                      child: sending
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(isMobile ? "Send" : "Send invites"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.hasSearch,
    required this.creating,
    required this.onCreate,
  });

  final bool hasSearch;
  final bool creating;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final c = context.c;

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                hasSearch ? Icons.search_off : Icons.folder_open,
                color: c.textSecondary,
                size: 44,
              ),
              const SizedBox(height: 12),
              Text(
                hasSearch ? "No results" : "No projects yet",
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                hasSearch ? "Try a different keyword." : "Create your first project to start tracking issues.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: c.textSecondary,
                  fontSize: 12,
                ),
              ),
              if (!hasSearch) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: isMobile ? double.infinity : null,
                  child: ElevatedButton.icon(
                    onPressed: creating ? null : onCreate,
                    icon: const Icon(Icons.add),
                    label: const Text("Create project"),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------- your create project widgets unchanged -----------------

class _CreateProjectDialog extends StatelessWidget {
  const _CreateProjectDialog();

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Dialog(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: const _CreateProjectForm(isBottomSheet: false),
      ),
    );
  }
}

class _CreateProjectSheet extends StatelessWidget {
  const _CreateProjectSheet();

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: const SafeArea(
        top: false,
        child: _CreateProjectForm(isBottomSheet: true),
      ),
    );
  }
}

class _CreateProjectForm extends StatefulWidget {
  const _CreateProjectForm({required this.isBottomSheet});
  final bool isBottomSheet;

  @override
  State<_CreateProjectForm> createState() => _CreateProjectFormState();
}

class _CreateProjectFormState extends State<_CreateProjectForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _keyCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _keyCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final creating = context.select((ProjectsBloc b) => b.state.creating);
    final isMobile = Responsive.isMobile(context);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, widget.isBottomSheet ? 16 : 18),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  "Create project",
                  style: TextStyle(
                    color: context.c.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: "Close",
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: context.c.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              "Name your project and choose a unique key.",
              style: TextStyle(color: context.c.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 14),
            const _FieldLabel("Name"),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                hintText: "e.g. IssueFlow Mobile",
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? "Name is required" : null,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            const _FieldLabel("Key"),
            const SizedBox(height: 6),
            TextFormField(
              controller: _keyCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(hintText: "e.g. IF"),
              validator: (v) {
                final val = (v ?? "").trim();
                if (val.isEmpty) return "Key is required";
                if (val.length < 2) return "Min 2 characters";
                if (val.length > 10) return "Max 10 characters";
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            const _FieldLabel("Description (optional)"),
            const SizedBox(height: 6),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "Short summary of what this project tracks…",
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: creating ? null : () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: creating ? null : _submit,
                    child: Text(isMobile ? "Create" : "Create project"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;

    final name = _nameCtrl.text.trim();
    final key = _keyCtrl.text.trim();
    final desc = _descCtrl.text.trim();

    context.read<ProjectsBloc>().add(
          ProjectsCreateRequested(
            name: name,
            key: key,
            description: desc.isEmpty ? null : desc,
          ),
        );

    Navigator.pop(context);
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: context.c.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

// ======================================================================
// INVITES DIALOG/SHEET UI (NO SEPARATE PAGE)
// ======================================================================

class _InvitesDialog extends StatelessWidget {
  const _InvitesDialog();

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Dialog(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: const _InvitesContent(isBottomSheet: false),
      ),
    );
  }
}

class _InvitesSheet extends StatelessWidget {
  const _InvitesSheet();

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: const SafeArea(
        top: false,
        child: _InvitesContent(isBottomSheet: true),
      ),
    );
  }
}

class _InvitesContent extends StatelessWidget {
  const _InvitesContent({required this.isBottomSheet});
  final bool isBottomSheet;

  String _fmtDate(DateTime d) {
    String two(int v) => v < 10 ? "0$v" : "$v";
    return "${two(d.day)}/${two(d.month)}/${d.year}";
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return BlocConsumer<InvitesBloc, InvitesState>(
      listenWhen: (p, st) =>
          (p.error != st.error && st.error != null) ||
          (p.acceptedToken != st.acceptedToken && st.acceptedToken != null),
      listener: (context, state) {
        if (state.error != null) {
          AppToast.show(context, message: state.error!, isError: true);
          return;
        }

        if (state.acceptedToken != null) {
          context.read<ProjectsBloc>().add(const ProjectsFetchRequested());
          AppToast.show(context, message: "Invite accepted");
          Navigator.pop(context);
        }
      },
      builder: (context, state) {
        final loading = state.loading;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, isBottomSheet ? 16 : 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.mail_outline,
                    color: c.textSecondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Project invites",
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: "Refresh",
                    onPressed: loading ? null : () => context.read<InvitesBloc>().add(const InvitesFetchRequested()),
                    icon: Icon(
                      Icons.refresh,
                      color: c.textSecondary,
                    ),
                  ),
                  IconButton(
                    tooltip: "Close",
                    onPressed: loading ? null : () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                "Accept an invite to join the project instantly.",
                style: TextStyle(color: c.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 14),
              if (loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state.invites.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: c.surface2,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: c.border),
                  ),
                  child: Text(
                    "No pending invites",
                    style: TextStyle(color: c.textSecondary),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.invites.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final inv = state.invites[i];
                    final accepting = state.acceptingToken == inv.token;

                    final dynamic any = inv as dynamic;
                    final String projectName = (any.projectName ?? "").toString();
                    final String invitedByEmail = (any.invitedByEmail ?? "").toString();

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: c.border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: c.surface2,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: c.border),
                            ),
                            child: Icon(
                              Icons.folder_open,
                              color: c.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  projectName.isEmpty ? "Project invite" : projectName,
                                  style: TextStyle(
                                    color: c.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person_outline,
                                      size: 16,
                                      color: c.textSecondary,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        invitedByEmail.isEmpty ? "Invited by: (unknown)" : "Invited by: $invitedByEmail",
                                        style: TextStyle(
                                          color: c.textSecondary,
                                          fontSize: 12,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.schedule,
                                      size: 16,
                                      color: c.textSecondary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "Expires: ${_fmtDate(inv.expiresAt)}",
                                      style: TextStyle(
                                        color: c.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            height: 40,
                            child: ElevatedButton(
                              onPressed: accepting
                                  ? null
                                  : () {
                                      context.read<InvitesBloc>().add(
                                            InvitesAcceptRequested(inv.token),
                                          );
                                    },
                              child: accepting
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text("Accept"),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
