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

/// Technician Dashboard
/// Manage maintenance schedules, technical issues, and equipment repairs
class TechnicianDashboard extends ConsumerStatefulWidget {
  const TechnicianDashboard({super.key});

  @override
  ConsumerState<TechnicianDashboard> createState() => _TechnicianDashboardState();
}

class _TechnicianDashboardState extends ConsumerState<TechnicianDashboard> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Technician Dashboard',
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
            _buildWelcomeSection(user?.name ?? 'Technician', isDark),
            const SizedBox(height: AppSpacing.xl),

            // Stats Overview
            _buildStatsOverview(isDark),
            const SizedBox(height: AppSpacing.xl),

            // Quick Actions
            _buildQuickActions(isDark),
            const SizedBox(height: AppSpacing.xl),

            // Urgent Issues & Today's Schedule
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildUrgentIssues(isDark)),
                const SizedBox(width: AppSpacing.lg),
                Expanded(child: _buildTodaysSchedule(isDark)),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Maintenance Calendar & Equipment Status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildMaintenanceCalendar(isDark)),
                const SizedBox(width: AppSpacing.lg),
                Expanded(child: _buildEquipmentStatus(isDark)),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: PermissionGate(
        permission: Permission.scheduleMaintenace,
        child: FloatingActionButton.extended(
          onPressed: () => context.go('${AppRoutes.technicianDashboard}/maintenance'),
          icon: const Icon(Icons.build),
          label: const Text('New Maintenance'),
          backgroundColor: AppColors.primary,
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
            AppColors.primary.withOpacity(0.1),
            AppColors.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.engineering, size: 32, color: AppColors.primary),
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
                  'Manage maintenance and resolve technical issues',
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
      {'title': 'Open Issues', 'value': '7', 'change': '+2', 'icon': Icons.report_problem, 'color': AppColors.error},
      {'title': 'Scheduled Today', 'value': '4', 'change': '', 'icon': Icons.event, 'color': AppColors.primary},
      {'title': 'Completed This Week', 'value': '12', 'change': '+3', 'icon': Icons.check_circle, 'color': AppColors.success},
      {'title': 'Equipment Monitored', 'value': '28', 'change': '', 'icon': Icons.settings, 'color': AppColors.info},
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      stat['title'] as String,
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 11,
                        color: isDark ? Colors.white60 : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  if ((stat['change'] as String).isNotEmpty)
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
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(bool isDark) {
    final actions = [
      {'title': 'Schedule Maintenance', 'icon': Icons.calendar_today, 'color': AppColors.primary, 'permission': Permission.scheduleMaintenace},
      {'title': 'Report Issue', 'icon': Icons.report, 'color': AppColors.error, 'permission': Permission.raiseTechnicalIssue},
      {'title': 'View Equipment', 'icon': Icons.settings, 'color': AppColors.info, 'permission': Permission.viewInventory},
      {'title': 'Maintenance History', 'icon': Icons.history, 'color': AppColors.success, 'permission': Permission.viewMaintenanceHistory},
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
              if (action['title'] == 'Schedule Maintenance') {
                _showCreateMaintenanceDialog();
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

  Widget _buildUrgentIssues(bool isDark) {
    final issues = [
      {'title': 'Water pump malfunction', 'farm': 'Green Valley', 'severity': 'Critical', 'time': '30m ago', 'color': AppColors.error},
      {'title': 'pH sensor not responding', 'farm': 'Sunny Acres', 'severity': 'High', 'time': '2h ago', 'color': AppColors.warning},
      {'title': 'LED light flickering', 'farm': 'Fresh Farms', 'severity': 'Medium', 'time': '4h ago', 'color': AppColors.info},
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
                'Urgent Issues',
                style: AppTypography.h6.copyWith(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  '${issues.length}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...issues.map((issue) => Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: (issue['color'] as Color).withOpacity(0.05),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(color: (issue['color'] as Color).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber, color: issue['color'] as Color, size: 16),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        issue['title'] as String,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (issue['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      child: Text(
                        issue['severity'] as String,
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 9,
                          color: issue['color'] as Color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.agriculture, size: 12, color: isDark ? Colors.white60 : AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      issue['farm'] as String,
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 10,
                        color: isDark ? Colors.white60 : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Icon(Icons.access_time, size: 12, color: isDark ? Colors.white60 : AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      issue['time'] as String,
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 10,
                        color: isDark ? Colors.white60 : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () {},
            child: const Text('View All Issues →'),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysSchedule(bool isDark) {
    final schedule = [
      {'task': 'Preventive maintenance - Water pumps', 'time': '09:00 AM', 'farm': 'Green Valley', 'status': 'Completed'},
      {'task': 'Calibrate pH sensors', 'time': '11:00 AM', 'farm': 'Sunny Acres', 'status': 'In Progress'},
      {'task': 'Inspect HVAC system', 'time': '02:00 PM', 'farm': 'Fresh Farms', 'status': 'Scheduled'},
      {'task': 'Replace LED lights', 'time': '04:00 PM', 'farm': 'Urban Greens', 'status': 'Scheduled'},
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
            'Today\'s Schedule',
            style: AppTypography.h6.copyWith(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...schedule.map((item) {
            final color = item['status'] == 'Completed'
                ? AppColors.success
                : item['status'] == 'In Progress'
                    ? AppColors.warning
                    : AppColors.info;
            
            return Container(
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
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['task'] as String,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 10, color: isDark ? Colors.white60 : AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              item['time'] as String,
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 10,
                                color: isDark ? Colors.white60 : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Icon(Icons.agriculture, size: 10, color: isDark ? Colors.white60 : AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              item['farm'] as String,
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 10,
                                color: isDark ? Colors.white60 : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    child: Text(
                      item['status'] as String,
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 9,
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMaintenanceCalendar(bool isDark) {
    final upcoming = [
      {'date': 'Nov 2', 'task': 'Monthly system check', 'type': 'Preventive'},
      {'date': 'Nov 5', 'task': 'Sensor calibration', 'type': 'Calibration'},
      {'date': 'Nov 8', 'task': 'Equipment inspection', 'type': 'Inspection'},
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
                'Upcoming Maintenance',
                style: AppTypography.h6.copyWith(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.calendar_month, size: 20),
                onPressed: () {},
                tooltip: 'View Calendar',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...upcoming.map((item) => Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Column(
                    children: [
                      Text(
                        (item['date'] as String).split(' ')[0],
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        (item['date'] as String).split(' ')[1],
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['task'] as String,
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        item['type'] as String,
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

  Widget _buildEquipmentStatus(bool isDark) {
    final equipment = [
      {'name': 'Water Pumps', 'status': 'Operational', 'lastCheck': '2 days ago', 'color': AppColors.success},
      {'name': 'pH Sensors', 'status': 'Needs Calibration', 'lastCheck': '1 week ago', 'color': AppColors.warning},
      {'name': 'HVAC System', 'status': 'Operational', 'lastCheck': '3 days ago', 'color': AppColors.success},
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
            'Equipment Status',
            style: AppTypography.h6.copyWith(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...equipment.map((item) => Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: (item['color'] as Color).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.settings, color: item['color'] as Color, size: 16),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'] as String,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Last check: ${item['lastCheck']}',
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
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (item['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    item['status'] as String,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 9,
                      color: item['color'] as Color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          )),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () {},
            child: const Text('View All Equipment →'),
          ),
        ],
      ),
    );
  }

  void _showCreateMaintenanceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Schedule Maintenance'),
        content: const Text('Maintenance scheduling form will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Maintenance scheduled successfully')),
              );
            },
            child: const Text('Schedule'),
          ),
        ],
      ),
    );
  }
}
