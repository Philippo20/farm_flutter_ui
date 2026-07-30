import 'dart:async';

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
import '../../core/widgets/skeleton_loader.dart';
import '../../services/superadmin_api_service.dart';

/// Technician Dashboard
/// Manage maintenance schedules, technical issues, and equipment repairs
class TechnicianDashboard extends ConsumerStatefulWidget {
  const TechnicianDashboard({super.key});

  @override
  ConsumerState<TechnicianDashboard> createState() =>
      _TechnicianDashboardState();
}

class _TechnicianDashboardState extends ConsumerState<TechnicianDashboard> {
  final SuperAdminApiService _api = SuperAdminApiService();
  Timer? _refreshTimer;
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _alerts = [];
  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> _sensors = [];
  List<Map<String, dynamic>> _farms = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadDashboardData(silent: true),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDashboardData({bool silent = false}) async {
    if (!silent && mounted) setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _api.getAlerts(),
        _api.getFarmTasks(),
        _api.getSensors(),
        _api.getFarms(),
      ]);
      if (!mounted) return;
      final user = ref.read(currentUserProvider);
      final farmIds = user?.assignedFarmIds.toSet() ?? <String>{};
      final userId = user?.id ?? '';
      bool belongsToTechnician(Map<String, dynamic> item) {
        final assignedTo = _value(item, ['assigned_to_id', 'technician_id']);
        final farmId = _value(item, ['farm_id', 'farmId']);
        if (assignedTo.isNotEmpty) return assignedTo == userId;
        if (farmIds.isNotEmpty && farmId.isNotEmpty) {
          return farmIds.contains(farmId);
        }
        return true;
      }

      setState(() {
        _alerts = results[0].where(belongsToTechnician).toList();
        _tasks = results[1].where(belongsToTechnician).toList();
        _sensors = results[2].where(belongsToTechnician).toList();
        _farms = results[3];
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
      });
    }
  }

  String _value(Map<String, dynamic> data, List<String> keys,
      [String fallback = '']) {
    for (final key in keys) {
      final value = data[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return fallback;
  }

  bool _isResolved(Map<String, dynamic> alert) {
    return alert['resolved'] == true ||
        _value(alert, ['status']).toLowerCase() == 'resolved';
  }

  bool _isToday(String value) {
    final date = DateTime.tryParse(value);
    final now = DateTime.now();
    return date != null &&
        date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isWithinWeek(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return false;
    final age = DateTime.now().difference(date).inDays;
    return age >= 0 && age <= 7;
  }

  String _dateLabel(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return 'TBD';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
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
            onPressed: () => context.go(AppRoutes.notifications),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () => context.go(AppRoutes.profile),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: AdminDataSkeleton(rowCount: 5))
          : _errorMessage != null
              ? _buildErrorState(isDark)
              : SingleChildScrollView(
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
          onPressed: () =>
              context.go('${AppRoutes.technicianDashboard}/maintenance'),
          icon: const Icon(Icons.build),
          label: const Text('New Maintenance'),
          backgroundColor: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 42,
                color: isDark ? Colors.white54 : AppColors.textSecondary),
            const SizedBox(height: AppSpacing.md),
            Text('Unable to load technician dashboard',
                style: AppTypography.h6.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary)),
            const SizedBox(height: AppSpacing.sm),
            Text(_errorMessage ?? 'Please try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: isDark ? Colors.white60 : AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: _loadDashboardData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
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
            child: const Icon(Icons.engineering,
                size: 32, color: AppColors.primary),
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
    final openIssues = _alerts.where((alert) => !_isResolved(alert)).length;
    final scheduledToday = _tasks.where((task) {
      final due = _value(task, ['due_date', 'scheduled_date', 'created_at']);
      return _isToday(due) &&
          _value(task, ['status']).toLowerCase() != 'completed';
    }).length;
    final completedThisWeek = _tasks.where((task) {
      final status = _value(task, ['status']).toLowerCase();
      final updated = _value(task, ['updated_at', 'created_at']);
      return status == 'completed' && _isWithinWeek(updated);
    }).length;
    final stats = [
      {
        'title': 'Open Issues',
        'value': '$openIssues',
        'change': '',
        'icon': Icons.report_problem,
        'color': AppColors.error
      },
      {
        'title': 'Scheduled Today',
        'value': '$scheduledToday',
        'change': '',
        'icon': Icons.event,
        'color': AppColors.primary
      },
      {
        'title': 'Completed This Week',
        'value': '$completedThisWeek',
        'change': '',
        'icon': Icons.check_circle,
        'color': AppColors.success
      },
      {
        'title': 'Equipment Monitored',
        'value': '${_sensors.length}',
        'change': '',
        'icon': Icons.settings,
        'color': AppColors.info
      },
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
            border: Border.all(
                color:
                    isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(stat['icon'] as IconData,
                      color: stat['color'] as Color, size: 20),
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
                        color:
                            isDark ? Colors.white60 : AppColors.textSecondary,
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
      {
        'title': 'Schedule Maintenance',
        'icon': Icons.calendar_today,
        'color': AppColors.primary,
        'permission': Permission.scheduleMaintenace
      },
      {
        'title': 'Report Issue',
        'icon': Icons.report,
        'color': AppColors.error,
        'permission': Permission.raiseTechnicalIssue
      },
      {
        'title': 'View Equipment',
        'icon': Icons.settings,
        'color': AppColors.info,
        'permission': Permission.viewInventory
      },
      {
        'title': 'Maintenance History',
        'icon': Icons.history,
        'color': AppColors.success,
        'permission': Permission.viewMaintenanceHistory
      },
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
            onTap: () => _handleQuickAction(action['title'] as String),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: (action['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                    color: (action['color'] as Color).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(action['icon'] as IconData,
                      color: action['color'] as Color, size: 20),
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
    final issues =
        _alerts.where((alert) => !_isResolved(alert)).take(5).map((alert) {
      final severity = _value(alert, ['severity', 'priority'], 'Medium');
      final normalized = severity.toLowerCase();
      final color = normalized == 'critical' || normalized == 'high'
          ? AppColors.error
          : normalized == 'medium'
              ? AppColors.warning
              : AppColors.info;
      return {
        'title': _value(alert, ['message', 'title'], 'Technical alert'),
        'farm': _value(alert, ['farm_name', 'farmName'], 'Assigned farm'),
        'severity': severity,
        'time': _value(alert, ['timestamp', r'$createdAt'], 'Recent'),
        'color': color,
      };
    }).toList();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
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
                  border: Border.all(
                      color: (issue['color'] as Color).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber,
                            color: issue['color'] as Color, size: 16),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            issue['title'] as String,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color:
                                  isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (issue['color'] as Color).withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusFull),
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
                        Icon(Icons.agriculture,
                            size: 12,
                            color: isDark
                                ? Colors.white60
                                : AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          issue['farm'] as String,
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 10,
                            color: isDark
                                ? Colors.white60
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Icon(Icons.access_time,
                            size: 12,
                            color: isDark
                                ? Colors.white60
                                : AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          issue['time'] as String,
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 10,
                            color: isDark
                                ? Colors.white60
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () => context.go(AppRoutes.issuesList),
            child: const Text('View All Issues →'),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysSchedule(bool isDark) {
    final schedule = _tasks
        .where((task) {
          final due =
              _value(task, ['due_date', 'scheduled_date', 'created_at']);
          return _isToday(due);
        })
        .take(5)
        .map((task) => {
              'task': _value(task, ['title', 'task'], 'Scheduled maintenance'),
              'time': _value(task, ['due_date', 'scheduled_date'], 'Today'),
              'farm': _value(task, ['farm_name', 'farmName'], 'Assigned farm'),
              'status': _value(task, ['status'], 'Pending'),
            })
        .toList();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
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
                color: isDark
                    ? Colors.white.withOpacity(0.03)
                    : AppColors.neutral50,
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
                            color:
                                isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.access_time,
                                size: 10,
                                color: isDark
                                    ? Colors.white60
                                    : AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              item['time'] as String,
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 10,
                                color: isDark
                                    ? Colors.white60
                                    : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Icon(Icons.agriculture,
                                size: 10,
                                color: isDark
                                    ? Colors.white60
                                    : AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              item['farm'] as String,
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 10,
                                color: isDark
                                    ? Colors.white60
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusFull),
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
    final upcoming = _tasks
        .where((task) {
          final due = DateTime.tryParse(
              _value(task, ['due_date', 'scheduled_date', 'created_at']));
          return due != null && !due.isBefore(DateTime.now());
        })
        .take(5)
        .map((task) {
          final due =
              _value(task, ['due_date', 'scheduled_date', 'created_at']);
          return {
            'date': _dateLabel(due),
            'task': _value(task, ['title', 'task'], 'Scheduled maintenance'),
            'type': _value(task, ['priority', 'status'], 'Planned'),
          };
        })
        .toList();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
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
                  color: isDark
                      ? Colors.white.withOpacity(0.03)
                      : AppColors.neutral50,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Column(
                        children: [
                          Text(
                            (item['date'] as String).split(' ')[0],
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color:
                                  isDark ? Colors.white : AppColors.textPrimary,
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
                              color:
                                  isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            item['type'] as String,
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 10,
                              color: isDark
                                  ? Colors.white60
                                  : AppColors.textSecondary,
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
    final equipment = _sensors.take(5).map((sensor) {
      final status = _value(sensor, ['status'], 'Offline');
      final online = status.toLowerCase() == 'online' ||
          status.toLowerCase() == 'active' ||
          status.toLowerCase() == 'operational';
      return {
        'name':
            _value(sensor, ['name', 'sensor_type', 'serial_number'], 'Sensor'),
        'status': online ? 'Operational' : status,
        'lastCheck': _value(sensor, ['last_seen_at', 'updated_at'], 'Unknown'),
        'color': online ? AppColors.success : AppColors.warning,
      };
    }).toList();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
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
                  color: isDark
                      ? Colors.white.withOpacity(0.03)
                      : AppColors.neutral50,
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
                      child: Icon(Icons.settings,
                          color: item['color'] as Color, size: 16),
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
                              color:
                                  isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Last check: ${item['lastCheck']}',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 10,
                              color: isDark
                                  ? Colors.white60
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (item['color'] as Color).withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusFull),
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
            onPressed: () => context.go(AppRoutes.equipmentList),
            child: const Text('View All Equipment →'),
          ),
        ],
      ),
    );
  }

  void _handleQuickAction(String title) {
    switch (title) {
      case 'Schedule Maintenance':
        _showCreateMaintenanceDialog();
        break;
      case 'Report Issue':
        context.go(AppRoutes.issuesList);
        break;
      case 'View Equipment':
        context.go(AppRoutes.equipmentList);
        break;
      case 'Maintenance History':
        context.go(AppRoutes.maintenanceSchedule);
        break;
    }
  }

  Future<void> _showCreateMaintenanceDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final dueDateController = TextEditingController();
    String? selectedFarmId;
    String selectedPriority = 'Medium';
    bool submitting = false;
    String? formError;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final user = ref.read(currentUserProvider);
          final availableFarms = _farms.where((farm) {
            final farmId = _value(farm, ['id', r'$id']);
            return user == null ||
                user.assignedFarmIds.isEmpty ||
                user.assignedFarmIds.contains(farmId);
          }).toList();

          Future<void> submit() async {
            if (titleController.text.trim().isEmpty || selectedFarmId == null) {
              setModalState(() =>
                  formError = 'Select a farm and enter a maintenance title.');
              return;
            }
            setModalState(() {
              submitting = true;
              formError = null;
            });
            try {
              final farm = availableFarms.firstWhere(
                  (item) => _value(item, ['id', r'$id']) == selectedFarmId);
              await _api.createFarmTask(data: {
                'farm_id': selectedFarmId!,
                'farm_name':
                    _value(farm, ['name', 'farm_name'], 'Assigned farm'),
                'title': titleController.text.trim(),
                'description': descriptionController.text.trim(),
                'manager_comment': 'Maintenance scheduled by technician',
                'caretaker_comment': '',
                'assigned_to_id': user?.id ?? '',
                'assigned_to_name': user?.name ?? 'Technician',
                'assigned_by_id': user?.id ?? '',
                'assigned_by_name': user?.name ?? 'Technician',
                'priority': selectedPriority,
                'due_date': dueDateController.text.trim(),
              });
              if (dialogContext.mounted) Navigator.of(dialogContext).pop(true);
            } catch (error) {
              setModalState(() {
                submitting = false;
                formError = error.toString();
              });
            }
          }

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 24)
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.build_circle_outlined,
                              color: Colors.white),
                          const SizedBox(width: 12),
                          const Expanded(
                              child: Text('Schedule Maintenance',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700))),
                          IconButton(
                              onPressed: submitting
                                  ? null
                                  : () => Navigator.of(dialogContext).pop(),
                              icon:
                                  const Icon(Icons.close, color: Colors.white)),
                        ],
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            DropdownButtonFormField<String>(
                              value: selectedFarmId,
                              decoration: const InputDecoration(
                                  labelText: 'Farm',
                                  prefixIcon: Icon(Icons.agriculture_outlined)),
                              items: availableFarms.map((farm) {
                                final id = _value(farm, ['id', r'$id']);
                                return DropdownMenuItem(
                                    value: id,
                                    child: Text(_value(
                                        farm, ['name', 'farm_name'], 'Farm')));
                              }).toList(),
                              onChanged: submitting
                                  ? null
                                  : (value) => setModalState(
                                      () => selectedFarmId = value),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                                controller: titleController,
                                enabled: !submitting,
                                decoration: const InputDecoration(
                                    labelText: 'Maintenance title',
                                    prefixIcon: Icon(Icons.title))),
                            const SizedBox(height: 12),
                            TextField(
                                controller: descriptionController,
                                enabled: !submitting,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                    labelText: 'Description',
                                    prefixIcon: Icon(Icons.notes_outlined))),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: selectedPriority,
                              decoration: const InputDecoration(
                                  labelText: 'Priority',
                                  prefixIcon: Icon(Icons.flag_outlined)),
                              items: const ['Low', 'Medium', 'High']
                                  .map((value) => DropdownMenuItem(
                                      value: value, child: Text(value)))
                                  .toList(),
                              onChanged: submitting
                                  ? null
                                  : (value) => setModalState(() =>
                                      selectedPriority = value ?? 'Medium'),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                                controller: dueDateController,
                                enabled: !submitting,
                                decoration: const InputDecoration(
                                    labelText: 'Due date (optional)',
                                    hintText: '2026-08-15T09:00:00Z',
                                    prefixIcon: Icon(Icons.event_outlined))),
                            if (formError != null) ...[
                              const SizedBox(height: 12),
                              Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(formError!,
                                      style: const TextStyle(
                                          color: AppColors.error))),
                            ],
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                              onPressed: submitting
                                  ? null
                                  : () => Navigator.of(dialogContext).pop(),
                              child: const Text('Cancel')),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                              onPressed: submitting ? null : submit,
                              icon: submitting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.save_outlined),
                              label:
                                  Text(submitting ? 'Saving...' : 'Schedule')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
    titleController.dispose();
    descriptionController.dispose();
    dueDateController.dispose();
    if (result == true && mounted) {
      await _loadDashboardData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maintenance scheduled successfully')),
        );
      }
    }
  }
}
