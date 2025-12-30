import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppText {
  // ✅ Keep your existing dark theme (unchanged)
  static const textTheme = TextTheme(
    titleLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      color: AppColors.textPrimary,
      height: 1.35,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      color: AppColors.textSecondary,
      height: 1.35,
    ),
    labelLarge: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
  );

  // ✅ UPDATED: Jira-like light theme text colors (less harsh)
  static const lightTextTheme = TextTheme(
    titleLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: Color(0xFF172B4D),
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: Color(0xFF172B4D),
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      color: Color(0xFF172B4D),
      height: 1.35,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      color: Color(0xFF44546F), // softer than 5E6C84
      height: 1.35,
    ),
    labelLarge: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: Color(0xFF172B4D),
    ),
  );
}
