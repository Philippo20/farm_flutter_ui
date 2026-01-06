import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/superadmin_sidebar.dart';
import '../../core/widgets/modern_admin_header.dart';
import '../../providers/auth_provider.dart';
import '../../models/enums.dart';

/// Super Admin User Management - Manage all users with approval workflow
class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  String _selectedFilter = 'All';
  
  final List<Map<String, dynamic>> _users = [
    {'id': 'U001', 'name': 'Sarah SuperAdmin', 'email': 'superadmin@farm.com', 'role': 'Super Admin', 'status': 'Active', 'department': 'Administration', 'joined': '2024-01-01'},
    {'id': 'U002', 'name': 'John Admin', 'email': 'admin@farm.com', 'role': 'Admin', 'status': 'Active', 'department': 'Management', 'joined': '2024-01-15'},
    {'id': 'U003', 'name': 'Alice Owner', 'email': 'owner@farm.com', 'role': 'Owner', 'status': 'Active', 'department': 'Farm Operations', 'joined': '2024-02-01'},
    {'id': 'U004', 'name': 'Bob Caretaker', 'email': 'caretaker@farm.com', 'role': 'Caretaker', 'status': 'Active', 'department': 'Field Work', 'joined': '2024-02-10'},
    {'id': 'U005', 'name': 'John Smith', 'email': 'john@example.com', 'role': 'Caretaker', 'status': 'Pending', 'department': 'Field Work', 'joined': '2024-10-28'},
    {'id': 'U006', 'name': 'Mary Johnson', 'email': 'mary@example.com', 'role': 'Owner', 'status': 'Pending', 'department': 'Farm Operations', 'joined': '2024-10-29'},
    {'id': 'U007', 'name': 'Tom Davis', 'email': 'tom@example.com', 'role': 'Caretaker', 'status': 'Suspended', 'department': 'Field Work', 'joined': '2024-03-15'},
    {'id': 'U008', 'name': 'Emma Wilson', 'email': 'emma@example.com', 'role': 'Owner', 'status': 'Active', 'department': 'Farm Operations', 'joined': '2024-04-01'},
  ];
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);
    
    final filteredUsers = _selectedFilter == 'All' 
        ? _users 
        : _users.where((u) => u['status'] == _selectedFilter).toList();
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Row(
        children: [
          SuperAdminSidebar(
            selectedIndex: 1,
            onItemSelected: (_) {},
            userName: user?.name ?? 'Super Admin',
            userEmail: user?.email ?? '',
            userRole: 'Super Administrator',
          ),
          Expanded(
            child: Column(
              children: [
                ModernAdminHeader(
                  userName: user?.name.split(' ').first ?? 'Super Admin',
                  onNotificationTap: () {},
                  onProfileTap: () {},
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('User Management', style: AppTypography.h4.copyWith(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)),
                                Text('Manage users, approve registrations, and assign roles', style: AppTypography.bodyMedium.copyWith(color: isDark ? Colors.white70 : AppColors.textSecondary)),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _showAddUserDialog(context, isDark),
                              icon: const Icon(Icons.person_add, size: 20),
                              label: const Text('Add User'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: AppSpacing.xl),
                        
                        // Stats
                        _buildStats(isDark),
                        
                        const SizedBox(height: AppSpacing.xl),
                        
                        // Filters
                        _buildFilters(isDark),
                        
                        const SizedBox(height: AppSpacing.lg),
                        
                        // Users Table
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDark : Colors.white,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                            border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('All Users (${filteredUsers.length})', style: AppTypography.h6.copyWith(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)),
                              const SizedBox(height: AppSpacing.lg),
                              ...filteredUsers.map((u) => _buildUserRow(u, isDark)),
                            ],
                          ),
                        ),
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
  
  Widget _buildStats(bool isDark) {
    final stats = [
      {'title': 'Total Users', 'value': '248', 'icon': Icons.people, 'color': AppColors.primary},
      {'title': 'Active', 'value': '235', 'icon': Icons.check_circle, 'color': AppColors.success},
      {'title': 'Pending Approval', 'value': '7', 'icon': Icons.pending, 'color': AppColors.warning},
      {'title': 'Suspended', 'value': '6', 'icon': Icons.block, 'color': AppColors.error},
    ];
    
    return Row(
      children: stats.map((stat) => Expanded(
        child: Container(
          margin: EdgeInsets.only(right: stat != stats.last ? AppSpacing.md : 0),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: (stat['color'] as Color).withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: (stat['color'] as Color).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (stat['color'] as Color).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(stat['icon'] as IconData, color: stat['color'] as Color, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stat['value'] as String, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: stat['color'] as Color)),
                  Text(stat['title'] as String, style: TextStyle(fontSize: 11, color: (stat['color'] as Color).withOpacity(0.8))),
                ],
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }
  
  Widget _buildFilters(bool isDark) {
    final filters = ['All', 'Active', 'Pending', 'Suspended'];
    
    return Row(
      children: filters.map((filter) => Padding(
        padding: const EdgeInsets.only(right: AppSpacing.sm),
        child: ChoiceChip(
          label: Text(filter),
          selected: _selectedFilter == filter,
          onSelected: (selected) {
            if (selected) setState(() => _selectedFilter = filter);
          },
          selectedColor: AppColors.primary.withOpacity(0.2),
          labelStyle: TextStyle(
            color: _selectedFilter == filter ? AppColors.primary : (isDark ? Colors.white70 : AppColors.textSecondary),
            fontWeight: _selectedFilter == filter ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      )).toList(),
    );
  }
  
  Widget _buildUserRow(Map<String, dynamic> user, bool isDark) {
    Color statusColor;
    switch (user['status']) {
      case 'Active':
        statusColor = AppColors.success;
        break;
      case 'Pending':
        statusColor = AppColors.warning;
        break;
      case 'Suspended':
        statusColor = AppColors.error;
        break;
      default:
        statusColor = AppColors.textSecondary;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Text(
              user['name'].toString().substring(0, 1),
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user['name'], style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isDark ? Colors.white : AppColors.textPrimary)),
                Text(user['email'], style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : AppColors.textSecondary)),
              ],
            ),
          ),
          Expanded(
            child: Text(user['role'], style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(user['department'], style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : AppColors.textSecondary)),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Text(user['status'], style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
            ),
          ),
          Expanded(
            child: Text(user['joined'], style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : AppColors.textSecondary)),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (user['status'] == 'Pending') ...[
                IconButton(
                  onPressed: () => _approveUser(user),
                  icon: const Icon(Icons.check_circle, size: 20),
                  color: AppColors.success,
                  tooltip: 'Approve',
                ),
                IconButton(
                  onPressed: () => _rejectUser(user),
                  icon: const Icon(Icons.cancel, size: 20),
                  color: AppColors.error,
                  tooltip: 'Reject',
                ),
              ] else ...[
                IconButton(
                  onPressed: () => _showEditUserDialog(context, user, isDark),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  color: AppColors.primary,
                ),
                IconButton(
                  onPressed: () => _toggleSuspend(user),
                  icon: Icon(user['status'] == 'Suspended' ? Icons.check_circle_outline : Icons.block, size: 18),
                  color: user['status'] == 'Suspended' ? AppColors.success : AppColors.error,
                  tooltip: user['status'] == 'Suspended' ? 'Activate' : 'Suspend',
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
  
  void _approveUser(Map<String, dynamic> user) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${user['name']} approved successfully!')),
    );
  }
  
  void _rejectUser(Map<String, dynamic> user) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${user['name']} rejected')),
    );
  }
  
  void _toggleSuspend(Map<String, dynamic> user) {
    final action = user['status'] == 'Suspended' ? 'activated' : 'suspended';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${user['name']} $action')),
    );
  }
  
  void _showAddUserDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New User'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              TextField(decoration: InputDecoration(labelText: 'Full Name', border: OutlineInputBorder())),
              SizedBox(height: AppSpacing.md),
              TextField(decoration: InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
              SizedBox(height: AppSpacing.md),
              TextField(decoration: InputDecoration(labelText: 'Role', border: OutlineInputBorder())),
              SizedBox(height: AppSpacing.md),
              TextField(decoration: InputDecoration(labelText: 'Department', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User added successfully!')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Add User'),
          ),
        ],
      ),
    );
  }
  
  void _showEditUserDialog(BuildContext context, Map<String, dynamic> user, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit User'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(decoration: InputDecoration(labelText: 'Full Name', border: const OutlineInputBorder()), controller: TextEditingController(text: user['name'])),
              const SizedBox(height: AppSpacing.md),
              TextField(decoration: InputDecoration(labelText: 'Email', border: const OutlineInputBorder()), controller: TextEditingController(text: user['email'])),
              const SizedBox(height: AppSpacing.md),
              TextField(decoration: InputDecoration(labelText: 'Role', border: const OutlineInputBorder()), controller: TextEditingController(text: user['role'])),
              const SizedBox(height: AppSpacing.md),
              TextField(decoration: InputDecoration(labelText: 'Department', border: const OutlineInputBorder()), controller: TextEditingController(text: user['department'])),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User updated successfully!')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
