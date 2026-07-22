// app_filter_chip.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

class AppFilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final ValueChanged<bool> onChanged;
  final Color color;
  final bool isDark;

  const AppFilterChip({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onChanged,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white.withOpacity(0.8) : color),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white.withOpacity(0.8) : color),
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: onChanged,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      selectedColor: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        side: BorderSide(
          color: isSelected
              ? color
              : (isDark ? Colors.white.withOpacity(0.1) : AppColors.neutral200),
        ),
      ),
      elevation: 0,
    );
  }
}
