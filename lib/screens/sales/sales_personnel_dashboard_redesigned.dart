import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/modern_dashboard_scaffold.dart';
import '../../core/widgets/weather_time_widget.dart';

/// Sales Personnel Dashboard - Redesigned
class SalesPersonnelDashboardRedesigned extends ConsumerWidget {
  const SalesPersonnelDashboardRedesigned({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ModernDashboardScaffold(
      title: 'Sales Personnel',
      menuItems: [
        DashboardMenuItem(title: 'Dashboard', icon: Icons.dashboard, isSelected: true),
        DashboardMenuItem(title: 'Record Delivery', icon: Icons.local_shipping, badge: '5', onTap: () {}),
        DashboardMenuItem(title: 'Pipeline', icon: Icons.timeline, badge: '8', onTap: () {}),
        DashboardMenuItem(title: 'My Sales', icon: Icons.attach_money, onTap: () {}),
        DashboardMenuItem(title: 'Performance', icon: Icons.trending_up, onTap: () {}),
        DashboardMenuItem(title: 'Settings', icon: Icons.settings, onTap: () {}),
      ],
      children: [
        const WeatherTimeWidget(),
        const SizedBox(height: AppSpacing.lg),
        LayoutBuilder(builder: (context, constraints) {
          return GridView.count(
            crossAxisCount: constraints.maxWidth > 800 ? 4 : 2,
            childAspectRatio: 3.2,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              CompactStatCard(title: 'Deliveries', value: '5 Today', icon: Icons.local_shipping, color: AppColors.primary, trend: '+2', isPositive: true),
              CompactStatCard(title: 'My Sales', value: '\$45.2K', icon: Icons.attach_money, color: AppColors.success, trend: '+12%', isPositive: true),
              CompactStatCard(title: 'Prospects', value: '8 Active', icon: Icons.people, color: AppColors.info),
              CompactStatCard(title: 'Conversion', value: '65%', icon: Icons.trending_up, color: AppColors.warning, trend: '+5%', isPositive: true),
            ],
          );
        }),
        const SizedBox(height: AppSpacing.xl),
        Text('Sales Activities', style: AppTypography.h5.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(builder: (context, constraints) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return GridView.count(
            crossAxisCount: constraints.maxWidth > 800 ? 3 : 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildCard(context, isDark, 'Record Delivery', Icons.local_shipping, AppColors.primary, '5 pending', () {}),
              _buildCard(context, isDark, 'Pipeline', Icons.timeline, AppColors.info, '8 prospects', () {}),
              _buildCard(context, isDark, 'Track Sales', Icons.attach_money, AppColors.success, '\$45.2K', () {}),
              _buildCard(context, isDark, 'Expenses', Icons.receipt, AppColors.warning, 'Log expenses', () {}),
              _buildCard(context, isDark, 'Reports', Icons.assessment, AppColors.primary, 'View analytics', () {}),
              _buildCard(context, isDark, 'Settings', Icons.settings_outlined, AppColors.textSecondary, 'Preferences', () {}),
            ],
          );
        }),
      ],
      floatingActionButton: FloatingActionButton.extended(onPressed: () {}, backgroundColor: AppColors.primary, icon: const Icon(Icons.add), label: const Text('Record Delivery')),
    );
  }

  Widget _buildCard(BuildContext context, bool isDark, String title, IconData icon, Color color, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(color: isDark ? AppColors.surfaceDark : Colors.white, borderRadius: BorderRadius.circular(AppSpacing.radiusMd), border: Border.all(color: isDark ? Colors.white10 : Colors.black12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(padding: const EdgeInsets.all(AppSpacing.md), decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle), child: Icon(icon, size: 32, color: color)),
            const SizedBox(height: AppSpacing.sm),
            Text(title, textAlign: TextAlign.center, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(subtitle, textAlign: TextAlign.center, style: AppTypography.bodySmall.copyWith(color: isDark ? Colors.white60 : AppColors.textSecondary, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
