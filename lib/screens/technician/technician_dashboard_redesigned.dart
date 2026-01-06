import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/modern_dashboard_scaffold.dart';
import '../../core/widgets/weather_time_widget.dart';
import '../../widgets/alert_summary_card.dart';
import 'sensor_management_screen.dart';

/// Technician Dashboard - Redesigned
/// Maintenance and technical support
class TechnicianDashboardRedesigned extends ConsumerWidget {
  const TechnicianDashboardRedesigned({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ModernDashboardScaffold(
      title: 'Technician',
      menuItems: [
        DashboardMenuItem(
          title: 'Dashboard',
          icon: Icons.dashboard,
          isSelected: true,
        ),
        DashboardMenuItem(
          title: 'Open Issues',
          icon: Icons.warning_amber,
          badge: '5',
          onTap: () {},
        ),
        DashboardMenuItem(
          title: 'Maintenance',
          icon: Icons.build,
          badge: '3',
          onTap: () {},
        ),
        DashboardMenuItem(
          title: 'Request Items',
          icon: Icons.shopping_cart,
          onTap: () {},
        ),
        DashboardMenuItem(
          title: 'Asset Check',
          icon: Icons.inventory,
          onTap: () {},
        ),
        DashboardMenuItem(
          title: 'Settings',
          icon: Icons.settings,
          onTap: () {},
        ),
      ],
      children: [
        // Weather & Time Widget
        const WeatherTimeWidget(),
        
        const SizedBox(height: AppSpacing.lg),
        
        // Compact Stats Section
        _buildStatsSection(context),
        
        const SizedBox(height: AppSpacing.xl),
        
        // Alert Summary
        const AlertSummaryCard(
          showRecentAlerts: true,
          maxRecentAlerts: 2,
        ),
        
        const SizedBox(height: AppSpacing.xl),
        
        // Section Title
        Text(
          'Farm Asset Monitoring',
          style: AppTypography.h5.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: AppSpacing.md),
        
        // Asset Monitoring Grid
        _buildAssetMonitoringGrid(context),
        
        const SizedBox(height: AppSpacing.xl),
        
        // Section Title
        Text(
          'Maintenance Tasks',
          style: AppTypography.h5.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: AppSpacing.md),
        
        // Features Grid
        _buildFeaturesGrid(context),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: AppColors.error,
        icon: const Icon(Icons.add),
        label: const Text('Report Issue'),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 800 ? 4 : 2;
        
        return GridView.count(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 3.2,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            CompactStatCard(
              title: 'Open Issues',
              value: '5 Issues',
              icon: Icons.warning_amber,
              color: AppColors.error,
              trend: '-2',
              isPositive: true,
            ),
            CompactStatCard(
              title: 'Resolved Today',
              value: '24 Fixed',
              icon: Icons.check_circle,
              color: AppColors.success,
              trend: '+8',
              isPositive: true,
            ),
            CompactStatCard(
              title: 'Maintenance Due',
              value: '3 Tasks',
              icon: Icons.build,
              color: AppColors.warning,
            ),
            CompactStatCard(
              title: 'System Status',
              value: '95%',
              icon: Icons.speed,
              color: AppColors.primary,
              trend: '+2%',
              isPositive: true,
            ),
          ],
        );
      },
    );
  }

  Widget _buildAssetMonitoringGrid(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 800 ? 4 : 2;
        
        return GridView.count(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 1.2,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildAssetCard(context, isDark, 'Pumps', Icons.water_drop, AppColors.info, '8 Active', '2 Need service', () {}),
            _buildAssetCard(context, isDark, 'Fans', Icons.air, AppColors.primary, '12 Active', 'All operational', () {}),
            _buildAssetCard(
              context, 
              isDark, 
              'Sensors', 
              Icons.sensors, 
              AppColors.success, 
              '10 Active', 
              'Manage all sensors', 
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SensorManagementScreen(),
                  ),
                );
              },
            ),
            _buildAssetCard(context, isDark, 'Air Condition', Icons.ac_unit, AppColors.warning, '6 Active', '1 Maintenance', () {}),
          ],
        );
      },
    );
  }

  Widget _buildAssetCard(BuildContext context, bool isDark, String title, IconData icon, Color color, String status, String subtitle, VoidCallback onTap) {
    // Check if this card has an action (not empty callback)
    final hasAction = title == 'Sensors'; // Only Sensors card has navigation
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: hasAction 
              ? color.withOpacity(0.3) 
              : (isDark ? Colors.white10 : Colors.black12),
            width: hasAction ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
                  child: Icon(icon, size: 32, color: color),
                ),
                if (hasAction)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(title, textAlign: TextAlign.center, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(status, textAlign: TextAlign.center, style: AppTypography.bodySmall.copyWith(color: color, fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    subtitle, 
                    textAlign: TextAlign.center, 
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark ? Colors.white60 : AppColors.textSecondary, 
                      fontSize: 10,
                    ), 
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (hasAction) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    size: 14,
                    color: color,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesGrid(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 800 ? 4 : 2;
        
        return GridView.count(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 1.2,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildFeatureCard(
              context,
              isDark,
              'Report Issue',
              Icons.report_problem,
              AppColors.error,
              '5 open issues',
              () {},
            ),
            _buildFeatureCard(
              context,
              isDark,
              'View Solutions',
              Icons.lightbulb_outline,
              AppColors.warning,
              'Knowledge base',
              () {},
            ),
            _buildFeatureCard(
              context,
              isDark,
              'Schedule Maintenance',
              Icons.event,
              AppColors.info,
              '3 tasks due',
              () {},
            ),
            _buildFeatureCard(
              context,
              isDark,
              'Request Items',
              Icons.shopping_cart,
              AppColors.primary,
              'Order supplies',
              () {},
            ),
            _buildFeatureCard(
              context,
              isDark,
              'Asset Check',
              Icons.inventory,
              AppColors.success,
              'Verify equipment',
              () {},
            ),
            _buildFeatureCard(
              context,
              isDark,
              'System Status',
              Icons.monitor_heart,
              AppColors.info,
              '95% operational',
              () {},
            ),
            _buildFeatureCard(
              context,
              isDark,
              'Repair History',
              Icons.history,
              AppColors.warning,
              'View past fixes',
              () {},
            ),
            _buildFeatureCard(
              context,
              isDark,
              'Settings',
              Icons.settings_outlined,
              AppColors.textSecondary,
              'Preferences',
              () {},
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    bool isDark,
    String title,
    IconData icon,
    Color color,
    String subtitle,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black12,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: color,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white60 : AppColors.textSecondary,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
