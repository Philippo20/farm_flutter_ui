import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/fulfillment_manager_sidebar.dart';
import '../../core/widgets/fulfillment_manager_header.dart';
import '../../core/widgets/modern_dashboard_scaffold.dart';
import '../../core/widgets/weather_time_widget.dart';
import '../../core/widgets/weather_info_chip.dart';
import '../../providers/auth_provider.dart';

/// Fulfillment Manager Dashboard - Redesigned
/// Harvest coordination and packaging management
class FulfillmentManagerDashboardRedesigned extends ConsumerStatefulWidget {
  const FulfillmentManagerDashboardRedesigned({super.key});

  @override
  ConsumerState<FulfillmentManagerDashboardRedesigned> createState() =>
      _FulfillmentManagerDashboardRedesignedState();
}

class _FulfillmentManagerDashboardRedesignedState
    extends ConsumerState<FulfillmentManagerDashboardRedesigned> {
  int _selectedNavIndex = 0;
  WeatherInfo? _weatherInfo;

  @override
  void initState() {
    super.initState();
    // Load weather info if needed
    _weatherInfo = const WeatherInfo(condition: 'Sunny', temperature: 28.5);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'Fulfillment Manager';
    final userEmail = authState.user?.email ?? 'fulfillment@farmestates.com';
    final userRole = 'Fulfillment Manager';

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Row(
        children: [
          // Sidebar
          FulfillmentManagerSidebar(
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
                FulfillmentManagerHeader(
                  userName: userName,
                  weatherInfo: _weatherInfo,
                  onNotificationTap: () {
                    // Handle notifications
                  },
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
