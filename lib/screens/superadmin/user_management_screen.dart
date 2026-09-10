import '../../core/widgets/create_user_modal.dart';
import '../../core/widgets/user_search_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/superadmin_sidebar.dart';
import '../../core/widgets/modern_admin_header.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../providers/auth_provider.dart';
import '../../services/superadmin_api_service.dart';

/// Super Admin User Management - Manage all users with approval workflow
class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  static const List<String> _roleOptions = [
    'Super Admin',
    'Admin',
    'Farm Manager',
    'Owner',
    'Caretaker',
    'Technicians',
    'Fulfillment Manager',
    'Packaging Supervisor',
    'Quality Officer',
    'Sales Manager',
    'Sales Person',
    'Accountant',
    'Driver',
  ];
  static const List<String> _departmentOptions = [
    'Executive',
    'Administration',
    'Management',
    'Farm Operations',
    'Ownership',
    'Daily Operations',
    'Field Work',
    'Maintenance',
    'Fulfillment',
    'Packaging',
    'Quality Assurance',
    'Sales',
    'Finance',
    'Logistics',
  ];

  String _selectedFilter = 'All';
  String _searchQuery = '';
  final Map<String, String> _userActions = {};
  int _selectedNavIndex = 1;
  bool _isLoadingUsers = false;
  String? _usersError;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final SuperAdminApiService _api = SuperAdminApiService();

  final List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoadingUsers = true;
      _usersError = null;
    });

    try {
      final users = await _api.getUsers();
      if (!mounted) return;
      setState(() {
        _users
          ..clear()
          ..addAll(users.map(_mapUserDocument));
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _usersError = error.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoadingUsers = false);
      }
    }
  }

  Map<String, dynamic> _mapUserDocument(Map<String, dynamic> doc) {
    final role = _roleLabel(doc['role']);
    return {
      'id': (doc[r'$id'] ?? doc['user_id'] ?? doc['id'] ?? '').toString(),
      'name': (doc['name'] ?? 'Unnamed User').toString(),
      'email': (doc['email'] ?? '').toString(),
      'role': role,
      'status': _statusLabel(doc['status']),
      'department': (doc['department'] ?? _departmentForRole(role)).toString(),
      'joined': _dateLabel(doc[r'$createdAt'] ?? doc['created_at']),
      'password': (doc['password'] ?? '').toString(),
      'address': (doc['address'] ?? '').toString(),
      'phone': (doc['phone'] ?? '').toString(),
      'driverLicenseNumber': (doc['driver_license_number'] ?? '').toString(),
      'vehicle': (doc['vehicle'] ?? '').toString(),
      'vehicleType': (doc['vehicle_type'] ?? '').toString(),
      'vehicleCapacityKg': (doc['vehicle_capacity_kg'] ?? 0).toString(),
    };
  }

  String _roleLabel(dynamic value) {
    final raw = value?.toString() ?? '';
    switch (raw.toLowerCase()) {
      case 'superadmin':
      case 'super_admin':
        return 'Super Admin';
      case 'admin':
        return 'Admin';
      case 'farm_manager':
        return 'Farm Manager';
      case 'farm_owner':
      case 'owner':
        return 'Owner';
      case 'caretaker':
        return 'Caretaker';
      case 'technicians':
      case 'technician':
        return 'Technicians';
      case 'fulfillment_manager':
        return 'Fulfillment Manager';
      case 'packaging_supervisor':
        return 'Packaging Supervisor';
      case 'quality_officer':
      case 'quality_assurance':
        return 'Quality Officer';
      case 'sales_manager':
        return 'Sales Manager';
      case 'sales_person':
      case 'sales_personnel':
        return 'Sales Person';
      case 'accountant':
        return 'Accountant';
      case 'driver':
        return 'Driver';
      default:
        final label = _labelFromSnakeCase(raw);
        return _roleOptions.contains(label) ? label : 'Caretaker';
    }
  }

  String _labelFromSnakeCase(String value) {
    return value
        .replaceAll('_', ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  String _statusLabel(dynamic value) {
    if (value == null || value.toString().isEmpty) return 'Active';
    return _labelFromSnakeCase(value.toString());
  }

  String _departmentForRole(String role) {
    final normalized = role.toLowerCase();
    if (normalized.contains('admin')) return 'Administration';
    if (normalized.contains('sales')) return 'Sales';
    if (normalized.contains('driver')) return 'Logistics';
    if (normalized.contains('accountant')) return 'Finance';
    if (normalized.contains('packaging')) return 'Packaging';
    if (normalized.contains('quality')) return 'Quality Assurance';
    if (normalized.contains('fulfillment')) return 'Fulfillment';
    return 'Farm Operations';
  }

  String _dateLabel(dynamic value) {
    final text = value?.toString() ?? '';
    if (text.length >= 10) return text.substring(0, 10);
    return text.isEmpty ? '-' : text;
  }

  String _roleValue(String label) {
    switch (label) {
      case 'Super Admin':
        return 'superadmin';
      case 'Admin':
        return 'admin';
      case 'Farm Manager':
        return 'farm_manager';
      case 'Owner':
        return 'farm_owner';
      case 'Caretaker':
        return 'caretaker';
      case 'Technicians':
        return 'technician';
      case 'Fulfillment Manager':
        return 'fulfillment_manager';
      case 'Packaging Supervisor':
        return 'packaging_supervisor';
      case 'Quality Officer':
        return 'quality_officer';
      case 'Sales Manager':
        return 'sales_manager';
      case 'Sales Person':
        return 'sales_person';
      case 'Accountant':
        return 'accountant';
      case 'Driver':
        return 'driver';
      default:
        return 'caretaker';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth < 1200 && screenWidth >= 600;

    final query = _searchQuery.trim().toLowerCase();
    final filteredUsers = _users.where((user) {
      if (_selectedFilter != 'All' && user['status'] != _selectedFilter)
        return false;
      final searchable = ['name', 'email', 'role', 'department', 'phone']
          .map((key) => (user[key] ?? '').toString())
          .join(' ')
          .toLowerCase();
      return query.isEmpty || searchable.contains(query);
    }).toList();

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
      bottomNavigationBar: isMobile
          ? SuperAdminMobileBottomNav(
              selectedIndex: 1,
              onItemSelected: (_) {},
            )
          : null,
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
                onProfileTap: () => Navigator.of(context).pushNamed('/profile'),
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
          onProfileTap: () => Navigator.of(context).pushNamed('/profile'),
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
        SizedBox(height: isMobile ? 8 : sectionSpacing),
        _buildStats(
          isDark,
          crossAxisCount: statsColumns,
          childAspectRatio: statsRatio,
          isMobile: isMobile,
        ),
        SizedBox(height: sectionSpacing),
        UserSearchField(
            value: _searchQuery,
            onChanged: (value) => setState(() => _searchQuery = value)),
        const SizedBox(height: 12),
        _buildFilters(isDark),
        const SizedBox(height: AppSpacing.lg),
        if (_usersError != null) ...[
          _buildSyncStatus(isDark),
          const SizedBox(height: AppSpacing.md),
        ],
        if (_isLoadingUsers && _users.isEmpty)
          const AdminDataSkeleton(showStats: false)
        else if (filteredUsers.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            child: const Column(children: [
              Icon(Icons.search_off_rounded, size: 28),
              SizedBox(height: 8),
              Text('No users found'),
              SizedBox(height: 4),
              Text('Try another search or status filter.',
                  textAlign: TextAlign.center),
            ]),
          )
        else if (isCompact)
          _buildUserCards(filteredUsers, isDark, isMobile: isMobile)
        else
          _buildUserTable(filteredUsers, isDark),
      ],
    );
  }

  Widget _buildSyncStatus(bool isDark) {
    final hasError = _usersError != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: hasError
            ? AppColors.error.withOpacity(0.08)
            : AppColors.info.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.error),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Could not refresh users: $_usersError',
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Refresh users',
            onPressed: _isLoadingUsers ? null : _loadUsers,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
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
              fontWeight: FontWeight.w600,
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
                fontWeight: FontWeight.w600,
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
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${filteredUsers.length} records',
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? Colors.white60 : AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildUserTableHeader(isDark),
          const SizedBox(height: AppSpacing.sm),
          ...filteredUsers
              .map((u) => _withUserProgress(u, _buildUserRow(u, isDark))),
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
          fontWeight: FontWeight.w500,
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
            fontWeight: FontWeight.w500,
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

  Widget _buildUserCards(List<Map<String, dynamic>> filteredUsers, bool isDark,
      {required bool isMobile}) {
    return Column(
      children: [
        for (var index = 0; index < filteredUsers.length; index++) ...[
          if (isMobile)
            _withUserProgress(filteredUsers[index],
                _buildMobileUserCard(filteredUsers[index], isDark))
          else
            _withUserProgress(filteredUsers[index],
                _buildCompactUserCard(filteredUsers[index], isDark)),
          if (isMobile && index < filteredUsers.length - 1)
            const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildStats(
    bool isDark, {
    required int crossAxisCount,
    required double childAspectRatio,
    required bool isMobile,
  }) {
    final totalUsers = _users.length;
    final activeUsers =
        _users.where((user) => user['status'] == 'Active').length;
    final pendingUsers =
        _users.where((user) => user['status'] == 'Pending').length;
    final suspendedUsers =
        _users.where((user) => user['status'] == 'Suspended').length;
    final stats = [
      {
        'title': 'Total Users',
        'value': totalUsers.toString(),
        'icon': Icons.people,
        'color': AppColors.primary
      },
      {
        'title': 'Active',
        'value': activeUsers.toString(),
        'icon': Icons.check_circle,
        'color': AppColors.success
      },
      {
        'title': 'Pending Approval',
        'value': pendingUsers.toString(),
        'icon': Icons.pending,
        'color': AppColors.warning
      },
      {
        'title': 'Suspended',
        'value': suspendedUsers.toString(),
        'icon': Icons.block,
        'color': AppColors.error
      },
    ];

    return GridView.builder(
      padding: isMobile ? EdgeInsets.zero : null,
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
                          fontWeight: FontWeight.w500,
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
                      fontWeight: FontWeight.w500,
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
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textPrimary)),
                      Text('${user['id']} | ${user['email']}',
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
                fontWeight: FontWeight.w500,
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
    final name = (user['name'] ?? '').toString().trim();
    final initials = name.isEmpty
        ? '?'
        : name
            .split(RegExp(r'\s+'))
            .take(2)
            .map((part) => part.characters.first)
            .join()
            .toUpperCase();
    final status = (user['status'] ?? 'Active').toString();
    final isPending = status == 'Pending';
    final isSuspended = status == 'Suspended';
    final foreground = isDark ? Colors.white : AppColors.textPrimary;
    final secondary = isDark ? Colors.white60 : AppColors.textSecondary;

    Widget detail(IconData icon, String label, dynamic value) {
      final text = (value ?? '').toString().trim();
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: secondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTypography.bodySmall.copyWith(
                        fontSize: 10,
                        color: secondary,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 3),
                Text(text.isEmpty ? 'Not provided' : text,
                    style: AppTypography.bodySmall.copyWith(
                        fontSize: 12,
                        color: foreground,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: isDark ? Colors.white10 : AppColors.neutral200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.10 : 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(initials,
                    style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.primary, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name.isEmpty ? 'Unnamed User' : name,
                      style: AppTypography.bodyMedium.copyWith(
                          fontSize: 14,
                          color: foreground,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text((user['email'] ?? '').toString(),
                      style: AppTypography.bodySmall
                          .copyWith(fontSize: 12, color: secondary)),
                ],
              )),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMobileUserBadge((user['role'] ?? '').toString(),
                  _roleColor((user['role'] ?? '').toString())),
              _buildMobileUserBadge(status, _statusColor(status)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Divider(
                height: 1,
                color: isDark ? Colors.white10 : AppColors.neutral200),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  child: detail(Icons.business_outlined, 'Department',
                      user['department'])),
              const SizedBox(width: 12),
              Expanded(
                  child: detail(
                      Icons.calendar_today_outlined, 'Joined', user['joined'])),
            ],
          ),
          if (user['role'] == 'Driver') ...[
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    child: detail(Icons.local_shipping_outlined, 'Vehicle',
                        user['vehicle'])),
                const SizedBox(width: 12),
                Expanded(
                    child: detail(Icons.scale_outlined, 'Capacity',
                        '${user['vehicleCapacityKg'] ?? 0} kg')),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
                child: OutlinedButton.icon(
              onPressed: () =>
                  isPending ? _rejectUser(user) : _toggleSuspend(user),
              icon: Icon(
                  isPending
                      ? Icons.close_rounded
                      : (isSuspended
                          ? Icons.check_circle_outline
                          : Icons.block),
                  size: 16),
              label: Text(isPending
                  ? 'Reject'
                  : (isSuspended ? 'Activate' : 'Suspend')),
              style: OutlinedButton.styleFrom(
                foregroundColor:
                    isSuspended ? AppColors.success : AppColors.error,
                minimumSize: const Size(0, 44),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                textStyle: AppTypography.bodySmall
                    .copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                side: BorderSide(
                    color: isDark ? Colors.white12 : AppColors.neutral200),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            )),
            const SizedBox(width: 10),
            Expanded(
                child: FilledButton.icon(
              onPressed: () => isPending
                  ? _approveUser(user)
                  : _showEditUserDialog(context, user, isDark),
              icon: Icon(isPending ? Icons.check_rounded : Icons.edit_outlined,
                  size: 16),
              label: Text(isPending ? 'Approve' : 'Edit user'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 44),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                textStyle: AppTypography.bodySmall
                    .copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            )),
          ]),
        ],
      ),
    );
  }

  Widget _buildMobileUserBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: AppTypography.bodySmall.copyWith(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _buildCompactUserCard(Map<String, dynamic> user, bool isDark) {
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
                      color: AppColors.primary, fontWeight: FontWeight.w500),
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
                        fontWeight: FontWeight.w500,
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
                      fontWeight: FontWeight.w500),
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
              if (user['role'] == 'Driver')
                _buildInfoPill(
                  'Vehicle',
                  user['vehicle'].toString().isEmpty
                      ? 'Pending'
                      : user['vehicle'],
                  isDark,
                ),
              if (user['role'] == 'Driver')
                _buildInfoPill(
                  'Capacity',
                  '${user['vehicleCapacityKg']} kg',
                  isDark,
                ),
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

  Widget _withUserProgress(Map<String, dynamic> user, Widget child) {
    final label = _userActions[user['id'].toString()];
    return Stack(children: [
      AbsorbPointer(absorbing: label != null, child: child),
      if (label != null)
        Positioned.fill(
            child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(12)),
          child: Semantics(
              liveRegion: true,
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: 10),
                Text(label,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ])),
        )),
    ]);
  }

  Future<void> _approveUser(Map<String, dynamic> user) async {
    await _updateUserStatus(user, 'Active', 'approved');
  }

  Future<void> _rejectUser(Map<String, dynamic> user) async {
    await _updateUserStatus(user, 'Suspended', 'rejected');
  }

  Future<void> _toggleSuspend(Map<String, dynamic> user) async {
    final nextStatus = user['status'] == 'Suspended' ? 'Active' : 'Suspended';
    final action = nextStatus == 'Active' ? 'activated' : 'suspended';
    await _updateUserStatus(user, nextStatus, action);
  }

  Future<void> _updateUserStatus(
    Map<String, dynamic> user,
    String status,
    String action,
  ) async {
    final id = user['id'].toString();
    if (_userActions.containsKey(id)) return;
    setState(() =>
        _userActions[id] = action == 'approved' ? 'Approving…' : 'Updating…');
    final messenger = ScaffoldMessenger.of(context);
    final actor = ref.read(authProvider).user;
    try {
      await _api.updateUser(
        id: user['id'].toString(),
        name: user['name']?.toString() ?? '',
        email: user['email']?.toString() ?? '',
        password: '',
        address: user['address']?.toString() ?? '',
        role: _roleValueFromUser(user),
        phone: user['phone']?.toString() ?? '',
        department: _departmentFromUser(user),
        status: status,
        actorId: actor?.id ?? '',
        actorRole: 'superadmin',
        driverLicenseNumber: user['driverLicenseNumber']?.toString() ?? '',
        vehicle: user['vehicle']?.toString() ?? '',
        vehicleType: user['vehicleType']?.toString() ?? '',
        vehicleCapacityKg:
            double.tryParse(user['vehicleCapacityKg']?.toString() ?? '') ?? 0,
      );
      if (!mounted) return;
      await _loadUsers();
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('${user['name']} $action successfully.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Update failed: ${error.toString()}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _userActions.remove(id));
    }
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _api.deleteUser(user['id'].toString());
      if (!mounted) return;
      await _loadUsers();
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('${user['name']} deleted.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Delete failed: ${error.toString()}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _createUser({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String address,
    required String status,
    required String role,
    required String department,
    required String driverLicenseNumber,
    required String vehicle,
    required String vehicleType,
    required double vehicleCapacityKg,
  }) async {
    final actor = ref.read(authProvider).user;
    await _api.createUser(
      name: name,
      email: email,
      password: password,
      address: address,
      role: _roleValue(role),
      phone: phone,
      department: department,
      status: status,
      actorId: actor?.id ?? '',
      actorRole: 'superadmin',
      driverLicenseNumber: driverLicenseNumber,
      vehicle: vehicle,
      vehicleType: vehicleType,
      vehicleCapacityKg: vehicleCapacityKg,
    );
    if (mounted) await _loadUsers();
  }

  String _roleValueFromUser(Map<String, dynamic> user) {
    final rawRole = user['role']?.toString() ?? '';
    const backendRoles = {
      'superadmin',
      'admin',
      'farm_manager',
      'farm_owner',
      'caretaker',
      'technician',
      'fulfillment_manager',
      'packaging_supervisor',
      'quality_officer',
      'sales_manager',
      'sales_person',
      'accountant',
      'driver',
    };
    if (backendRoles.contains(rawRole)) return rawRole;
    return _roleValue(rawRole);
  }

  String _departmentFromUser(Map<String, dynamic> user) {
    final department = user['department']?.toString() ?? '';
    if (department.isNotEmpty) return department;
    return _departmentForRole(_roleLabel(user['role']));
  }

  String _safeRequired(String? value, String fallback) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  Future<void> _showAddUserDialog(BuildContext context, bool isDark) async {
    final saved = await showCreateUserModal(context,
        roles: _roleOptions,
        departments: _roleOptions.map(_departmentForRole).toSet().toList(),
        includeAccountFields: true,
        departmentForRole: _departmentForRole,
        onSubmit: (values) => _createUser(
              name: values['name'] as String,
              email: values['email'] as String,
              password: values['password'] as String,
              phone: _safeRequired(values['phone'] as String, '+233000000000'),
              address:
                  _safeRequired(values['address'] as String, 'Farm Estates'),
              status: values['status'] as String,
              role: values['role'] as String,
              department: values['department'] as String,
              driverLicenseNumber: values['license'] as String,
              vehicle: values['vehicle'] as String,
              vehicleType: values['vehicleType'] as String,
              vehicleCapacityKg: values['capacity'] as double,
            ));
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('User created successfully.'),
          backgroundColor: AppColors.success));
    }
  }

  Future<void> _showEditUserDialog(
      BuildContext context, Map<String, dynamic> user, bool isDark) async {
    final role = _roleLabel(user['role']);
    final saved = await showCreateUserModal(context,
        roles: _roleOptions,
        departments: _departmentOptions,
        initialValues: {
          'name': user['name'],
          'email': user['email'],
          'role': role,
          'department': _departmentOptions.contains(user['department'])
              ? user['department']
              : _departmentForRole(role),
          'status': user['status'],
          'license': user['driverLicenseNumber'],
          'vehicle': user['vehicle'],
          'vehicleType': user['vehicleType'],
          'capacity': user['vehicleCapacityKg'],
        }, onDelete: () {
      if (context.mounted) _showDeleteConfirmDialog(context, user, isDark);
    }, onSubmit: (values) async {
      final actor = ref.read(authProvider).user;
      await _api.updateUser(
        id: user['id'].toString(),
        name: values['name'] as String,
        email: values['email'] as String,
        password: values['password'] as String? ?? '',
        address: _safeRequired(user['address']?.toString(), 'Farm Estates'),
        phone: _safeRequired(user['phone']?.toString(), '+233000000000'),
        role: _roleValue(values['role'] as String),
        department: values['department'] as String,
        status: values['status'] as String,
        actorId: actor?.id ?? '',
        actorRole: 'superadmin',
        driverLicenseNumber: values['license'] as String,
        vehicle: values['vehicle'] as String,
        vehicleType: values['vehicleType'] as String,
        vehicleCapacityKg: values['capacity'] as double,
      );
      if (mounted) await _loadUsers();
    });
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('User updated successfully.'),
          backgroundColor: AppColors.success));
    }
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
                  fontWeight: FontWeight.w600,
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
                      onPressed: () async {
                        Navigator.pop(context);
                        await _deleteUser(user);
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
}
