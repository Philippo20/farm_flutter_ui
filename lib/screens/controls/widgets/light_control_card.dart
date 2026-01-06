import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Light Control Card Widget
class LightControlCard extends StatelessWidget {
  final String lightName;
  final Map<String, dynamic> lightData;
  final Function(bool) onToggle;
  final Function(double) onBrightnessChange;
  final VoidCallback onSchedule;

  const LightControlCard({
    super.key,
    required this.lightName,
    required this.lightData,
    required this.onToggle,
    required this.onBrightnessChange,
    required this.onSchedule,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOn = lightData['state'] == 'ON';
    final brightness = (lightData['brightness'] ?? 100).toDouble();
    final powerUsage = lightData['powerUsage'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isOn 
              ? Colors.amber.withOpacity(0.3)
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
                      ? Colors.amber.withOpacity(0.15)
                      : Colors.grey.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(
                  Icons.light_mode,
                  color: isOn ? Colors.amber : Colors.grey,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lightName,
                      style: AppTypography.h6.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      isOn ? 'On - ${brightness.toInt()}%' : 'Off',
                      style: AppTypography.bodySmall.copyWith(
                        color: isOn ? Colors.amber : Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isOn,
                onChanged: onToggle,
                activeColor: Colors.amber,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Brightness Slider
          if (isOn) ...[
            Text(
              'Brightness',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Slider(
              value: brightness,
              min: 0,
              max: 100,
              divisions: 20,
              label: '${brightness.toInt()}%',
              activeColor: Colors.amber,
              onChanged: onBrightnessChange,
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Metrics
          Row(
            children: [
              Expanded(
                child: _buildMetric(
                  'Power Usage',
                  '$powerUsage W',
                  Icons.power,
                  isDark,
                ),
              ),
              Expanded(
                child: _buildMetric(
                  'Status',
                  isOn ? 'Active' : 'Inactive',
                  Icons.info_outline,
                  isDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onSchedule,
                  icon: const Icon(Icons.schedule, size: 18),
                  label: const Text('Schedule'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.amber,
                    side: const BorderSide(color: Colors.amber),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.timer, size: 18),
                  label: const Text('Timer'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.info,
                    side: BorderSide(color: AppColors.info),
                  ),
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
          Icon(icon, size: 20, color: Colors.amber),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
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
