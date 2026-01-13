import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/farm_owner_sidebar.dart';
import '../../core/widgets/farm_owner_header.dart';
import '../../core/widgets/modern_dashboard_scaffold.dart';
import '../../core/widgets/weather_time_widget.dart';
import '../../core/widgets/weather_info_chip.dart';
import '../../providers/auth_provider.dart';

/// Farm Owner Dashboard - Redesigned
/// Financial focus with digital wallet
class FarmOwnerDashboardRedesigned extends ConsumerStatefulWidget {
  const FarmOwnerDashboardRedesigned({super.key});

  @override
  ConsumerState<FarmOwnerDashboardRedesigned> createState() => _FarmOwnerDashboardRedesignedState();
}

class _FarmOwnerDashboardRedesignedState extends ConsumerState<FarmOwnerDashboardRedesigned> {
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
    final userName = authState.user?.name ?? 'Farm Owner';
    final userEmail = authState.user?.email ?? 'owner@farmestates.com';
    final userRole = 'Farm Owner';

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: isMobile
          ? _buildMobileLayout(isDark, userName)
          : _buildDesktopLayout(isDark, userName, userEmail, userRole),
      floatingActionButton: isMobile
          ? null
          : FloatingActionButton.extended(
              onPressed: () {},
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add),
              label: const Text('Withdraw Funds'),
            ),
      bottomNavigationBar: isMobile ? _buildBottomNavigation(isDark) : null,
    );
  }

  Widget _buildDesktopLayout(bool isDark, String userName, String userEmail, String userRole) {
    return Row(
      children: [
        // Sidebar
        FarmOwnerSidebar(
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
              FarmOwnerHeader(
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
                        'Financial Overview',
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
    );
  }

  Widget _buildMobileLayout(bool isDark, String userName) {
    return Column(
      children: [
        // Header
        FarmOwnerHeader(
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

                const SizedBox(height: AppSpacing.md),

                // Compact Stats Section
                _buildStatsSection(context),

                const SizedBox(height: AppSpacing.lg),

                // Section Title
                Text(
                  'Financial Overview',
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
    );
  }

  Widget _buildBottomNavigation(bool isDark) {
    final navItems = [
      {
        'icon': Icons.dashboard_outlined,
        'label': 'Dashboard',
        'index': 0,
        'route': '/farm-owner'
      },
      {
        'icon': Icons.account_balance_wallet_outlined,
        'label': 'Wallet',
        'index': 1,
        'route': '/farm-owner/digital-wallet'
      },
      {
        'icon': Icons.analytics_outlined,
        'label': 'Analytics',
        'index': 2,
        'route': '/farm-owner/analytics'
      },
      {
        'icon': Icons.money_outlined,
        'label': 'Withdraw',
        'index': 3,
        'route': '/farm-owner/withdraw-funds'
      },
      {
        'icon': Icons.assessment_outlined,
        'label': 'Reports',
        'index': 4,
        'route': '/farm-owner/reports'
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
              title: 'Wallet Balance',
              value: '\$48,500',
              icon: Icons.account_balance_wallet,
              color: AppColors.primary,
              trend: '+23%',
              isPositive: true,
              onTap: () {},
            ),
            CompactStatCard(
              title: 'Monthly Revenue',
              value: '\$12,300',
              icon: Icons.trending_up,
              color: AppColors.success,
              trend: '+15%',
              isPositive: true,
            ),
            CompactStatCard(
              title: 'Total Farms',
              value: '5 Farms',
              icon: Icons.agriculture,
              color: AppColors.info,
            ),
            CompactStatCard(
              title: 'Total Yield',
              value: '850 kg',
              icon: Icons.inventory,
              color: AppColors.warning,
              trend: '+8%',
              isPositive: true,
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
              'Digital Wallet',
              Icons.account_balance_wallet_outlined,
              AppColors.primary,
              '\$48,500 available',
              () {},
            ),
            _buildFeatureCard(
              context,
              isDark,
              'Withdraw Funds',
              Icons.money,
              AppColors.success,
              'Request withdrawal',
              () {},
            ),
            _buildFeatureCard(
              context,
              isDark,
              'Analytics',
              Icons.analytics,
              AppColors.info,
              'View performance',
              () {},
            ),
            _buildFeatureCard(
              context,
              isDark,
              'Financial Reports',
              Icons.assessment,
              AppColors.warning,
              'Download reports',
              () {},
            ),
            _buildFeatureCard(
              context,
              isDark,
              'Farm Performance',
              Icons.trending_up,
              AppColors.primary,
              '5 farms tracked',
              () {},
            ),
            _buildFeatureCard(
              context,
              isDark,
              'Settings',
              Icons.settings_outlined,
              AppColors.textSecondary,
              'Account settings',
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
