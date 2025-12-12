import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Reusable auth text field with Jira-like styling.
/// Supports password eye toggle when [isPassword] is true.
class AuthTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? hintText;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.hintText,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  /// Only used when isPassword = true
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,

      /// If it's a password field, hide text unless user toggles eye icon
      obscureText: widget.isPassword ? _obscure : false,

      style: theme.textTheme.bodyMedium,

      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hintText,

        /// Subtle border (Jira-like)
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
        ),

        /// Password toggle (eye icon)
        suffixIcon: widget.isPassword
            ? IconButton(
                tooltip: _obscure ? "Show password" : "Hide password",
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: AppColors.textSecondary,
                ),
              )
            : null,
      ),
    );
  }
}
