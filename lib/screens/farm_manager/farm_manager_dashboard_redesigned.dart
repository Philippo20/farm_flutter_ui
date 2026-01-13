import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/farm_manager_sidebar.dart';
import '../../core/widgets/farm_manager_header.dart';
import '../../core/widgets/modern_dashboard_scaffold.dart';
import '../../core/widgets/weather_time_widget.dart';
import '../../core/widgets/weather_info_chip.dart';
import '../../providers/auth_provider.dart';

/// Farm Manager Dashboard - Redesigned
/// Professional layout with sidebar, weather, and compact stats
class FarmManagerDashboardRedesigned extends ConsumerStatefulWidget {
  const FarmManagerDashboardRedesigned({super.key});

  @override
  ConsumerState<FarmManagerDashboardRedesigned> createState() =>
      _FarmManagerDashboardRedesignedState();
}

class _FarmManagerDashboardRedesignedState extends ConsumerState<FarmManagerDashboardRedesigned> {
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'Farm Manager';
    final userEmail = authState.user?.email ?? 'manager@farmestates.com';
    final userRole = 'Farm Manager';

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: isMobile
          ? _buildMobileLayout(isDark, userName)
          : _buildDesktopLayout(isDark, userName, userEmail, userRole),
      floatingActionButton: isMobile
          ? null
          : FloatingActionButton.extended(
              onPressed: () => Navigator.pushNamed(context, '/batch-generation'),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add),
              label: const Text('Generate Batch'),
            ),
    );
  }

  Widget _buildDesktopLayout(bool isDark, String userName, String userEmail, String userRole) {
    return Row(
      children: [
        // Sidebar
        FarmManagerSidebar(
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
              FarmManagerHeader(
                userName: userName,
                weatherInfo: _weatherInfo,
                onNotificationTap: () {
                  // Handle notifications
                },
              ),

              // Content
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 600;
                    return SingleChildScrollView(
                      padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Weather & Time Widget
                          const WeatherTimeWidget(),

                          SizedBox(height: isMobile ? AppSpacing.md : AppSpacing.lg),

                          // Compact Stats Section
                          _buildStatsSection(context),

                          SizedBox(height: isMobile ? AppSpacing.lg : AppSpacing.xl),

                          // Section Title
                          Text(
                            'Quick Actions',
                            style: AppTypography.h5.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 18 : 20,
                            ),
                          ),

                          SizedBox(height: isMobile ? AppSpacing.sm : AppSpacing.md),

                          // Features Grid
                          _buildFeaturesGrid(context),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(bool isDark, String userName) {
    return Column(
      children: [
        // Header
        FarmManagerHeader(
          userName: userName,
          weatherInfo: _weatherInfo,
          onNotificationTap: () {
            // Handle notifications
          },
        ),

        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Weather & Time Widget
                const WeatherTimeWidget(),

                const SizedBox(height: AppSpacing.lg),

                // Compact Stats Section
                _buildStatsSection(context),

                const SizedBox(height: AppSpacing.lg),

                // Section Title
                Text(
                  'Quick Actions',
                  style: AppTypography.h5.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Features Grid
                _buildFeaturesGrid(context),
              ],
            ),
          ),
        ),

        // Bottom Navigation
        _buildBottomNavigation(isDark),
      ],
    );
  }

  Widget _buildBottomNavigation(bool isDark) {
    final navItems = [
      {
        'icon': Icons.dashboard_outlined,
        'label': 'Dashboard',
        'index': 0,
        'route': '/farm-manager'
      },
      {
        'icon': Icons.inventory_2_outlined,
        'label': 'Inventory',
        'index': 1,
        'route': '/farm-manager/inventory'
      },
      {
        'icon': Icons.grid_view_outlined,
        'label': 'Batches',
        'index': 2,
        'route': '/farm-manager/batch-generation'
      },
      {
        'icon': Icons.request_quote_outlined,
        'label': 'Funds',
        'index': 3,
        'route': '/farm-manager/fund-request'
      },
      {'icon': Icons.assessment_outlined, 'label': 'Reports', 'index': 4, 'route': '/farm-manager/reports'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: navItems.take(5).map((item) {
              final index = item['index'] as int;
              final route = item['route'] as String;
              final isSelected = index == _selectedNavIndex;

              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (_selectedNavIndex != index) {
                        setState(() => _selectedNavIndex = index);
                        try {
                          Navigator.pushReplacementNamed(context, route);
                        } catch (e) {
                          try {
                            Navigator.pushNamed(context, route);
                          } catch (e2) {
                            debugPrint('Navigation error: $e2');
                          }
                        }
                      }
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item['icon'] as IconData,
                          size: 24,
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? Colors.white.withOpacity(0.5) : AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['label'] as String,
                          style: AppTypography.caption.copyWith(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark
                                    ? Colors.white.withOpacity(0.5)
                                    : AppColors.textSecondary),
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive: 4 columns on desktop, 2 on tablet, 2 on mobile
        final crossAxisCount = constraints.maxWidth > 800 ? 4 : 2;
        // Adjust aspect ratio based on screen size
        final childAspectRatio = isMobile ? 2.8 : (constraints.maxWidth > 800 ? 3.2 : 2.8);

        return GridView.count(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: isMobile ? AppSpacing.xs : AppSpacing.sm,
          mainAxisSpacing: isMobile ? AppSpacing.xs : AppSpacing.sm,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive: 4 columns on desktop, 2 on tablet, 2 on mobile
        final crossAxisCount = constraints.maxWidth > 800 ? 4 : 2;
        // Adjust aspect ratio based on screen size
        final childAspectRatio = isMobile ? 1.1 : (constraints.maxWidth > 800 ? 1.2 : 1.15);

        return GridView.count(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: isMobile ? AppSpacing.sm : AppSpacing.md,
          mainAxisSpacing: isMobile ? AppSpacing.sm : AppSpacing.md,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: EdgeInsets.all(isMobile ? AppSpacing.sm : AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black12,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(isMobile ? AppSpacing.sm : AppSpacing.md),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: isMobile ? 24 : 32,
                color: color,
              ),
            ),
            SizedBox(height: isMobile ? AppSpacing.xs : AppSpacing.sm),
            Flexible(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontSize: isMobile ? 12 : 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: isMobile ? 2 : 4),
            Flexible(
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? Colors.white60 : AppColors.textSecondary,
                  fontSize: isMobile ? 10 : 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
