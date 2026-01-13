import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/farm_owner_sidebar.dart';
import '../../core/widgets/farm_owner_header.dart';
import '../../providers/auth_provider.dart';

/// Reports Screen for Farm Owner
/// View and download financial and performance reports
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int _selectedNavIndex = 4;
  String _selectedReportType = 'All';
  String _selectedPeriod = 'Last 30 Days';

  final List<Map<String, dynamic>> _reports = [
    {
      'id': 'RPT001',
      'title': 'Monthly Financial Report',
      'type': 'Financial',
      'period': 'January 2024',
      'date': '2024-01-31',
      'size': '2.5 MB',
      'icon': Icons.description,
      'color': AppColors.primary,
    },
    {
      'id': 'RPT002',
      'title': 'Farm Performance Summary',
      'type': 'Performance',
      'period': 'Q4 2023',
      'date': '2024-01-15',
      'size': '1.8 MB',
      'icon': Icons.analytics,
      'color': AppColors.success,
    },
    {
      'id': 'RPT003',
      'title': 'Revenue Analysis',
      'type': 'Financial',
      'period': '2023',
      'date': '2024-01-01',
      'size': '3.2 MB',
      'icon': Icons.trending_up,
      'color': AppColors.info,
    },
    {
      'id': 'RPT004',
      'title': 'Yield Report',
      'type': 'Performance',
      'period': 'December 2023',
      'date': '2023-12-31',
      'size': '1.5 MB',
      'icon': Icons.inventory,
      'color': AppColors.warning,
    },
  ];

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
                      _buildReportTypes(isDark),
                      const SizedBox(height: AppSpacing.lg),
                      _buildReportsList(isDark),
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
                _buildReportTypes(isDark),
                const SizedBox(height: AppSpacing.md),
                _buildReportsList(isDark),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reports',
            style: AppTypography.h4.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: isDark ? Colors.white.withOpacity(0.1) : AppColors.neutral200,
                    ),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedPeriod,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: ['Last 7 Days', 'Last 30 Days', 'Last 3 Months', 'Last Year'].map((period) {
                      return DropdownMenuItem(
                        value: period,
                        child: Text(
                          period,
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedPeriod = value!);
                    },
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.sm,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Icon(Icons.download, size: 20),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Reports',
          style: AppTypography.h4.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          children: [
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
            const SizedBox(width: AppSpacing.sm),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download),
              label: const Text('Generate Report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReportTypes(bool isDark) {
    final types = ['All', 'Financial', 'Performance', 'Yield', 'Revenue'];
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: types.map((type) {
          final isSelected = type == _selectedReportType;
          return Padding(
            padding: EdgeInsets.only(right: isMobile ? AppSpacing.xs : AppSpacing.sm),
            child: FilterChip(
              label: Text(
                type,
                style: TextStyle(
                  fontSize: isMobile ? 11 : 12,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedReportType = type);
              },
              selectedColor: AppColors.primary.withOpacity(0.2),
              checkmarkColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : (isDark ? Colors.white : AppColors.textPrimary),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: isMobile ? 11 : 12,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? AppSpacing.xs : AppSpacing.sm,
                vertical: isMobile ? 4 : 8,
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReportsList(bool isDark) {
    final filteredReports = _selectedReportType == 'All'
        ? _reports
        : _reports.where((report) => report['type'] == _selectedReportType).toList();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Reports',
          style: AppTypography.h5.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 16 : 18,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ...filteredReports.map((report) {
          return _buildReportCard(report, isDark);
        }),
      ],
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report, bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: EdgeInsets.all(isMobile ? AppSpacing.sm : AppSpacing.md),
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
            padding: EdgeInsets.all(isMobile ? 8 : 12),
            decoration: BoxDecoration(
              color: (report['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(
              report['icon'] as IconData,
              color: report['color'] as Color,
              size: isMobile ? 20 : 24,
            ),
          ),
          SizedBox(width: isMobile ? AppSpacing.sm : AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  report['title'] as String,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontSize: isMobile ? 13 : 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isMobile ? 3 : 4),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 4 : 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: (report['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Text(
                        report['type'] as String,
                        style: AppTypography.caption.copyWith(
                          color: report['color'] as Color,
                          fontSize: isMobile ? 9 : 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${report['period']} • ${report['size']}',
                      style: AppTypography.caption.copyWith(
                        color: isDark ? Colors.white.withOpacity(0.6) : AppColors.textSecondary,
                        fontSize: isMobile ? 9 : 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: isMobile ? AppSpacing.xs : AppSpacing.sm),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.download,
                  size: isMobile ? 20 : 24,
                ),
                color: AppColors.primary,
                tooltip: 'Download',
                padding: EdgeInsets.all(isMobile ? 4 : 8),
                constraints: BoxConstraints(
                  minWidth: isMobile ? 32 : 48,
                  minHeight: isMobile ? 32 : 48,
                ),
              ),
              if (!isMobile)
                Text(
                  report['date'] as String,
                  style: AppTypography.caption.copyWith(
                    color: isDark ? Colors.white.withOpacity(0.5) : AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ],
      ),
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
