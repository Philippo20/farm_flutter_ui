import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Environment Monitoring Card for Caretaker Dashboard
/// Displays Temperature, Humidity, and CO2 levels with trends
class EnvironmentMonitoringCard extends StatelessWidget {
  final double temperature;
  final int humidity;
  final int co2;
  final String temperatureTrend;
  final String humidityTrend;
  final String co2Trend;
  final VoidCallback? onTap;

  const EnvironmentMonitoringCard({
    super.key,
    required this.temperature,
    required this.humidity,
    required this.co2,
    this.temperatureTrend = 'stable',
    this.humidityTrend = 'stable',
    this.co2Trend = 'stable',
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
          boxShadow: isDark ? null : [
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
                    color: AppColors.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(
                    Icons.eco,
                    color: AppColors.success,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Environment',
                        style: AppTypography.h6.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Greenhouse Conditions',
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

            // Temperature Metric
            _buildLargeMetric(
              context,
              'Temperature',
              temperature.toStringAsFixed(1),
              '°C',
              _getTemperatureStatus(temperature),
              temperatureTrend,
              Icons.thermostat_rounded,
              AppColors.warning,
              isDark,
            ),

            const SizedBox(height: AppSpacing.md),

            // Humidity and CO2 Row
            Row(
              children: [
                Expanded(
                  child: _buildCompactMetric(
                    context,
                    'Humidity',
                    '$humidity',
                    '%',
                    _getHumidityStatus(humidity),
                    humidityTrend,
                    Icons.water_drop_rounded,
                    AppColors.info,
                    isDark,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildCompactMetric(
                    context,
                    'CO₂ Level',
                    co2.toString(),
                    'ppm',
                    _getCo2Status(co2),
                    co2Trend,
                    Icons.air_rounded,
                    Colors.grey,
                    isDark,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Recommendations
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : AppColors.neutral100,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      _getRecommendation(),
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? Colors.white70 : AppColors.textSecondary,
                        fontSize: 11,
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

  Widget _buildLargeMetric(
    BuildContext context,
    String label,
    String value,
    String unit,
    String status,
    String trend,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    final statusColor = _getStatusColor(status);
    final trendIcon = _getTrendIcon(trend);
    final trendColor = _getTrendColor(trend);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        style: AppTypography.h4.copyWith(
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        unit,
                        style: AppTypography.bodyMedium.copyWith(
                          color: isDark ? Colors.white60 : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: trendColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(trendIcon, size: 14, color: trendColor),
                const SizedBox(width: 4),
                Text(
                  trend.toUpperCase(),
                  style: AppTypography.bodySmall.copyWith(
                    color: trendColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactMetric(
    BuildContext context,
    String label,
    String value,
    String unit,
    String status,
    String trend,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    final statusColor = _getStatusColor(status);
    final trendIcon = _getTrendIcon(trend);
    final trendColor = _getTrendColor(trend);

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
              Icon(trendIcon, size: 12, color: trendColor),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: AppTypography.h5.copyWith(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
  String _getTemperatureStatus(double temp) {
    if (temp >= 18 && temp <= 24) return 'optimal';
    if (temp >= 15 && temp <= 28) return 'acceptable';
    return 'critical';
  }

  String _getHumidityStatus(int humidity) {
    if (humidity >= 50 && humidity <= 70) return 'optimal';
    if (humidity >= 40 && humidity <= 80) return 'acceptable';
    return 'critical';
  }

  String _getCo2Status(int co2) {
    if (co2 >= 400 && co2 <= 1000) return 'optimal';
    if (co2 >= 300 && co2 <= 1200) return 'acceptable';
    return 'critical';
  }

  String _getOverallStatus() {
    final statuses = [
      _getTemperatureStatus(temperature),
      _getHumidityStatus(humidity),
      _getCo2Status(co2),
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

  IconData _getTrendIcon(String trend) {
    switch (trend) {
      case 'up':
        return Icons.trending_up;
      case 'down':
        return Icons.trending_down;
      case 'stable':
        return Icons.trending_flat;
      default:
        return Icons.remove;
    }
  }

  Color _getTrendColor(String trend) {
    switch (trend) {
      case 'up':
        return AppColors.error;
      case 'down':
        return AppColors.info;
      case 'stable':
        return AppColors.success;
      default:
        return Colors.grey;
    }
  }

  String _getRecommendation() {
    if (_getTemperatureStatus(temperature) == 'critical') {
      return temperature > 24
          ? 'Temperature too high. Increase ventilation or activate cooling.'
          : 'Temperature too low. Reduce ventilation or activate heating.';
    }
    if (_getHumidityStatus(humidity) == 'critical') {
      return humidity > 70
          ? 'Humidity too high. Increase air circulation to prevent mold.'
          : 'Humidity too low. Consider misting or adding humidifiers.';
    }
    if (_getCo2Status(co2) == 'critical') {
      return co2 > 1200
          ? 'CO₂ levels high. Increase ventilation immediately.'
          : 'CO₂ levels low. Ensure adequate air circulation.';
    }
    return 'All environmental parameters are within optimal range. Keep monitoring!';
  }
}
