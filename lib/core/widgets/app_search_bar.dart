// app_search_bar.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

class AppSearchBar extends StatelessWidget {
  final String hintText;
  final ValueChanged<String> onChanged;
  final bool isDark;

  const AppSearchBar({
    super.key,
    required this.hintText,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : AppColors.neutral200,
        ),
        color: isDark ? AppColors.surfaceDark : Colors.white,
      ),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: isDark ? Colors.white.withOpacity(0.5) : AppColors.textSecondary,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: isDark ? Colors.white.withOpacity(0.5) : AppColors.textSecondary,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
        ),
        style: AppTypography.bodyMedium.copyWith(
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
      ),
    );
  }
}