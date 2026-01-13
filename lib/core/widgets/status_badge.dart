// status_badge.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/models/batch/batch_model.dart';

class StatusBadge extends StatelessWidget {
  final BatchStatus status;

  const StatusBadge({super.key, required this.status});

  Color _getColor() {
    switch (status) {
      case BatchStatus.nursery:
        return AppColors.info;
      case BatchStatus.transplanted:
        return AppColors.info;
      case BatchStatus.growing:
        return AppColors.warning;
      case BatchStatus.harvesting:
        return AppColors.warning;
      case BatchStatus.harvested:
        return AppColors.primary;
      case BatchStatus.packaged:
        return AppColors.primary;
      case BatchStatus.qualityChecked:
        return AppColors.success;
      case BatchStatus.readyForSales:
        return AppColors.success;
      case BatchStatus.delivered:
        return AppColors.success;
      case BatchStatus.completed:
        return AppColors.success;
      case BatchStatus.cancelled:
        return AppColors.error;
    }
  }

  String _getLabel() {
    return status.toString().split('.').last;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _getLabel(),
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
