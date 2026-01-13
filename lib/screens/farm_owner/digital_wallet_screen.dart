import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/farm_owner_sidebar.dart';
import '../../core/widgets/farm_owner_header.dart';
import '../../providers/auth_provider.dart';

/// Digital Wallet Screen for Farm Owner
/// View wallet balance, transactions, and financial overview
class DigitalWalletScreen extends ConsumerStatefulWidget {
  const DigitalWalletScreen({super.key});

  @override
  ConsumerState<DigitalWalletScreen> createState() => _DigitalWalletScreenState();
}

class _DigitalWalletScreenState extends ConsumerState<DigitalWalletScreen> {
  int _selectedNavIndex = 1;
  String _selectedFilter = 'All';

  final List<Map<String, dynamic>> _transactions = [
    {
      'id': 'TXN001',
      'type': 'Credit',
      'amount': 50000,
      'description': 'Harvest Payment - Green Valley Farm',
      'date': '2024-01-15',
      'status': 'Completed',
      'icon': Icons.arrow_downward,
      'color': AppColors.success,
    },
    {
      'id': 'TXN002',
      'type': 'Debit',
      'amount': 15000,
      'description': 'Withdrawal to Bank Account',
      'date': '2024-01-12',
      'status': 'Completed',
      'icon': Icons.arrow_upward,
      'color': AppColors.error,
    },
    {
      'id': 'TXN003',
      'type': 'Credit',
      'amount': 30000,
      'description': 'Harvest Payment - Sunny Acres',
      'date': '2024-01-10',
      'status': 'Completed',
      'icon': Icons.arrow_downward,
      'color': AppColors.success,
    },
    {
      'id': 'TXN004',
      'type': 'Credit',
      'amount': 25000,
      'description': 'Harvest Payment - Fresh Farms',
      'date': '2024-01-08',
      'status': 'Completed',
      'icon': Icons.arrow_downward,
      'color': AppColors.success,
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
                      _buildWalletBalanceCard(isDark),
                      const SizedBox(height: AppSpacing.lg),
                      _buildStatsCards(isDark),
                      const SizedBox(height: AppSpacing.lg),
                      _buildTransactionsSection(isDark),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: _buildWalletBalanceCard(isDark),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: _buildStatsCards(isDark),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: _buildTransactionsSection(isDark),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWalletBalanceCard(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        
        return Container(
          width: isMobile ? double.infinity : null,
          constraints: isMobile ? null : const BoxConstraints(maxWidth: 500),
          padding: EdgeInsets.all(isMobile ? AppSpacing.lg : AppSpacing.xl),
          margin: EdgeInsets.only(bottom: isMobile ? AppSpacing.md : 0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primaryDark,
              ],
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      'Wallet Balance',
                      style: AppTypography.bodyLarge.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: isMobile ? 14 : 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white.withOpacity(0.9),
                    size: isMobile ? 24 : 28,
                  ),
                ],
              ),
              SizedBox(height: isMobile ? AppSpacing.sm : AppSpacing.md),
              Text(
                '\$48,500.00',
                style: AppTypography.h3.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 28 : 36,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: isMobile ? AppSpacing.xs : AppSpacing.sm),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.trending_up,
                    color: Colors.white.withOpacity(0.8),
                    size: isMobile ? 14 : 16,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      '+23% from last month',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: isMobile ? 11 : 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsCards(bool isDark) {
    final stats = [
      {
        'title': 'Total Income',
        'value': '\$105,000',
        'icon': Icons.arrow_downward,
        'color': AppColors.success,
      },
      {
        'title': 'Total Withdrawals',
        'value': '\$56,500',
        'icon': Icons.arrow_upward,
        'color': AppColors.error,
      },
      {
        'title': 'Pending',
        'value': '\$12,000',
        'icon': Icons.pending,
        'color': AppColors.warning,
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final crossAxisCount = isMobile ? 1 : 3;
        final childAspectRatio = isMobile ? 3.2 : 2.5;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: isMobile ? AppSpacing.sm : AppSpacing.md,
          mainAxisSpacing: isMobile ? AppSpacing.sm : AppSpacing.md,
          children: stats.map((stat) {
            return Container(
              padding: EdgeInsets.all(isMobile ? AppSpacing.sm : AppSpacing.md),
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(isMobile ? 8 : 8),
                        decoration: BoxDecoration(
                          color: (stat['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Icon(
                          stat['icon'] as IconData,
                          color: stat['color'] as Color,
                          size: isMobile ? 20 : 20,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isMobile ? AppSpacing.sm : AppSpacing.sm),
                  Text(
                    stat['value'] as String,
                    style: AppTypography.h5.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      fontSize: isMobile ? 22 : 24,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isMobile ? 6 : 4),
                  Text(
                    stat['title'] as String,
                    style: AppTypography.caption.copyWith(
                      color: isDark ? Colors.white.withOpacity(0.6) : AppColors.textSecondary,
                      fontSize: isMobile ? 12 : 12,
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

  Widget _buildTransactionsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: AppTypography.h5.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            DropdownButton<String>(
              value: _selectedFilter,
              items: ['All', 'Credit', 'Debit'].map((filter) {
                return DropdownMenuItem(
                  value: filter,
                  child: Text(filter),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedFilter = value!);
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ..._transactions.map((transaction) {
          return _buildTransactionCard(transaction, isDark);
        }),
      ],
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction, bool isDark) {
    final isCredit = transaction['type'] == 'Credit';
    final amount = transaction['amount'] as int;
    final color = transaction['color'] as Color;

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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(
              transaction['icon'] as IconData,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction['description'] as String,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      transaction['date'] as String,
                      style: AppTypography.caption.copyWith(
                        color: isDark ? Colors.white.withOpacity(0.6) : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      child: Text(
                        transaction['status'] as String,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.success,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : '-'}\$${amount.toStringAsFixed(0)}',
            style: AppTypography.h6.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
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
