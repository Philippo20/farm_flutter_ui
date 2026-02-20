import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/sales_personnel_sidebar.dart';
import '../../core/widgets/sales_personnel_header.dart';
import '../../core/widgets/modern_dashboard_scaffold.dart';
import '../../core/widgets/weather_time_widget.dart';
import '../../core/widgets/weather_info_chip.dart';
import '../../providers/auth_provider.dart';

/// Sales Personnel Dashboard - Redesigned
class SalesPersonnelDashboardRedesigned extends ConsumerStatefulWidget {
  const SalesPersonnelDashboardRedesigned({super.key});

  @override
  ConsumerState<SalesPersonnelDashboardRedesigned> createState() =>
      _SalesPersonnelDashboardRedesignedState();
}

class _SalesPersonnelDashboardRedesignedState
    extends ConsumerState<SalesPersonnelDashboardRedesigned> {
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'Sales Personnel';
    final userEmail = authState.user?.email ?? 'salesperson@farmestates.com';
    final userRole = 'Sales Personnel';

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: isMobile
          ? _buildMobileLayout(isDark, userName)
          : _buildDesktopLayout(isDark, userName, userEmail, userRole),
      floatingActionButton: !isMobile
          ? FloatingActionButton.extended(
              onPressed: () {},
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add),
              label: const Text('Record Delivery'),
            )
          : null,
      bottomNavigationBar: isMobile ? _buildBottomNavigation(isDark) : null,
    );
  }

  Widget _buildDesktopLayout(bool isDark, String userName, String userEmail, String userRole) {
    return Row(
      children: [
        // Sidebar
        SalesPersonnelSidebar(
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
              SalesPersonnelHeader(
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
                      Text(
                        'Sales Activities',
                        style: AppTypography.h5.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
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
    );
  }

  Widget _buildMobileLayout(bool isDark, String userName) {
    return Column(
      children: [
        // Header
        SalesPersonnelHeader(
          userName: userName,
          weatherInfo: _weatherInfo,
          onNotificationTap: () {},
        ),

        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const WeatherTimeWidget(),
                const SizedBox(height: AppSpacing.md),
                _buildStatsSection(context),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Sales Activities',
                  style: AppTypography.h5.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _buildFeaturesGrid(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return GridView.count(
      crossAxisCount: isMobile ? 2 : (screenWidth > 800 ? 4 : 2),
      childAspectRatio: isMobile ? 2.5 : 3.2,
      crossAxisSpacing: isMobile ? AppSpacing.xs : AppSpacing.sm,
      mainAxisSpacing: isMobile ? AppSpacing.xs : AppSpacing.sm,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        CompactStatCard(
          title: 'Deliveries',
          value: '5 Today',
          icon: Icons.local_shipping,
          color: AppColors.primary,
          trend: '+2',
          isPositive: true,
        ),
        CompactStatCard(
          title: 'My Sales',
          value: '\$45.2K',
          icon: Icons.attach_money,
          color: AppColors.success,
          trend: '+12%',
          isPositive: true,
        ),
        CompactStatCard(
          title: 'Prospects',
          value: '8 Active',
          icon: Icons.people,
          color: AppColors.info,
        ),
        CompactStatCard(
          title: 'Conversion',
          value: '65%',
          icon: Icons.trending_up,
          color: AppColors.warning,
          trend: '+5%',
          isPositive: true,
        ),
      ],
    );
  }

  Widget _buildFeaturesGrid(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return GridView.count(
      crossAxisCount: isMobile ? 2 : (screenWidth > 800 ? 3 : 2),
      childAspectRatio: isMobile ? 1.1 : 1.2,
      crossAxisSpacing: isMobile ? AppSpacing.xs : AppSpacing.md,
      mainAxisSpacing: isMobile ? AppSpacing.xs : AppSpacing.md,
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
  }

  Widget _buildBottomNavigation(bool isDark) {
    final navItems = [
      {
        'icon': Icons.dashboard_outlined,
        'label': 'Dashboard',
        'index': 0,
        'route': '/sales-personnel-dashboard'
      },
      {
        'icon': Icons.local_shipping_outlined,
        'label': 'Delivery',
        'index': 1,
        'route': '/record-delivery'
      },
      {
        'icon': Icons.timeline_outlined,
        'label': 'Pipeline',
        'index': 2,
        'route': '/pipeline'
      },
      {
        'icon': Icons.attach_money_outlined,
        'label': 'Sales',
        'index': 3,
        'route': '/my-sales'
      },
      {
        'icon': Icons.assessment_outlined,
        'label': 'Reports',
        'index': 4,
        'route': '/sales-personnel/reports'
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
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedNavIndex = index;
                    });
                    Navigator.of(context).pushNamed(route);
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item['icon'] as IconData,
                        size: 24,
                        color: isSelected
                            ? AppColors.primary
                            : (isDark ? Colors.white.withOpacity(0.6) : AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['label'] as String,
                        style: AppTypography.caption.copyWith(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? Colors.white.withOpacity(0.6) : AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, bool isDark, String title, IconData icon, Color color, String subtitle, VoidCallback onTap) {
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
            const SizedBox(height: 4),
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
