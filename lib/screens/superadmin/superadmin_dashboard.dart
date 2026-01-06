import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/superadmin_sidebar.dart';
import '../../core/widgets/modern_admin_header.dart';
import '../../providers/auth_provider.dart';

/// Super Admin Dashboard - Full system control and monitoring
class SuperAdminDashboard extends ConsumerStatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  ConsumerState<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends ConsumerState<SuperAdminDashboard> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Row(
        children: [
          SuperAdminSidebar(
            selectedIndex: 0,
            onItemSelected: (index) {},
            userName: user?.name ?? 'Super Admin',
            userEmail: user?.email ?? '',
            userRole: 'Super Administrator',
          ),
          
          Expanded(
            child: Column(
              children: [
                ModernAdminHeader(
                  userName: user?.name.split(' ').first ?? 'Admin',
                  onNotificationTap: () {},
                  onProfileTap: () {},
                ),
                
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome Section
                        _buildWelcomeSection(isDark),
                        
                        const SizedBox(height: AppSpacing.xl),
                        
                        // System Overview Stats
                        _buildSystemStats(isDark),
                        
                        const SizedBox(height: AppSpacing.xl),
                        
                        // Quick Actions
                        _buildQuickActions(isDark),
                        
                        const SizedBox(height: AppSpacing.xl),
                        
                        // Pending Approvals
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildPendingUsers(isDark)),
                            const SizedBox(width: AppSpacing.lg),
                            Expanded(child: _buildPendingFarms(isDark)),
                          ],
                        ),
                        
                        const SizedBox(height: AppSpacing.xl),
                        
                        // Recent Activity
                        _buildRecentActivity(isDark),
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
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
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
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.admin_panel_settings, size: 40, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Super Admin Control Center',
                  style: AppTypography.h4.copyWith(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Full system access and configuration',
                  style: AppTypography.bodyMedium.copyWith(
                    fontFamily: 'Roboto',
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: Row(
              children: const [
                Icon(Icons.verified_user, size: 16, color: AppColors.success),
                SizedBox(width: 4),
                Text('All Access', style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSystemStats(bool isDark) {
    final stats = [
      {'title': 'Total Users', 'value': '248', 'change': '+12', 'icon': Icons.people, 'color': AppColors.primary},
      {'title': 'Active Farms', 'value': '24', 'change': '+3', 'icon': Icons.agriculture, 'color': AppColors.success},
      {'title': 'Plant Types', 'value': '45', 'change': '+5', 'icon': Icons.local_florist, 'color': AppColors.info},
      {'title': 'System Health', 'value': '98%', 'change': '+2%', 'icon': Icons.health_and_safety, 'color': AppColors.warning},
      {'title': 'Pending Approvals', 'value': '7', 'change': '', 'icon': Icons.pending_actions, 'color': AppColors.error},
      {'title': 'Revenue (MTD)', 'value': '\$420K', 'change': '+18%', 'icon': Icons.attach_money, 'color': AppColors.success},
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
        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (stat['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(stat['icon'] as IconData, color: stat['color'] as Color, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      stat['title'] as String,
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 11,
                        color: isDark ? Colors.white60 : AppColors.textSecondary,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          stat['value'] as String,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        if ((stat['change'] as String).isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            stat['change'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              color: (stat['change'] as String).startsWith('+') ? AppColors.success : AppColors.error,
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
      },
    );
  }
  
  Widget _buildQuickActions(bool isDark) {
    final actions = [
      {'title': 'Manage Users', 'subtitle': 'Add, edit, approve users', 'icon': Icons.person_add, 'color': AppColors.primary, 'route': '/superadmin/users'},
      {'title': 'Plant Types', 'subtitle': 'Create plant varieties', 'icon': Icons.eco, 'color': AppColors.success, 'route': '/superadmin/plants'},
      {'title': 'Pricing', 'subtitle': 'Set prices & packaging', 'icon': Icons.price_change, 'color': AppColors.warning, 'route': '/superadmin/pricing'},
      {'title': 'Audit Logs', 'subtitle': 'View system activity', 'icon': Icons.history, 'color': AppColors.info, 'route': '/superadmin/audit'},
      {'title': 'System Config', 'subtitle': 'Platform settings', 'icon': Icons.settings_applications, 'color': AppColors.error, 'route': '/superadmin/config'},
      {'title': 'Backup Data', 'subtitle': 'Export & restore', 'icon': Icons.backup, 'color': Colors.purple, 'route': '/superadmin/backup'},
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
            return InkWell(
              onTap: () {
                Navigator.pushNamed(context, action['route'] as String);
              },
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: (action['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: (action['color'] as Color).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(action['icon'] as IconData, color: action['color'] as Color, size: 28),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            action['title'] as String,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            action['subtitle'] as String,
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 11,
                              color: isDark ? Colors.white60 : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 14, color: action['color'] as Color),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
  
  Widget _buildPendingUsers(bool isDark) {
    final pendingUsers = [
      {'name': 'John Smith', 'email': 'john@example.com', 'role': 'Caretaker', 'date': '2 hours ago'},
      {'name': 'Mary Johnson', 'email': 'mary@example.com', 'role': 'Owner', 'date': '5 hours ago'},
      {'name': 'Bob Wilson', 'email': 'bob@example.com', 'role': 'Caretaker', 'date': '1 day ago'},
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
                'Pending User Approvals',
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
                  '${pendingUsers.length}',
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ...pendingUsers.map((user) => Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    user['name']!.substring(0, 1),
                    style: const TextStyle(color: AppColors.primary, fontSize: 12),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['name']!,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${user['role']} • ${user['date']}',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 10,
                          color: isDark ? Colors.white60 : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                  onPressed: () {},
                  tooltip: 'Approve',
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: AppColors.error, size: 20),
                  onPressed: () {},
                  tooltip: 'Reject',
                ),
              ],
            ),
          )),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/superadmin/users'),
            child: const Text('View All Pending Users →'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPendingFarms(bool isDark) {
    final pendingFarms = [
      {'name': 'Green Valley Farm', 'owner': 'Alice Brown', 'location': 'North Region', 'date': '3 hours ago'},
      {'name': 'Sunny Acres', 'owner': 'Tom Davis', 'location': 'East Hills', 'date': '1 day ago'},
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
                'Pending Farm Approvals',
                style: AppTypography.h6.copyWith(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  '${pendingFarms.length}',
                  style: const TextStyle(
                    color: AppColors.warning,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ...pendingFarms.map((farm) => Container(
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
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: const Icon(Icons.agriculture, color: AppColors.success, size: 20),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        farm['name']!,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${farm['owner']} • ${farm['date']}',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 10,
                          color: isDark ? Colors.white60 : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                  onPressed: () {},
                  tooltip: 'Approve',
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: AppColors.error, size: 20),
                  onPressed: () {},
                  tooltip: 'Reject',
                ),
              ],
            ),
          )),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/superadmin/farms'),
            child: const Text('View All Pending Farms →'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRecentActivity(bool isDark) {
    final activities = [
      {'user': 'Sarah SuperAdmin', 'action': 'Created new plant type "Cherry Tomatoes"', 'time': '10 mins ago', 'icon': Icons.add_circle, 'color': AppColors.success},
      {'user': 'Sarah SuperAdmin', 'action': 'Approved user "John Smith"', 'time': '2 hours ago', 'icon': Icons.check_circle, 'color': AppColors.info},
      {'user': 'Sarah SuperAdmin', 'action': 'Updated pricing for "Lettuce - 500g"', 'time': '5 hours ago', 'icon': Icons.edit, 'color': AppColors.warning},
      {'user': 'Sarah SuperAdmin', 'action': 'Created system backup', 'time': '1 day ago', 'icon': Icons.backup, 'color': AppColors.primary},
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
                'Recent Activity',
                style: AppTypography.h6.copyWith(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/superadmin/audit'),
                child: const Text('View All →'),
              ),
            ],
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
                  child: Icon(activity['icon'] as IconData, color: activity['color'] as Color, size: 16),
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
                          fontSize: 13,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${activity['user']} • ${activity['time']}',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 11,
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
}
