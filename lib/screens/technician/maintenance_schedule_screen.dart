import '../../core/widgets/app_dialog.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/permission_gate.dart';
import '../../core/models/user/user_permissions.dart';
import '../../core/widgets/technician_mobile_bottom_nav.dart';
import '../../core/widgets/technician_sidebar.dart';
import '../../core/widgets/technician_header.dart';
import '../../core/widgets/role_mobile_navigation.dart';
import '../../providers/auth_provider.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../services/superadmin_api_service.dart';

/// Maintenance Schedule Screen
/// View and manage maintenance schedules and technical issues
class MaintenanceScheduleScreen extends ConsumerStatefulWidget {
  const MaintenanceScheduleScreen({super.key, this.loadData});
  final Future<List<List<Map<String, dynamic>>>> Function()? loadData;

  @override
  ConsumerState<MaintenanceScheduleScreen> createState() =>
      _MaintenanceScheduleScreenState();
}

class _MaintenanceScheduleScreenState
    extends ConsumerState<MaintenanceScheduleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'All';
  int _selectedNavIndex = 2;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final SuperAdminApiService _api = SuperAdminApiService();
  Timer? _refreshTimer;
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> _alerts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMaintenanceData();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadMaintenanceData(silent: true),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadMaintenanceData({bool silent = false}) async {
    if (!silent && mounted) setState(() => _isLoading = true);
    try {
      final results = await (widget.loadData?.call() ??
          Future.wait([
            _api.getFarmTasks(),
            _api.getAlerts(),
          ]));
      if (!mounted) return;
      final user = ref.read(currentUserProvider);
      final assignedFarmIds =
          user?.farmId == null ? <String>{} : {user!.farmId!};
      setState(() {
        _tasks = results[0].where((task) {
          final assignedTo = _value(task, ['assigned_to_id', 'technician_id']);
          final farmId = _value(task, ['farm_id', 'farmId', 'farmID']);
          final assignedToUser = assignedTo.isEmpty || assignedTo == user?.id;
          final assignedFarm = assignedFarmIds.isEmpty ||
              farmId.isEmpty ||
              assignedFarmIds.contains(farmId);
          return assignedToUser && assignedFarm;
        }).toList();
        _alerts = results[1].where((alert) {
          final farmId = _value(alert, ['farm_id', 'farmId', 'farmID']);
          return assignedFarmIds.isEmpty ||
              farmId.isEmpty ||
              assignedFarmIds.contains(farmId);
        }).toList();
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
      if (value != null && value.toString().trim().isNotEmpty)
        return value.toString();
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'Technician';
    final userEmail = authState.user?.email ?? 'technician@farmestates.com';
    final userRole = 'Technician';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      drawer: isMobile
          ? RoleMobileDrawer(
              userName: userName,
              userEmail: userEmail,
              userRole: userRole,
              selectedIndex: _selectedNavIndex,
              onItemSelected: (_) {},
              items: technicianNavigationItems,
            )
          : null,
      body: isMobile
          ? _buildMobileLayout(isDark, userName)
          : _buildDesktopLayout(isDark, userName, userEmail, userRole),
      bottomNavigationBar: isMobile
          ? TechnicianMobileBottomNav(
              selectedIndex: _selectedNavIndex,
              onItemSelected: (index) =>
                  setState(() => _selectedNavIndex = index),
            )
          : null,
      floatingActionButton: PermissionGate(
        permission: Permission.scheduleMaintenace,
        child: FloatingActionButton.extended(
          onPressed: () => _showCreateDialog(),
          icon: const Icon(Icons.add),
          label: Text(_tabController.index == 0 ? 'Schedule' : 'Report Issue'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildMobileDrawer(
      bool isDark, String userName, String userEmail, String userRole) {
    return Drawer(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.neutral100,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                    ),
                    child: Center(
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'T',
                        style: AppTypography.h5.copyWith(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: AppTypography.bodyLarge.copyWith(
                              color: Colors.white, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          userRole,
                          style: AppTypography.bodySmall
                              .copyWith(color: Colors.white.withOpacity(0.8)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(Icons.dashboard_outlined, 'Dashboard', 0,
                      '/technician_dashboard', isDark),
                  _buildDrawerItem(Icons.sensors_outlined, 'Sensors', 1,
                      '/sensor-management', isDark),
                  _buildDrawerItem(Icons.build_outlined, 'Maintenance', 2,
                      '/maintenance-schedule', isDark),
                  _buildDrawerItem(Icons.history_outlined, 'Repair History', 3,
                      '/repair-history', isDark),
                  _buildDrawerItem(Icons.settings_outlined, 'Settings', 4,
                      '/technician-settings', isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
      IconData icon, String label, int index, String route, bool isDark) {
    final isSelected = index == _selectedNavIndex;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected
            ? AppColors.primary
            : (isDark ? Colors.white70 : AppColors.textSecondary),
      ),
      title: Text(
        label,
        style: AppTypography.bodyMedium.copyWith(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected
              ? AppColors.primary
              : (isDark ? Colors.white : AppColors.textPrimary),
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.primary.withOpacity(0.1),
      onTap: () {
        final shouldNavigate = index != _selectedNavIndex;
        Navigator.pop(context);
        if (shouldNavigate) {
          setState(() => _selectedNavIndex = index);
          try {
            Navigator.pushReplacementNamed(context, route);
          } catch (e) {
            debugPrint('Navigation error: $e');
          }
        }
      },
    );
  }

  Widget _buildDesktopLayout(
      bool isDark, String userName, String userEmail, String userRole) {
    return Row(
      children: [
        TechnicianSidebar(
          selectedIndex: _selectedNavIndex,
          onItemSelected: (index) => setState(() => _selectedNavIndex = index),
          userName: userName,
          userEmail: userEmail,
          userRole: userRole,
        ),
        Expanded(
          child: Column(
            children: [
              TechnicianHeader(
                userName: userName,
                onNotificationTap: () {},
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  0,
                ),
                child: _buildTabShell(isDark, false),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMaintenanceTab(isDark),
                    _buildIssuesTab(isDark),
                  ],
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
        TechnicianHeader(
          userName: userName,
          onNotificationTap: () {},
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.md,
            0,
          ),
          child: _buildTabShell(isDark, true),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildMaintenanceTab(isDark),
              _buildIssuesTab(isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabShell(bool isDark, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? AppSpacing.xs : AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark ? Colors.white10 : AppColors.neutral200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.16 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TabBar(
        onTap: (_) => setState(() => _selectedFilter = 'All'),
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: isDark ? Colors.white70 : AppColors.textSecondary,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: AppTypography.bodySmall.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: isMobile ? 12 : 13,
        ),
        unselectedLabelStyle: AppTypography.bodySmall.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: isMobile ? 12 : 13,
        ),
        tabs: [
          Tab(text: isMobile ? 'Maintenance' : 'Maintenance Schedule'),
          Tab(text: isMobile ? 'Issues' : 'Technical Issues'),
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
        'route': '/technician_dashboard'
      },
      {
        'icon': Icons.sensors_outlined,
        'label': 'Sensors',
        'index': 1,
        'route': '/sensor-management'
      },
      {
        'icon': Icons.build_outlined,
        'label': 'Maintain',
        'index': 2,
        'route': '/maintenance-schedule'
      },
      {
        'icon': Icons.history_outlined,
        'label': 'History',
        'index': 3,
        'route': '/repair-history'
      },
      {
        'icon': Icons.settings_outlined,
        'label': 'Settings',
        'index': 4,
        'route': '/technician-settings'
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(
          top: BorderSide(
            color:
                isDark ? Colors.white.withOpacity(0.1) : AppColors.neutral100,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: navItems.map((item) {
              final index = item['index'] as int;
              final isSelected = index == _selectedNavIndex;
              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (_selectedNavIndex != index) {
                        setState(() => _selectedNavIndex = index);
                        try {
                          Navigator.pushReplacementNamed(
                              context, item['route'] as String);
                        } catch (e) {
                          debugPrint('Navigation error: $e');
                        }
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        border: isSelected
                            ? Border(
                                top: BorderSide(
                                    color: AppColors.primary, width: 2))
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            item['icon'] as IconData,
                            size: 22,
                            color: isSelected
                                ? AppColors.primary
                                : (isDark
                                    ? Colors.white.withOpacity(0.5)
                                    : AppColors.textSecondary),
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
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
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

  Widget _buildMaintenanceTab(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    if (_isLoading) {
      return Center(
        child: AdminDataSkeleton(rowCount: 5, compact: isMobile),
      );
    }
    if (_errorMessage != null) {
      return Center(
        child: ElevatedButton.icon(
          onPressed: _loadMaintenanceData,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry loading maintenance'),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildStatsOverview(isDark, isMobile, isMaintenanceTab: true),
          _buildFilterChips(isDark,
              ['All', 'Scheduled', 'In Progress', 'Completed', 'Overdue']),
          _buildMaintenanceList(isDark),
        ],
      ),
    );
  }

  Widget _buildIssuesTab(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    if (_isLoading) {
      return Center(
        child: AdminDataSkeleton(rowCount: 5, compact: isMobile),
      );
    }
    if (_errorMessage != null) {
      return Center(
        child: ElevatedButton.icon(
          onPressed: _loadMaintenanceData,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry loading issues'),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildStatsOverview(isDark, isMobile, isMaintenanceTab: false),
          _buildFilterChips(
              isDark, ['All', 'Critical', 'High', 'Medium', 'Low']),
          _buildIssuesList(isDark),
        ],
      ),
    );
  }

  Widget _buildStatsOverview(bool isDark, bool isMobile,
      {required bool isMaintenanceTab}) {
    final statusCount = (String status) => _tasks.where((task) {
          return _value(task, ['status']).toLowerCase() == status.toLowerCase();
        }).length;
    final overdueCount = _tasks.where((task) {
      final due =
          DateTime.tryParse(_value(task, ['due_date', 'scheduled_date']));
      return due != null &&
          due.isBefore(DateTime.now()) &&
          _value(task, ['status']).toLowerCase() != 'completed';
    }).length;
    final stats = isMaintenanceTab
        ? [
            {
              'title': 'Scheduled',
              'value': '${statusCount('Pending') + statusCount('Not Started')}',
              'icon': Icons.schedule,
              'color': AppColors.primary
            },
            {
              'title': 'In Progress',
              'value': '${statusCount('In Progress') + statusCount('Started')}',
              'icon': Icons.engineering,
              'color': AppColors.warning
            },
            {
              'title': 'Completed',
              'value': '${statusCount('Completed')}',
              'icon': Icons.check_circle,
              'color': AppColors.success
            },
            {
              'title': 'Overdue',
              'value': '$overdueCount',
              'icon': Icons.warning,
              'color': AppColors.error
            },
          ]
        : [
            {
              'title': 'Critical',
              'value': '${_alerts.where((alert) => _value(alert, [
                        'severity',
                        'priority'
                      ]).toLowerCase() == 'critical').length}',
              'icon': Icons.error,
              'color': AppColors.error
            },
            {
              'title': 'High',
              'value': '${_alerts.where((alert) => _value(alert, [
                        'severity',
                        'priority'
                      ]).toLowerCase() == 'high').length}',
              'icon': Icons.priority_high,
              'color': AppColors.warning
            },
            {
              'title': 'Medium',
              'value': '${_alerts.where((alert) => _value(alert, [
                        'severity',
                        'priority'
                      ]).toLowerCase() == 'medium').length}',
              'icon': Icons.info,
              'color': AppColors.info
            },
            {
              'title': 'Resolved',
              'value': '${_alerts.where((alert) => _value(alert, [
                        'status'
                      ]).toLowerCase() == 'resolved').length}',
              'icon': Icons.check_circle,
              'color': AppColors.success
            },
          ];

    return Container(
      padding: EdgeInsets.fromLTRB(
        isMobile ? AppSpacing.md : AppSpacing.lg,
        isMobile ? AppSpacing.md : AppSpacing.lg,
        isMobile ? AppSpacing.md : AppSpacing.lg,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOperationsHero(isDark, isMobile,
              isMaintenanceTab: isMaintenanceTab),
          SizedBox(height: isMobile ? AppSpacing.md : AppSpacing.lg),
          _responsiveCards(
              stats
                  .map((stat) => _buildStatCard(isDark, isMobile,
                      title: stat['title'] as String,
                      value: stat['value'] as String,
                      icon: stat['icon'] as IconData,
                      color: stat['color'] as Color))
                  .toList(),
              minimumWidth: 125),
        ],
      ),
    );
  }

  Widget _buildOperationsHero(bool isDark, bool isMobile,
          {required bool isMaintenanceTab}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(isMaintenanceTab ? 'Maintenance overview' : 'Technical issues',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textPrimary)),
        const SizedBox(height: 5),
        Text(
            isMaintenanceTab
                ? 'Scheduled work and active repairs'
                : 'Review reported faults and follow-up work',
            style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white70 : AppColors.textSecondary)),
      ]);

  Widget _buildStatCard(
    bool isDark,
    bool isMobile, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? AppSpacing.sm : AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: color.withOpacity(0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(
              icon,
              size: isMobile ? 18 : 20,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTypography.h5.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: isMobile ? 18 : 22,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white70 : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(bool isDark, List<String> filters) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    return Container(
      padding: EdgeInsets.fromLTRB(
        isMobile ? AppSpacing.md : AppSpacing.lg,
        AppSpacing.sm,
        isMobile ? AppSpacing.md : AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          alignment: WrapAlignment.start,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: filters.map((filter) {
            final isSelected = _selectedFilter == filter;
            return ChoiceChip(
              showCheckmark: false,
              label: Text(filter),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedFilter = filter),
              selectedColor: AppColors.primary.withOpacity(0.18),
              backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
              labelStyle: AppTypography.bodySmall.copyWith(
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? Colors.white : AppColors.textPrimary),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              side: BorderSide(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.35)
                    : (isDark ? Colors.white12 : AppColors.neutral200),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMaintenanceList(bool isDark) {
    final maintenanceItems = _tasks.map((task) {
      final due = DateTime.tryParse(
          _value(task, ['due_date', 'scheduled_date', 'created_at']));
      final rawStatus = _value(task, ['status'], 'Pending');
      final displayStatus = rawStatus.toLowerCase() == 'pending' ||
              rawStatus.toLowerCase() == 'not started'
          ? 'Scheduled'
          : rawStatus.toLowerCase() == 'started'
              ? 'In Progress'
              : rawStatus;
      final isOverdue = due != null &&
          due.isBefore(DateTime.now()) &&
          rawStatus.toLowerCase() != 'completed';
      return <String, dynamic>{
        'id': _value(task, [r'$id', 'id', 'task_id']),
        'type': 'Maintenance',
        'equipment': _value(task, ['title', 'task'], 'Maintenance task'),
        'farm': _value(task, ['farm_name', 'farmName'], 'Assigned farm'),
        'scheduledDate': due ?? DateTime.now(),
        'status': isOverdue ? 'Overdue' : displayStatus,
        'priority': _value(task, ['priority'], 'Medium'),
        'assignedTo': _value(task, ['assigned_to_name'], 'Assigned technician'),
        'estimatedDuration': 0,
        'tasks': <String>[
          _value(task, ['description'], 'Review and complete maintenance task')
        ],
        'backendTask': task,
      };
    }).where((item) {
      return _selectedFilter == 'All' || item['status'] == _selectedFilter;
    }).toList();

    return _recordCards(isDark, maintenanceItems, false);
  }

  Widget _buildIssuesList(bool isDark) {
    final issues = _alerts
        .where((alert) => _value(alert, ['status']).toLowerCase() != 'resolved')
        .map((alert) {
      final priority = _value(alert, ['severity', 'priority'], 'Medium');
      final reportedAt = DateTime.tryParse(
          _value(alert, ['timestamp', 'created_at', r'$createdAt']));
      return <String, dynamic>{
        'id': _value(alert, [r'$id', 'id']),
        'title': _value(alert, ['message', 'title'], 'Technical issue'),
        'description': _value(alert, ['description', 'details'], ''),
        'category': _value(
            alert, ['sensorType', 'sensor_type', 'category'], 'Technical'),
        'severity': priority,
        'status': _value(alert, ['status'], 'Reported'),
        'farm': _value(alert, ['farm_name', 'farmName'], 'Assigned farm'),
        'reportedBy':
            _value(alert, ['reported_by_name', 'created_by_name'], 'System'),
        'reportedAt': reportedAt ?? DateTime.now(),
        'affectsProduction': priority.toLowerCase() == 'high' ||
            priority.toLowerCase() == 'critical',
      };
    }).where((issue) {
      return _selectedFilter == 'All' ||
          issue['severity'].toString().toLowerCase() ==
              _selectedFilter.toLowerCase();
    }).toList();

    return _recordCards(isDark, issues, true);
  }

  Widget _recordCards(
      bool dark, List<Map<String, dynamic>> records, bool issues) {
    final secondary = dark ? Colors.white70 : AppColors.textSecondary;
    final foreground = dark ? Colors.white : AppColors.textPrimary;
    return Padding(
        padding: EdgeInsets.fromLTRB(
            MediaQuery.sizeOf(context).width < 768 ? 16 : 24,
            8,
            MediaQuery.sizeOf(context).width < 768 ? 16 : 24,
            16),
        child: records.isEmpty
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                child: Text(
                    issues
                        ? 'No issues match this filter.'
                        : 'No maintenance tasks match this filter.',
                    style: TextStyle(fontSize: 12, color: secondary)))
            : _responsiveCards(
                records.map((item) {
                  final title =
                      (issues ? item['title'] : item['equipment']).toString();
                  final status = item['status'].toString();
                  final priority =
                      (issues ? item['severity'] : item['priority']).toString();
                  final color = issues
                      ? _getSeverityColor(priority)
                      : _getStatusColor(status);
                  final date =
                      issues ? item['reportedAt'] : item['scheduledDate'];
                  return Material(
                      color: dark ? AppColors.surfaceDark : Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                              color: dark
                                  ? Colors.white10
                                  : AppColors.neutral200)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => issues
                            ? _showIssueDetailsModal(item)
                            : _showMaintenanceDetailsModal(item),
                        child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                                color:
                                                    color.withValues(alpha: .1),
                                                borderRadius:
                                                    BorderRadius.circular(10)),
                                            child: Icon(
                                                issues
                                                    ? Icons
                                                        .warning_amber_rounded
                                                    : Icons.build_outlined,
                                                size: 18,
                                                color: color)),
                                        const SizedBox(width: 10),
                                        Expanded(
                                            child: Text(title,
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: foreground))),
                                        const Icon(Icons.chevron_right,
                                            size: 18)
                                      ]),
                                  const SizedBox(height: 12),
                                  Wrap(spacing: 8, runSpacing: 6, children: [
                                    Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 5),
                                        decoration: BoxDecoration(
                                            color: color.withValues(alpha: .1),
                                            borderRadius:
                                                BorderRadius.circular(6)),
                                        child: Text(status,
                                            style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: color))),
                                    Text(priority + ' priority',
                                        style: TextStyle(
                                            fontSize: 11, color: secondary))
                                  ]),
                                  const SizedBox(height: 12),
                                  Text(item['farm'].toString(),
                                      style: TextStyle(
                                          fontSize: 12, color: foreground)),
                                  const SizedBox(height: 8),
                                  Text(
                                      date is DateTime
                                          ? DateFormat('d MMM yyyy')
                                              .format(date.toLocal())
                                          : 'Date not recorded',
                                      style: TextStyle(
                                          fontSize: 11, color: secondary)),
                                  const SizedBox(height: 8),
                                  Text(
                                      (issues
                                              ? item['description']
                                              : (item['tasks'] as List)
                                                  .join(' '))
                                          .toString(),
                                      style: TextStyle(
                                          fontSize: 12,
                                          height: 1.4,
                                          color: secondary)),
                                  if (!issues) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                        'Assigned to: ' +
                                            item['assignedTo'].toString(),
                                        style: TextStyle(
                                            fontSize: 11, color: secondary))
                                  ],
                                ])),
                      ));
                }).toList(),
                minimumWidth: 350));
  }

  Widget _responsiveCards(List<Widget> cards, {double minimumWidth = 170}) =>
      LayoutBuilder(builder: (context, constraints) {
        final columns =
            (constraints.maxWidth / minimumWidth).floor().clamp(1, 4);
        final rows = (cards.length / columns).ceil();
        return Column(children: [
          for (var row = 0; row < rows; row++) ...[
            if (row > 0) const SizedBox(height: 12),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (var col = 0; col < columns; col++) ...[
                if (col > 0) const SizedBox(width: 12),
                Expanded(
                    child: row * columns + col < cards.length
                        ? cards[row * columns + col]
                        : const SizedBox())
              ]
            ])
          ]
        ]);
      });

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
    showAppDialog(
      context: context,
      builder: (context) => AppAlertDialog(
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
    showAppDialog(
      context: context,
      builder: (context) => AppAlertDialog(
        title: Text(_tabController.index == 0
            ? 'Schedule Maintenance'
            : 'Report Issue'),
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
                SnackBar(
                    content: Text(_tabController.index == 0
                        ? 'Maintenance scheduled'
                        : 'Issue reported')),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showMaintenanceDetailsModal(Map<String, dynamic> item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showAppDialog(
      context: context,
      builder: (context) => AppDialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: isDark ? Colors.white10 : AppColors.neutral200,
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailModalHeader(
                    title: item['equipment'] as String,
                    subtitle: '${item['type']} • ${item['farm']}',
                    accent: _getStatusColor(item['status'] as String),
                    isDark: isDark,
                    badges: [
                      _buildDetailBadge(item['status'] as String,
                          _getStatusColor(item['status'] as String), isDark),
                      _buildDetailBadge(
                          item['priority'] as String,
                          _getPriorityColor(item['priority'] as String),
                          isDark),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildDetailInfoGrid(
                    isDark,
                    [
                      _DetailField('Assigned To', item['assignedTo'] as String),
                      _DetailField(
                          'Duration', '${item['estimatedDuration']} min'),
                      _DetailField(
                          'Scheduled Date',
                          DateFormat('MMM d, yyyy')
                              .format(item['scheduledDate'] as DateTime)),
                      _DetailField('Task Count',
                          '${(item['tasks'] as List).length} items'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Planned Work',
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...(item['tasks'] as List).map(
                    (task) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _buildChecklistItem(task.toString(), isDark),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Close'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.play_circle_outline, size: 18),
                          label: const Text('Start Task'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showIssueDetailsModal(Map<String, dynamic> issue) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showAppDialog(
      context: context,
      builder: (context) => AppDialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: isDark ? Colors.white10 : AppColors.neutral200,
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailModalHeader(
                    title: issue['title'] as String,
                    subtitle: '${issue['category']} • ${issue['farm']}',
                    accent: _getSeverityColor(issue['severity'] as String),
                    isDark: isDark,
                    badges: [
                      _buildDetailBadge(
                          issue['severity'] as String,
                          _getSeverityColor(issue['severity'] as String),
                          isDark),
                      _buildDetailBadge(
                          issue['status'] as String,
                          _getIssueStatusColor(issue['status'] as String),
                          isDark),
                      if (issue['affectsProduction'] as bool)
                        _buildDetailBadge(
                            'Affects Production', AppColors.error, isDark),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildDetailInfoGrid(
                    isDark,
                    [
                      _DetailField(
                          'Reported By', issue['reportedBy'] as String),
                      _DetailField('Reported',
                          _getTimeAgo(issue['reportedAt'] as DateTime)),
                      _DetailField('Farm', issue['farm'] as String),
                      _DetailField('Production Impact',
                          (issue['affectsProduction'] as bool) ? 'Yes' : 'No'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.04)
                          : AppColors.neutral50,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Response Guidance',
                          style: AppTypography.bodyMedium.copyWith(
                            color:
                                isDark ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          (issue['affectsProduction'] as bool)
                              ? 'This incident affects production. Escalate immediately and dispatch a technician on-site.'
                              : 'This incident can be handled in the normal response queue without immediate production shutdown.',
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark
                                ? Colors.white70
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Close'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.assignment_turned_in_outlined,
                              size: 18),
                          label: const Text('Acknowledge'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailModalHeader({
    required String title,
    required String subtitle,
    required Color accent,
    required bool isDark,
    required List<Widget> badges,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [accent.withOpacity(0.22), AppColors.backgroundDark]
              : [accent.withOpacity(0.10), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: accent.withOpacity(isDark ? 0.28 : 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.h5.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: badges,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailBadge(String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withOpacity(0.24)),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildDetailInfoGrid(bool isDark, List<_DetailField> fields) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: fields
          .map(
            (field) => SizedBox(
              width: 260,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.04)
                      : AppColors.neutral50,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: isDark ? Colors.white10 : AppColors.neutral200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      field.label,
                      style: AppTypography.caption.copyWith(
                        color:
                            isDark ? Colors.white60 : AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      field.value,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildChecklistItem(String text, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, size: 12, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMaintenanceDetails(Map<String, dynamic> item) {
    showAppDialog(
      context: context,
      builder: (context) => AppAlertDialog(
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
              const Text('Tasks:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
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
    showAppDialog(
      context: context,
      builder: (context) => AppAlertDialog(
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

class _DetailField {
  final String label;
  final String value;

  const _DetailField(this.label, this.value);
}
