import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Climate Control Card Widget
class ClimateControlCard extends StatelessWidget {
  final String systemName;
  final Map<String, dynamic> climateData;
  final Function(bool) onToggle;
  final Function(String) onModeChange;
  final Function(double) onTempChange;

  const ClimateControlCard({
    super.key,
    required this.systemName,
    required this.climateData,
    required this.onToggle,
    required this.onModeChange,
    required this.onTempChange,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOn = climateData['state'] == 'ON';
    final mode = climateData['mode'] ?? 'Auto';
    final setpoint = (climateData['setpoint'] ?? 22).toDouble();
    final currentTemp = climateData['currentTemp'] ?? 20;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isOn 
              ? AppColors.info.withOpacity(0.3)
              : (isDark ? Colors.white10 : Colors.black12),
          width: isOn ? 2 : 1,
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
                  color: isOn 
                      ? AppColors.info.withOpacity(0.15)
                      : Colors.grey.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(
                  Icons.thermostat,
                  color: isOn ? AppColors.info : Colors.grey,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      systemName,
                      style: AppTypography.h6.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      isOn ? 'Running - $mode Mode' : 'Stopped',
                      style: AppTypography.bodySmall.copyWith(
                        color: isOn ? AppColors.info : Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isOn,
                onChanged: onToggle,
                activeColor: AppColors.info,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Mode Selection
          if (isOn) ...[
            Text(
              'Mode',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Auto', label: Text('Auto')),
                ButtonSegment(value: 'Cool', label: Text('Cool')),
                ButtonSegment(value: 'Heat', label: Text('Heat')),
              ],
              selected: {mode},
              onSelectionChanged: (Set<String> newSelection) {
                onModeChange(newSelection.first);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            
            // Temperature Setpoint
            Text(
              'Temperature Setpoint',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Slider(
              value: setpoint,
              min: 15,
              max: 30,
              divisions: 30,
              label: '${setpoint.toInt()}°C',
              activeColor: AppColors.info,
              onChanged: onTempChange,
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Metrics
          Row(
            children: [
              Expanded(
                child: _buildMetric(
                  'Current',
                  '$currentTemp°C',
                  Icons.thermostat,
                  isDark,
                ),
              ),
              Expanded(
                child: _buildMetric(
                  'Setpoint',
                  '${setpoint.toInt()}°C',
                  Icons.adjust,
                  isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.white.withOpacity(0.05)
            : AppColors.neutral100,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.info),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.h6.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white60 : AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
