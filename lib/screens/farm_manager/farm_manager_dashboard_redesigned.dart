import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/modern_dashboard_scaffold.dart';
import '../../core/widgets/weather_time_widget.dart';

/// Farm Manager Dashboard - Redesigned
/// Professional layout with sidebar, weather, and compact stats
class FarmManagerDashboardRedesigned extends ConsumerWidget {
  const FarmManagerDashboardRedesigned({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ModernDashboardScaffold(
      title: 'Farm Manager',
      menuItems: [
        DashboardMenuItem(
          title: 'Dashboard',
          icon: Icons.dashboard,
          isSelected: true,
        ),
        DashboardMenuItem(
          title: 'Inventory',
          icon: Icons.inventory_2_outlined,
          badge: '24',
          onTap: () => Navigator.pushNamed(context, '/inventory'),
        ),
        DashboardMenuItem(
          title: 'Batch Generation',
          icon: Icons.grid_view,
          onTap: () => Navigator.pushNamed(context, '/batch-generation'),
        ),
        DashboardMenuItem(
          title: 'Fund Requests',
          icon: Icons.request_quote,
          badge: '3',
          onTap: () => Navigator.pushNamed(context, '/fund-request'),
        ),
        DashboardMenuItem(
          title: 'Reports',
          icon: Icons.assessment,
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
          'Quick Actions',
          style: AppTypography.h5.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: AppSpacing.md),
        
        // Features Grid
        _buildFeaturesGrid(context),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/batch-generation'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Generate Batch'),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive: 4 columns on desktop, 2 on mobile
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
              title: 'Total Inventory',
              value: '24 Items',
              icon: Icons.inventory_2,
              color: AppColors.primary,
              trend: '+12%',
              isPositive: true,
              onTap: () => Navigator.pushNamed(context, '/inventory'),
            ),
            CompactStatCard(
              title: 'Active Batches',
              value: '12 Batches',
              icon: Icons.grid_view,
              color: AppColors.info,
              trend: '+8%',
              isPositive: true,
            ),
            CompactStatCard(
              title: 'Pending Requests',
              value: '3 Requests',
              icon: Icons.pending_actions,
              color: AppColors.warning,
            ),
            CompactStatCard(
              title: 'Assigned Farms',
              value: '5 Farms',
              icon: Icons.agriculture,
              color: AppColors.success,
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
              'Inventory Management',
              Icons.inventory_2_outlined,
              AppColors.primary,
              '24 items in stock',
              () => Navigator.pushNamed(context, '/inventory'),
            ),
            _buildFeatureCard(
              context,
              isDark,
              'Batch Generation',
              Icons.grid_view,
              AppColors.info,
              'Create new batches',
              () => Navigator.pushNamed(context, '/batch-generation'),
            ),
            _buildFeatureCard(
              context,
              isDark,
              'Harvest Scheduling',
              Icons.calendar_today,
              AppColors.success,
              'Plan harvest dates',
              () {},
            ),
            _buildFeatureCard(
              context,
              isDark,
              'Fund Requests',
              Icons.request_quote,
              AppColors.warning,
              '3 pending requests',
              () => Navigator.pushNamed(context, '/fund-request'),
            ),
            _buildFeatureCard(
              context,
              isDark,
              'Farm Monitoring',
              Icons.agriculture,
              AppColors.primary,
              '5 farms assigned',
              () {},
            ),
            _buildFeatureCard(
              context,
              isDark,
              'Financial Reports',
              Icons.assessment,
              AppColors.info,
              'View progress',
              () {},
            ),
            _buildFeatureCard(
              context,
              isDark,
              'Team Management',
              Icons.people_outline,
              AppColors.success,
              'Manage team',
              () {},
            ),
            _buildFeatureCard(
              context,
              isDark,
              'Settings',
              Icons.settings_outlined,
              AppColors.textSecondary,
              'Configure system',
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
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white60 : AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
