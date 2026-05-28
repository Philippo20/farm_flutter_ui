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
import '../../providers/auth_provider.dart';

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
  int _selectedNavIndex = 2;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'Technician';
    final userEmail = authState.user?.email ?? 'technician@farmestates.com';
    final userRole = 'Technician';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      drawer: isMobile
          ? _buildMobileDrawer(isDark, userName, userEmail, userRole)
          : null,
      body: isMobile
          ? _buildMobileLayout(isDark, userName)
          : _buildDesktopLayout(isDark, userName, userEmail, userRole),
      bottomNavigationBar: isMobile
          ? TechnicianMobileBottomNav(
              selectedIndex: _selectedNavIndex,
              onItemSelected: (index) => setState(() => _selectedNavIndex = index),
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

  Widget _buildMobileDrawer(bool isDark, String userName, String userEmail, String userRole) {
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
                        style: AppTypography.h5.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
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
                          style: AppTypography.bodyLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          userRole,
                          style: AppTypography.bodySmall.copyWith(color: Colors.white.withOpacity(0.8)),
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
                  _buildDrawerItem(Icons.dashboard_outlined, 'Dashboard', 0, '/technician_dashboard', isDark),
                  _buildDrawerItem(Icons.sensors_outlined, 'Sensors', 1, '/sensor-management', isDark),
                  _buildDrawerItem(Icons.build_outlined, 'Maintenance', 2, '/maintenance-schedule', isDark),
                  _buildDrawerItem(Icons.history_outlined, 'Repair History', 3, '/repair-history', isDark),
                  _buildDrawerItem(Icons.settings_outlined, 'Settings', 4, '/technician-settings', isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String label, int index, String route, bool isDark) {
    final isSelected = index == _selectedNavIndex;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColors.primary : (isDark ? Colors.white70 : AppColors.textSecondary),
      ),
      title: Text(
        label,
        style: AppTypography.bodyMedium.copyWith(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? AppColors.primary : (isDark ? Colors.white : AppColors.textPrimary),
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

  Widget _buildDesktopLayout(bool isDark, String userName, String userEmail, String userRole) {
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
      {'icon': Icons.dashboard_outlined, 'label': 'Dashboard', 'index': 0, 'route': '/technician_dashboard'},
      {'icon': Icons.sensors_outlined, 'label': 'Sensors', 'index': 1, 'route': '/sensor-management'},
      {'icon': Icons.build_outlined, 'label': 'Maintain', 'index': 2, 'route': '/maintenance-schedule'},
      {'icon': Icons.history_outlined, 'label': 'History', 'index': 3, 'route': '/repair-history'},
      {'icon': Icons.settings_outlined, 'label': 'Settings', 'index': 4, 'route': '/technician-settings'},
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
            color: isDark ? Colors.white.withOpacity(0.1) : AppColors.neutral100,
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
                          Navigator.pushReplacementNamed(context, item['route'] as String);
                        } catch (e) {
                          debugPrint('Navigation error: $e');
                        }
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        border: isSelected
                            ? Border(top: BorderSide(color: AppColors.primary, width: 2))
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
                                : (isDark ? Colors.white.withOpacity(0.5) : AppColors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['label'] as String,
                            style: AppTypography.caption.copyWith(
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark ? Colors.white.withOpacity(0.5) : AppColors.textSecondary),
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
    
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildStatsOverview(isDark, isMobile, isMaintenanceTab: true),
          _buildFilterChips(isDark, ['All', 'Scheduled', 'In Progress', 'Completed', 'Overdue']),
          _buildMaintenanceList(isDark),
        ],
      ),
    );
  }

  Widget _buildIssuesTab(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildStatsOverview(isDark, isMobile, isMaintenanceTab: false),
          _buildFilterChips(isDark, ['All', 'Critical', 'High', 'Medium', 'Low']),
          _buildIssuesList(isDark),
        ],
      ),
    );
  }

  Widget _buildStatsOverview(bool isDark, bool isMobile, {required bool isMaintenanceTab}) {
    final stats = isMaintenanceTab
        ? [
            {'title': 'Scheduled', 'value': '5', 'icon': Icons.schedule, 'color': AppColors.primary},
            {'title': 'In Progress', 'value': '2', 'icon': Icons.engineering, 'color': AppColors.warning},
            {'title': 'Completed', 'value': '12', 'icon': Icons.check_circle, 'color': AppColors.success},
            {'title': 'Overdue', 'value': '1', 'icon': Icons.warning, 'color': AppColors.error},
          ]
        : [
            {'title': 'Critical', 'value': '1', 'icon': Icons.error, 'color': AppColors.error},
            {'title': 'High', 'value': '3', 'icon': Icons.priority_high, 'color': AppColors.warning},
            {'title': 'Medium', 'value': '5', 'icon': Icons.info, 'color': AppColors.info},
            {'title': 'Resolved', 'value': '18', 'icon': Icons.check_circle, 'color': AppColors.success},
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
          _buildOperationsHero(isDark, isMobile, isMaintenanceTab: isMaintenanceTab),
          SizedBox(height: isMobile ? AppSpacing.md : AppSpacing.lg),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isMobile ? 2 : 4,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              childAspectRatio: isMobile ? 1.42 : 1.95,
            ),
            itemCount: stats.length,
            itemBuilder: (context, index) {
              final stat = stats[index];
              return _buildStatCard(
                isDark,
                isMobile,
                title: stat['title'] as String,
                value: stat['value'] as String,
                icon: stat['icon'] as IconData,
                color: stat['color'] as Color,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOperationsHero(bool isDark, bool isMobile, {required bool isMaintenanceTab}) {
    final title = isMaintenanceTab ? 'Maintenance Command Center' : 'Issue Response Queue';
    final subtitle = isMaintenanceTab
        ? 'Track scheduled work, active repairs, and overdue equipment tasks across farms.'
        : 'Prioritize faults, field incidents, and production risks before they escalate.';
    final accent = isMaintenanceTab ? AppColors.primary : AppColors.error;
    final badge = isMaintenanceTab ? '20 active tasks' : '9 open incidents';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  accent.withOpacity(0.24),
                  AppColors.surfaceDark,
                ]
              : [
                  accent.withOpacity(0.10),
                  Colors.white,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: accent.withOpacity(isDark ? 0.28 : 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: accent.withOpacity(isDark ? 0.18 : 0.10),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Text(
              badge,
              style: AppTypography.caption.copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: AppTypography.h5.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: isMobile ? 20 : 24,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

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
          const Spacer(),
          Text(
            value,
            style: AppTypography.h5.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w800,
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
    final isMobile = MediaQuery.of(context).size.width < 768;
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

    return GridView.builder(
      padding: EdgeInsets.fromLTRB(
        isMobile ? AppSpacing.md : AppSpacing.lg,
        AppSpacing.sm,
        isMobile ? AppSpacing.md : AppSpacing.lg,
        isMobile ? 96 : AppSpacing.lg,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 1 : 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        mainAxisExtent: isMobile ? 230 : 250,
      ),
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.14 : 0.04),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: InkWell(
            onTap: () => _showMaintenanceDetailsModal(item),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: Padding(
              padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              statusColor.withOpacity(0.20),
                              statusColor.withOpacity(0.08),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(color: statusColor.withOpacity(0.18)),
                        ),
                        child: Icon(Icons.build_rounded, color: statusColor, size: 24),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['equipment'] as String,
                              style: AppTypography.bodyLarge.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: isMobile ? 14 : 15,
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
                          style: AppTypography.caption.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w800,
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
                      Expanded(
                        child: Text(
                          'Assigned to: ${item['assignedTo']}',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 11,
                            color: isDark ? Colors.white60 : AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
    final isMobile = MediaQuery.of(context).size.width < 768;
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

    return GridView.builder(
      padding: EdgeInsets.fromLTRB(
        isMobile ? AppSpacing.md : AppSpacing.lg,
        AppSpacing.sm,
        isMobile ? AppSpacing.md : AppSpacing.lg,
        isMobile ? 96 : AppSpacing.lg,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 1 : 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        mainAxisExtent: isMobile ? 220 : 236,
      ),
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.14 : 0.04),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: InkWell(
            onTap: () => _showIssueDetailsModal(issue),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: Padding(
              padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              severityColor.withOpacity(0.20),
                              severityColor.withOpacity(0.08),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: Icon(Icons.warning_amber_rounded, color: severityColor, size: 24),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              issue['title'] as String,
                              style: AppTypography.bodyLarge.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: isMobile ? 14 : 15,
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
                          style: AppTypography.caption.copyWith(
                            color: severityColor,
                            fontWeight: FontWeight.w800,
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
                          style: AppTypography.caption.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w800,
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
                      Flexible(
                        child: Text(
                          'Reported by: ${issue['reportedBy']}',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 11,
                            color: isDark ? Colors.white60 : AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
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

  void _showMaintenanceDetailsModal(Map<String, dynamic> item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => Dialog(
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
                      _buildDetailBadge(item['status'] as String, _getStatusColor(item['status'] as String), isDark),
                      _buildDetailBadge(item['priority'] as String, _getPriorityColor(item['priority'] as String), isDark),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildDetailInfoGrid(
                    isDark,
                    [
                      _DetailField('Assigned To', item['assignedTo'] as String),
                      _DetailField('Duration', '${item['estimatedDuration']} min'),
                      _DetailField('Scheduled Date', DateFormat('MMM d, yyyy').format(item['scheduledDate'] as DateTime)),
                      _DetailField('Task Count', '${(item['tasks'] as List).length} items'),
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
    showDialog(
      context: context,
      builder: (context) => Dialog(
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
                      _buildDetailBadge(issue['severity'] as String, _getSeverityColor(issue['severity'] as String), isDark),
                      _buildDetailBadge(issue['status'] as String, _getIssueStatusColor(issue['status'] as String), isDark),
                      if (issue['affectsProduction'] as bool)
                        _buildDetailBadge('Affects Production', AppColors.error, isDark),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildDetailInfoGrid(
                    isDark,
                    [
                      _DetailField('Reported By', issue['reportedBy'] as String),
                      _DetailField('Reported', _getTimeAgo(issue['reportedAt'] as DateTime)),
                      _DetailField('Farm', issue['farm'] as String),
                      _DetailField('Production Impact', (issue['affectsProduction'] as bool) ? 'Yes' : 'No'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.04) : AppColors.neutral50,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Response Guidance',
                          style: AppTypography.bodyMedium.copyWith(
                            color: isDark ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          (issue['affectsProduction'] as bool)
                              ? 'This incident affects production. Escalate immediately and dispatch a technician on-site.'
                              : 'This incident can be handled in the normal response queue without immediate production shutdown.',
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark ? Colors.white70 : AppColors.textSecondary,
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
                          icon: const Icon(Icons.assignment_turned_in_outlined, size: 18),
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
                  color: isDark ? Colors.white.withOpacity(0.04) : AppColors.neutral50,
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
                        color: isDark ? Colors.white60 : AppColors.textSecondary,
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

class _DetailField {
  final String label;
  final String value;

  const _DetailField(this.label, this.value);
}
