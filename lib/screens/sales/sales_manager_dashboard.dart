import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Sales Manager Dashboard - Limited to specified features only
/// Features: Batch Confirmation, Off-Taker Management, Delivery Confirmation,
/// Financial Monitoring, Sales Performance, Reports, Commission Tracking
class SalesManagerDashboard extends ConsumerStatefulWidget {
  const SalesManagerDashboard({super.key});

  @override
  ConsumerState<SalesManagerDashboard> createState() =>
      _SalesManagerDashboardState();
}

class _SalesManagerDashboardState extends ConsumerState<SalesManagerDashboard> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Sales Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
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

              // Revenue Overview
              _buildRevenueOverview(isDark),
              const SizedBox(height: AppSpacing.xl),

              // Main Features
              Text(
                'Sales Operations',
                style: AppTypography.h5.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _buildFeaturesGrid(isDark),

              const SizedBox(height: AppSpacing.xl),

              // Sales Performance
              _buildSalesPerformance(isDark),

              const SizedBox(height: AppSpacing.xl),

              // Recent Transactions
              _buildRecentTransactions(isDark),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/sales/add-offtaker');
        },
        backgroundColor: Colors.green[700],
        icon: const Icon(Icons.person_add),
        label: const Text('Add Off-Taker'),
      ),
    );
  }

  Widget _buildWelcomeSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green[700]!,
            Colors.green[700]!.withOpacity(0.7),
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
                  'Sales Department',
                  style: AppTypography.h5.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Sales Manager',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '12 Active Off-Takers â€¢ 5 Sales Personnel',
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
              Icons.point_of_sale,
              size: 40,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueOverview(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: Colors.green[700]!.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attach_money, color: Colors.green[700], size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Revenue Overview',
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
                child: _buildRevenueItem(
                    'Total Sales', '\$125,400', AppColors.success, isDark),
              ),
              Expanded(
                child: _buildRevenueItem(
                    'Paid', '\$98,200', AppColors.info, isDark),
              ),
              Expanded(
                child: _buildRevenueItem(
                    'Unpaid', '\$27,200', AppColors.warning, isDark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueItem(
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
        ),
      ],
    );
  }

  Widget _buildFeaturesGrid(bool isDark) {
    final features = [
      _FeatureItem(
        title: 'Batch Confirmation',
        subtitle: 'From fulfillment',
        icon: Icons.qr_code,
        color: Colors.green[700]!,
        route: '/sales/batches',
      ),
      _FeatureItem(
        title: 'Off-Taker Management',
        subtitle: 'Manage buyers',
        icon: Icons.business,
        color: AppColors.info,
        route: '/sales/offtakers',
        badge: '12',
      ),
      _FeatureItem(
        title: 'Delivery Confirmation',
        subtitle: 'From sales personnel',
        icon: Icons.local_shipping,
        color: AppColors.warning,
        route: '/sales/deliveries',
      ),
      _FeatureItem(
        title: 'Financial Monitoring',
        subtitle: 'Paid/Unpaid tracking',
        icon: Icons.account_balance,
        color: Colors.purple,
        route: '/sales/financials',
      ),
      _FeatureItem(
        title: 'Sales Performance',
        subtitle: 'Personnel metrics',
        icon: Icons.trending_up,
        color: Colors.orange,
        route: '/sales/performance',
      ),
      _FeatureItem(
        title: 'Reports',
        subtitle: 'Sales reports',
        icon: Icons.assessment,
        color: Colors.indigo,
        route: '/sales/reports',
      ),
      _FeatureItem(
        title: 'Commission Tracking',
        subtitle: 'Coming soon',
        icon: Icons.monetization_on,
        color: Colors.amber,
        route: '/sales/commission',
        badge: 'Soon',
      ),
      _FeatureItem(
        title: 'Payment Proof',
        subtitle: 'Upload receipts',
        icon: Icons.receipt_long,
        color: Colors.teal,
        route: '/sales/payment-proof',
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
                    color:
                        feature.badge == 'Soon' ? Colors.amber : AppColors.info,
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

  Widget _buildSalesPerformance(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sales Personnel Performance',
          style: AppTypography.h6.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildPerformanceItem(
          'John Doe',
          '15 sales',
          '\$45,200',
          '8 off-takers',
          AppColors.success,
          isDark,
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildPerformanceItem(
          'Jane Smith',
          '12 sales',
          '\$38,500',
          '6 off-takers',
          AppColors.info,
          isDark,
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildPerformanceItem(
          'Mike Johnson',
          '10 sales',
          '\$32,100',
          '5 off-takers',
          AppColors.warning,
          isDark,
        ),
      ],
    );
  }

  Widget _buildPerformanceItem(
    String name,
    String sales,
    String revenue,
    String offtakers,
    Color color,
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
            child: Icon(Icons.person, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildMetric(sales, Icons.shopping_cart, color),
                    const SizedBox(width: AppSpacing.md),
                    _buildMetric(revenue, Icons.attach_money, color),
                    const SizedBox(width: AppSpacing.md),
                    _buildMetric(offtakers, Icons.business, color),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: AppTypography.bodySmall.copyWith(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
          'FA-20251001',
          'ABC Company - 250 kg',
          'Paid',
          '\$12,500',
          AppColors.success,
          '2 hours ago',
          isDark,
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildTransactionItem(
          'FB-20251002',
          'XYZ Corp - 180 kg',
          'Unpaid',
          '\$9,200',
          AppColors.warning,
          '5 hours ago',
          isDark,
        ),
      ],
    );
  }

  Widget _buildTransactionItem(
    String batchNumber,
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
            child: Icon(Icons.receipt, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  batchNumber,
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
