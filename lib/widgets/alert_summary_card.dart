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
    final criticalAlerts =
        activeAlerts.where((a) => a.isCritical).take(maxRecentAlerts).toList();
    final hasCritical = (stats['critical'] as num? ?? 0) > 0;
    final activeCount = (stats['active'] as num? ?? 0).toInt();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [AppColors.surfaceDark, Color(0xFF181818)]
              : const [Colors.white, Color(0xFFF9FCFA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: hasCritical
              ? AppColors.error.withOpacity(isDark ? 0.45 : 0.35)
              : (isDark ? Colors.white24 : AppColors.neutral200),
          width: hasCritical ? 1.6 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (hasCritical ? AppColors.error : Colors.black)
                .withOpacity(isDark ? 0.16 : 0.07),
            blurRadius: 18,
            offset: const Offset(0, 8),
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
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: hasCritical
                      ? AppColors.error.withOpacity(0.14)
                      : AppColors.info.withOpacity(0.14),
                  border: Border.all(
                    color: hasCritical
                        ? AppColors.error.withOpacity(0.35)
                        : AppColors.info.withOpacity(0.35),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  hasCritical
                      ? Icons.warning_amber_rounded
                      : Icons.notifications_active_rounded,
                  color: hasCritical ? AppColors.error : AppColors.info,
                  size: 22,
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
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$activeCount active alerts',
                      style: AppTypography.bodySmall.copyWith(
                        color:
                            isDark ? Colors.white60 : AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: hasCritical
                            ? AppColors.error.withOpacity(0.12)
                            : AppColors.success.withOpacity(0.12),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusFull),
                        border: Border.all(
                          color: hasCritical
                              ? AppColors.error.withOpacity(0.28)
                              : AppColors.success.withOpacity(0.28),
                        ),
                      ),
                      child: Text(
                        hasCritical ? 'Needs attention' : 'System stable',
                        style: AppTypography.labelSmall.copyWith(
                          color:
                              hasCritical ? AppColors.error : AppColors.success,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onViewAll ??
                    () {
                      context.go('/alerts');
                    },
                style: TextButton.styleFrom(
                  foregroundColor:
                      hasCritical ? AppColors.error : AppColors.info,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    side: BorderSide(
                      color: (hasCritical ? AppColors.error : AppColors.info)
                          .withOpacity(0.3),
                    ),
                  ),
                ),
                child: const Text('View all'),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Statistics grid
          _buildStatsGrid(stats, isDark),

          // Recent Critical Alerts
          if (showRecentAlerts && criticalAlerts.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Divider(
              color: isDark ? Colors.white12 : AppColors.neutral200,
              height: AppSpacing.lg,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(
                  Icons.priority_high_rounded,
                  size: 16,
                  color: AppColors.error,
                ),
                const SizedBox(width: 6),
                Text(
                  'Critical Alerts',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ...criticalAlerts.map((alert) => _buildAlertItem(alert, isDark)),
          ],

          // No Alerts State
          if (activeCount == 0) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.success.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'All systems operating normally',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
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

  Widget _buildStatsGrid(Map<String, dynamic> stats, bool isDark) {
    final items = <Map<String, dynamic>>[
      {
        'label': 'Critical',
        'value': stats['critical'].toString(),
        'color': AppColors.error,
        'icon': Icons.error_outline_rounded,
      },
      {
        'label': 'Warning',
        'value': stats['warning'].toString(),
        'color': AppColors.warning,
        'icon': Icons.warning_amber_rounded,
      },
      {
        'label': 'Info',
        'value': stats['info'].toString(),
        'color': AppColors.info,
        'icon': Icons.info_outline_rounded,
      },
      {
        'label': 'Today',
        'value': stats['todayCount'].toString(),
        'color': AppColors.primary,
        'icon': Icons.today_rounded,
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 430;
        final columns = compact ? 2 : 4;
        final spacing = AppSpacing.sm;
        final tileWidth =
            (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items
              .map(
                (item) => SizedBox(
                  width: tileWidth,
                  child: _buildStatItem(
                    item['label'] as String,
                    item['value'] as String,
                    item['color'] as Color,
                    item['icon'] as IconData,
                    isDark,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    Color color,
    IconData icon,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.18 : 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(isDark ? 0.35 : 0.22)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                    fontSize: 16,
                    height: 1.1,
                  ),
                ),
                Text(
                  label,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                    fontSize: 10,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertItem(AlertModel alert, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.fromLTRB(8, 8, 10, 8),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(isDark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.error.withOpacity(isDark ? 0.38 : 0.24),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 15,
            ),
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
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  alert.message,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontSize: 10.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: isDark ? Colors.white12 : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Text(
              alert.timeAgo,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
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
