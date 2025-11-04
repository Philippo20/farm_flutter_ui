import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Water Quality Monitoring Card for Caretaker Dashboard
/// Displays pH, EC, TDS, and Water Temperature with status indicators
class WaterQualityCard extends StatelessWidget {
  final double ph;
  final double ec;
  final int tds;
  final double waterTemp;
  final VoidCallback? onTap;

  const WaterQualityCard({
    super.key,
    required this.ph,
    required this.ec,
    required this.tds,
    required this.waterTemp,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overallStatus = _getOverallStatus();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: _getStatusColor(overallStatus).withOpacity(0.3),
            width: 2,
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
                    color: AppColors.info.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(
                    Icons.water_drop,
                    color: AppColors.info,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Water Quality',
                        style: AppTypography.h6.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Nutrient Tank Monitoring',
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark ? Colors.white60 : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(overallStatus, isDark),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            // Metrics Grid
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    context,
                    'pH Level',
                    ph.toStringAsFixed(1),
                    'pH',
                    _getPhStatus(ph),
                    Icons.science,
                    Colors.purple,
                    isDark,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildMetricItem(
                    context,
                    'EC',
                    ec.toStringAsFixed(2),
                    'mS/cm',
                    _getEcStatus(ec),
                    Icons.electric_bolt,
                    AppColors.warning,
                    isDark,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    context,
                    'TDS',
                    tds.toString(),
                    'ppm',
                    _getTdsStatus(tds),
                    Icons.opacity,
                    AppColors.info,
                    isDark,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildMetricItem(
                    context,
                    'Water Temp',
                    waterTemp.toStringAsFixed(1),
                    '°C',
                    _getWaterTempStatus(waterTemp),
                    Icons.thermostat,
                    AppColors.error,
                    isDark,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Status Message
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: _getStatusColor(overallStatus).withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                children: [
                  Icon(
                    _getStatusIcon(overallStatus),
                    size: 16,
                    color: _getStatusColor(overallStatus),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      _getStatusMessage(overallStatus),
                      style: AppTypography.bodySmall.copyWith(
                        color: _getStatusColor(overallStatus),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(
    BuildContext context,
    String label,
    String value,
    String unit,
    String status,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    final statusColor = _getStatusColor(status);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: AppTypography.h5.copyWith(
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  unit,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, bool isDark) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getStatusIcon(status), size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: AppTypography.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // Status determination methods
  String _getPhStatus(double ph) {
    if (ph >= 5.5 && ph <= 6.5) return 'optimal';
    if (ph >= 5.0 && ph <= 7.0) return 'acceptable';
    return 'critical';
  }

  String _getEcStatus(double ec) {
    if (ec >= 1.0 && ec <= 1.2) return 'optimal';
    if (ec >= 0.8 && ec <= 1.5) return 'acceptable';
    return 'critical';
  }

  String _getTdsStatus(int tds) {
    if (tds >= 300 && tds <= 800) return 'optimal';
    if (tds >= 200 && tds <= 1000) return 'acceptable';
    return 'critical';
  }

  String _getWaterTempStatus(double temp) {
    if (temp >= 15 && temp <= 20) return 'optimal';
    if (temp >= 12 && temp <= 25) return 'acceptable';
    return 'critical';
  }

  String _getOverallStatus() {
    final statuses = [
      _getPhStatus(ph),
      _getEcStatus(ec),
      _getTdsStatus(tds),
      _getWaterTempStatus(waterTemp),
    ];

    if (statuses.any((s) => s == 'critical')) return 'critical';
    if (statuses.any((s) => s == 'acceptable')) return 'acceptable';
    return 'optimal';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'optimal':
        return AppColors.success;
      case 'acceptable':
        return AppColors.warning;
      case 'critical':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'optimal':
        return Icons.check_circle;
      case 'acceptable':
        return Icons.warning;
      case 'critical':
        return Icons.error;
      default:
        return Icons.info;
    }
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case 'optimal':
        return 'All water quality parameters are within optimal range';
      case 'acceptable':
        return 'Water quality is acceptable, monitor closely';
      case 'critical':
        return 'Immediate attention required! Adjust water parameters';
      default:
        return 'Unknown status';
    }
  }
}
