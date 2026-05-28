import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/superadmin_sidebar.dart';
import '../../core/widgets/modern_admin_header.dart';
import '../../providers/auth_provider.dart';

/// Super Admin User Management - Manage all users with approval workflow
class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  String _selectedFilter = 'All';
  int _selectedNavIndex = 1;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Map<String, dynamic>> _users = [
    {
      'id': 'U001',
      'name': 'Sarah SuperAdmin',
      'email': 'superadmin@farm.com',
      'role': 'Super Admin',
      'status': 'Active',
      'department': 'Administration',
      'joined': '2024-01-01'
    },
    {
      'id': 'U002',
      'name': 'John Admin',
      'email': 'admin@farm.com',
      'role': 'Admin',
      'status': 'Active',
      'department': 'Management',
      'joined': '2024-01-15'
    },
    {
      'id': 'U003',
      'name': 'Alice Owner',
      'email': 'owner@farm.com',
      'role': 'Owner',
      'status': 'Active',
      'department': 'Farm Operations',
      'joined': '2024-02-01'
    },
    {
      'id': 'U004',
      'name': 'Bob Caretaker',
      'email': 'caretaker@farm.com',
      'role': 'Caretaker',
      'status': 'Active',
      'department': 'Field Work',
      'joined': '2024-02-10'
    },
    {
      'id': 'U005',
      'name': 'John Smith',
      'email': 'john@example.com',
      'role': 'Caretaker',
      'status': 'Pending',
      'department': 'Field Work',
      'joined': '2024-10-28'
    },
    {
      'id': 'U006',
      'name': 'Mary Johnson',
      'email': 'mary@example.com',
      'role': 'Owner',
      'status': 'Pending',
      'department': 'Farm Operations',
      'joined': '2024-10-29'
    },
    {
      'id': 'U007',
      'name': 'Tom Davis',
      'email': 'tom@example.com',
      'role': 'Caretaker',
      'status': 'Suspended',
      'department': 'Field Work',
      'joined': '2024-03-15'
    },
    {
      'id': 'U008',
      'name': 'Emma Wilson',
      'email': 'emma@example.com',
      'role': 'Owner',
      'status': 'Active',
      'department': 'Farm Operations',
      'joined': '2024-04-01'
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth < 1200 && screenWidth >= 600;

    final filteredUsers = _selectedFilter == 'All'
        ? _users
        : _users.where((u) => u['status'] == _selectedFilter).toList();

    final userName = user?.name ?? 'Super Admin';
    final userEmail = user?.email ?? '';
    final firstName = userName.split(' ').first;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      drawer: isMobile
          ? SuperAdminDrawer(
              selectedIndex: _selectedNavIndex,
              onItemSelected: (index) {
                setState(() => _selectedNavIndex = index);
              },
              userName: userName,
              userEmail: userEmail,
              userRole: 'Super Administrator',
            )
          : null,
      body: isMobile
          ? _buildMobileLayout(
              isDark: isDark,
              filteredUsers: filteredUsers,
              firstName: firstName,
            )
          : _buildDesktopLayout(
              isDark: isDark,
              filteredUsers: filteredUsers,
              userName: userName,
              userEmail: userEmail,
              firstName: firstName,
              isTablet: isTablet,
            ),
    );
  }

  Widget _buildDesktopLayout({
    required bool isDark,
    required List<Map<String, dynamic>> filteredUsers,
    required String userName,
    required String userEmail,
    required String firstName,
    required bool isTablet,
  }) {
    return Row(
      children: [
        SuperAdminSidebar(
          selectedIndex: 1,
          onItemSelected: (_) {},
          userName: userName,
          userEmail: userEmail,
          userRole: 'Super Administrator',
        ),
        Expanded(
          child: Column(
            children: [
              ModernAdminHeader(
                userName: firstName,
                onNotificationTap: () {},
                onProfileTap: () {},
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: _buildUserContent(
                    isDark: isDark,
                    filteredUsers: filteredUsers,
                    isCompact: isTablet,
                    isMobile: false,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout({
    required bool isDark,
    required List<Map<String, dynamic>> filteredUsers,
    required String firstName,
  }) {
    return Column(
      children: [
        ModernAdminHeader(
          userName: firstName,
          onNotificationTap: () {},
          onProfileTap: () {},
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: _buildUserContent(
              isDark: isDark,
              filteredUsers: filteredUsers,
              isCompact: true,
              isMobile: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserContent({
    required bool isDark,
    required List<Map<String, dynamic>> filteredUsers,
    required bool isCompact,
    required bool isMobile,
  }) {
    final sectionSpacing = isMobile ? AppSpacing.lg : AppSpacing.xl;
    final statsColumns = isMobile ? 2 : (isCompact ? 2 : 4);
    final statsRatio = isMobile ? 1.8 : (isCompact ? 2.2 : 2.6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeaderSection(isDark, isCompact),
        SizedBox(height: sectionSpacing),
        _buildStats(
          isDark,
          crossAxisCount: statsColumns,
          childAspectRatio: statsRatio,
        ),
        SizedBox(height: sectionSpacing),
        _buildFilters(isDark),
        const SizedBox(height: AppSpacing.lg),
        if (isCompact)
          _buildUserCards(filteredUsers, isDark)
        else
          _buildUserTable(filteredUsers, isDark),
      ],
    );
  }

  Widget _buildHeaderSection(bool isDark, bool isCompact) {
    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User Management',
            style: AppTypography.h5.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage users, approve registrations, and assign roles',
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showAddUserDialog(context, isDark),
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('Add User'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Management',
              style: AppTypography.h4.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            Text(
              'Manage users, approve registrations, and assign roles',
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _showAddUserDialog(context, isDark),
          icon: const Icon(Icons.person_add, size: 20),
          label: const Text('Add User'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          ),
        ),
      ],
    );
  }

  Widget _buildUserTable(
      List<Map<String, dynamic>> filteredUsers, bool isDark) {
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
            children: [
              Expanded(
                child: Text(
                  'All Users',
                  style: AppTypography.h6.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${filteredUsers.length} records',
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? Colors.white60 : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildUserTableHeader(isDark),
          const SizedBox(height: AppSpacing.sm),
          ...filteredUsers.map((u) => _buildUserRow(u, isDark)),
        ],
      ),
    );
  }

  Widget _buildUserTableHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.04),
        ),
      ),
      child: Row(
        children: [
          _buildTableHeader('User', flex: 3, isDark: isDark),
          _buildTableHeader('Role', isDark: isDark),
          _buildTableHeader('Department', flex: 2, isDark: isDark),
          _buildTableHeader('Status', isDark: isDark),
          _buildTableHeader('Joined', isDark: isDark),
          const SizedBox(width: 88),
        ],
      ),
    );
  }

  Widget _buildTableHeader(
    String label, {
    int flex = 1,
    required bool isDark,
  }) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: AppTypography.bodySmall.copyWith(
          color: isDark ? Colors.white54 : AppColors.textSecondary,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(color: color.withOpacity(0.22)),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildUserActionButtons(Map<String, dynamic> user, bool isDark) {
    final isPending = user['status'] == 'Pending';
    return SizedBox(
      width: 88,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (isPending) ...[
            _buildTableIconAction(
              Icons.check_circle,
              AppColors.success,
              () => _approveUser(user),
              'Approve',
            ),
            _buildTableIconAction(
              Icons.cancel,
              AppColors.error,
              () => _rejectUser(user),
              'Reject',
            ),
          ] else ...[
            _buildTableIconAction(
              Icons.edit_outlined,
              AppColors.primary,
              () => _showEditUserDialog(context, user, isDark),
              'Edit',
            ),
            _buildTableIconAction(
              user['status'] == 'Suspended'
                  ? Icons.check_circle_outline
                  : Icons.block,
              user['status'] == 'Suspended'
                  ? AppColors.success
                  : AppColors.error,
              () => _toggleSuspend(user),
              user['status'] == 'Suspended' ? 'Activate' : 'Suspend',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTableIconAction(
    IconData icon,
    Color color,
    VoidCallback onPressed,
    String tooltip,
  ) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        color: color,
        tooltip: tooltip,
      ),
    );
  }

  Widget _buildUserCards(
      List<Map<String, dynamic>> filteredUsers, bool isDark) {
    return Column(
      children: [
        for (final user in filteredUsers) _buildMobileUserCard(user, isDark),
      ],
    );
  }

  Widget _buildStats(
    bool isDark, {
    required int crossAxisCount,
    required double childAspectRatio,
  }) {
    final stats = [
      {
        'title': 'Total Users',
        'value': '248',
        'icon': Icons.people,
        'color': AppColors.primary
      },
      {
        'title': 'Active',
        'value': '235',
        'icon': Icons.check_circle,
        'color': AppColors.success
      },
      {
        'title': 'Pending Approval',
        'value': '7',
        'icon': Icons.pending,
        'color': AppColors.warning
      },
      {
        'title': 'Suspended',
        'value': '6',
        'icon': Icons.block,
        'color': AppColors.error
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: (stat['color'] as Color).withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border:
                Border.all(color: (stat['color'] as Color).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (stat['color'] as Color).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(stat['icon'] as IconData,
                    color: stat['color'] as Color, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      stat['value'] as String,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: stat['color'] as Color),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      stat['title'] as String,
                      style: TextStyle(
                          fontSize: 11,
                          color: (stat['color'] as Color).withOpacity(0.8)),
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
    );
  }

  Widget _buildFilters(bool isDark) {
    final filters = ['All', 'Active', 'Pending', 'Suspended'];

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: filters.map((filter) {
        final isSelected = _selectedFilter == filter;
        return ChoiceChip(
          label: Text(filter),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) setState(() => _selectedFilter = filter);
          },
          selectedColor: AppColors.primary.withOpacity(0.2),
          backgroundColor:
              isDark ? Colors.white.withOpacity(0.05) : AppColors.neutral100,
          labelStyle: TextStyle(
            color: isSelected
                ? AppColors.primary
                : (isDark ? Colors.white70 : AppColors.textSecondary),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildUserRow(Map<String, dynamic> user, bool isDark) {
    final statusColor = _statusColor(user['status']);
    final roleColor = _roleColor(user['role']);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.04),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    user['name'].toString().substring(0, 1),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user['name'],
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textPrimary)),
                      Text('${user['id']} • ${user['email']}',
                          style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.white54
                                  : AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildBadge(user['role'], roleColor)),
          Expanded(
            flex: 2,
            child: Text(
              user['department'],
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(child: _buildBadge(user['status'], statusColor)),
          Expanded(
            child: Text(user['joined'],
                style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : AppColors.textSecondary)),
          ),
          _buildUserActionButtons(user, isDark),
        ],
      ),
    );
  }

  Widget _buildMobileUserCard(Map<String, dynamic> user, bool isDark) {
    final statusColor = _statusColor(user['status']);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Text(
                  user['name'].toString().substring(0, 1),
                  style: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['name'],
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user['email'],
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isDark ? Colors.white60 : AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                  user['status'],
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _buildInfoPill('Role', user['role'], isDark),
              _buildInfoPill('Dept', user['department'], isDark),
              _buildInfoPill('Joined', user['joined'], isDark),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
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
                    icon: Icon(
                        user['status'] == 'Suspended'
                            ? Icons.check_circle_outline
                            : Icons.block,
                        size: 18),
                    color: user['status'] == 'Suspended'
                        ? AppColors.success
                        : AppColors.error,
                    tooltip:
                        user['status'] == 'Suspended' ? 'Activate' : 'Suspend',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPill(String label, String value, bool isDark) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : AppColors.neutral100,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 11,
          color: isDark ? Colors.white70 : AppColors.textSecondary,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Active':
        return AppColors.success;
      case 'Pending':
        return AppColors.warning;
      case 'Suspended':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'Super Admin':
        return AppColors.primary;
      case 'Admin':
        return AppColors.info;
      case 'Owner':
        return AppColors.success;
      case 'Caretaker':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
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
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    String selectedRole = 'Caretaker';
    String selectedDepartment = 'Field Work';
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl)),
          insetPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? AppSpacing.md : AppSpacing.xxl,
            vertical: AppSpacing.xl,
          ),
          child: Container(
            width: isMobile ? double.infinity : 480,
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.8)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppSpacing.radiusXl)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: const Icon(Icons.person_add,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add New User',
                              style: AppTypography.h6.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Create a new user account',
                              style: AppTypography.bodySmall
                                  .copyWith(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white70),
                      ),
                    ],
                  ),
                ),

                // Form Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Full Name Field
                        _buildFormLabel('Full Name', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildTextField(
                          controller: nameController,
                          hint: 'Enter full name',
                          icon: Icons.person_outline,
                          isDark: isDark,
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Email Field
                        _buildFormLabel('Email Address', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildTextField(
                          controller: emailController,
                          hint: 'Enter email address',
                          icon: Icons.email_outlined,
                          isDark: isDark,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Role Dropdown
                        _buildFormLabel('Role', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildDropdownField(
                          value: selectedRole,
                          items: ['Super Admin', 'Admin', 'Owner', 'Caretaker'],
                          icon: Icons.badge_outlined,
                          isDark: isDark,
                          onChanged: (value) =>
                              setDialogState(() => selectedRole = value!),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Department Dropdown
                        _buildFormLabel('Department', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildDropdownField(
                          value: selectedDepartment,
                          items: [
                            'Administration',
                            'Management',
                            'Farm Operations',
                            'Field Work'
                          ],
                          icon: Icons.business_outlined,
                          isDark: isDark,
                          onChanged: (value) =>
                              setDialogState(() => selectedDepartment = value!),
                        ),
                      ],
                    ),
                  ),
                ),

                // Actions
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.03)
                        : AppColors.neutral50,
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(AppSpacing.radiusXl)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md),
                            side: BorderSide(
                                color: isDark
                                    ? Colors.white24
                                    : AppColors.neutral300),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusMd)),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                                color: isDark
                                    ? Colors.white70
                                    : AppColors.textSecondary),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.check_circle,
                                        color: Colors.white),
                                    const SizedBox(width: 8),
                                    Text(
                                        '${nameController.text.isEmpty ? "User" : nameController.text} added successfully!'),
                                  ],
                                ),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusMd)),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add User'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusMd)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditUserDialog(
      BuildContext context, Map<String, dynamic> user, bool isDark) {
    final nameController = TextEditingController(text: user['name']);
    final emailController = TextEditingController(text: user['email']);
    String selectedRole = user['role'];
    String selectedDepartment = user['department'];
    String selectedStatus = user['status'];
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl)),
          insetPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? AppSpacing.md : AppSpacing.xxl,
            vertical: AppSpacing.xl,
          ),
          child: Container(
            width: isMobile ? double.infinity : 480,
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.8)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppSpacing.radiusXl)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: const Icon(Icons.edit,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Edit User',
                              style: AppTypography.h6.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Update user information',
                              style: AppTypography.bodySmall
                                  .copyWith(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white70),
                      ),
                    ],
                  ),
                ),

                // User Info Preview
                Container(
                  margin: const EdgeInsets.all(AppSpacing.lg),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : AppColors.neutral50,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                        color: isDark
                            ? Colors.white10
                            : Colors.black.withOpacity(0.08)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: Text(
                          user['name'].toString().substring(0, 1),
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user['name'],
                              style: AppTypography.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'ID: ${user['id']} • Joined: ${user['joined']}',
                              style: AppTypography.bodySmall.copyWith(
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
                ),

                // Form Content
                Flexible(
                  child: SingleChildScrollView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Full Name Field
                        _buildFormLabel('Full Name', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildTextField(
                          controller: nameController,
                          hint: 'Enter full name',
                          icon: Icons.person_outline,
                          isDark: isDark,
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Email Field
                        _buildFormLabel('Email Address', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildTextField(
                          controller: emailController,
                          hint: 'Enter email address',
                          icon: Icons.email_outlined,
                          isDark: isDark,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Role & Status Row
                        if (!isMobile)
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFormLabel('Role', isDark),
                                    const SizedBox(height: AppSpacing.sm),
                                    _buildDropdownField(
                                      value: selectedRole,
                                      items: [
                                        'Super Admin',
                                        'Admin',
                                        'Owner',
                                        'Caretaker'
                                      ],
                                      icon: Icons.badge_outlined,
                                      isDark: isDark,
                                      onChanged: (value) => setDialogState(
                                          () => selectedRole = value!),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFormLabel('Status', isDark),
                                    const SizedBox(height: AppSpacing.sm),
                                    _buildDropdownField(
                                      value: selectedStatus,
                                      items: ['Active', 'Pending', 'Suspended'],
                                      icon: Icons.toggle_on_outlined,
                                      isDark: isDark,
                                      onChanged: (value) => setDialogState(
                                          () => selectedStatus = value!),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        else ...[
                          _buildFormLabel('Role', isDark),
                          const SizedBox(height: AppSpacing.sm),
                          _buildDropdownField(
                            value: selectedRole,
                            items: [
                              'Super Admin',
                              'Admin',
                              'Owner',
                              'Caretaker'
                            ],
                            icon: Icons.badge_outlined,
                            isDark: isDark,
                            onChanged: (value) =>
                                setDialogState(() => selectedRole = value!),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _buildFormLabel('Status', isDark),
                          const SizedBox(height: AppSpacing.sm),
                          _buildDropdownField(
                            value: selectedStatus,
                            items: ['Active', 'Pending', 'Suspended'],
                            icon: Icons.toggle_on_outlined,
                            isDark: isDark,
                            onChanged: (value) =>
                                setDialogState(() => selectedStatus = value!),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.lg),

                        // Department Dropdown
                        _buildFormLabel('Department', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildDropdownField(
                          value: selectedDepartment,
                          items: [
                            'Administration',
                            'Management',
                            'Farm Operations',
                            'Field Work'
                          ],
                          icon: Icons.business_outlined,
                          isDark: isDark,
                          onChanged: (value) =>
                              setDialogState(() => selectedDepartment = value!),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  ),
                ),

                // Actions
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.03)
                        : AppColors.neutral50,
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(AppSpacing.radiusXl)),
                  ),
                  child: Row(
                    children: [
                      // Delete Button
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showDeleteConfirmDialog(context, user, isDark);
                        },
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Delete'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                              horizontal: AppSpacing.md),
                          side: BorderSide(
                              color: AppColors.error.withOpacity(0.5)),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusMd)),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md),
                            side: BorderSide(
                                color: isDark
                                    ? Colors.white24
                                    : AppColors.neutral300),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusMd)),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                                color: isDark
                                    ? Colors.white70
                                    : AppColors.textSecondary),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.check_circle,
                                        color: Colors.white),
                                    const SizedBox(width: 8),
                                    Text(
                                        '${nameController.text} updated successfully!'),
                                  ],
                                ),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusMd)),
                              ),
                            );
                          },
                          icon: const Icon(Icons.save, size: 18),
                          label: const Text('Save'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusMd)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(
      BuildContext context, Map<String, dynamic> user, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_forever,
                    color: AppColors.error, size: 40),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Delete User?',
                style: AppTypography.h5.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Are you sure you want to delete ${user['name']}? This action cannot be undone.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        side: BorderSide(
                            color:
                                isDark ? Colors.white24 : AppColors.neutral300),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd)),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                            color: isDark
                                ? Colors.white70
                                : AppColors.textSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.delete, color: Colors.white),
                                const SizedBox(width: 8),
                                Text('${user['name']} deleted'),
                              ],
                            ),
                            backgroundColor: AppColors.error,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusMd)),
                          ),
                        );
                      },
                      icon: const Icon(Icons.delete, size: 18),
                      label: const Text('Delete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widgets for form fields
  Widget _buildFormLabel(String label, bool isDark) {
    return Text(
      label,
      style: AppTypography.bodyMedium.copyWith(
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : AppColors.textPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: isDark
                ? Colors.white38
                : AppColors.textSecondary.withOpacity(0.5)),
        prefixIcon: Icon(icon,
            color: isDark ? Colors.white54 : AppColors.textSecondary, size: 20),
        filled: true,
        fillColor:
            isDark ? Colors.white.withOpacity(0.05) : AppColors.neutral50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide:
              BorderSide(color: isDark ? Colors.white12 : AppColors.neutral200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide:
              BorderSide(color: isDark ? Colors.white12 : AppColors.neutral200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
      ),
    );
  }

  Widget _buildDropdownField({
    required String value,
    required List<String> items,
    required IconData icon,
    required bool isDark,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border:
            Border.all(color: isDark ? Colors.white12 : AppColors.neutral200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down,
              color: isDark ? Colors.white54 : AppColors.textSecondary),
          dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
          style: TextStyle(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontSize: 14),
          items: items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Row(
                      children: [
                        Icon(icon,
                            color: isDark
                                ? Colors.white54
                                : AppColors.textSecondary,
                            size: 20),
                        const SizedBox(width: AppSpacing.md),
                        Text(item),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
