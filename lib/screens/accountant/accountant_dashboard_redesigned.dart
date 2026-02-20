import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/accountant_sidebar.dart';
import '../../core/widgets/accountant_header.dart';
import '../../core/widgets/modern_dashboard_scaffold.dart';
import '../../core/widgets/weather_time_widget.dart';
import '../../core/widgets/weather_info_chip.dart';
import '../../providers/auth_provider.dart';

/// Accountant Dashboard - Redesigned
class AccountantDashboardRedesigned extends ConsumerStatefulWidget {
  const AccountantDashboardRedesigned({super.key});

  @override
  ConsumerState<AccountantDashboardRedesigned> createState() =>
      _AccountantDashboardRedesignedState();
}

class _AccountantDashboardRedesignedState extends ConsumerState<AccountantDashboardRedesigned> {
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
    final userName = authState.user?.name ?? 'Accountant';
    final userEmail = authState.user?.email ?? 'accountant@farmestates.com';
    final userRole = 'Accountant';

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
              label: const Text('New Transaction'),
            )
          : null,
      bottomNavigationBar: isMobile ? _buildBottomNavigation(isDark) : null,
    );
  }

  Widget _buildDesktopLayout(bool isDark, String userName, String userEmail, String userRole) {
    return Row(
      children: [
        // Sidebar
        AccountantSidebar(
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
              AccountantHeader(
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
                        'Financial Management',
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
        AccountantHeader(
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
                  'Financial Management',
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
          title: 'Pending',
          value: '7 Trans',
          icon: Icons.pending,
          color: AppColors.warning,
        ),
        CompactStatCard(
          title: 'Revenue',
          value: '\$125.4K',
          icon: Icons.trending_up,
          color: AppColors.success,
          trend: '+18%',
          isPositive: true,
        ),
        CompactStatCard(
          title: 'Expenses',
          value: '\$42.8K',
          icon: Icons.trending_down,
          color: AppColors.error,
          trend: '+5%',
          isPositive: false,
        ),
        CompactStatCard(
          title: 'Profit',
          value: '\$82.6K',
          icon: Icons.attach_money,
          color: AppColors.primary,
          trend: '+23%',
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
      crossAxisCount: isMobile ? 2 : (screenWidth > 800 ? 4 : 2),
      childAspectRatio: isMobile ? 1.1 : 1.2,
      crossAxisSpacing: isMobile ? AppSpacing.xs : AppSpacing.md,
      mainAxisSpacing: isMobile ? AppSpacing.xs : AppSpacing.md,
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
  }

  Widget _buildBottomNavigation(bool isDark) {
    final navItems = [
      {
        'icon': Icons.dashboard_outlined,
        'label': 'Dashboard',
        'index': 0,
        'route': '/accountant-dashboard'
      },
      {
        'icon': Icons.receipt_long_outlined,
        'label': 'Transactions',
        'index': 1,
        'route': '/transactions'
      },
      {
        'icon': Icons.account_balance_outlined,
        'label': 'Reconcile',
        'index': 2,
        'route': '/reconciliation'
      },
      {
        'icon': Icons.assessment_outlined,
        'label': 'Reports',
        'index': 3,
        'route': '/reports'
      },
      {
        'icon': Icons.approval_outlined,
        'label': 'Approvals',
        'index': 4,
        'route': '/approvals'
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

  Widget _buildCard(BuildContext context, bool isDark, String title, IconData icon, Color color,
      String subtitle, VoidCallback onTap) {
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
