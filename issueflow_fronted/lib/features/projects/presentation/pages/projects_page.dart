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
                      creating: state.creating,
                      onCreate: () => _openCreate(context),
                      onRefresh: () => context.read<ProjectsBloc>().add(
                            const ProjectsFetchRequested(),
                          ),
                    ),
                    const SizedBox(height: 12),
                    _SearchBar(controller: _searchCtrl),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _Body(
                        loading: state.loading,
                        creating: state.creating,
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

    // Mobile & narrow web: use bottom sheet (keyboard-safe)
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

    // Tablet/Desktop/Web wide: use dialog
    await showDialog<bool>(
      context: context,
      builder: (_) => const _CreateProjectDialog(),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.creating,
    required this.onCreate,
    required this.onRefresh,
  });

  final bool creating;
  final VoidCallback onCreate;
  final VoidCallback onRefresh;

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
        builder: (ctx, c) {
          // Use Wrap so it never overflows on narrow screens / web resize
          return Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 10,
            spacing: 10,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.dashboard_customize_outlined, color: AppColors.textSecondary),
                  SizedBox(width: 10),
                  _HeaderTitle(),
                ],
              ),

              // Spacer-like behavior in Wrap: push actions to the end when possible
              if (!isMobile) const SizedBox(width: 8),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: "Refresh",
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton.icon(
                    onPressed: creating ? null : onCreate,
                    icon: creating
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add),
                    label: Text(isMobile ? "Create" : "Create project"),
                  ),
                ],
              ),
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

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.textSecondary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: "Search projects…",
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            IconButton(
              tooltip: "Clear",
              onPressed: () => controller.clear(),
              icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 18),
            ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.loading,
    required this.creating,
    required this.hasSearch,
    required this.filteredCount,
    required this.allCount,
    required this.items,
    required this.onCreate,
  });

  final bool loading;
  final bool creating;
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
                name: p.name,
                keyText: p.key,
                description: p.description,
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
    required this.name,
    required this.keyText,
    required this.description,
    required this.onTap,
  });

  final String name;
  final String keyText;
  final String? description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _KeyBadge(keyText: keyText),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (description == null || description!.trim().isEmpty)
                        ? "No description"
                        : description!.trim(),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _KeyBadge extends StatelessWidget {
  const _KeyBadge({required this.keyText});
  final String keyText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        keyText,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
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

    // Scrollable so keyboard never hides fields
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
                    child: creating
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isMobile ? "Create" : "Create project"),
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
