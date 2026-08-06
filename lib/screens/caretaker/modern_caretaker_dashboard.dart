import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/modern_admin_sidebar.dart';
import '../../core/widgets/modern_admin_header.dart';

/// Modern Caretaker Dashboard focused on tasks and daily activities
class ModernCaretakerDashboard extends ConsumerStatefulWidget {
  const ModernCaretakerDashboard({super.key});

  @override
  ConsumerState<ModernCaretakerDashboard> createState() => _ModernCaretakerDashboardState();
}

class _ModernCaretakerDashboardState extends ConsumerState<ModernCaretakerDashboard> {
  String _selectedFarm = 'Northern Estate';
  String _selectedView = 'Today';
  
  final List<Map<String, dynamic>> _todayTasks = [
    {'id': '1', 'title': 'Water greenhouse plants', 'priority': 'High', 'status': 'Pending', 'time': '08:00 AM', 'location': 'Greenhouse A', 'icon': Icons.water_drop, 'color': Colors.blue},
    {'id': '2', 'title': 'Feed chickens', 'priority': 'High', 'status': 'Completed', 'time': '09:00 AM', 'location': 'Poultry Area', 'icon': Icons.egg, 'color': Colors.orange},
    {'id': '3', 'title': 'Check soil moisture', 'priority': 'Medium', 'status': 'In Progress', 'time': '10:30 AM', 'location': 'Field 2', 'icon': Icons.grass, 'color': Colors.green},
    {'id': '4', 'title': 'Harvest tomatoes', 'priority': 'High', 'status': 'Pending', 'time': '02:00 PM', 'location': 'Greenhouse B', 'icon': Icons.agriculture, 'color': Colors.red},
    {'id': '5', 'title': 'Equipment maintenance', 'priority': 'Low', 'status': 'Pending', 'time': '04:00 PM', 'location': 'Storage', 'icon': Icons.build, 'color': Colors.grey},
  ];
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Row(
        children: [
          // Caretaker Sidebar
          ModernAdminSidebar(
            selectedIndex: 0,
            onItemSelected: (index) {
              // Handle navigation
              final routes = ['/caretaker_dashboard', '/farm', '/tasks', '/reports', '/caretaker_settings'];
              if (index < routes.length) {
                Navigator.pushNamed(context, routes[index]);
              }
            },
            userName: "Mike Davis",
            userEmail: "mike@farm.com",
            userRole: "Caretaker",
          ),
          
          Expanded(
            child: Column(
              children: [
                // Header
                ModernAdminHeader(
                  userName: 'Mike',
                  farms: ['Northern Estate', 'Eastern Farm'],
                  selectedFarm: _selectedFarm,
                  onFarmChanged: (farm) => setState(() => _selectedFarm = farm!),
                  onNotificationTap: () {},
                  onProfileTap: () => Navigator.of(context).pushNamed('/profile'),
                ),
                
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome Section
                        _buildWelcomeSection(isDark),
                        
                        const SizedBox(height: AppSpacing.xl),
                        
                        // Quick Stats
                        _buildQuickStats(isDark),
                        
                        const SizedBox(height: AppSpacing.xl),
                        
                        // Today's Tasks
                        _buildTasksSection(isDark),
                        
                        const SizedBox(height: AppSpacing.xl),
                        
                        // Quick Actions Grid
                        _buildQuickActions(isDark),
                        
                        const SizedBox(height: AppSpacing.xl),
                        
                        // Recent Activities
                        _buildRecentActivities(isDark),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildWelcomeSection(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Caretaker Dashboard',
              style: AppTypography.h4.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage your daily tasks and farm activities',
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        // View Selector
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : AppColors.neutral100,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: DropdownButton<String>(
            value: _selectedView,
            items: ['Today', 'This Week', 'This Month']
                .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                .toList(),
            onChanged: (v) => setState(() => _selectedView = v!),
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down),
          ),
        ),
      ],
    );
  }
  
  Widget _buildQuickStats(bool isDark) {
    final stats = [
      {'title': 'Tasks Today', 'value': '${_todayTasks.length}', 'completed': '2/${_todayTasks.length}', 'icon': Icons.task_alt, 'color': AppColors.primary},
      {'title': 'Areas Assigned', 'value': '4', 'subtitle': 'Active', 'icon': Icons.location_on, 'color': AppColors.info},
      {'title': 'Animals Fed', 'value': '450', 'subtitle': 'Today', 'icon': Icons.pets, 'color': AppColors.warning},
      {'title': 'Plants Watered', 'value': '1.2K', 'subtitle': 'This Week', 'icon': Icons.local_florist, 'color': AppColors.success},
    ];
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.8,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: (stat['color'] as Color).withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: (stat['color'] as Color).withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(stat['icon'] as IconData, color: stat['color'] as Color, size: 22),
                  if (stat.containsKey('completed'))
                    Text(
                      stat['completed'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                stat['value'] as String,
                style: AppTypography.h5.copyWith(
                  fontWeight: FontWeight.bold,
                  color: stat['color'] as Color,
                ),
              ),
              Text(
                stat.containsKey('subtitle') ? stat['subtitle'] as String : stat['title'] as String,
                style: TextStyle(
                  fontSize: 11,
                  color: (stat['color'] as Color).withOpacity(0.8),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildTasksSection(bool isDark) {
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
                'Today\'s Tasks',
                style: AppTypography.h6.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Task'),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ..._todayTasks.map((task) => _buildTaskItem(task, isDark)),
        ],
      ),
    );
  }
  
  Widget _buildTaskItem(Map<String, dynamic> task, bool isDark) {
    Color statusColor = task['status'] == 'Completed' 
        ? AppColors.success 
        : task['status'] == 'In Progress' 
            ? AppColors.warning 
            : AppColors.textSecondary;
    
    Color priorityColor = task['priority'] == 'High' 
        ? AppColors.error 
        : task['priority'] == 'Medium' 
            ? AppColors.warning 
            : AppColors.info;
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: task['status'] == 'In Progress' 
              ? AppColors.warning.withOpacity(0.3)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          // Checkbox
          Checkbox(
            value: task['status'] == 'Completed',
            onChanged: (value) {
              setState(() {
                task['status'] = value! ? 'Completed' : 'Pending';
              });
            },
            activeColor: AppColors.success,
          ),
          
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (task['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(task['icon'] as IconData, color: task['color'] as Color, size: 18),
          ),
          
          const SizedBox(width: AppSpacing.md),
          
          // Task Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task['title'],
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                          decoration: task['status'] == 'Completed' 
                              ? TextDecoration.lineThrough 
                              : null,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      child: Text(
                        task['priority'],
                        style: TextStyle(
                          fontSize: 10,
                          color: priorityColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: isDark ? Colors.white60 : AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      task['time'],
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : AppColors.textSecondary),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Icon(Icons.location_on_outlined, size: 14, color: isDark ? Colors.white60 : AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      task['location'],
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Text(
              task['status'],
              style: TextStyle(
                fontSize: 11,
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuickActions(bool isDark) {
    final actions = [
      {'icon': Icons.camera_alt, 'label': 'Log Activity', 'color': AppColors.primary},
      {'icon': Icons.report_problem, 'label': 'Report Issue', 'color': AppColors.error},
      {'icon': Icons.inventory, 'label': 'Check Inventory', 'color': AppColors.warning},
      {'icon': Icons.schedule, 'label': 'View Schedule', 'color': AppColors.info},
      {'icon': Icons.water_drop, 'label': 'Water Plants', 'color': Colors.blue},
      {'icon': Icons.pets, 'label': 'Feed Animals', 'color': Colors.orange},
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: AppTypography.h6.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: 1,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: Container(
                decoration: BoxDecoration(
                  color: (action['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: (action['color'] as Color).withOpacity(0.3)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(action['icon'] as IconData, color: action['color'] as Color, size: 24),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      action['label'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        color: action['color'] as Color,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
  
  Widget _buildRecentActivities(bool isDark) {
    final activities = [
      {'time': '10:30 AM', 'action': 'Watered greenhouse plants', 'status': 'Completed'},
      {'time': '09:15 AM', 'action': 'Fed 450 chickens', 'status': 'Completed'},
      {'time': '08:45 AM', 'action': 'Checked soil moisture in Field 2', 'status': 'Logged'},
      {'time': '08:00 AM', 'action': 'Started morning shift', 'status': 'Active'},
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
            'Recent Activities',
            style: AppTypography.h6.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ...activities.map((activity) => Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              children: [
                Text(
                  activity['time'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    activity['action'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    activity['status'] as String,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
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
}
