import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/modern_dashboard_scaffold.dart';
import '../../core/widgets/weather_time_widget.dart';

/// Quality Assurance Dashboard - Redesigned
class QualityAssuranceDashboardRedesigned extends ConsumerWidget {
  const QualityAssuranceDashboardRedesigned({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ModernDashboardScaffold(
      title: 'Quality Assurance',
      menuItems: [
        DashboardMenuItem(title: 'Dashboard', icon: Icons.dashboard, isSelected: true),
        DashboardMenuItem(title: 'Inspection', icon: Icons.search, badge: '12', onTap: () {}),
        DashboardMenuItem(title: 'Approve', icon: Icons.check_circle, onTap: () {}),
        DashboardMenuItem(title: 'Reject', icon: Icons.cancel, onTap: () {}),
        DashboardMenuItem(title: 'Reports', icon: Icons.assessment, onTap: () {}),
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
              CompactStatCard(title: 'Pending', value: '12 Items', icon: Icons.pending, color: AppColors.warning),
              CompactStatCard(title: 'Pass Rate', value: '95%', icon: Icons.check_circle, color: AppColors.success, trend: '+2%', isPositive: true),
              CompactStatCard(title: 'Inspected', value: '28 Today', icon: Icons.fact_check, color: AppColors.info, trend: '+5', isPositive: true),
              CompactStatCard(title: 'Rejections', value: '5%', icon: Icons.cancel, color: AppColors.error, trend: '-1%', isPositive: true),
            ],
          );
        }),
        const SizedBox(height: AppSpacing.xl),
        Text('Quality Control', style: AppTypography.h5.copyWith(fontWeight: FontWeight.bold)),
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
              _buildCard(context, isDark, 'Inspect Items', Icons.search, AppColors.primary, '12 pending', () {}),
              _buildCard(context, isDark, 'Approve', Icons.check_circle, AppColors.success, 'Pass items', () {}),
              _buildCard(context, isDark, 'Reject', Icons.cancel, AppColors.error, 'Fail items', () {}),
              _buildCard(context, isDark, 'Standards', Icons.rule, AppColors.info, 'View criteria', () {}),
              _buildCard(context, isDark, 'Reports', Icons.assessment, AppColors.warning, 'Analytics', () {}),
              _buildCard(context, isDark, 'Settings', Icons.settings_outlined, AppColors.textSecondary, 'Preferences', () {}),
            ],
          );
        }),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('New Inspection'),
      ),
    );
  }

  Widget _buildCard(BuildContext context, bool isDark, String title, IconData icon, Color color, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        ),
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
