import 'package:flutter/material.dart';
import 'package:kaltrike_driver_app/src/shared/ui/app_colors.dart';
import 'package:kaltrike_driver_app/src/shared/ui/app_spacing.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final base = ThemeData.light();

    return base.copyWith(
      useMaterial3: false,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primary,
        secondary: AppColors.primaryLight,
        surface: AppColors.surface,
        error: AppColors.danger,
      ),
      textTheme: base.textTheme.copyWith(
        headlineSmall: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          letterSpacing: -0.4,
        ),
        titleLarge: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        titleMedium: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        bodyLarge: const TextStyle(
          fontSize: 16,
          color: AppColors.textPrimary,
          height: 1.45,
        ),
        bodyMedium: const TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
          height: 1.45,
        ),
        labelLarge: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.cardRadius,
          side: const BorderSide(color: AppColors.border),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: const TextStyle(color: AppColors.textMuted),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.fieldRadius,
          borderSide: const BorderSide(color: AppColors.border, width: 1.4),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.fieldRadius,
          borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.fieldRadius,
          borderSide: const BorderSide(color: AppColors.danger, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.fieldRadius,
          borderSide: const BorderSide(color: AppColors.danger, width: 1.8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          elevation: 0,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: AppSpacing.buttonRadius,
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: const RoundedRectangleBorder(
            borderRadius: AppSpacing.buttonRadius,
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.primary;
          }
          return Colors.white;
        }),
        side: const BorderSide(color: AppColors.border),
      ),
    );
  }
}
