import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  // Step control
  int step = 0;

  // Step 1: project
  final projectName = TextEditingController();
  final projectKey = TextEditingController(); // like "ISSUE"
  final projectDesc = TextEditingController();

  // Step 2: invite (comma separated)
  final invites = TextEditingController();

  // Step 3: first issue
  final issueTitle = TextEditingController();
  final issueDesc = TextEditingController();
  String issueType = 'Task'; // Task/Bug/Feature
  String issuePriority = 'Medium'; // Low/Medium/High

  @override
  void dispose() {
    projectName.dispose();
    projectKey.dispose();
    projectDesc.dispose();
    invites.dispose();
    issueTitle.dispose();
    issueDesc.dispose();
    super.dispose();
  }

  void _next() {
    if (step == 0) {
      if (projectName.text.trim().isEmpty) {
        AppToast.show(context, message: "Project name is required", isError: true);
        return;
      }
      if (projectKey.text.trim().length < 2) {
        AppToast.show(context, message: "Project key should be at least 2 letters", isError: true);
        return;
      }
    }

    if (step == 2) {
      if (issueTitle.text.trim().isEmpty) {
        AppToast.show(context, message: "Issue title is required", isError: true);
        return;
      }
      // Finish onboarding
      context.read<AuthBloc>().add(const AuthOnboardingCompleted());
      AppToast.show(context, message: "Onboarding complete!");
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

  Widget _card(BuildContext context, Widget child) {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to IssueFlow'),
        actions: [
          TextButton(
            onPressed: () {
              // Let user skip onboarding (still mark it done)
              context.read<AuthBloc>().add(const AuthOnboardingCompleted());
              AppToast.show(context, message: "Skipped onboarding");
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
                      Expanded(child: _leftInfoPanel(context)),
                      const SizedBox(width: 16),
                      Expanded(child: _rightStepPanel(context)),
                    ],
                  )
                : Column(
                    children: [
                      _leftInfoPanel(context),
                      const SizedBox(height: 16),
                      _rightStepPanel(context),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _leftInfoPanel(BuildContext context) {
    final t = Theme.of(context);
    return _card(
      context,
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

  Widget _rightStepPanel(BuildContext context) {
    return _card(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (step == 0) ...[
            _stepHeader(context, 'Create a project', 'A project groups issues and team members.'),
            const SizedBox(height: 16),
            TextField(
              controller: projectName,
              decoration: _dec('Project name', hint: 'e.g., IssueFlow'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: projectKey,
              decoration: _dec('Project key', hint: 'e.g., IF'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: projectDesc,
              maxLines: 3,
              decoration: _dec('Description (optional)', hint: 'Short description of the project'),
            ),
          ],
          if (step == 1) ...[
            _stepHeader(context, 'Invite members', 'Add teammates by email (optional).'),
            const SizedBox(height: 16),
            TextField(
              controller: invites,
              decoration: _dec('Emails', hint: 'a@x.com, b@y.com'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tip: you can invite later from Project settings.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
          if (step == 2) ...[
            _stepHeader(context, 'Create your first issue', 'Start with a small task to test the workflow.'),
            const SizedBox(height: 16),

            TextField(
              controller: issueTitle,
              decoration: _dec('Title', hint: 'e.g., Setup CI pipeline'),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: issueType,
                    items: const [
                      DropdownMenuItem(value: 'Task', child: Text('Task')),
                      DropdownMenuItem(value: 'Bug', child: Text('Bug')),
                      DropdownMenuItem(value: 'Feature', child: Text('Feature')),
                    ],
                    onChanged: (v) => setState(() => issueType = v ?? 'Task'),
                    decoration: _dec('Type'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: issuePriority,
                    items: const [
                      DropdownMenuItem(value: 'Low', child: Text('Low')),
                      DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'High', child: Text('High')),
                    ],
                    onChanged: (v) => setState(() => issuePriority = v ?? 'Medium'),
                    decoration: _dec('Priority'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            TextField(
              controller: issueDesc,
              maxLines: 3,
              decoration: _dec('Description (optional)'),
            ),
          ],
          const SizedBox(height: 18),

          Row(
            children: [
              if (step > 0)
                OutlinedButton(
                  onPressed: _back,
                  child: const Text('Back'),
                ),
              if (step > 0) const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _next,
                  child: Text(step == 2 ? 'Finish setup' : 'Continue'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
