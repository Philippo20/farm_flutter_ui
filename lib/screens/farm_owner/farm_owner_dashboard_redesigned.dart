import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/modern_dashboard_scaffold.dart';
import '../../core/widgets/weather_time_widget.dart';

/// Farm Owner Dashboard - Redesigned
/// Financial focus with digital wallet
class FarmOwnerDashboardRedesigned extends ConsumerWidget {
  const FarmOwnerDashboardRedesigned({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ModernDashboardScaffold(
      title: 'Farm Owner',
      menuItems: [
        DashboardMenuItem(
          title: 'Dashboard',
          icon: Icons.dashboard,
          isSelected: true,
        ),
        DashboardMenuItem(
          title: 'Digital Wallet',
          icon: Icons.account_balance_wallet,
          badge: '\$48.5K',
          onTap: () {},
        ),
        DashboardMenuItem(
          title: 'Analytics',
          icon: Icons.analytics,
          onTap: () {},
        ),
        DashboardMenuItem(
          title: 'Withdraw Funds',
          icon: Icons.money,
          onTap: () {},
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
          'Financial Overview',
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
        label: const Text('Withdraw Funds'),
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
              title: 'Wallet Balance',
              value: '\$48,500',
              icon: Icons.account_balance_wallet,
              color: AppColors.primary,
              trend: '+23%',
              isPositive: true,
              onTap: () {},
            ),
            CompactStatCard(
              title: 'Monthly Revenue',
              value: '\$12,300',
              icon: Icons.trending_up,
              color: AppColors.success,
              trend: '+15%',
              isPositive: true,
            ),
            CompactStatCard(
              title: 'Total Farms',
              value: '5 Farms',
              icon: Icons.agriculture,
              color: AppColors.info,
            ),
            CompactStatCard(
              title: 'Total Yield',
              value: '850 kg',
              icon: Icons.inventory,
              color: AppColors.warning,
              trend: '+8%',
              isPositive: true,
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
              'Digital Wallet',
              Icons.account_balance_wallet_outlined,
              AppColors.primary,
              '\$48,500 available',
              () {},
            ),
            _buildFeatureCard(
              context,
              isDark,
              'Withdraw Funds',
              Icons.money,
              AppColors.success,
              'Request withdrawal',
              () {},
            ),
            _buildFeatureCard(
              context,
              isDark,
              'Analytics',
              Icons.analytics,
              AppColors.info,
              'View performance',
              () {},
            ),
            _buildFeatureCard(
              context,
              isDark,
              'Financial Reports',
              Icons.assessment,
              AppColors.warning,
              'Download reports',
              () {},
            ),
            _buildFeatureCard(
              context,
              isDark,
              'Farm Performance',
              Icons.trending_up,
              AppColors.primary,
              '5 farms tracked',
              () {},
            ),
            _buildFeatureCard(
              context,
              isDark,
              'Settings',
              Icons.settings_outlined,
              AppColors.textSecondary,
              'Account settings',
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
