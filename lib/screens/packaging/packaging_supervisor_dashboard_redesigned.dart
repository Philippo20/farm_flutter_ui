import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/packaging_supervisor_sidebar.dart';
import '../../core/widgets/packaging_supervisor_header.dart';
import '../../core/widgets/modern_dashboard_scaffold.dart';
import '../../core/widgets/weather_time_widget.dart';
import '../../core/widgets/weather_info_chip.dart';
import '../../providers/auth_provider.dart';

/// Packaging Supervisor Dashboard - Redesigned
/// Package recording and waste tracking
class PackagingSupervisorDashboardRedesigned extends ConsumerStatefulWidget {
  const PackagingSupervisorDashboardRedesigned({super.key});

  @override
  ConsumerState<PackagingSupervisorDashboardRedesigned> createState() =>
      _PackagingSupervisorDashboardRedesignedState();
}

class _PackagingSupervisorDashboardRedesignedState
    extends ConsumerState<PackagingSupervisorDashboardRedesigned> {
  int _selectedNavIndex = 0;
  WeatherInfo? _weatherInfo;

  @override
  void initState() {
    super.initState();
    _weatherInfo = const WeatherInfo(condition: 'Sunny', temperature: 28.5);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'Packaging Supervisor';
    final userEmail = authState.user?.email ?? 'packaging@farmestates.com';
    final userRole = 'Packaging Supervisor';

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Row(
        children: [
          // Sidebar
          PackagingSupervisorSidebar(
            selectedIndex: _selectedNavIndex,
            onItemSelected: (index) {
              setState(() {
                _selectedNavIndex = index;
              });
            },
            userName: userName,
            userEmail: userEmail,
            userRole: userRole,
          ),

          // Main Content
          Expanded(
            child: Column(
              children: [
                // Header
                PackagingSupervisorHeader(
                  userName: userName,
                  weatherInfo: _weatherInfo,
                  onNotificationTap: () {},
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const WeatherTimeWidget(),
                        const SizedBox(height: AppSpacing.lg),
                        _buildStatsSection(context),
                        const SizedBox(height: AppSpacing.xl),
                        Text('Packaging Operations', style: AppTypography.h5.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: AppSpacing.md),
                        _buildFeaturesGrid(context),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Record Package'),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.count(
          crossAxisCount: constraints.maxWidth > 800 ? 4 : 2,
          childAspectRatio: 3.2,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            CompactStatCard(title: 'Progress', value: '65%', icon: Icons.pie_chart, color: AppColors.primary, trend: '+5%', isPositive: true),
            CompactStatCard(title: 'Completed', value: '45 Pkgs', icon: Icons.check_circle, color: AppColors.success, trend: '+12', isPositive: true),
            CompactStatCard(title: 'Waste', value: '2.3%', icon: Icons.delete, color: AppColors.error, trend: '-0.5%', isPositive: true),
            CompactStatCard(title: 'Efficiency', value: '92%', icon: Icons.speed, color: AppColors.info, trend: '+3%', isPositive: true),
          ],
        );
      },
    );
  }

  Widget _buildFeaturesGrid(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.count(
          crossAxisCount: constraints.maxWidth > 800 ? 2 : 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildFeatureCard(context, isDark, 'Record Package', Icons.inventory, AppColors.primary, 'Log packages', () {}),
            _buildFeatureCard(context, isDark, 'Track Waste', Icons.delete_outline, AppColors.error, 'Monitor waste', () {}),
          ],
        );
      },
    );
  }

  Widget _buildFeatureCard(BuildContext context, bool isDark, String title, IconData icon, Color color, String subtitle, VoidCallback onTap) {
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
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(icon, size: 32, color: color),
            ),
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
