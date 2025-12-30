import 'package:flutter/material.dart';
import 'package:issueflow_fronted/core/theme/app_palette.dart';
import 'app_colors.dart';
import 'app_text.dart';

class AppTheme {
  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      extensions: const [
        AppPalette(
          bg: Color(0xFF0E1621),
          surface: Color(0xFF161A23),
          surface2: Color(0xFF1E2230),
          hover: Color(0xFF252B3D),
          border: Color(0xFF2C3344),
          textPrimary: Color(0xFFE6EDF3),
          textSecondary: Color(0xFF9DA7B3),
          primary: Color(0xFF0C66E4),
          success: Color(0xFF1F845A),
          warning: Color(0xFFE2B203),
          info: Color(0xFF579DFF),
        ),
      ],
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        surface: AppColors.surface,
        // ignore: deprecated_member_use
        background: AppColors.bg,
      ),
      textTheme: AppText.textTheme,
      dividerColor: AppColors.border,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: AppColors.surface,
        selectedIconTheme: IconThemeData(color: AppColors.textPrimary),
        unselectedIconTheme: IconThemeData(color: AppColors.textSecondary),
        selectedLabelTextStyle: TextStyle(color: AppColors.textPrimary),
        unselectedLabelTextStyle: TextStyle(color: AppColors.textSecondary),
      ),
      drawerTheme: const DrawerThemeData(backgroundColor: AppColors.surface),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.textSecondary,
        textColor: AppColors.textPrimary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
        ),
        hintStyle: const TextStyle(color: AppColors.textSecondary),
      ),
    );
  }

  // ✅ UPDATED: softer Jira-like light theme (less irritating)
  static ThemeData light() {
    // Softer + calmer than before
    const bg = Color(0xFFF7F8FA);      // softer than F4F5F7
    const surface = Color(0xFFFFFFFF); // cards
    const surface2 = Color(0xFFF1F2F4); // inputs / inner containers (softer)
    const hover = Color(0xFFEBECF0);    // hover
    const border = Color(0xFFDCDFE4);   // softer border
    const textPrimary = Color(0xFF172B4D);
    const textSecondary = Color(0xFF44546F); // calmer
    const primary = Color(0xFF0C66E4);

    final scheme = const ColorScheme.light(
      primary: primary,
      surface: surface,
      // ignore: deprecated_member_use
      background: bg,
      onPrimary: Colors.white,
      onSurface: textPrimary,
    );

    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: bg,
      colorScheme: scheme,

      // ✅ your extension palette for light mode
      extensions: const [
        AppPalette(
          bg: bg,
          surface: surface,
          surface2: surface2,
          hover: hover,
          border: border,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          primary: primary,
          success: Color(0xFF1F845A),
          warning: Color(0xFFE2B203),
          info: Color(0xFF579DFF),
        ),
      ],

      textTheme: AppText.lightTextTheme,
      dividerColor: border,

      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: textPrimary,
      ),

      // ✅ make side nav / rail match light theme
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: surface,
        selectedIconTheme: IconThemeData(color: textPrimary),
        unselectedIconTheme: IconThemeData(color: textSecondary),
        selectedLabelTextStyle: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        unselectedLabelTextStyle: TextStyle(color: textSecondary),
      ),

      drawerTheme: const DrawerThemeData(backgroundColor: surface),

      listTileTheme: const ListTileThemeData(
        iconColor: textSecondary,
        textColor: textPrimary,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface2,
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primary, width: 1.2),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
