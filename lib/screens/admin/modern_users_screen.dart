import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/modern_admin_sidebar.dart';
import '../../core/widgets/modern_admin_header.dart';

/// Modern Users Management Screen with clean table design
class ModernUsersScreen extends ConsumerStatefulWidget {
  const ModernUsersScreen({super.key});

  @override
  ConsumerState<ModernUsersScreen> createState() => _ModernUsersScreenState();
}

class _ModernUsersScreenState extends ConsumerState<ModernUsersScreen> {
  String _searchQuery = '';
  String _selectedRole = 'All';
  String _selectedStatus = 'All';
  
  final List<Map<String, dynamic>> _users = [
    {'id': '001', 'name': 'John Smith', 'email': 'john@farm.com', 'role': 'Admin', 'status': 'Active', 'farms': 'Northern, Southern', 'lastActive': '2 hours ago', 'avatar': 'JS'},
    {'id': '002', 'name': 'Sarah Johnson', 'email': 'sarah@farm.com', 'role': 'Owner', 'status': 'Active', 'farms': 'Eastern', 'lastActive': '30 mins ago', 'avatar': 'SJ'},
    {'id': '003', 'name': 'Mike Davis', 'email': 'mike@farm.com', 'role': 'Caretaker', 'status': 'Active', 'farms': 'Western', 'lastActive': '1 day ago', 'avatar': 'MD'},
    {'id': '004', 'name': 'Emily Chen', 'email': 'emily@farm.com', 'role': 'Caretaker', 'status': 'Inactive', 'farms': 'Northern', 'lastActive': '5 days ago', 'avatar': 'EC'},
    {'id': '005', 'name': 'Robert Wilson', 'email': 'robert@farm.com', 'role': 'Owner', 'status': 'Active', 'farms': 'Southern, Western', 'lastActive': 'Online', 'avatar': 'RW'},
  ];
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Row(
        children: [
          // Sidebar
          ModernAdminSidebar(selectedIndex: 1, onItemSelected: (_) {}),
          
          // Main Content
          Expanded(
            child: Column(
              children: [
                // Header
                ModernAdminHeader(userName: 'Admin', onNotificationTap: () {}, onProfileTap: () {}),
                
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title & Add Button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('User Management', style: AppTypography.h4.copyWith(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)),
                                const SizedBox(height: 4),
                                Text('Manage users, roles, and permissions', style: AppTypography.bodyMedium.copyWith(color: isDark ? Colors.white70 : AppColors.textSecondary)),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.person_add, size: 20),
                              label: const Text('Add User'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: AppSpacing.xl),
                        
                        // Stats Cards
                        _buildStatsCards(isDark),
                        
                        const SizedBox(height: AppSpacing.xl),
                        
                        // Table Controls
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDark : Colors.white,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                            border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
                          ),
                          child: Row(
                            children: [
                              // Search
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  onChanged: (value) => setState(() => _searchQuery = value),
                                  decoration: InputDecoration(
                                    hintText: 'Search users...',
                                    prefixIcon: const Icon(Icons.search),
                                    filled: true,
                                    fillColor: isDark ? Colors.white10 : AppColors.neutral100,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd), borderSide: BorderSide.none),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              // Role Filter
                              _buildDropdown('Role', _selectedRole, ['All', 'Admin', 'Owner', 'Caretaker'], (v) => setState(() => _selectedRole = v!), isDark),
                              const SizedBox(width: AppSpacing.md),
                              // Status Filter
                              _buildDropdown('Status', _selectedStatus, ['All', 'Active', 'Inactive'], (v) => setState(() => _selectedStatus = v!), isDark),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: AppSpacing.lg),
                        
                        // Users Table
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDark : Colors.white,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                            border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
                          ),
                          child: Column(
                            children: [
                              // Table Header
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
                                ),
                                child: Row(
                                  children: [
                                    const Expanded(flex: 3, child: Text('User', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                                    const Expanded(flex: 2, child: Text('Role', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                                    const Expanded(flex: 2, child: Text('Status', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                                    const Expanded(flex: 2, child: Text('Farms', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                                    const Expanded(flex: 2, child: Text('Last Active', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                                    const SizedBox(width: 100, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12), textAlign: TextAlign.center)),
                                  ],
                                ),
                              ),
                              // Table Body
                              ..._users.where((user) {
                                if (_searchQuery.isNotEmpty && !user['name'].toLowerCase().contains(_searchQuery.toLowerCase())) return false;
                                if (_selectedRole != 'All' && user['role'] != _selectedRole) return false;
                                if (_selectedStatus != 'All' && user['status'] != _selectedStatus) return false;
                                return true;
                              }).map((user) => _buildUserRow(user, isDark)),
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
  
  Widget _buildStatsCards(bool isDark) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 3.5,
      children: [
        _buildStatCard(
          title: 'Total Users',
          value: '${_users.length}',
          change: '+12%',
          isPositive: true,
          icon: Icons.people_rounded,
          color: AppColors.primary,
          isDark: isDark,
        ),
        _buildStatCard(
          title: 'Active Users',
          value: '${_users.where((u) => u['status'] == 'Active').length}',
          change: '+5%',
          isPositive: true,
          icon: Icons.check_circle_rounded,
          color: AppColors.success,
          isDark: isDark,
        ),
        _buildStatCard(
          title: 'Caretakers',
          value: '${_users.where((u) => u['role'] == 'Caretaker').length}',
          change: '+8%',
          isPositive: true,
          icon: Icons.agriculture_rounded,
          color: AppColors.info,
          isDark: isDark,
        ),
        _buildStatCard(
          title: 'Owners',
          value: '${_users.where((u) => u['role'] == 'Owner').length}',
          change: '+3%',
          isPositive: true,
          icon: Icons.business_rounded,
          color: AppColors.warning,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String change,
    required bool isPositive,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon with colored background
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(isDark ? 0.15 : 0.9),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 18,
                ),
              ),
              
              const SizedBox(width: AppSpacing.sm),
              
              // Title and Value
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: AppTypography.bodySmall.copyWith(
                          color: color.withOpacity(0.8),
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value,
                          style: AppTypography.h6.copyWith(
                            fontWeight: FontWeight.bold,
                            color: color,
                            letterSpacing: -0.5,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: AppSpacing.xs),
              
              // Trend Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(isDark ? 0.15 : 0.9),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(
                    color: isPositive ? AppColors.success : AppColors.error,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 10,
                      color: isPositive ? AppColors.success : AppColors.error,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      change,
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isPositive ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildUserRow(Map<String, dynamic> user, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05))),
      ),
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              // User Info
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                      child: Center(child: Text(user['avatar'], style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12))),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user['name'], style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textPrimary)),
                          Text(user['email'], style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Role
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getRoleColor(user['role']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(user['role'], style: TextStyle(color: _getRoleColor(user['role']), fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                ),
              ),
              // Status
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: user['status'] == 'Active' ? AppColors.success : AppColors.error, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text(user['status'], style: TextStyle(color: user['status'] == 'Active' ? AppColors.success : AppColors.error, fontSize: 12)),
                  ],
                ),
              ),
              // Farms
              Expanded(flex: 2, child: Text(user['farms'], style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : AppColors.textSecondary), overflow: TextOverflow.ellipsis)),
              // Last Active
              Expanded(flex: 2, child: Text(user['lastActive'], style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : AppColors.textSecondary))),
              // Actions
              SizedBox(
                width: 100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(onPressed: () {}, icon: const Icon(Icons.edit_outlined), iconSize: 18, color: AppColors.primary),
                    IconButton(onPressed: () {}, icon: const Icon(Icons.delete_outline), iconSize: 18, color: AppColors.error),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : AppColors.neutral100,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: DropdownButton<String>(
        value: value,
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
        onChanged: onChanged,
        underline: const SizedBox(),
        icon: const Icon(Icons.arrow_drop_down),
      ),
    );
  }
  
  Color _getRoleColor(String role) {
    switch (role) {
      case 'Admin': return AppColors.error;
      case 'Owner': return AppColors.primary;
      case 'Caretaker': return AppColors.info;
      default: return AppColors.textSecondary;
    }
  }
}
