import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/modern_dashboard_scaffold.dart';
import '../../core/widgets/weather_time_widget.dart';

/// Accountant Dashboard - Redesigned
class AccountantDashboardRedesigned extends ConsumerWidget {
  const AccountantDashboardRedesigned({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ModernDashboardScaffold(
      title: 'Accountant',
      menuItems: [
        DashboardMenuItem(title: 'Dashboard', icon: Icons.dashboard, isSelected: true),
        DashboardMenuItem(title: 'Transactions', icon: Icons.receipt_long, badge: '7', onTap: () {}),
        DashboardMenuItem(title: 'Reconciliation', icon: Icons.account_balance, onTap: () {}),
        DashboardMenuItem(title: 'Reports', icon: Icons.assessment, onTap: () {}),
        DashboardMenuItem(title: 'Approvals', icon: Icons.approval, badge: '3', onTap: () {}),
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
              CompactStatCard(title: 'Pending', value: '7 Trans', icon: Icons.pending, color: AppColors.warning),
              CompactStatCard(title: 'Revenue', value: '\$125.4K', icon: Icons.trending_up, color: AppColors.success, trend: '+18%', isPositive: true),
              CompactStatCard(title: 'Expenses', value: '\$42.8K', icon: Icons.trending_down, color: AppColors.error, trend: '+5%', isPositive: false),
              CompactStatCard(title: 'Profit', value: '\$82.6K', icon: Icons.attach_money, color: AppColors.primary, trend: '+23%', isPositive: true),
            ],
          );
        }),
        const SizedBox(height: AppSpacing.xl),
        Text('Financial Management', style: AppTypography.h5.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(builder: (context, constraints) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return GridView.count(
            crossAxisCount: constraints.maxWidth > 800 ? 4 : 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildCard(context, isDark, 'Confirm Transactions', Icons.check_circle, AppColors.primary, '7 pending', () {}),
              _buildCard(context, isDark, 'View All', Icons.receipt_long, AppColors.info, 'All transactions', () {}),
              _buildCard(context, isDark, 'Reconcile', Icons.account_balance, AppColors.success, 'Bank reconciliation', () {}),
              _buildCard(context, isDark, 'Reports', Icons.assessment, AppColors.warning, 'Financial reports', () {}),
              _buildCard(context, isDark, 'Expenses', Icons.money_off, AppColors.error, 'Track expenses', () {}),
              _buildCard(context, isDark, 'Approvals', Icons.approval, AppColors.primary, '3 pending', () {}),
              _buildCard(context, isDark, 'Export', Icons.download, AppColors.info, 'Export data', () {}),
              _buildCard(context, isDark, 'Settings', Icons.settings_outlined, AppColors.textSecondary, 'Preferences', () {}),
            ],
          );
        }),
      ],
      floatingActionButton: FloatingActionButton.extended(onPressed: () {}, backgroundColor: AppColors.primary, icon: const Icon(Icons.add), label: const Text('New Transaction')),
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
