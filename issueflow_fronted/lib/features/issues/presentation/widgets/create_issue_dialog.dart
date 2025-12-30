import 'package:flutter/material.dart';
import '../../../../core/theme/app_palette.dart';

class CreateIssueResult {
  final String title;
  final String? description;
  final String type;
  final String priority;
  final DateTime? dueDate;

  CreateIssueResult({
    required this.title,
    this.description,
    required this.type,
    required this.priority,
    this.dueDate,
  });
}

class CreateIssueDialog extends StatefulWidget {
  const CreateIssueDialog({super.key});

  /// ✅ Web/Desktop/Tablet => custom Dialog (NOT AlertDialog) to avoid IntrinsicWidth issues
  /// ✅ Mobile => Bottom Sheet
  static Future<CreateIssueResult?> open(BuildContext context) async {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 600;

    if (isMobile) {
      return showModalBottomSheet<CreateIssueResult>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const _CreateIssueBottomSheet(),
      );
    }

    return showDialog<CreateIssueResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _CreateIssueDialog(),
    );
  }

  @override
  State<CreateIssueDialog> createState() => _CreateIssueDialogWrapperState();
}

/// This wrapper state is never shown directly (we use open()).
/// Keeping it only to satisfy StatefulWidget contract.
class _CreateIssueDialogWrapperState extends State<CreateIssueDialog> {
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// ---------------- Web/Desktop Dialog (custom, safe) ----------------

class _CreateIssueDialog extends StatefulWidget {
  const _CreateIssueDialog();

  @override
  State<_CreateIssueDialog> createState() => _CreateIssueDialogState();
}

class _CreateIssueDialogState extends State<_CreateIssueDialog> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _type = 'task';
  String _priority = 'medium';
  DateTime? _due;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      initialDate: _due ?? now,
    );
    if (picked != null) setState(() => _due = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      CreateIssueResult(
        title: _title.text.trim(),
        description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
        type: _type,
        priority: _priority,
        dueDate: _due,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Dialog(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: c.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 640,
          minWidth: 520,
          maxHeight: 650,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Header(
              title: 'Create issue',
              onClose: () => Navigator.pop(context, null),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                child: _FormBody(
                  formKey: _formKey,
                  titleController: _title,
                  descController: _desc,
                  type: _type,
                  priority: _priority,
                  dueDate: _due,
                  fmt: _fmt,
                  onTypeChanged: (v) => setState(() => _type = v),
                  onPriorityChanged: (v) => setState(() => _priority = v),
                  onPickDate: _pickDate,
                  onClearDate: () => setState(() => _due = null),
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, null),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.add),
                    label: const Text('Create'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------- Mobile Bottom Sheet (safe) ----------------

class _CreateIssueBottomSheet extends StatefulWidget {
  const _CreateIssueBottomSheet();

  @override
  State<_CreateIssueBottomSheet> createState() => _CreateIssueBottomSheetState();
}

class _CreateIssueBottomSheetState extends State<_CreateIssueBottomSheet> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _type = 'task';
  String _priority = 'medium';
  DateTime? _due;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      initialDate: _due ?? now,
    );
    if (picked != null) setState(() => _due = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      CreateIssueResult(
        title: _title.text.trim(),
        description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
        type: _type,
        priority: _priority,
        dueDate: _due,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        padding: EdgeInsets.only(bottom: bottomInset),
        color: Colors.transparent,
        child: SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              border: Border.all(color: c.border),
            ),
            constraints: const BoxConstraints(maxHeight: 700),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 10, 6),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Create issue',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context, null),
                        icon: Icon(Icons.close, color: c.textSecondary),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: _FormBody(
                      formKey: _formKey,
                      titleController: _title,
                      descController: _desc,
                      type: _type,
                      priority: _priority,
                      dueDate: _due,
                      fmt: _fmt,
                      onTypeChanged: (v) => setState(() => _type = v),
                      onPriorityChanged: (v) => setState(() => _priority = v),
                      onPickDate: _pickDate,
                      onClearDate: () => setState(() => _due = null),
                    ),
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, null),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _submit,
                          icon: const Icon(Icons.add),
                          label: const Text('Create'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ---------------- Shared UI blocks ----------------

class _Header extends StatelessWidget {
  final String title;
  final VoidCallback onClose;

  const _Header({required this.title, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 10, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: onClose,
            icon: Icon(Icons.close, color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _FormBody extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final TextEditingController descController;

  final String type;
  final String priority;
  final DateTime? dueDate;

  final String Function(DateTime) fmt;

  final ValueChanged<String> onTypeChanged;
  final ValueChanged<String> onPriorityChanged;

  final VoidCallback onPickDate;
  final VoidCallback onClearDate;

  const _FormBody({
    required this.formKey,
    required this.titleController,
    required this.descController,
    required this.type,
    required this.priority,
    required this.dueDate,
    required this.fmt,
    required this.onTypeChanged,
    required this.onPriorityChanged,
    required this.onPickDate,
    required this.onClearDate,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              prefixIcon: Icon(Icons.title),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Title is required';
              return null;
            },
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: descController,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              prefixIcon: Icon(Icons.notes_outlined),
            ),
            minLines: 2,
            maxLines: 4,
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, cBox) {
              final isNarrow = cBox.maxWidth < 420;

              final typeField = DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'task', child: Text('Task')),
                  DropdownMenuItem(value: 'bug', child: Text('Bug')),
                  DropdownMenuItem(value: 'feature', child: Text('Feature')),
                ],
                onChanged: (v) => onTypeChanged(v ?? 'task'),
              );

              final priorityField = DropdownButtonFormField<String>(
                value: priority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('Low')),
                  DropdownMenuItem(value: 'medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'high', child: Text('High')),
                ],
                onChanged: (v) => onPriorityChanged(v ?? 'medium'),
              );

              if (isNarrow) {
                return Column(
                  children: [
                    typeField,
                    const SizedBox(height: 12),
                    priorityField,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: typeField),
                  const SizedBox(width: 12),
                  Expanded(child: priorityField),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: onPickDate,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Due date (optional)',
                prefixIcon: Icon(Icons.calendar_today_outlined),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      dueDate == null ? '-' : fmt(dueDate!),
                      style: TextStyle(
                        color: dueDate == null ? c.textSecondary : c.textPrimary,
                      ),
                    ),
                  ),
                  if (dueDate != null)
                    IconButton(
                      tooltip: 'Clear',
                      onPressed: onClearDate,
                      icon: Icon(Icons.clear, color: c.textSecondary),
                    ),
                  Icon(Icons.chevron_right, color: c.textSecondary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
