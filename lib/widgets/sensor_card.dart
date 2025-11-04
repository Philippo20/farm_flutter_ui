// Sensor card widget

import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/app_spacing.dart';
import '../constants/app_icons.dart';
import '../models/sensor_model.dart';
import '../models/enums.dart';

/// Sensor Card Widget
/// Displays a sensor reading with icon, value, and status
class SensorCard extends StatelessWidget {
  final SensorModel sensor;
  final VoidCallback? onTap;
  final bool showTimestamp;
  final Color? customColor;

  const SensorCard({
    super.key,
    required this.sensor,
    this.onTap,
    this.showTimestamp = true,
    this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = customColor ?? _getSensorColor(sensor.type);
    final isStale = !sensor.isRecent;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.1),
                color.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Row
              Row(
                children: [
                  // Icon
                  Container(
                    padding: EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Icon(
                      AppIcons.getSensorIcon(sensor.type.name, filled: true),
                      color: color,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  // Label
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sensor.type.displayName,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (showTimestamp && isStale)
                          Row(
                            children: [
                              Icon(
                                Icons.warning_amber,
                                size: 12,
                                color: AppColors.warning,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Stale data',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.warning,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  // Status Indicator
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isStale ? AppColors.warning : AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.md),
              // Value Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    sensor.value.toStringAsFixed(1),
                    style: AppTypography.sensorValueLarge.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: AppSpacing.xs),
                  Text(
                    sensor.unit,
                    style: AppTypography.sensorUnit.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              if (showTimestamp) ...[
                SizedBox(height: AppSpacing.sm),
                // Timestamp
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 4),
                    Text(
                      sensor.timeAgo,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Get color based on sensor type
  Color _getSensorColor(SensorType type) {
    switch (type) {
      case SensorType.temperature:
        return AppColors.temperatureNormal;
      case SensorType.humidity:
        return AppColors.humidityNormal;
      case SensorType.ph:
        return AppColors.phNeutral;
      case SensorType.ec:
        return AppColors.ecNormal;
      case SensorType.light:
        return AppColors.lightNormal;
      case SensorType.co2:
        return AppColors.chartBlue;
      case SensorType.electricityCurrent:
      case SensorType.electricityVoltage:
      case SensorType.electricityWattage:
        return AppColors.chartYellow;
    }
  }
}

/// Compact Sensor Card for grid layouts
class CompactSensorCard extends StatelessWidget {
  final SensorModel sensor;
  final VoidCallback? onTap;

  const CompactSensorCard({
    super.key,
    required this.sensor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getSensorColor(sensor.type);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.sm),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                AppIcons.getSensorIcon(sensor.type.name),
                color: color,
                size: 32,
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                sensor.value.toStringAsFixed(1),
                style: AppTypography.sensorValue.copyWith(
                  color: color,
                ),
              ),
              Text(
                sensor.unit,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getSensorColor(SensorType type) {
    switch (type) {
      case SensorType.temperature:
        return AppColors.temperatureNormal;
      case SensorType.humidity:
        return AppColors.humidityNormal;
      case SensorType.ph:
        return AppColors.phNeutral;
      case SensorType.ec:
        return AppColors.ecNormal;
      case SensorType.light:
        return AppColors.lightNormal;
      case SensorType.co2:
        return AppColors.chartBlue;
      case SensorType.electricityCurrent:
      case SensorType.electricityVoltage:
      case SensorType.electricityWattage:
        return AppColors.chartYellow;
    }
  }
}
