import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: AppTypography.font().fontFamily,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      error: AppColors.error,
      surface: AppColors.surfaceLight,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      outlineVariant: AppColors.neutral200,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surfaceLight,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.neutral200),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      labelStyle: AppTypography.caption.copyWith(color: AppColors.textPrimary),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.neutral200)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.neutral200)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
    ),
    scaffoldBackgroundColor: AppColors.backgroundLight,
    textTheme: AppTypography.textTheme,
    // SnackBar theme for light mode
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surfaceDark,
      contentTextStyle: AppTypography.bodyMedium.copyWith(color: Colors.white),
      actionTextColor: AppColors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    // BottomSheet theme for light mode
    bottomSheetTheme: BottomSheetThemeData(
      surfaceTintColor: Colors.transparent,
      backgroundColor: Colors.white,
      modalBackgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    // Dialog theme for light mode
    dialogTheme: DialogThemeData(
      surfaceTintColor: Colors.transparent,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    // Tooltip theme for light mode
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: AppTypography.caption.copyWith(color: Colors.white),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: AppTypography.font().fontFamily,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      error: AppColors.error,
      surface: AppColors.surfaceDark,
      onSurface: Colors.white,
      onSurfaceVariant: Color(0xFFB5BEC8),
      outlineVariant: Color(0xFF384148),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surfaceDark,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: const Color(0xFF384148)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceDark,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      labelStyle: AppTypography.caption.copyWith(color: Colors.white),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: const Color(0xFF384148))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: const Color(0xFF384148))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
    ),
    scaffoldBackgroundColor: AppColors.backgroundDark,
    textTheme: AppTypography.textTheme.apply(
        bodyColor: AppColors.textOnDark, displayColor: AppColors.textOnDark),
    // SnackBar theme for dark mode
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surfaceLight,
      contentTextStyle:
          AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
      actionTextColor: AppColors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    // BottomSheet theme for dark mode
    bottomSheetTheme: BottomSheetThemeData(
      surfaceTintColor: Colors.transparent,
      backgroundColor: AppColors.surfaceDark,
      modalBackgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    // Dialog theme for dark mode
    dialogTheme: DialogThemeData(
      surfaceTintColor: Colors.transparent,
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    // Tooltip theme for dark mode
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: AppTypography.caption.copyWith(color: AppColors.textPrimary),
    ),
  );
}
