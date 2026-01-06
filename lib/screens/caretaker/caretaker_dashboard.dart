import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/providers/enhanced_auth_provider.dart';
import '../../core/widgets/permission_gate.dart';
import '../../core/models/user/user_permissions.dart';
import '../../core/routes/app_routes.dart';

/// Caretaker Dashboard
/// Daily farm monitoring, record keeping, and input requests
class CaretakerDashboard extends ConsumerStatefulWidget {
  const CaretakerDashboard({super.key});

  @override
  ConsumerState<CaretakerDashboard> createState() => _CaretakerDashboardState();
}

class _CaretakerDashboardState extends ConsumerState<CaretakerDashboard> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Caretaker Dashboard',
          style: AppTypography.h5.copyWith(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () {},
            tooltip: 'Chat with Farm Owner',
          ),
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
            _buildWelcomeSection(user?.name ?? 'Caretaker', isDark),
            const SizedBox(height: AppSpacing.xl),

            // Quick Actions
            _buildQuickActions(isDark),
            const SizedBox(height: AppSpacing.xl),

            // Today's Tasks & Assigned Batches
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildTodaysTasks(isDark)),
                const SizedBox(width: AppSpacing.lg),
                Expanded(child: _buildAssignedBatches(isDark)),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Recent Records & Pending Inputs
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildRecentRecords(isDark)),
                const SizedBox(width: AppSpacing.lg),
                Expanded(child: _buildPendingInputs(isDark)),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: PermissionGate(
        permission: Permission.createRecords,
        child: FloatingActionButton.extended(
          onPressed: () => context.go('${AppRoutes.caretakerDashboard}/record-entry'),
          icon: const Icon(Icons.add),
          label: const Text('Create Record'),
          backgroundColor: AppColors.success,
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(String name, bool isDark) {
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(now);
    
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.eco, size: 32, color: AppColors.success),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good ${_getGreeting()}, $name!',
                      style: AppTypography.h5.copyWith(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
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
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Row(
              children: [
                const Icon(Icons.agriculture, size: 16, color: AppColors.success),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Assigned Farm: Green Valley Farm',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }

  Widget _buildQuickActions(bool isDark) {
    final actions = [
      {'title': 'Create Record', 'icon': Icons.add_circle, 'color': AppColors.success, 'permission': Permission.createRecords},
      {'title': 'Request Inputs', 'icon': Icons.inventory, 'color': AppColors.primary, 'permission': Permission.requestInputs},
      {'title': 'Report Issue', 'icon': Icons.report_problem, 'color': AppColors.error, 'permission': Permission.raiseTechnicalIssue},
      {'title': 'View Records', 'icon': Icons.history, 'color': AppColors.info, 'permission': Permission.viewRecords},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 2.5,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return PermissionGate(
          permission: action['permission'] as String,
          child: InkWell(
            onTap: () {
              if (action['title'] == 'Create Record') {
                _showCreateRecordDialog();
              }
            },
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
                  Icon(action['icon'] as IconData, color: action['color'] as Color, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      action['title'] as String,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTodaysTasks(bool isDark) {
    final tasks = [
      {'task': 'Morning monitoring', 'time': '08:00 AM', 'status': 'Completed', 'color': AppColors.success},
      {'task': 'Water pH adjustment', 'time': '10:00 AM', 'status': 'Completed', 'color': AppColors.success},
      {'task': 'Nutrient feeding', 'time': '02:00 PM', 'status': 'Pending', 'color': AppColors.warning},
      {'task': 'Evening check', 'time': '06:00 PM', 'status': 'Pending', 'color': AppColors.warning},
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
            'Today\'s Tasks',
            style: AppTypography.h6.copyWith(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...tasks.map((task) => Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: task['color'] as Color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task['task'] as String,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        task['time'] as String,
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 10,
                          color: isDark ? Colors.white60 : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (task['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    task['status'] as String,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 9,
                      color: task['color'] as Color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildAssignedBatches(bool isDark) {
    final batches = [
      {'batch': 'LE-20241101-20241201', 'plant': 'Lettuce', 'stage': 'Growing', 'progress': 0.65},
      {'batch': 'BA-20241110-20241208', 'plant': 'Basil', 'stage': 'Transplanted', 'progress': 0.25},
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
            'Assigned Batches',
            style: AppTypography.h6.copyWith(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...batches.map((batch) => Container(
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
                      batch['batch'] as String,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
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
                        batch['stage'] as String,
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
                  batch['plant'] as String,
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
          )),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () {},
            child: const Text('View All Batches →'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentRecords(bool isDark) {
    final records = [
      {'type': 'Daily Monitoring', 'time': '2 hours ago', 'icon': Icons.visibility, 'color': AppColors.success},
      {'type': 'Watering', 'time': '4 hours ago', 'icon': Icons.water_drop, 'color': AppColors.primary},
      {'type': 'Feeding', 'time': 'Yesterday', 'icon': Icons.science, 'color': AppColors.warning},
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
                'Recent Records',
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
          ...records.map((record) => Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (record['color'] as Color).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(record['icon'] as IconData, color: record['color'] as Color, size: 16),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record['type'] as String,
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        record['time'] as String,
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 10,
                          color: isDark ? Colors.white60 : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 12, color: isDark ? Colors.white30 : Colors.black26),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildPendingInputs(bool isDark) {
    final inputs = [
      {'item': 'Nutrient Solution A', 'status': 'Approved', 'color': AppColors.success},
      {'item': 'pH Down', 'status': 'Pending', 'color': AppColors.warning},
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
            'Input Requests',
            style: AppTypography.h6.copyWith(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...inputs.map((input) => Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: (input['color'] as Color).withOpacity(0.05),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(color: (input['color'] as Color).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    input['item'] as String,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (input['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    input['status'] as String,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 9,
                      color: input['color'] as Color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          )),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Request New Input'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateRecordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Farm Record'),
        content: const Text('Record creation form will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Record created successfully')),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
