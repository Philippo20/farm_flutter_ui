import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/sales_manager_sidebar.dart';
import '../../core/widgets/sales_manager_header.dart';
import '../../core/widgets/modern_dashboard_scaffold.dart';
import '../../core/widgets/weather_time_widget.dart';
import '../../core/widgets/weather_info_chip.dart';
import '../../providers/auth_provider.dart';

/// Sales Manager Dashboard - Redesigned
class SalesManagerDashboardRedesigned extends ConsumerStatefulWidget {
  const SalesManagerDashboardRedesigned({super.key});

  @override
  ConsumerState<SalesManagerDashboardRedesigned> createState() =>
      _SalesManagerDashboardRedesignedState();
}

class _SalesManagerDashboardRedesignedState
    extends ConsumerState<SalesManagerDashboardRedesigned> {
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
    final userName = authState.user?.name ?? 'Sales Manager';
    final userEmail = authState.user?.email ?? 'sales@farmestates.com';
    final userRole = 'Sales Manager';

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Row(
        children: [
          // Sidebar
          SalesManagerSidebar(
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
                SalesManagerHeader(
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
                        LayoutBuilder(builder: (context, constraints) {
                          return GridView.count(
                            crossAxisCount: constraints.maxWidth > 800 ? 4 : 2,
                            childAspectRatio: 3.2,
                            crossAxisSpacing: AppSpacing.sm,
                            mainAxisSpacing: AppSpacing.sm,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              CompactStatCard(title: 'Revenue', value: '\$125.4K', icon: Icons.attach_money, color: AppColors.success, trend: '+18%', isPositive: true),
                              CompactStatCard(title: 'Off-Takers', value: '12 Active', icon: Icons.people, color: AppColors.primary),
                              CompactStatCard(title: 'Deliveries', value: '5 Pending', icon: Icons.local_shipping, color: AppColors.warning),
                              CompactStatCard(title: 'Performance', value: '87%', icon: Icons.trending_up, color: AppColors.info, trend: '+5%', isPositive: true),
                            ],
                          );
                        }),
                        const SizedBox(height: AppSpacing.xl),
                        Text('Sales Operations', style: AppTypography.h5.copyWith(fontWeight: FontWeight.bold)),
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
                              _buildCard(context, isDark, 'Off-Takers', Icons.people, AppColors.primary, '12 active', () {}),
                              _buildCard(context, isDark, 'Deliveries', Icons.local_shipping, AppColors.warning, '5 pending', () {}),
                              _buildCard(context, isDark, 'Performance', Icons.trending_up, AppColors.success, '87% target', () {}),
                              _buildCard(context, isDark, 'Financial', Icons.attach_money, AppColors.info, '\$125.4K', () {}),
                              _buildCard(context, isDark, 'Add Off-Taker', Icons.person_add, AppColors.primary, 'New client', () {}),
                              _buildCard(context, isDark, 'Commission', Icons.account_balance, AppColors.success, 'View earnings', () {}),
                              _buildCard(context, isDark, 'Reports', Icons.assessment, AppColors.warning, 'Analytics', () {}),
                              _buildCard(context, isDark, 'Settings', Icons.settings_outlined, AppColors.textSecondary, 'Preferences', () {}),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: () {}, backgroundColor: AppColors.primary, icon: const Icon(Icons.add), label: const Text('Add Off-Taker')),
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
