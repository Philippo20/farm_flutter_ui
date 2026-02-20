import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/permission_gate.dart';
import '../../core/models/user/user_permissions.dart';
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
      bottomNavigationBar: isMobile ? _buildBottomNavigation(isDark) : null,
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
                  _buildDrawerItem(Icons.dashboard_outlined, 'Dashboard', 0, '/technician-dashboard', isDark),
                  _buildDrawerItem(Icons.warning_amber_outlined, 'Open Issues', 1, '/open-issues', isDark),
                  _buildDrawerItem(Icons.build_outlined, 'Maintenance', 2, '/maintenance', isDark),
                  _buildDrawerItem(Icons.shopping_cart_outlined, 'Request Items', 3, '/request-items', isDark),
                  _buildDrawerItem(Icons.inventory_outlined, 'Asset Check', 4, '/asset-check', isDark),
                  _buildDrawerItem(Icons.settings_outlined, 'Settings', 5, '/settings', isDark),
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
        setState(() => _selectedNavIndex = index);
        Navigator.pop(context);
        if (index != _selectedNavIndex) {
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
              // Tab Bar
              Container(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: isDark ? Colors.white60 : AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  tabs: const [
                    Tab(text: 'Maintenance Schedule'),
                    Tab(text: 'Technical Issues'),
                  ],
                ),
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
        // Tab Bar
        Container(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: isDark ? Colors.white60 : AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            labelStyle: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'Maintenance'),
              Tab(text: 'Issues'),
            ],
          ),
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

  Widget _buildBottomNavigation(bool isDark) {
    final navItems = [
      {'icon': Icons.dashboard_outlined, 'label': 'Dashboard', 'index': 0, 'route': '/technician-dashboard'},
      {'icon': Icons.warning_amber_outlined, 'label': 'Issues', 'index': 1, 'route': '/open-issues'},
      {'icon': Icons.build_outlined, 'label': 'Maintain', 'index': 2, 'route': '/maintenance'},
      {'icon': Icons.shopping_cart_outlined, 'label': 'Request', 'index': 3, 'route': '/request-items'},
      {'icon': Icons.inventory_outlined, 'label': 'Assets', 'index': 4, 'route': '/asset-check'},
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
    
    return Column(
      children: [
        // Stats Overview
        _buildStatsOverview(isDark, isMobile, isMaintenanceTab: true),
        _buildFilterChips(isDark, ['All', 'Scheduled', 'In Progress', 'Completed', 'Overdue']),
        Expanded(child: _buildMaintenanceList(isDark)),
      ],
    );
  }

  Widget _buildIssuesTab(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    
    return Column(
      children: [
        // Stats Overview
        _buildStatsOverview(isDark, isMobile, isMaintenanceTab: false),
        _buildFilterChips(isDark, ['All', 'Critical', 'High', 'Medium', 'Low']),
        Expanded(child: _buildIssuesList(isDark)),
      ],
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
      padding: EdgeInsets.all(isMobile ? AppSpacing.sm : AppSpacing.md),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isMobile ? 2 : 4,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          childAspectRatio: isMobile ? 1.8 : 2.5,
        ),
        itemCount: stats.length,
        itemBuilder: (context, index) {
          final stat = stats[index];
          return Container(
            padding: EdgeInsets.all(isMobile ? AppSpacing.sm : AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: (stat['color'] as Color).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isMobile ? 6 : 8),
                  decoration: BoxDecoration(
                    color: (stat['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Icon(
                    stat['icon'] as IconData,
                    size: isMobile ? 18 : 20,
                    color: stat['color'] as Color,
                  ),
                ),
                SizedBox(width: isMobile ? AppSpacing.xs : AppSpacing.sm),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stat['value'] as String,
                        style: AppTypography.h5.copyWith(
                          fontWeight: FontWeight.bold,
                          color: stat['color'] as Color,
                          fontSize: isMobile ? 18 : 20,
                        ),
                      ),
                      Text(
                        stat['title'] as String,
                        style: AppTypography.caption.copyWith(
                          color: isDark ? Colors.white60 : AppColors.textSecondary,
                          fontSize: isMobile ? 10 : 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChips(bool isDark, List<String> filters) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    
    if (isMobile) {
      // Use Wrap for mobile to prevent overflow
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: filters.map((filter) {
            final isSelected = _selectedFilter == filter;
            return GestureDetector(
              onTap: () => setState(() => _selectedFilter = filter),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                child: Text(
                  filter,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white : AppColors.textPrimary),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
    }
    
    // Use horizontal list for desktop/tablet
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
