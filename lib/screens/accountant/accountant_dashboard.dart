import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Accountant Dashboard - Limited to specified features only
/// Features: Transaction Confirmation, View All Transactions, Financial Reports,
/// Auto-Reconciliation, Multi-Filter Reporting, Expense Management, Fund Approval
class AccountantDashboard extends ConsumerStatefulWidget {
  const AccountantDashboard({super.key});

  @override
  ConsumerState<AccountantDashboard> createState() =>
      _AccountantDashboardState();
}

class _AccountantDashboardState extends ConsumerState<AccountantDashboard> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Accountant'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {},
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '7',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              _buildWelcomeSection(isDark),
              const SizedBox(height: AppSpacing.xl),

              // Financial Overview
              _buildFinancialOverview(isDark),
              const SizedBox(height: AppSpacing.xl),

              // Main Features
              Text(
                'Financial Operations',
                style: AppTypography.h5.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _buildFeaturesGrid(isDark),

              const SizedBox(height: AppSpacing.xl),

              // Pending Confirmations
              _buildPendingConfirmations(isDark),

              const SizedBox(height: AppSpacing.xl),

              // Recent Transactions
              _buildRecentTransactions(isDark),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/accountant/reconcile');
        },
        backgroundColor: Colors.deepOrange,
        icon: const Icon(Icons.check_circle),
        label: const Text('Reconcile'),
      ),
    );
  }

  Widget _buildWelcomeSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepOrange,
            Colors.deepOrange.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Finance Department',
                  style: AppTypography.h5.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Accountant',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '7 Pending Confirmations â€¢ \$125,400 This Month',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance,
              size: 40,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialOverview(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: Colors.deepOrange.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet,
                  color: Colors.deepOrange, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Financial Overview',
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildOverviewItem(
                    'Total Revenue', '\$125,400', AppColors.success, isDark),
              ),
              Expanded(
                child: _buildOverviewItem(
                    'Expenses', '\$42,800', AppColors.error, isDark),
              ),
              Expanded(
                child: _buildOverviewItem(
                    'Net Profit', '\$82,600', AppColors.info, isDark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewItem(
      String label, String value, Color color, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.h5.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: isDark ? Colors.white70 : AppColors.textSecondary,
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFeaturesGrid(bool isDark) {
    final features = [
      _FeatureItem(
        title: 'Confirm Transactions',
        subtitle: 'From sales personnel',
        icon: Icons.verified,
        color: Colors.deepOrange,
        route: '/accountant/confirm',
        badge: '7',
      ),
      _FeatureItem(
        title: 'All Transactions',
        subtitle: 'Complete history',
        icon: Icons.receipt_long,
        color: AppColors.info,
        route: '/accountant/transactions',
      ),
      _FeatureItem(
        title: 'Financial Reports',
        subtitle: 'Generate reports',
        icon: Icons.assessment,
        color: Colors.purple,
        route: '/accountant/reports',
      ),
      _FeatureItem(
        title: 'Auto-Reconciliation',
        subtitle: 'Match transactions',
        icon: Icons.sync_alt,
        color: AppColors.success,
        route: '/accountant/reconcile',
      ),
      _FeatureItem(
        title: 'Multi-Filter Reports',
        subtitle: 'Custom filters',
        icon: Icons.filter_alt,
        color: Colors.indigo,
        route: '/accountant/filters',
      ),
      _FeatureItem(
        title: 'Expense Management',
        subtitle: 'Track expenses',
        icon: Icons.money_off,
        color: AppColors.error,
        route: '/accountant/expenses',
      ),
      _FeatureItem(
        title: 'Fund Approvals',
        subtitle: 'Approve requests',
        icon: Icons.approval,
        color: Colors.amber,
        route: '/accountant/approvals',
        badge: '3',
      ),
      _FeatureItem(
        title: 'Export Data',
        subtitle: 'PDF & Excel',
        icon: Icons.download,
        color: Colors.teal,
        route: '/accountant/export',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.1,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        return _buildFeatureCard(feature, isDark);
      },
    );
  }

  Widget _buildFeatureCard(_FeatureItem feature, bool isDark) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, feature.route),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: feature.color.withOpacity(0.3),
          ),
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(feature.icon, size: 32, color: feature.color),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  feature.title,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  feature.subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            if (feature.badge != null)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    feature.badge!,
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingConfirmations(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pending Confirmations',
              style: AppTypography.h6.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text(
                '7',
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _buildConfirmationItem(
          'Payment from ABC Company',
          'FA-20251001 - \$12,500',
          'Awaiting confirmation',
          Icons.payment,
          AppColors.warning,
          '2 hours ago',
          isDark,
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildConfirmationItem(
          'Fund Request - Farm Manager',
          'Budget approval - \$5,000',
          'Awaiting approval',
          Icons.approval,
          AppColors.info,
          '5 hours ago',
          isDark,
        ),
      ],
    );
  }

  Widget _buildConfirmationItem(
    String title,
    String subtitle,
    String status,
    IconData icon,
    Color color,
    String time,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Text(
                        status,
                        style: AppTypography.bodySmall.copyWith(
                          color: color,
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      time,
                      style: AppTypography.bodySmall.copyWith(
                        color:
                            isDark ? Colors.white38 : AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: isDark ? Colors.white38 : AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: AppTypography.h6.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _buildTransactionItem(
          'Payment Received',
          'ABC Company - FA-20251001',
          'Confirmed',
          '\$12,500',
          AppColors.success,
          '1 hour ago',
          isDark,
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildTransactionItem(
          'Expense',
          'Seeds & Nutrients - Farm A',
          'Confirmed',
          '-\$3,200',
          AppColors.error,
          '3 hours ago',
          isDark,
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildTransactionItem(
          'Payment Received',
          'XYZ Corp - FB-20251002',
          'Confirmed',
          '\$9,200',
          AppColors.success,
          '5 hours ago',
          isDark,
        ),
      ],
    );
  }

  Widget _buildTransactionItem(
    String title,
    String details,
    String status,
    String amount,
    Color color,
    String time,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              amount.startsWith('-')
                  ? Icons.arrow_upward
                  : Icons.arrow_downward,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  details,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Text(
                        status,
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      time,
                      style: AppTypography.bodySmall.copyWith(
                        color:
                            isDark ? Colors.white38 : AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;
  final String? badge;

  _FeatureItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
    this.badge,
  });
}
