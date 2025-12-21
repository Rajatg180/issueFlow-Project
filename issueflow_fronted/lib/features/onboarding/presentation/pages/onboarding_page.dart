import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../domain/entities/onboarding_payload.dart';
import '../bloc/onboarding_bloc.dart';
import '../bloc/onboarding_event.dart';
import '../bloc/onboarding_state.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  int step = 0;

  final projectName = TextEditingController();
  final projectKey = TextEditingController();
  final projectDesc = TextEditingController();

  final invites = TextEditingController();

  // ✅ NEW (UI-only for invite step)
  final _inviteEmailCtrl = TextEditingController();
  final List<String> _inviteEmails = [];

  final issueTitle = TextEditingController();
  final issueDesc = TextEditingController();

  String issueType = 'task'; // backend expects: task/bug/feature
  String issuePriority = 'medium'; // backend expects: low/medium/high

  /// Optional due date (null by default)
  DateTime? dueDate;

  @override
  void dispose() {
    projectName.dispose();
    projectKey.dispose();
    projectDesc.dispose();
    invites.dispose();
    _inviteEmailCtrl.dispose(); // ✅ NEW
    issueTitle.dispose();
    issueDesc.dispose();
    super.dispose();
  }

  // ---------------------------
  // Validation
  // ---------------------------
  bool _validateStep() {
    if (step == 0) {
      if (projectName.text.trim().isEmpty) {
        AppToast.show(context, message: "Project name is required", isError: true);
        return false;
      }
      if (projectKey.text.trim().length < 2) {
        AppToast.show(context, message: "Project key should be at least 2 letters", isError: true);
        return false;
      }
    }

    if (step == 2) {
      if (issueTitle.text.trim().isEmpty) {
        AppToast.show(context, message: "Issue title is required", isError: true);
        return false;
      }
    }

    return true;
  }

  // ---------------------------
  // Helpers
  // ---------------------------
  List<String> _parseInvites() {
    // "a@x.com, b@y.com" -> ["a@x.com","b@y.com"]
    return invites.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  // ✅ NEW: keep invites controller in sync with chips (no backend change)
  void _syncInvitesController() {
    invites.text = _inviteEmails.join(', ');
  }

  bool _isValidEmail(String email) {
    final e = email.trim();
    // Simple email check (no dependency)
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e);
    return ok;
  }

  void _addInviteEmail() {
    final email = _inviteEmailCtrl.text.trim().toLowerCase();
    if (email.isEmpty) return;

    if (!_isValidEmail(email)) {
      AppToast.show(context, message: "Enter a valid email", isError: true);
      return;
    }

    if (_inviteEmails.contains(email)) {
      AppToast.show(context, message: "Already added", isError: true);
      return;
    }

    setState(() {
      _inviteEmails.add(email);
      _inviteEmailCtrl.clear();
      _syncInvitesController();
    });
  }

  void _removeInviteEmail(String email) {
    setState(() {
      _inviteEmails.remove(email);
      _syncInvitesController();
    });
  }

  String _fmtDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return "${d.year}-$mm-$dd";
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final initial = dueDate ?? now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
      helpText: "Select due date",
    );

    if (picked == null) return;

    setState(() {
      dueDate = DateTime(picked.year, picked.month, picked.day);
    });
  }

  void _clearDueDate() {
    setState(() => dueDate = null);
  }

  OnboardingPayload _buildPayload() {
    return OnboardingPayload(
      projectName: projectName.text.trim(),
      projectKey: projectKey.text.trim().toUpperCase(),
      projectDescription: projectDesc.text.trim().isEmpty ? null : projectDesc.text.trim(),
      invites: _parseInvites(),
      issueTitle: issueTitle.text.trim(),
      issueDescription: issueDesc.text.trim().isEmpty ? null : issueDesc.text.trim(),
      issueType: issueType,
      issuePriority: issuePriority,
      dueDate: dueDate,
    );
  }

  void _next(BuildContext context) {
    if (!_validateStep()) return;

    if (step == 2) {
      final payload = _buildPayload();
      context.read<OnboardingBloc>().add(OnboardingSetupRequested(payload));
      return;
    }

    setState(() => step++);
  }

  void _back() {
    if (step == 0) return;
    setState(() => step--);
  }

  Widget _stepHeader(BuildContext context, String title, String subtitle) {
    final t = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: t.textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(subtitle, style: t.textTheme.bodySmall),
      ],
    );
  }

  Widget _progressDots() {
    Widget dot(bool active) => Container(
          width: active ? 18 : 8,
          height: 8,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.border,
            borderRadius: BorderRadius.circular(999),
          ),
        );

    return Row(
      children: [
        dot(step == 0),
        dot(step == 1),
        dot(step == 2),
      ],
    );
  }

  Widget _card(Widget child) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }

  InputDecoration _dec(String label, {String? hint}) {
    return InputDecoration(labelText: label, hintText: hint);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    return BlocProvider(
      create: (_) => sl<OnboardingBloc>(),
      child: BlocListener<OnboardingBloc, OnboardingState>(
        listener: (context, state) {
          if (state is OnboardingFailure) {
            AppToast.show(context, message: state.message, isError: true);
          }

          if (state is OnboardingSuccess) {
            AppToast.show(
              context,
              message: "Setup complete! Project ${state.result.projectKey} created.",
            );

            context.read<AuthBloc>().add(const AuthAppStarted());
          }

          if (state is OnboardingSkipSuccess) {
            AppToast.show(context, message: "Skipped onboarding");
            context.read<AuthBloc>().add(const AuthAppStarted());
          }
        },
        child: BlocBuilder<OnboardingBloc, OnboardingState>(
          builder: (context, state) {
            final isLoading = state is OnboardingLoading;

            // ✅ KEYBOARD FIX: add bottom padding when keyboard is open
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;

            return Scaffold(
              appBar: AppBar(
                title: const Text('Welcome to IssueFlow'),
                actions: [
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            context.read<OnboardingBloc>().add(const OnboardingSkipRequested());
                          },
                    child: const Text('Skip'),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              body: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _leftInfoPanel()),
                              const SizedBox(width: 16),
                              Expanded(child: _rightStepPanel(context, isLoading)),
                            ],
                          )
                        : SingleChildScrollView(
                            // ✅ this prevents overflow on mobile when keyboard opens
                            padding: EdgeInsets.only(bottom: bottomInset),
                            child: Column(
                              children: [
                                _leftInfoPanel(),
                                const SizedBox(height: 16),
                                _rightStepPanel(context, isLoading),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _leftInfoPanel() {
    final t = Theme.of(context);

    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick setup', style: t.textTheme.titleMedium),
          const SizedBox(height: 10),
          _progressDots(),
          const SizedBox(height: 16),
          _checkRow(step >= 0, 'Create your first project'),
          const SizedBox(height: 10),
          _checkRow(step >= 1, 'Invite your team (optional)'),
          const SizedBox(height: 10),
          _checkRow(step >= 2, 'Create your first issue'),
          const SizedBox(height: 18),
          Text(
            "This takes less than a minute. You can change everything later.",
            style: t.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _checkRow(bool done, String text) {
    return Row(
      children: [
        Icon(
          done ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 18,
          color: done ? AppColors.primary : AppColors.textSecondary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          ),
        )
      ],
    );
  }

  Widget _rightStepPanel(BuildContext context, bool isLoading) {
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (step == 0) ...[
            _stepHeader(context, 'Create a project', 'A project groups issues and team members.'),
            const SizedBox(height: 16),
            TextField(
              controller: projectName,
              enabled: !isLoading,
              decoration: _dec('Project name', hint: 'e.g., IssueFlow'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: projectKey,
              enabled: !isLoading,
              decoration: _dec('Project key', hint: 'e.g., IF'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: projectDesc,
              enabled: !isLoading,
              maxLines: 3,
              decoration: _dec('Description (optional)', hint: 'Short description of the project'),
            ),
          ],

          // ✅ ONLY THIS STEP UI IS UPDATED
          if (step == 1) ...[
            _stepHeader(context, 'Invite members', 'Add teammates by email (optional).'),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inviteEmailCtrl,
                      enabled: !isLoading,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => isLoading ? null : _addInviteEmail(),
                      decoration: const InputDecoration(
                        hintText: 'Enter email (e.g. a@x.com)',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 40,
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : _addInviteEmail,
                      icon: const Icon(Icons.add),
                      label: const Text("Add"),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            if (_inviteEmails.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _inviteEmails
                    .map(
                      (e) => Chip(
                        label: Text(e),
                        onDeleted: isLoading ? null : () => _removeInviteEmail(e),
                        deleteIconColor: AppColors.textSecondary,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
            ],

            const Text(
              'Tip: you can invite later from Project settings.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),

            // keep original controller present (so no behavior changes)
            // ignore: dead_code
            Offstage(
              offstage: true,
              child: TextField(controller: invites),
            ),
          ],

          if (step == 2) ...[
            _stepHeader(context, 'Create your first issue', 'Start with a small task to test the workflow.'),
            const SizedBox(height: 16),
            TextField(
              controller: issueTitle,
              enabled: !isLoading,
              decoration: _dec('Title', hint: 'e.g., Setup CI pipeline'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: issueType,
                    items: const [
                      DropdownMenuItem(value: 'task', child: Text('Task')),
                      DropdownMenuItem(value: 'bug', child: Text('Bug')),
                      DropdownMenuItem(value: 'feature', child: Text('Feature')),
                    ],
                    onChanged: isLoading ? null : (v) => setState(() => issueType = v ?? 'task'),
                    decoration: _dec('Type'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: issuePriority,
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('Low')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'high', child: Text('High')),
                    ],
                    onChanged: isLoading ? null : (v) => setState(() => issuePriority = v ?? 'medium'),
                    decoration: _dec('Priority'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _dueDateRow(isLoading),
            const SizedBox(height: 12),
            TextField(
              controller: issueDesc,
              enabled: !isLoading,
              maxLines: 3,
              decoration: _dec('Description (optional)'),
            ),
          ],

          const SizedBox(height: 18),
          Row(
            children: [
              if (step > 0)
                OutlinedButton(
                  onPressed: isLoading ? null : _back,
                  child: const Text('Back'),
                ),
              if (step > 0) const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: isLoading ? null : () => _next(context),
                  child: isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(step == 2 ? 'Finish setup' : 'Continue'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dueDateRow(bool isLoading) {
    final label = (dueDate == null) ? "None" : _fmtDate(dueDate!);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.event, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Due date",
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: isLoading ? null : _pickDueDate,
            child: const Text("Pick"),
          ),
          if (dueDate != null)
            TextButton(
              onPressed: isLoading ? null : _clearDueDate,
              child: const Text("Clear"),
            ),
        ],
      ),
    );
  }
}
