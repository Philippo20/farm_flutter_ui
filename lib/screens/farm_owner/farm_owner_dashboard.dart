import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/providers/enhanced_auth_provider.dart';
import '../../core/widgets/permission_gate.dart';
import '../../core/models/user/user_permissions.dart';

/// Farm Owner Dashboard
/// Monitor farm performance, financials, and withdraw funds
class FarmOwnerDashboard extends ConsumerStatefulWidget {
  const FarmOwnerDashboard({super.key});

  @override
  ConsumerState<FarmOwnerDashboard> createState() => _FarmOwnerDashboardState();
}

class _FarmOwnerDashboardState extends ConsumerState<FarmOwnerDashboard> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Farm Owner Dashboard',
          style: AppTypography.h5.copyWith(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            _buildWelcomeSection(user?.name ?? 'Farm Owner', isDark),
            const SizedBox(height: AppSpacing.xl),

            // Wallet Card
            PermissionGate(
              permission: Permission.viewWallet,
              child: Column(
                children: [
                  _buildWalletCard(isDark),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),

            // Farm Performance Stats
            _buildFarmStats(isDark),
            const SizedBox(height: AppSpacing.xl),

            // Financial Overview & Farm Activity
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildFinancialOverview(isDark)),
                const SizedBox(width: AppSpacing.lg),
                Expanded(child: _buildFarmActivity(isDark)),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Recent Transactions
            _buildRecentTransactions(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(String name, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.info.withOpacity(0.1),
            AppColors.info.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.info.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.business, size: 32, color: AppColors.info),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, $name!',
                  style: AppTypography.h5.copyWith(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Monitor your farm performance and manage finances',
                  style: AppTypography.bodyMedium.copyWith(
                    fontFamily: 'Roboto',
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available Balance',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$24,580.50',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 32),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _buildWalletStat('This Month', '+\$5,240', Icons.trending_up),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildWalletStat('Last Withdrawal', '\$2,000', Icons.arrow_downward),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          PermissionGate(
            permission: Permission.withdrawFunds,
            child: ElevatedButton.icon(
              onPressed: () => _showWithdrawalDialog(),
              icon: const Icon(Icons.account_balance),
              label: const Text('Withdraw Funds'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.success,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletStat(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmStats(bool isDark) {
    final stats = [
      {'title': 'My Farms', 'value': '2', 'icon': Icons.agriculture, 'color': AppColors.success},
      {'title': 'Active Batches', 'value': '8', 'icon': Icons.inventory_2, 'color': AppColors.primary},
      {'title': 'Total Revenue', 'value': '\$48.5K', 'icon': Icons.attach_money, 'color': AppColors.warning},
      {'title': 'Profit Margin', 'value': '32%', 'icon': Icons.trending_up, 'color': AppColors.info},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 2.2,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(stat['icon'] as IconData, color: stat['color'] as Color, size: 20),
                  const Spacer(),
                  Text(
                    stat['value'] as String,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                stat['title'] as String,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 11,
                  color: isDark ? Colors.white60 : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFinancialOverview(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Financial Overview',
            style: AppTypography.h6.copyWith(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildFinancialItem('Total Income', '\$52,400', AppColors.success, isDark),
          _buildFinancialItem('Operating Costs', '\$18,200', AppColors.error, isDark),
          _buildFinancialItem('Net Profit', '\$34,200', AppColors.info, isDark),
          const Divider(height: AppSpacing.lg),
          _buildFinancialItem('Pending Payments', '\$3,500', AppColors.warning, isDark),
        ],
      ),
    );
  }

  Widget _buildFinancialItem(String label, String amount, Color color, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 13,
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmActivity(bool isDark) {
    final activities = [
      {'farm': 'Green Valley', 'batch': 'LE-20241101', 'status': 'Growing', 'progress': 0.65},
      {'farm': 'Sunny Acres', 'batch': 'TO-20241015', 'status': 'Flowering', 'progress': 0.45},
      {'farm': 'Green Valley', 'batch': 'BA-20241110', 'status': 'Transplanted', 'progress': 0.25},
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Farm Activity',
            style: AppTypography.h6.copyWith(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...activities.map((activity) => Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      activity['farm'] as String,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      child: Text(
                        activity['status'] as String,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 9,
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Batch: ${activity['batch']}',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 10,
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: activity['progress'] as double,
                  backgroundColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(bool isDark) {
    final transactions = [
      {'type': 'Income', 'description': 'Batch LE-20241015 delivered', 'amount': '+\$2,450', 'date': 'Today', 'color': AppColors.success},
      {'type': 'Withdrawal', 'description': 'Bank transfer to account', 'amount': '-\$2,000', 'date': 'Yesterday', 'color': AppColors.error},
      {'type': 'Income', 'description': 'Batch TO-20241001 delivered', 'amount': '+\$3,200', 'date': '2 days ago', 'color': AppColors.success},
      {'type': 'Cost', 'description': 'Input supplies deducted', 'amount': '-\$450', 'date': '3 days ago', 'color': AppColors.warning},
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Transactions',
                style: AppTypography.h6.copyWith(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
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
          ...transactions.map((transaction) => Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (transaction['color'] as Color).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    transaction['type'] == 'Income' ? Icons.arrow_upward : Icons.arrow_downward,
                    color: transaction['color'] as Color,
                    size: 16,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction['description'] as String,
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        transaction['date'] as String,
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 10,
                          color: isDark ? Colors.white60 : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  transaction['amount'] as String,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: transaction['color'] as Color,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  void _showWithdrawalDialog() {
    final amountController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw Funds'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Available Balance: \$24,580.50', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Process withdrawal
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Withdrawal request submitted')),
              );
            },
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
  }
}
