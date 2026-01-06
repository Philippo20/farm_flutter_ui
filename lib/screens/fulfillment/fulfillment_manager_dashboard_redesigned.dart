import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/modern_dashboard_scaffold.dart';
import '../../core/widgets/weather_time_widget.dart';

/// Fulfillment Manager Dashboard - Redesigned
/// Harvest coordination and packaging management
class FulfillmentManagerDashboardRedesigned extends ConsumerWidget {
  const FulfillmentManagerDashboardRedesigned({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ModernDashboardScaffold(
      title: 'Fulfillment Manager',
      menuItems: [
        DashboardMenuItem(
          title: 'Dashboard',
          icon: Icons.dashboard,
          isSelected: true,
        ),
        DashboardMenuItem(
          title: 'Confirm Harvest',
          icon: Icons.check_box,
          badge: '7',
          onTap: () {},
        ),
        DashboardMenuItem(
          title: 'Packaging',
          icon: Icons.inventory_2,
          onTap: () {},
        ),
        DashboardMenuItem(
          title: 'Yield Loss',
          icon: Icons.trending_down,
          onTap: () {},
        ),
        DashboardMenuItem(
          title: 'Materials',
          icon: Icons.category,
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
        
        // Section Title
        Text(
          'Fulfillment Operations',
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
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Confirm Harvest'),
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
              title: 'Pending Harvest',
              value: '7 Batches',
              icon: Icons.pending_actions,
              color: AppColors.warning,
              onTap: () {},
            ),
            CompactStatCard(
              title: 'Received Today',
              value: '850 kg',
              icon: Icons.inventory,
              color: AppColors.success,
              trend: '+12%',
              isPositive: true,
            ),
            CompactStatCard(
              title: 'Yield Loss',
              value: '1.8%',
              icon: Icons.trending_down,
              color: AppColors.error,
              trend: '-0.5%',
              isPositive: true,
            ),
            CompactStatCard(
              title: 'Material Stock',
              value: '85%',
              icon: Icons.category,
              color: AppColors.info,
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeaturesGrid(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 800 ? 3 : 2;
        
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
              'Confirm Harvest',
              Icons.check_box,
              AppColors.primary,
              '7 pending',
              () {},
            ),
            _buildFeatureCard(
              context,
              isDark,
              'Coordinate Packaging',
              Icons.inventory_2,
              AppColors.success,
              'Assign tasks',
              () {},
            ),
            _buildFeatureCard(
              context,
              isDark,
              'Yield Calculator',
              Icons.calculate,
              AppColors.info,
              'Track losses',
              () {},
            ),
            _buildFeatureCard(
              context,
              isDark,
              'Material Request',
              Icons.shopping_cart,
              AppColors.warning,
              'Order supplies',
              () {},
            ),
            _buildFeatureCard(
              context,
              isDark,
              'Reports',
              Icons.assessment,
              AppColors.primary,
              'View analytics',
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
