import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/providers/enhanced_auth_provider.dart';
import '../../core/widgets/permission_gate.dart';
import '../../core/models/user/user_permissions.dart';
import '../../core/routes/app_routes.dart';

/// Farm Manager Dashboard
/// Manages farm operations, inventory, batch production, and team coordination
class FarmManagerDashboard extends ConsumerStatefulWidget {
  const FarmManagerDashboard({super.key});

  @override
  ConsumerState<FarmManagerDashboard> createState() => _FarmManagerDashboardState();
}

class _FarmManagerDashboardState extends ConsumerState<FarmManagerDashboard> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Farm Manager Dashboard',
          style: AppTypography.h5.copyWith(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
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
            _buildWelcomeSection(user?.name ?? 'Farm Manager', isDark),
            const SizedBox(height: AppSpacing.xl),

            // Stats Overview
            _buildStatsOverview(isDark),
            const SizedBox(height: AppSpacing.xl),

            // Quick Actions
            _buildQuickActions(isDark),
            const SizedBox(height: AppSpacing.xl),

            // Active Batches & Alerts
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildActiveBatches(isDark)),
                const SizedBox(width: AppSpacing.lg),
                Expanded(child: _buildInventoryAlerts(isDark)),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Recent Activity
            _buildRecentActivity(isDark),
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
            AppColors.success.withOpacity(0.1),
            AppColors.success.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.agriculture, size: 32, color: AppColors.success),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, $name!',
                  style: AppTypography.h5.copyWith(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage your farms, inventory, and production batches',
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

  Widget _buildStatsOverview(bool isDark) {
    final stats = [
      {'title': 'Assigned Farms', 'value': '5', 'change': '+1', 'icon': Icons.agriculture, 'color': AppColors.success},
      {'title': 'Active Batches', 'value': '12', 'change': '+3', 'icon': Icons.inventory_2, 'color': AppColors.primary},
      {'title': 'Ready to Harvest', 'value': '4', 'change': '', 'icon': Icons.eco, 'color': AppColors.warning},
      {'title': 'Low Stock Items', 'value': '7', 'change': '-2', 'icon': Icons.warning_amber, 'color': AppColors.error},
      {'title': 'Pending Approvals', 'value': '3', 'change': '', 'icon': Icons.pending_actions, 'color': AppColors.info},
      {'title': 'Budget Available', 'value': '\$15K', 'change': '+5%', 'icon': Icons.account_balance_wallet, 'color': AppColors.success},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 2.5,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return _buildStatCard(stat, isDark);
      },
    );
  }

  Widget _buildStatCard(Map<String, dynamic> stat, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (stat['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(stat['icon'] as IconData, color: stat['color'] as Color, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  stat['title'] as String,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 10,
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      stat['value'] as String,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    if ((stat['change'] as String).isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Text(
                        stat['change'] as String,
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 10,
                          color: (stat['change'] as String).startsWith('+')
                              ? AppColors.success
                              : AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(bool isDark) {
    final actions = [
      {'title': 'Generate Batch', 'icon': Icons.add_circle, 'color': AppColors.success, 'permission': Permission.generateBatch},
      {'title': 'Manage Inventory', 'icon': Icons.inventory, 'color': AppColors.primary, 'permission': Permission.manageInventory},
      {'title': 'Supply Inputs', 'icon': Icons.local_shipping, 'color': AppColors.warning, 'permission': Permission.supplyInputs},
      {'title': 'Request Budget', 'icon': Icons.request_quote, 'color': AppColors.info, 'permission': Permission.requestBudget},
      {'title': 'View Reports', 'icon': Icons.assessment, 'color': AppColors.error, 'permission': Permission.viewReports},
      {'title': 'Trigger Delivery', 'icon': Icons.send, 'color': Colors.purple, 'permission': Permission.triggerDelivery},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: AppTypography.h6.copyWith(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: 3,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return PermissionGate(
              permission: action['permission'] as String,
              child: _buildActionCard(action, isDark),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionCard(Map<String, dynamic> action, bool isDark) {
    return InkWell(
      onTap: () => _handleActionTap(action['title'] as String),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: (action['color'] as Color).withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: (action['color'] as Color).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(action['icon'] as IconData, color: action['color'] as Color, size: 24),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                action['title'] as String,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 12, color: action['color'] as Color),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveBatches(bool isDark) {
    final batches = [
      {'batch': 'LE-20241101-20241201', 'farm': 'Green Valley', 'plant': 'Lettuce', 'status': 'Growing', 'progress': 0.65},
      {'batch': 'TO-20241015-20241214', 'farm': 'Sunny Acres', 'plant': 'Tomatoes', 'status': 'Flowering', 'progress': 0.45},
      {'batch': 'BA-20241110-20241208', 'farm': 'Fresh Farms', 'plant': 'Basil', 'status': 'Transplanted', 'progress': 0.25},
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
            'Active Batches',
            style: AppTypography.h6.copyWith(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...batches.map((batch) => _buildBatchItem(batch, isDark)),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () {},
            child: const Text('View All Batches →'),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchItem(Map<String, dynamic> batch, bool isDark) {
    return Container(
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
            children: [
              Expanded(
                child: Text(
                  batch['batch'] as String,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  batch['status'] as String,
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
            '${batch['farm']} • ${batch['plant']}',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 10,
              color: isDark ? Colors.white60 : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: batch['progress'] as double,
            backgroundColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryAlerts(bool isDark) {
    final alerts = [
      {'item': 'Nutrient Solution A', 'level': 'Low', 'quantity': '15 L', 'color': AppColors.warning},
      {'item': 'pH Down', 'level': 'Critical', 'quantity': '2 L', 'color': AppColors.error},
      {'item': 'Lettuce Seeds', 'level': 'Low', 'quantity': '500 g', 'color': AppColors.warning},
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
            'Inventory Alerts',
            style: AppTypography.h6.copyWith(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...alerts.map((alert) => _buildAlertItem(alert, isDark)),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () {},
            child: const Text('View All Inventory →'),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertItem(Map<String, dynamic> alert, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: (alert['color'] as Color).withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: (alert['color'] as Color).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: alert['color'] as Color, size: 16),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert['item'] as String,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${alert['level']} • ${alert['quantity']}',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 10,
                    color: alert['color'] as Color,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_shopping_cart, size: 16),
            onPressed: () {},
            tooltip: 'Reorder',
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(bool isDark) {
    final activities = [
      {'action': 'Generated batch LE-20241115-20241215', 'user': 'You', 'time': '10 mins ago', 'icon': Icons.add_circle, 'color': AppColors.success},
      {'action': 'Supplied nutrients to Green Valley Farm', 'user': 'You', 'time': '2 hours ago', 'icon': Icons.local_shipping, 'color': AppColors.primary},
      {'action': 'Approved input request from Bob Caretaker', 'user': 'You', 'time': '5 hours ago', 'icon': Icons.check_circle, 'color': AppColors.info},
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
            'Recent Activity',
            style: AppTypography.h6.copyWith(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...activities.map((activity) => Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: (activity['color'] as Color).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(activity['icon'] as IconData, color: activity['color'] as Color, size: 14),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity['action'] as String,
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 12,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        activity['time'] as String,
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 10,
                          color: isDark ? Colors.white60 : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  /// Handle quick action navigation
  void _handleActionTap(String actionTitle) {
    switch (actionTitle) {
      case 'Generate Batch':
        context.go('${AppRoutes.farmManagerDashboard}/batch-generation');
        break;
      case 'Manage Inventory':
        context.go('${AppRoutes.farmManagerDashboard}/inventory');
        break;
      case 'View Reports':
        // TODO: Navigate to reports screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reports screen coming soon')),
        );
        break;
      case 'Request Budget':
        // TODO: Show budget request dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget request dialog coming soon')),
        );
        break;
      case 'Approve Harvest':
        // TODO: Show harvest approval dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Harvest approval coming soon')),
        );
        break;
      case 'Trigger Delivery':
        // TODO: Show delivery trigger dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Delivery trigger coming soon')),
        );
        break;
    }
  }
}
