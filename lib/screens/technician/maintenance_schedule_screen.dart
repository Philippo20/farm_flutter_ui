import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/permission_gate.dart';
import '../../core/models/user/user_permissions.dart';

/// Maintenance Schedule Screen
/// View and manage maintenance schedules and technical issues
class MaintenanceScheduleScreen extends ConsumerStatefulWidget {
  const MaintenanceScheduleScreen({super.key});

  @override
  ConsumerState<MaintenanceScheduleScreen> createState() => _MaintenanceScheduleScreenState();
}

class _MaintenanceScheduleScreenState extends ConsumerState<MaintenanceScheduleScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Maintenance & Issues',
          style: AppTypography.h5.copyWith(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Maintenance Schedule'),
            Tab(text: 'Technical Issues'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMaintenanceTab(isDark),
          _buildIssuesTab(isDark),
        ],
      ),
      floatingActionButton: PermissionGate(
        permission: Permission.scheduleMaintenace,
        child: FloatingActionButton.extended(
          onPressed: () => _showCreateDialog(),
          icon: const Icon(Icons.add),
          label: Text(_tabController.index == 0 ? 'Schedule' : 'Report Issue'),
          backgroundColor: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildMaintenanceTab(bool isDark) {
    return Column(
      children: [
        _buildFilterChips(isDark, ['All', 'Scheduled', 'In Progress', 'Completed', 'Overdue']),
        Expanded(child: _buildMaintenanceList(isDark)),
      ],
    );
  }

  Widget _buildIssuesTab(bool isDark) {
    return Column(
      children: [
        _buildFilterChips(isDark, ['All', 'Critical', 'High', 'Medium', 'Low']),
        Expanded(child: _buildIssuesList(isDark)),
      ],
    );
  }

  Widget _buildFilterChips(bool isDark, List<String> filters) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;

          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = filter),
            child: Container(
              margin: const EdgeInsets.only(right: AppSpacing.sm),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.surfaceDark : Colors.white),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
                ),
              ),
              child: Center(
                child: Text(
                  filter,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white : AppColors.textPrimary),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMaintenanceList(bool isDark) {
    final maintenanceItems = [
      {
        'id': '1',
        'type': 'Preventive',
        'equipment': 'Water Pump System',
        'farm': 'Green Valley',
        'scheduledDate': DateTime.now().add(const Duration(days: 2)),
        'status': 'Scheduled',
        'priority': 'Medium',
        'assignedTo': 'John Tech',
        'estimatedDuration': 120,
        'tasks': ['Check motor', 'Replace filters', 'Test flow rate'],
      },
      {
        'id': '2',
        'type': 'Corrective',
        'equipment': 'pH Sensor Array',
        'farm': 'Sunny Acres',
        'scheduledDate': DateTime.now(),
        'status': 'In Progress',
        'priority': 'High',
        'assignedTo': 'Sarah Tech',
        'estimatedDuration': 90,
        'tasks': ['Calibrate sensors', 'Replace faulty unit'],
      },
      {
        'id': '3',
        'type': 'Inspection',
        'equipment': 'HVAC System',
        'farm': 'Fresh Farms',
        'scheduledDate': DateTime.now().subtract(const Duration(days: 1)),
        'status': 'Overdue',
        'priority': 'Critical',
        'assignedTo': 'Mike Tech',
        'estimatedDuration': 60,
        'tasks': ['Inspect ducts', 'Check thermostat', 'Clean filters'],
      },
      {
        'id': '4',
        'type': 'Calibration',
        'equipment': 'EC Meters',
        'farm': 'Urban Greens',
        'scheduledDate': DateTime.now().subtract(const Duration(days: 3)),
        'status': 'Completed',
        'priority': 'Low',
        'assignedTo': 'John Tech',
        'estimatedDuration': 45,
        'tasks': ['Calibrate all meters', 'Document readings'],
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: maintenanceItems.length,
      itemBuilder: (context, index) {
        final item = maintenanceItems[index];
        final statusColor = _getStatusColor(item['status'] as String);
        final priorityColor = _getPriorityColor(item['priority'] as String);

        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
          ),
          child: InkWell(
            onTap: () => _showMaintenanceDetails(item),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Icon(Icons.build, color: statusColor, size: 24),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['equipment'] as String,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: isDark ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '${item['type']} • ${item['farm']}',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 11,
                                color: isDark ? Colors.white60 : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        ),
                        child: Text(
                          item['status'] as String,
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 10,
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: isDark ? Colors.white60 : AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM d, yyyy').format(item['scheduledDate'] as DateTime),
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 11,
                          color: isDark ? Colors.white60 : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Icon(Icons.access_time, size: 14, color: isDark ? Colors.white60 : AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${item['estimatedDuration']} min',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 11,
                          color: isDark ? Colors.white60 : AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: priorityColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                          border: Border.all(color: priorityColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.flag, size: 10, color: priorityColor),
                            const SizedBox(width: 2),
                            Text(
                              item['priority'] as String,
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 9,
                                color: priorityColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Icon(Icons.person, size: 14, color: isDark ? Colors.white60 : AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        'Assigned to: ${item['assignedTo']}',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 11,
                          color: isDark ? Colors.white60 : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Tasks: ${(item['tasks'] as List).length}',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 10,
                      color: isDark ? Colors.white60 : AppColors.textSecondary,
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

  Widget _buildIssuesList(bool isDark) {
    final issues = [
      {
        'id': '1',
        'title': 'Water pump malfunction',
        'category': 'Plumbing',
        'severity': 'Critical',
        'status': 'Reported',
        'farm': 'Green Valley',
        'reportedBy': 'Jane Caretaker',
        'reportedAt': DateTime.now().subtract(const Duration(minutes: 30)),
        'affectsProduction': true,
      },
      {
        'id': '2',
        'title': 'pH sensor not responding',
        'category': 'Sensors',
        'severity': 'High',
        'status': 'Acknowledged',
        'farm': 'Sunny Acres',
        'reportedBy': 'Bob Caretaker',
        'reportedAt': DateTime.now().subtract(const Duration(hours: 2)),
        'affectsProduction': false,
      },
      {
        'id': '3',
        'title': 'LED light flickering',
        'category': 'Lighting',
        'severity': 'Medium',
        'status': 'In Progress',
        'farm': 'Fresh Farms',
        'reportedBy': 'Alice Caretaker',
        'reportedAt': DateTime.now().subtract(const Duration(hours: 4)),
        'affectsProduction': false,
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: issues.length,
      itemBuilder: (context, index) {
        final issue = issues[index];
        final severityColor = _getSeverityColor(issue['severity'] as String);
        final statusColor = _getIssueStatusColor(issue['status'] as String);

        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: (issue['affectsProduction'] as bool)
                  ? AppColors.error.withOpacity(0.3)
                  : (isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
            ),
          ),
          child: InkWell(
            onTap: () => _showIssueDetails(issue),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: severityColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Icon(Icons.warning_amber, color: severityColor, size: 24),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              issue['title'] as String,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: isDark ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '${issue['category']} • ${issue['farm']}',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 11,
                                color: isDark ? Colors.white60 : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: severityColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        ),
                        child: Text(
                          issue['severity'] as String,
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 10,
                            color: severityColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        ),
                        child: Text(
                          issue['status'] as String,
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 10,
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (issue['affectsProduction'] as bool) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.production_quantity_limits, size: 10, color: AppColors.error),
                              SizedBox(width: 2),
                              Text(
                                'Affects Production',
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 9,
                                  color: AppColors.error,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Icon(Icons.person, size: 14, color: isDark ? Colors.white60 : AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        'Reported by: ${issue['reportedBy']}',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 11,
                          color: isDark ? Colors.white60 : AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.access_time, size: 14, color: isDark ? Colors.white60 : AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        _getTimeAgo(issue['reportedAt'] as DateTime),
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 11,
                          color: isDark ? Colors.white60 : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Scheduled':
        return AppColors.primary;
      case 'In Progress':
        return AppColors.warning;
      case 'Completed':
        return AppColors.success;
      case 'Overdue':
        return AppColors.error;
      default:
        return AppColors.info;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Critical':
        return AppColors.error;
      case 'High':
        return AppColors.warning;
      case 'Medium':
        return AppColors.info;
      case 'Low':
        return AppColors.success;
      default:
        return AppColors.info;
    }
  }

  Color _getSeverityColor(String severity) {
    return _getPriorityColor(severity);
  }

  Color _getIssueStatusColor(String status) {
    switch (status) {
      case 'Reported':
        return AppColors.error;
      case 'Acknowledged':
        return AppColors.warning;
      case 'In Progress':
        return AppColors.primary;
      case 'Resolved':
        return AppColors.success;
      default:
        return AppColors.info;
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Options'),
        content: const Text('Advanced filtering will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_tabController.index == 0 ? 'Schedule Maintenance' : 'Report Issue'),
        content: const Text('Form will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(_tabController.index == 0 ? 'Maintenance scheduled' : 'Issue reported')),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showMaintenanceDetails(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item['equipment'] as String),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Type: ${item['type']}'),
              Text('Status: ${item['status']}'),
              Text('Priority: ${item['priority']}'),
              Text('Farm: ${item['farm']}'),
              Text('Assigned to: ${item['assignedTo']}'),
              Text('Duration: ${item['estimatedDuration']} min'),
              const SizedBox(height: AppSpacing.sm),
              const Text('Tasks:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...(item['tasks'] as List).map((task) => Text('• $task')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showIssueDetails(Map<String, dynamic> issue) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(issue['title'] as String),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category: ${issue['category']}'),
            Text('Severity: ${issue['severity']}'),
            Text('Status: ${issue['status']}'),
            Text('Farm: ${issue['farm']}'),
            Text('Reported by: ${issue['reportedBy']}'),
            Text('Affects Production: ${issue['affectsProduction']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
