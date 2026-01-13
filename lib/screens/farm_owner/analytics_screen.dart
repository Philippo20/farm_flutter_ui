import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/farm_owner_sidebar.dart';
import '../../core/widgets/farm_owner_header.dart';
import '../../providers/auth_provider.dart';

/// Analytics Screen for Farm Owner
/// View farm performance analytics and insights
class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  int _selectedNavIndex = 2;
  String _selectedPeriod = 'Last 30 Days';

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
      bottomNavigationBar: isMobile ? _buildBottomNavigation(isDark) : null,
    );
  }

  Widget _buildDesktopLayout(bool isDark, String userName, String userEmail, String userRole) {
    return Row(
      children: [
        FarmOwnerSidebar(
          selectedIndex: _selectedNavIndex,
          onItemSelected: (index) {
            setState(() => _selectedNavIndex = index);
          },
          userName: userName,
          userEmail: userEmail,
          userRole: userRole,
        ),
        Expanded(
          child: Column(
            children: [
              FarmOwnerHeader(
                userName: userName,
                onNotificationTap: () {},
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(isDark),
                      const SizedBox(height: AppSpacing.lg),
                      _buildPerformanceCards(isDark),
                      const SizedBox(height: AppSpacing.lg),
                      _buildChartsSection(isDark),
                      const SizedBox(height: AppSpacing.lg),
                      _buildFarmComparison(isDark),
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
        FarmOwnerHeader(
          userName: userName,
          onNotificationTap: () {},
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(isDark),
                const SizedBox(height: AppSpacing.md),
                _buildPerformanceCards(isDark),
                const SizedBox(height: AppSpacing.md),
                _buildChartsSection(isDark),
                const SizedBox(height: AppSpacing.md),
                _buildFarmComparison(isDark),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Farm Analytics',
          style: AppTypography.h4.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        DropdownButton<String>(
          value: _selectedPeriod,
          items: ['Last 7 Days', 'Last 30 Days', 'Last 3 Months', 'Last Year'].map((period) {
            return DropdownMenuItem(
              value: period,
              child: Text(period),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedPeriod = value!);
          },
        ),
      ],
    );
  }

  Widget _buildPerformanceCards(bool isDark) {
    final metrics = [
      {
        'title': 'Total Revenue',
        'value': '\$105,000',
        'change': '+23%',
        'isPositive': true,
        'icon': Icons.trending_up,
        'color': AppColors.success,
      },
      {
        'title': 'Total Yield',
        'value': '850 kg',
        'change': '+15%',
        'isPositive': true,
        'icon': Icons.inventory,
        'color': AppColors.info,
      },
      {
        'title': 'Active Farms',
        'value': '5',
        'change': '+2',
        'isPositive': true,
        'icon': Icons.agriculture,
        'color': AppColors.primary,
      },
      {
        'title': 'Avg. Yield/Farm',
        'value': '170 kg',
        'change': '+8%',
        'isPositive': true,
        'icon': Icons.analytics,
        'color': AppColors.warning,
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final crossAxisCount = isMobile ? 2 : 4;
        final childAspectRatio = isMobile ? 1.3 : 1.8;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          children: metrics.map((metric) {
            return Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.1) : AppColors.neutral200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (metric['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Icon(
                          metric['icon'] as IconData,
                          color: metric['color'] as Color,
                          size: 20,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (metric['isPositive'] as bool)
                              ? AppColors.success.withOpacity(0.1)
                              : AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              (metric['isPositive'] as bool) ? Icons.trending_up : Icons.trending_down,
                              size: 12,
                              color: (metric['isPositive'] as bool) ? AppColors.success : AppColors.error,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              metric['change'] as String,
                              style: AppTypography.caption.copyWith(
                                color: (metric['isPositive'] as bool) ? AppColors.success : AppColors.error,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    metric['value'] as String,
                    style: AppTypography.h5.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    metric['title'] as String,
                    style: AppTypography.caption.copyWith(
                      color: isDark ? Colors.white.withOpacity(0.6) : AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildChartsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Revenue Trend',
          style: AppTypography.h5.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          height: 200,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.1) : AppColors.neutral200,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.show_chart,
                  size: 48,
                  color: isDark ? Colors.white.withOpacity(0.3) : AppColors.textSecondary,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Chart visualization will be displayed here',
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? Colors.white.withOpacity(0.5) : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFarmComparison(bool isDark) {
    final farms = [
      {'name': 'Green Valley Farm', 'revenue': 35000, 'yield': 280, 'color': AppColors.primary},
      {'name': 'Sunny Acres', 'revenue': 30000, 'yield': 250, 'color': AppColors.success},
      {'name': 'Fresh Farms', 'revenue': 25000, 'yield': 200, 'color': AppColors.info},
      {'name': 'Golden Fields', 'revenue': 15000, 'yield': 120, 'color': AppColors.warning},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Farm Performance Comparison',
          style: AppTypography.h5.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ...farms.map((farm) {
          return Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.1) : AppColors.neutral200,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: farm['color'] as Color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        farm['name'] as String,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Revenue: \$${farm['revenue']}',
                            style: AppTypography.caption.copyWith(
                              color: isDark ? Colors.white.withOpacity(0.6) : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Text(
                            'Yield: ${farm['yield']} kg',
                            style: AppTypography.caption.copyWith(
                              color: isDark ? Colors.white.withOpacity(0.6) : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
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
}
