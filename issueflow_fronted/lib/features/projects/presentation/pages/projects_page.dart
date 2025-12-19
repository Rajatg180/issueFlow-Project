import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/responsive/responsive.dart';
import '../bloc/projects_bloc.dart';
import '../bloc/projects_event.dart';
import '../bloc/projects_state.dart';

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  final _searchCtrl = TextEditingController();
  String _query = "";

  @override
  void initState() {
    super.initState();
    context.read<ProjectsBloc>().add(const ProjectsFetchRequested());

    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return BlocConsumer<ProjectsBloc, ProjectsState>(
      listenWhen: (prev, curr) => prev.error != curr.error && curr.error != null,
      listener: (context, state) {
        AppToast.show(
          context,
          message: state.error!.replaceFirst('Exception: ', ''),
          isError: true,
        );
      },
      builder: (context, state) {
        final items = state.items.where((p) {
          if (_query.isEmpty) return true;
          final name = p.name.toLowerCase();
          final key = p.key.toLowerCase();
          final desc = (p.description ?? "").toLowerCase();
          return name.contains(_query) || key.contains(_query) || desc.contains(_query);
        }).toList();

        // ✅ Sort: pinned first, then favorite, then createdAt desc
        items.sort((a, b) {
          int byPin = (b.isPinned ? 1 : 0).compareTo(a.isPinned ? 1 : 0);
          if (byPin != 0) return byPin;
          int byFav = (b.isFavorite ? 1 : 0).compareTo(a.isFavorite ? 1 : 0);
          if (byFav != 0) return byFav;
          return b.createdAt.compareTo(a.createdAt);
        });

        return Container(
          color: AppColors.bg,
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
                      
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _Body(
                        loading: state.loading,
                        creating: state.creating,
                        deletingId: state.deletingId,
                        updatingPrefId: state.updatingPrefId,
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

  Future<void> _openCreate(BuildContext context) async {
    final isMobile = Responsive.isMobile(context);

    if (isMobile) {
      await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.surface,
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
}

class _Header extends StatefulWidget {
  const _Header({
    required this.searchCtrl,
    required this.creating,
    required this.onCreate,
  });

  final TextEditingController searchCtrl;
  final bool creating;
  final VoidCallback onCreate;

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

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 720;

          final title = Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.dashboard_customize_outlined, color: AppColors.textSecondary),
              SizedBox(width: 10),
              _HeaderTitle(),
            ],
          );

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
                          color: AppColors.surface2,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              tooltip: _searchOpen ? "Close search" : "Search",
                              onPressed: _searchOpen ? _closeSearch : _openSearch,
                              icon: Icon(
                                _searchOpen ? Icons.close : Icons.search,
                                color: AppColors.textSecondary,
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
                                  icon: const Icon(
                                    Icons.backspace_outlined,
                                    color: AppColors.textSecondary,
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
                      label: Text(isMobile ? "Create" : "Create project"),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          "Projects",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (!isMobile)
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Text(
              "Manage projects and jump into issues.",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
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

  final bool hasSearch;
  final int filteredCount;
  final int allCount;
  final List items;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
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
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
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
                // ✅ we still "disable" briefly if you want, but we DO NOT show any loader
                isUpdatingPref: updatingPrefId == p.id,
                onTap: () => AppToast.show(context, message: "Selected ${p.key}"),
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
    required this.onTap,
  });

  final String id;
  final String name;
  final String keyText;
  final String? description;
  final DateTime createdAt;
  final bool isFavorite;
  final bool isPinned;

  final bool isDeleting;
  final bool isUpdatingPref;
  final VoidCallback onTap;

  String _createdLabel(DateTime d) {
    String two(int v) => v < 10 ? "0$v" : "$v";
    return "${two(d.day)}/${two(d.month)}/${d.year}";
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          "Delete project?",
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800),
        ),
        content: Text(
          "Project $keyText will be removed.\nAll issues in this project will also be deleted.",
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7F1D1D),
              foregroundColor: AppColors.textPrimary,
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
    if (isUpdatingPref || isDeleting) return;
    context.read<ProjectsBloc>().add(
          ProjectsFavoriteToggled(projectId: id, value: !isFavorite),
        );
    AppToast.show(context, message: !isFavorite ? "Added to favorites" : "Removed from favorites");
  }

  void _togglePin(BuildContext context) {
    if (isUpdatingPref || isDeleting) return;
    context.read<ProjectsBloc>().add(
          ProjectsPinnedToggled(projectId: id, value: !isPinned),
        );
    AppToast.show(context, message: !isPinned ? "Pinned to sidebar" : "Unpinned");
  }

    @override
  Widget build(BuildContext context) {
    final disabled = isDeleting || isUpdatingPref;

    return LayoutBuilder(
      builder: (context, c) {
        final narrow = c.maxWidth < 520;
        final veryNarrow = c.maxWidth < 380;

        final createdPill = Text(
          "Created ${_createdLabel(createdAt)}",
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 8,
            fontWeight: FontWeight.w600,
          ),
        );

        Widget rightActionsInline() {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: isPinned ? "Unpin" : "Pin",
                onPressed: disabled ? null : () => _togglePin(context),
                icon: Icon(
                  isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  color: isPinned ? Colors.red : AppColors.textSecondary,
                ),
              ),
              IconButton(
                tooltip: isFavorite ? "Unfavorite" : "Favorite",
                onPressed: disabled ? null : () => _toggleFavorite(context),
                icon: Icon(
                  isFavorite ? Icons.star : Icons.star_border,
                  color: isFavorite ? Colors.amber : AppColors.textSecondary,
                ),
              ),
              PopupMenuButton<String>(
                tooltip: "Actions",
                color: AppColors.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (v) {
                  if (v == "delete") _confirmDelete(context);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: "delete",
                    child: Text("Delete", style: TextStyle(color: AppColors.textPrimary)),
                  ),
                ],
                child: const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.more_vert, color: AppColors.textSecondary),
                ),
              ),
            ],
          );
        }

        Widget rightActionsMenuOnly() {
          return PopupMenuButton<String>(
            tooltip: "Actions",
            color: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (v) {
              if (v == "fav") _toggleFavorite(context);
              if (v == "pin") _togglePin(context);
              if (v == "delete") _confirmDelete(context);
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: "pin",
                child: Row(
                  children: [
                    Icon(
                      isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                      size: 18,
                      color: isPinned ? Colors.red : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Text(isPinned ? "Unpin" : "Pin",
                        style: const TextStyle(color: AppColors.textPrimary)),
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
                      color: isFavorite ? Colors.amber : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Text(isFavorite ? "Unfavorite" : "Favorite",
                        style: const TextStyle(color: AppColors.textPrimary)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: "delete",
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                    SizedBox(width: 10),
                    Text("Delete", style: TextStyle(color: AppColors.textPrimary)),
                  ],
                ),
              ),
            ],
            child: const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(Icons.more_vert, color: AppColors.textSecondary),
            ),
          );
        }

        // ✅ FULL HEIGHT LEADING RAIL
        Widget leadingRail() {
          return SizedBox(
            width: 56,
            child: Container(
              height: double.infinity, // <-- stretches due to IntrinsicHeight()
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    keyText.length >= 2 ? keyText.substring(0, 2) : keyText,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
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
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),

              // ✅ This makes left rail match tile height
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
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        height: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 6),

                                    // keep your UI same: description in wrap
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        Text(
                                          (description == null || description!.trim().isEmpty)
                                              ? "No description"
                                              : description!.trim(),
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
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

                              if (isDeleting)
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

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
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
                color: AppColors.textSecondary,
                size: 44,
              ),
              const SizedBox(height: 12),
              Text(
                hasSearch ? "No results" : "No projects yet",
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                hasSearch ? "Try a different keyword." : "Create your first project to start tracking issues.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
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

/// Desktop/Tablet dialog version
class _CreateProjectDialog extends StatelessWidget {
  const _CreateProjectDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: const _CreateProjectForm(isBottomSheet: false),
      ),
    );
  }
}

/// Mobile bottom sheet version (keyboard-safe)
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
                const Text(
                  "Create project",
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: "Close",
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              "Name your project and choose a unique key.",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 14),
            const _FieldLabel("Name"),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(hintText: "e.g. IssueFlow Mobile"),
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
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
