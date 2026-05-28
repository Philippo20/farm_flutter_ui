import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/modern_dashboard_scaffold.dart';
import '../../core/widgets/technician_mobile_bottom_nav.dart';
import '../../core/widgets/technician_sidebar.dart';
import '../../core/widgets/technician_header.dart';
import '../../core/widgets/weather_time_widget.dart';
import '../../core/widgets/weather_info_chip.dart';
import '../../widgets/alert_summary_card.dart';
import '../../providers/auth_provider.dart';

/// Technician Dashboard - Redesigned
/// Maintenance and technical support
class TechnicianDashboardRedesigned extends ConsumerStatefulWidget {
  const TechnicianDashboardRedesigned({super.key});

  @override
  ConsumerState<TechnicianDashboardRedesigned> createState() =>
      _TechnicianDashboardRedesignedState();
}

class _TechnicianDashboardRedesignedState extends ConsumerState<TechnicianDashboardRedesigned> {
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
    final userName = authState.user?.name ?? 'Technician';
    final userEmail = authState.user?.email ?? 'technician@farmestates.com';
    final userRole = 'Technician';

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: isMobile
          ? _buildMobileLayout(isDark, userName)
          : _buildDesktopLayout(isDark, userName, userEmail, userRole),
      floatingActionButton: !isMobile
          ? FloatingActionButton.extended(
              onPressed: () {},
              backgroundColor: AppColors.error,
              icon: const Icon(Icons.add),
              label: const Text('Report Issue'),
            )
          : null,
      bottomNavigationBar: isMobile
          ? TechnicianMobileBottomNav(
              selectedIndex: _selectedNavIndex,
              onItemSelected: (index) => setState(() => _selectedNavIndex = index),
            )
          : null,
    );
  }

  Widget _buildDesktopLayout(bool isDark, String userName, String userEmail, String userRole) {
    return Row(
      children: [
        // Sidebar
        TechnicianSidebar(
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
              TechnicianHeader(
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

                      // Alert Summary
                      const AlertSummaryCard(
                        showRecentAlerts: true,
                        maxRecentAlerts: 2,
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // Section Title
                      Text(
                        'Farm Asset Monitoring',
                        style: AppTypography.h5.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Asset Monitoring Grid
                      _buildAssetMonitoringGrid(context),

                      const SizedBox(height: AppSpacing.xl),

                      // Section Title
                      Text(
                        'Maintenance Tasks',
                        style: AppTypography.h5.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textPrimary,
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
    );
  }

  Widget _buildMobileLayout(bool isDark, String userName) {
    return Column(
      children: [
        TechnicianHeader(
          userName: userName,
          weatherInfo: _weatherInfo,
          onNotificationTap: () {
            // Handle notifications
          },
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Weather & Time Widget
                const WeatherTimeWidget(),

                const SizedBox(height: AppSpacing.md),

                // Compact Stats Section
                _buildStatsSection(context),

                const SizedBox(height: AppSpacing.lg),

                // Alert Summary
                const AlertSummaryCard(
                  showRecentAlerts: true,
                  maxRecentAlerts: 2,
                ),

                const SizedBox(height: AppSpacing.lg),

                // Section Title
                Text(
                  'Farm Asset Monitoring',
                  style: AppTypography.h5.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Asset Monitoring Grid
                _buildAssetMonitoringGrid(context),

                const SizedBox(height: AppSpacing.lg),

                // Section Title
                Text(
                  'Maintenance Tasks',
                  style: AppTypography.h5.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isDark ? Colors.white : AppColors.textPrimary,
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
    );
  }

  Widget _buildBottomNavigation(bool isDark) {
    final navItems = [
      {
        'icon': Icons.dashboard_outlined,
        'label': 'Dashboard',
        'index': 0,
        'route': '/technician_dashboard'
      },
      {
        'icon': Icons.sensors_outlined,
        'label': 'Sensors',
        'index': 1,
        'route': '/sensor-management'
      },
      {
        'icon': Icons.build_outlined,
        'label': 'Maintenance',
        'index': 2,
        'route': '/maintenance-schedule'
      },
      {
        'icon': Icons.history_outlined,
        'label': 'History',
        'index': 3,
        'route': '/repair-history'
      },
      {
        'icon': Icons.settings_outlined,
        'label': 'Settings',
        'index': 4,
        'route': '/technician-settings'
      },
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
            children: navItems.map((item) {
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
              title: 'Open Issues',
              value: '5 Issues',
              icon: Icons.warning_amber,
              color: AppColors.error,
              trend: '-2',
              isPositive: true,
            ),
            CompactStatCard(
              title: 'Resolved Today',
              value: '24 Fixed',
              icon: Icons.check_circle,
              color: AppColors.success,
              trend: '+8',
              isPositive: true,
            ),
            CompactStatCard(
              title: 'Maintenance Due',
              value: '3 Tasks',
              icon: Icons.build,
              color: AppColors.warning,
            ),
            CompactStatCard(
              title: 'System Status',
              value: '95%',
              icon: Icons.speed,
              color: AppColors.primary,
              trend: '+2%',
              isPositive: true,
            ),
          ],
        );
      },
    );
  }

  Widget _buildAssetMonitoringGrid(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 800 ? 4 : 2;
        // Adjust aspect ratio for mobile to prevent overflow
        final childAspectRatio = isMobile ? 1.4 : 1.2;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: isMobile ? AppSpacing.sm : AppSpacing.md,
          mainAxisSpacing: isMobile ? AppSpacing.sm : AppSpacing.md,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildAssetCard(context, isDark, 'Pumps', Icons.water_drop, AppColors.info, '8 Active',
                '2 Need service', () {}, isMobile),
            _buildAssetCard(context, isDark, 'Fans', Icons.air, AppColors.primary, '12 Active',
                'All operational', () {}, isMobile),
            _buildAssetCard(
              context,
              isDark,
              'Sensors',
              Icons.sensors,
              AppColors.success,
              '10 Active',
              'Manage all sensors',
                () => Navigator.pushNamed(context, '/sensor-management'),
              isMobile,
            ),
            _buildAssetCard(context, isDark, 'Air Condition', Icons.ac_unit, AppColors.warning,
                '6 Active', '1 Maintenance', () {}, isMobile),
          ],
        );
      },
    );
  }

  Widget _buildAssetCard(BuildContext context, bool isDark, String title, IconData icon,
      Color color, String status, String subtitle, VoidCallback onTap, bool isMobile) {
    // Check if this card has an action (not empty callback)
    final hasAction = title == 'Sensors'; // Only Sensors card has navigation

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: EdgeInsets.all(isMobile ? AppSpacing.sm : AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: hasAction ? color.withOpacity(0.3) : (isDark ? Colors.white10 : Colors.black12),
            width: hasAction ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: EdgeInsets.all(isMobile ? AppSpacing.sm : AppSpacing.md),
                  decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
                  child: Icon(icon, size: isMobile ? 28 : 32, color: color),
                ),
                if (hasAction)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: isMobile ? 6 : AppSpacing.sm),
            Flexible(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontSize: isMobile ? 13 : 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: isMobile ? 3 : 4),
            Flexible(
              child: Text(
                status,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: color,
                  fontSize: isMobile ? 11 : 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: isMobile ? 2 : 2),
            Flexible(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? Colors.white60 : AppColors.textSecondary,
                        fontSize: isMobile ? 9 : 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (hasAction) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      size: isMobile ? 12 : 14,
                      color: color,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesGrid(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 800 ? 4 : 2;
        // Adjust aspect ratio for mobile to prevent overflow
        final childAspectRatio = isMobile ? 1.4 : 1.2;

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
              'Report Issue',
              Icons.report_problem,
              AppColors.error,
              '5 open issues',
               () => Navigator.pushNamed(context, '/maintenance-schedule'),
              isMobile,
            ),
            _buildFeatureCard(
              context,
              isDark,
              'View Solutions',
              Icons.lightbulb_outline,
              AppColors.warning,
              'Knowledge base',
               () => Navigator.pushNamed(context, '/maintenance-schedule'),
              isMobile,
            ),
            _buildFeatureCard(
              context,
              isDark,
              'Schedule Maintenance',
              Icons.event,
              AppColors.info,
              '3 tasks due',
               () => Navigator.pushNamed(context, '/maintenance-schedule'),
              isMobile,
            ),
            _buildFeatureCard(
              context,
              isDark,
              'Request Items',
              Icons.shopping_cart,
              AppColors.primary,
              'Order supplies',
               () => Navigator.pushNamed(context, '/maintenance-schedule'),
              isMobile,
            ),
            _buildFeatureCard(
              context,
              isDark,
              'Asset Check',
              Icons.inventory,
              AppColors.success,
              'Verify equipment',
              () {},
              isMobile,
            ),
            _buildFeatureCard(
              context,
              isDark,
              'System Status',
              Icons.monitor_heart,
              AppColors.info,
              '95% operational',
              () {},
              isMobile,
            ),
            _buildFeatureCard(
              context,
              isDark,
              'Repair History',
              Icons.history,
              AppColors.warning,
              'View past fixes',
              () => Navigator.pushNamed(context, '/repair-history'),
              isMobile,
            ),
            _buildFeatureCard(
              context,
              isDark,
              'Settings',
              Icons.settings_outlined,
              AppColors.textSecondary,
              'Preferences',
              () => Navigator.pushNamed(context, '/technician-settings'),
              isMobile,
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
    bool isMobile,
  ) {
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
                size: isMobile ? 28 : 32,
                color: color,
              ),
            ),
            SizedBox(height: isMobile ? 6 : AppSpacing.sm),
            Flexible(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontSize: isMobile ? 13 : 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: isMobile ? 3 : 4),
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
