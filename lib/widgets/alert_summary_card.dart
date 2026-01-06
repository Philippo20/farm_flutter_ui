import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../data/mock_farm_data.dart';
import '../models/alert_model.dart';

/// Alert Summary Card Widget
/// Displays alert statistics and recent critical alerts
class AlertSummaryCard extends StatelessWidget {
  final VoidCallback? onViewAll;
  final bool showRecentAlerts;
  final int maxRecentAlerts;

  const AlertSummaryCard({
    super.key,
    this.onViewAll,
    this.showRecentAlerts = true,
    this.maxRecentAlerts = 3,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stats = MockFarmData.getAlertStats();
    final activeAlerts = MockFarmData.getActiveAlerts();
    final criticalAlerts = activeAlerts.where((a) => a.isCritical).take(maxRecentAlerts).toList();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: stats['critical'] > 0 
              ? AppColors.error.withOpacity(0.3)
              : (isDark ? Colors.white10 : Colors.black12),
          width: stats['critical'] > 0 ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: stats['critical'] > 0 
                      ? AppColors.error.withOpacity(0.15)
                      : AppColors.info.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(
                  stats['critical'] > 0 ? Icons.warning_amber : Icons.notifications_active,
                  color: stats['critical'] > 0 ? AppColors.error : AppColors.info,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'System Alerts',
                      style: AppTypography.h6.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${stats['active']} active alerts',
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? Colors.white60 : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onViewAll ?? () {
                  context.go('/alerts');
                },
                child: const Text('View All'),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Statistics Grid
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Critical',
                  stats['critical'].toString(),
                  AppColors.error,
                  Icons.error_outline,
                  isDark,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Warning',
                  stats['warning'].toString(),
                  AppColors.warning,
                  Icons.warning,
                  isDark,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Info',
                  stats['info'].toString(),
                  AppColors.info,
                  Icons.info_outline,
                  isDark,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Today',
                  stats['todayCount'].toString(),
                  AppColors.primary,
                  Icons.today,
                  isDark,
                ),
              ),
            ],
          ),

          // Recent Critical Alerts
          if (showRecentAlerts && criticalAlerts.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Critical Alerts',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...criticalAlerts.map((alert) => _buildAlertItem(alert, isDark)),
          ],

          // No Alerts State
          if (stats['active'] == 0) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'All systems operating normally',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon, bool isDark) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.h6.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: isDark ? Colors.white60 : AppColors.textSecondary,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAlertItem(AlertModel alert, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.error.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: 16,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.sensorType.displayName,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
                Text(
                  alert.message,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            alert.timeAgo,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white60 : AppColors.textSecondary,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact Alert Badge for navigation items
class AlertBadge extends StatelessWidget {
  final int count;
  final Color? color;

  const AlertBadge({
    super.key,
    required this.count,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();

    final badgeColor = color ?? AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(10),
      ),
      constraints: const BoxConstraints(
        minWidth: 18,
        minHeight: 18,
      ),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: AppTypography.bodySmall.copyWith(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
