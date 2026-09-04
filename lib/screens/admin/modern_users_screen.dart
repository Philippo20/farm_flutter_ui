import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/modern_admin_header.dart';
import '../../core/widgets/modern_admin_sidebar.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../providers/auth_provider.dart';
import '../../services/superadmin_api_service.dart';

class ModernUsersScreen extends ConsumerStatefulWidget {
  const ModernUsersScreen({super.key});

  @override
  ConsumerState<ModernUsersScreen> createState() => _ModernUsersScreenState();
}

class _ModernUsersScreenState extends ConsumerState<ModernUsersScreen> {
  final SuperAdminApiService _api = SuperAdminApiService();
  final List<Map<String, dynamic>> _users = [];

  String _searchQuery = '';
  String _selectedRole = 'All';
  String _selectedStatus = 'All';
  bool _isLoading = true;
  String? _loadError;

  static const List<String> _roleOptions = [
    'Admin',
    'Farm Manager',
    'Owner',
    'Caretaker',
    'Technician',
    'Fulfillment Manager',
    'Packaging Supervisor',
    'Quality Officer',
    'Sales Manager',
    'Sales Person',
    'Accountant',
    'Driver',
  ];

  static const List<String> _statusOptions = [
    'Active',
    'Pending',
    'Suspended',
  ];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
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
      setState(() => _loadError = error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _mapUserDocument(Map<String, dynamic> doc) {
    final role = _roleLabel(doc['role']);
    final name = _text(doc['name'], fallback: 'Unnamed User');
    final email = _text(doc['email']);
    return {
      'id': _text(doc[r'$id'] ?? doc['user_id'] ?? doc['id']),
      'name': name,
      'email': email,
      'role': role,
      'roleValue': _roleValue(role),
      'status': _statusLabel(doc['status']),
      'department': _text(
        doc['department'],
        fallback: _departmentForRole(role),
      ),
      'address': _text(doc['address']),
      'phone': _text(doc['phone']),
      'password': _text(doc['password']),
      'driverLicenseNumber': _text(doc['driver_license_number']),
      'vehicle': _text(doc['vehicle']),
      'vehicleType': _text(doc['vehicle_type']),
      'vehicleCapacityKg': _text(doc['vehicle_capacity_kg'], fallback: '0'),
      'joined': _dateLabel(doc[r'$createdAt'] ?? doc['created_at']),
      'lastActive': _dateLabel(doc[r'$updatedAt'] ?? doc['updated_at']),
      'avatar': _initials(name),
    };
  }

  String _text(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  String _roleLabel(dynamic value) {
    final raw = value?.toString().trim() ?? '';
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
        return 'Technician';
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
        return label.isEmpty ? 'Caretaker' : label;
    }
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
      case 'Technician':
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
        return label.toLowerCase().replaceAll(' ', '_');
    }
  }

  String _statusLabel(dynamic value) {
    final status = _labelFromSnakeCase(value?.toString() ?? '');
    if (status == 'Inactive') return 'Suspended';
    return status.isEmpty ? 'Active' : status;
  }

  String _labelFromSnakeCase(String value) {
    return value
        .replaceAll('_', ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
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
    if (normalized.contains('technician')) return 'IoT Operations';
    return 'Farm Operations';
  }

  String _dateLabel(dynamic value) {
    final text = value?.toString() ?? '';
    if (text.isEmpty) return '-';
    final date = DateTime.tryParse(text);
    if (date == null) return text.length > 10 ? text.substring(0, 10) : text;
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  List<Map<String, dynamic>> get _filteredUsers {
    final query = _searchQuery.trim().toLowerCase();
    return _users.where((user) {
      final haystack = [
        user['name'],
        user['email'],
        user['role'],
        user['department'],
        user['phone'],
      ].join(' ').toLowerCase();
      if (query.isNotEmpty && !haystack.contains(query)) return false;
      if (_selectedRole != 'All' && user['role'] != _selectedRole) {
        return false;
      }
      if (_selectedStatus != 'All' && user['status'] != _selectedStatus) {
        return false;
      }
      return true;
    }).toList();
  }

  List<String> get _roleFilterItems {
    final roles = _users.map((u) => u['role'].toString()).toSet().toList()
      ..sort();
    return ['All', ...roles];
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);
    final userName = user?.name ?? 'Admin';
    final userEmail = user?.email ?? '';

    return Scaffold(
      drawer: isMobile
          ? AdminDrawer(
              selectedIndex: 1,
              onItemSelected: (_) {},
              userName: userName,
              userEmail: userEmail,
              userRole: 'Administrator',
            )
          : null,
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: isMobile
          ? _buildMobileLayout(isDark, userName)
          : _buildDesktopLayout(isDark, userName, userEmail),
      bottomNavigationBar: isMobile
          ? AdminMobileBottomNav(selectedIndex: 1, onItemSelected: (_) {})
          : null,
    );
  }

  Widget _buildDesktopLayout(bool isDark, String userName, String userEmail) {
    return Row(
      children: [
        ModernAdminSidebar(
          selectedIndex: 1,
          onItemSelected: (_) {},
          userName: userName,
          userEmail: userEmail,
          userRole: 'Administrator',
        ),
        Expanded(
          child: Column(
            children: [
              ModernAdminHeader(
                userName: userName.split(' ').first,
                onNotificationTap: () {},
                onProfileTap: () => Navigator.of(context).pushNamed('/profile'),
              ),
              Expanded(child: _buildContent(isDark, AppSpacing.xl, false)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(bool isDark, String userName) {
    return Column(
      children: [
        ModernAdminHeader(
          userName: userName.split(' ').first,
          onNotificationTap: () {},
          onProfileTap: () => Navigator.of(context).pushNamed('/profile'),
        ),
        Expanded(child: _buildContent(isDark, AppSpacing.md, true)),
      ],
    );
  }

  Widget _buildContent(bool isDark, double padding, bool isMobile) {
    if (_isLoading) {
      return SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: const AdminDataSkeleton(rowCount: 6),
      );
    }

    if (_loadError != null) {
      return _buildErrorState(isDark, padding);
    }

    final filteredUsers = _filteredUsers;
    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitleRow(isDark, isMobile),
            const SizedBox(height: AppSpacing.xl),
            Transform.translate(
              offset: Offset(0, isMobile ? -70 : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  isMobile
                      ? _buildMobileStatsCards(isDark)
                      : _buildStatsCards(isDark),
                  const SizedBox(height: AppSpacing.xl),
                  _buildControls(isDark, isMobile),
                  const SizedBox(height: AppSpacing.lg),
                  if (isMobile)
                    _buildMobileUsersList(filteredUsers, isDark)
                  else
                    _buildUsersTable(filteredUsers, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isDark, double padding) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08),
          ),
        ),
        child: Column(
          children: [
            const Icon(Icons.cloud_off, color: AppColors.error, size: 42),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Unable to load users',
              style: AppTypography.h6.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _loadError ?? 'Please try again.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: _loadUsers,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleRow(bool isDark, bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'User Management',
                style:
                    (isMobile ? AppTypography.h5 : AppTypography.h4).copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage backend users, roles, and account status',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        ElevatedButton.icon(
          onPressed: () => _showAddUserDialog(context, isDark),
          icon: Icon(Icons.person_add, size: isMobile ? 18 : 20),
          label: Text(isMobile ? 'Add' : 'Add User'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? AppSpacing.md : AppSpacing.lg,
              vertical: isMobile ? AppSpacing.sm : AppSpacing.md,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
        ),
      ],
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
      children: _statCards(isDark),
    );
  }

  Widget _buildMobileStatsCards(bool isDark) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 2.5,
      children: _statCards(isDark),
    );
  }

  List<Widget> _statCards(bool isDark) {
    final activeCount = _users.where((u) => u['status'] == 'Active').length;
    final pendingCount = _users.where((u) => u['status'] == 'Pending').length;
    final suspendedCount =
        _users.where((u) => u['status'] == 'Suspended').length;
    return [
      _buildStatCard(
        title: 'Total Users',
        value: '${_users.length}',
        icon: Icons.people_rounded,
        color: AppColors.primary,
        isDark: isDark,
      ),
      _buildStatCard(
        title: 'Active',
        value: '$activeCount',
        icon: Icons.check_circle_rounded,
        color: AppColors.success,
        isDark: isDark,
      ),
      _buildStatCard(
        title: 'Pending',
        value: '$pendingCount',
        icon: Icons.pending_actions_rounded,
        color: AppColors.warning,
        isDark: isDark,
      ),
      _buildStatCard(
        title: 'Suspended',
        value: '$suspendedCount',
        icon: Icons.block_rounded,
        color: AppColors.error,
        isDark: isDark,
      ),
    ];
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(isDark ? 0.15 : 0.9),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodySmall.copyWith(
                      color: color.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    value,
                    style: AppTypography.h6.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(bool isDark, bool isMobile) {
    final roleItems = _roleFilterItems;
    if (!roleItems.contains(_selectedRole)) _selectedRole = 'All';
    if (!['All', ..._statusOptions].contains(_selectedStatus)) {
      _selectedStatus = 'All';
    }

    return Container(
      padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08),
        ),
      ),
      child: isMobile
          ? Column(
              children: [
                _buildSearchField(isDark),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        'Role',
                        _selectedRole,
                        roleItems,
                        (v) => setState(() => _selectedRole = v!),
                        isDark,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _buildDropdown(
                        'Status',
                        _selectedStatus,
                        ['All', ..._statusOptions],
                        (v) => setState(() => _selectedStatus = v!),
                        isDark,
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(flex: 2, child: _buildSearchField(isDark)),
                const SizedBox(width: AppSpacing.md),
                _buildDropdown(
                  'Role',
                  _selectedRole,
                  roleItems,
                  (v) => setState(() => _selectedRole = v!),
                  isDark,
                ),
                const SizedBox(width: AppSpacing.md),
                _buildDropdown(
                  'Status',
                  _selectedStatus,
                  ['All', ..._statusOptions],
                  (v) => setState(() => _selectedStatus = v!),
                  isDark,
                ),
              ],
            ),
    );
  }

  Widget _buildSearchField(bool isDark) {
    return TextField(
      onChanged: (value) => setState(() => _searchQuery = value),
      decoration: InputDecoration(
        hintText: 'Search users...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: isDark ? Colors.white10 : AppColors.neutral100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      ),
    );
  }

  Widget _buildMobileUsersList(
    List<Map<String, dynamic>> filteredUsers,
    bool isDark,
  ) {
    if (filteredUsers.isEmpty) return _buildEmptyState(isDark);
    return Column(
      children: filteredUsers
          .map((user) => _buildMobileUserCard(user, isDark))
          .toList(),
    );
  }

  Widget _buildMobileUserCard(Map<String, dynamic> user, bool isDark) {
    final roleColor = _getRoleColor(user['role']);
    final statusColor = _getStatusColor(user['status']);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildAvatar(user, roleColor, 40),
              const SizedBox(width: AppSpacing.sm),
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
              _buildUserActionButtons(user, isDark),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(child: _buildBadge(user['role'], roleColor)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _buildBadge(user['status'], statusColor)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${user['department']} - Joined ${user['joined']}',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (user['role'] == 'Driver') ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${user['vehicle'].toString().isEmpty ? 'Vehicle pending' : user['vehicle']} | ${user['vehicleType'].toString().isEmpty ? 'Type pending' : user['vehicleType']} | ${user['vehicleCapacityKg']} kg',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUsersTable(
    List<Map<String, dynamic>> filteredUsers,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.black.withValues(alpha: 0.08),
        ),
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  '${filteredUsers.length} records',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildUserTableHeader(isDark),
          const SizedBox(height: AppSpacing.sm),
          if (filteredUsers.isEmpty)
            _buildEmptyState(isDark)
          else
            ...filteredUsers.map((user) => _buildUserRow(user, isDark)),
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
        color:
            isDark ? Colors.white.withValues(alpha: 0.04) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          _buildTableHeader('User', flex: 3, isDark: isDark),
          _buildTableHeader('Role', flex: 2, isDark: isDark),
          _buildTableHeader('Department', flex: 2, isDark: isDark),
          _buildTableHeader('Status', isDark: isDark),
          _buildTableHeader('Joined', isDark: isDark),
          const SizedBox(width: 88),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String label, {int flex = 1, required bool isDark}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: AppTypography.bodySmall.copyWith(
          color: isDark ? Colors.white54 : AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildUserRow(Map<String, dynamic> user, bool isDark) {
    final roleColor = _getRoleColor(user['role']);
    final statusColor = _getStatusColor(user['status']);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.025)
            : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                _buildAvatar(user, roleColor, 40),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['name'],
                        style: AppTypography.bodyMedium.copyWith(
                          color: isDark ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '#${user['id']} - ${user['email']}',
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.62)
                              : AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(flex: 2, child: _buildBadge(user['role'], roleColor)),
          Expanded(
            flex: 2,
            child: Text(
              user['department'],
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(child: _buildBadge(user['status'], statusColor)),
          Expanded(
            child: Text(
              user['joined'],
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _buildUserActionButtons(user, isDark),
        ],
      ),
    );
  }

  Widget _buildAvatar(Map<String, dynamic> user, Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.95),
            color.withValues(alpha: 0.68),
          ],
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          user['avatar'],
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
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
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Text(
          text,
          style: TextStyle(color: color, fontSize: 11),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Icon(
            Icons.people_outline,
            color: isDark ? Colors.white38 : AppColors.textSecondary,
            size: 40,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No users found',
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? Colors.white70 : AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserActionButtons(Map<String, dynamic> user, bool isDark) {
    return SizedBox(
      width: 88,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildTableIconAction(
            Icons.edit_outlined,
            AppColors.primary,
            () => _showEditUserDialog(context, user, isDark),
            'Edit',
          ),
          _buildTableIconAction(
            Icons.delete_outline,
            AppColors.error,
            () => _showDeleteUserDialog(context, user, isDark),
            'Delete',
          ),
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

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : AppColors.neutral100,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: DropdownButton<String>(
        value: items.contains(value) ? value : items.first,
        items: items
            .map(
              (item) => DropdownMenuItem(
                value: item,
                child: Text(
                  item,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
        isExpanded: true,
        underline: const SizedBox(),
        icon: const Icon(Icons.arrow_drop_down),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Admin':
      case 'Super Admin':
        return AppColors.error;
      case 'Owner':
      case 'Farm Manager':
        return AppColors.primary;
      case 'Caretaker':
      case 'Technician':
        return AppColors.info;
      case 'Driver':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active':
        return AppColors.success;
      case 'Suspended':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  Widget _buildBottomNavigation(bool isDark) {
    final navItems = [
      {
        'icon': Icons.dashboard_outlined,
        'label': 'Dashboard',
        'index': 0,
        'route': '/dashboard',
      },
      {
        'icon': Icons.people_outline,
        'label': 'Users',
        'index': 1,
        'route': '/users',
      },
      {
        'icon': Icons.agriculture_outlined,
        'label': 'Farms',
        'index': 2,
        'route': '/farms',
      },
      {
        'icon': Icons.sensors_outlined,
        'label': 'Sensors',
        'index': 3,
        'route': '/sensors',
      },
      {
        'icon': Icons.analytics_outlined,
        'label': 'Analytics',
        'index': 4,
        'route': '/analytics',
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: navItems.map((item) {
              final index = item['index'] as int;
              final route = item['route'] as String;
              final isSelected = index == 1;
              return Expanded(
                child: InkWell(
                  onTap: () {
                    if (!isSelected) {
                      Navigator.pushReplacementNamed(context, route);
                    }
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item['icon'] as IconData,
                        size: 24,
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
                          fontWeight:
                              isSelected ? FontWeight.w500 : FontWeight.normal,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Future<void> _createUser({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String address,
    required String role,
    required String department,
    required String status,
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
      actorRole: 'admin',
      driverLicenseNumber: driverLicenseNumber,
      vehicle: vehicle,
      vehicleType: vehicleType,
      vehicleCapacityKg: vehicleCapacityKg,
    );
    await _loadUsers();
  }

  Future<void> _updateUser({
    required Map<String, dynamic> user,
    required String name,
    required String email,
    required String password,
    required String phone,
    required String address,
    required String role,
    required String department,
    required String status,
    required String driverLicenseNumber,
    required String vehicle,
    required String vehicleType,
    required double vehicleCapacityKg,
  }) async {
    final actor = ref.read(authProvider).user;
    await _api.updateUser(
      id: user['id'].toString(),
      name: name,
      email: email,
      password: password,
      address: address,
      role: _roleValue(role),
      phone: phone,
      department: department,
      status: status,
      actorId: actor?.id ?? '',
      actorRole: 'admin',
      driverLicenseNumber: driverLicenseNumber,
      vehicle: vehicle,
      vehicleType: vehicleType,
      vehicleCapacityKg: vehicleCapacityKg,
    );
    await _loadUsers();
  }

  void _showAddUserDialog(BuildContext context, bool isDark) {
    _showUserFormDialog(context: context, isDark: isDark);
  }

  void _showEditUserDialog(
    BuildContext context,
    Map<String, dynamic> user,
    bool isDark,
  ) {
    _showUserFormDialog(context: context, isDark: isDark, user: user);
  }

  void _showUserFormDialog({
    required BuildContext context,
    required bool isDark,
    Map<String, dynamic>? user,
  }) {
    final isEdit = user != null;
    final nameController =
        TextEditingController(text: isEdit ? user['name'] : '');
    final emailController =
        TextEditingController(text: isEdit ? user['email'] : '');
    final passwordController = TextEditingController(
      text: isEdit ? _text(user['password'], fallback: 'FarmDemo#2026New') : '',
    );
    final phoneController =
        TextEditingController(text: isEdit ? user['phone'] : '');
    final addressController =
        TextEditingController(text: isEdit ? user['address'] : '');
    final licenseController =
        TextEditingController(text: isEdit ? user['driverLicenseNumber'] : '');
    final vehicleController =
        TextEditingController(text: isEdit ? user['vehicle'] : '');
    final vehicleTypeController =
        TextEditingController(text: isEdit ? user['vehicleType'] : '');
    final vehicleCapacityController =
        TextEditingController(text: isEdit ? user['vehicleCapacityKg'] : '');
    String selectedRole = isEdit ? user['role'] : 'Caretaker';
    String selectedStatus = isEdit ? user['status'] : 'Pending';
    String? errorText;
    bool isSaving = false;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    showDialog(
      context: context,
      barrierDismissible: !isSaving,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final department = _departmentForRole(selectedRole);
          Future<void> save() async {
            final name = nameController.text.trim();
            final email = emailController.text.trim();
            final password = passwordController.text.trim();
            final phone = phoneController.text.trim();
            final address = addressController.text.trim();
            final isDriver = selectedRole == 'Driver';
            final driverLicenseNumber = licenseController.text.trim();
            final vehicle = vehicleController.text.trim();
            final vehicleType = vehicleTypeController.text.trim();
            final vehicleCapacityKg =
                double.tryParse(vehicleCapacityController.text.trim()) ?? 0;

            if (name.isEmpty || email.isEmpty || password.isEmpty) {
              setDialogState(
                () => errorText = 'Name, email, and password are required.',
              );
              return;
            }
            if (!email.contains('@')) {
              setDialogState(() => errorText = 'Enter a valid email address.');
              return;
            }
            if (isDriver &&
                (driverLicenseNumber.isEmpty ||
                    vehicle.isEmpty ||
                    vehicleType.isEmpty)) {
              setDialogState(() => errorText =
                  'Driver license number, vehicle registration, and vehicle type are required.');
              return;
            }

            final navigator = Navigator.of(dialogContext);
            final messenger = ScaffoldMessenger.of(context);
            setDialogState(() {
              isSaving = true;
              errorText = null;
            });
            try {
              if (isEdit) {
                await _updateUser(
                  user: user,
                  name: name,
                  email: email,
                  password: password,
                  phone: phone.isEmpty ? '+233000000000' : phone,
                  address: address.isEmpty ? 'Farm Estates' : address,
                  role: selectedRole,
                  department: department,
                  status: selectedStatus,
                  driverLicenseNumber: driverLicenseNumber,
                  vehicle: vehicle,
                  vehicleType: vehicleType,
                  vehicleCapacityKg: vehicleCapacityKg,
                );
              } else {
                await _createUser(
                  name: name,
                  email: email,
                  password: password,
                  phone: phone.isEmpty ? '+233000000000' : phone,
                  address: address.isEmpty ? 'Farm Estates' : address,
                  role: selectedRole,
                  department: department,
                  status: selectedStatus,
                  driverLicenseNumber: driverLicenseNumber,
                  vehicle: vehicle,
                  vehicleType: vehicleType,
                  vehicleCapacityKg: vehicleCapacityKg,
                );
              }
              if (!mounted || !dialogContext.mounted) return;
              navigator.pop();
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    isEdit
                        ? '$name updated successfully.'
                        : '$name created successfully.',
                  ),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } catch (error) {
              if (!mounted) return;
              setDialogState(() {
                isSaving = false;
                errorText = error.toString();
              });
            }
          }

          return Dialog(
            backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            ),
            insetPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? AppSpacing.md : AppSpacing.xxl,
              vertical: AppSpacing.xl,
            ),
            child: Container(
              width: isMobile ? double.infinity : 560,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildModalHeader(
                    isDark: isDark,
                    icon: isEdit ? Icons.edit : Icons.person_add,
                    title: isEdit ? 'Edit User' : 'Add New User',
                    subtitle: isEdit
                        ? 'Update backend account details'
                        : 'Create a backend user account',
                    color: isEdit ? AppColors.info : AppColors.primary,
                    onClose:
                        isSaving ? null : () => Navigator.pop(dialogContext),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFormLabel('Full Name', isDark),
                          const SizedBox(height: AppSpacing.sm),
                          _buildFormTextField(
                            controller: nameController,
                            hint: 'e.g., John Smith',
                            icon: Icons.person,
                            isDark: isDark,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _buildFormLabel('Email Address', isDark),
                          const SizedBox(height: AppSpacing.sm),
                          _buildFormTextField(
                            controller: emailController,
                            hint: 'e.g., user@farm.com',
                            icon: Icons.email,
                            isDark: isDark,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _buildFormLabel('Password', isDark),
                          const SizedBox(height: AppSpacing.sm),
                          _buildFormTextField(
                            controller: passwordController,
                            hint: 'Temporary password',
                            icon: Icons.lock,
                            isDark: isDark,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFormLabel('Role', isDark),
                                    const SizedBox(height: AppSpacing.sm),
                                    _buildFormDropdown(
                                      value: selectedRole,
                                      items: _roleOptions,
                                      icon: Icons.badge,
                                      isDark: isDark,
                                      onChanged: isSaving
                                          ? null
                                          : (v) => setDialogState(
                                                () => selectedRole = v!,
                                              ),
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
                                    _buildFormDropdown(
                                      value: selectedStatus,
                                      items: _statusOptions,
                                      icon: Icons.toggle_on,
                                      isDark: isDark,
                                      onChanged: isSaving
                                          ? null
                                          : (v) => setDialogState(
                                                () => selectedStatus = v!,
                                              ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _buildFormLabel('Phone', isDark),
                          const SizedBox(height: AppSpacing.sm),
                          _buildFormTextField(
                            controller: phoneController,
                            hint: '+233...',
                            icon: Icons.phone,
                            isDark: isDark,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _buildFormLabel('Address', isDark),
                          const SizedBox(height: AppSpacing.sm),
                          _buildFormTextField(
                            controller: addressController,
                            hint: 'Farm Estates',
                            icon: Icons.location_on,
                            isDark: isDark,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _buildReadOnlyField(
                            label: 'Department',
                            value: department,
                            isDark: isDark,
                          ),
                          if (selectedRole == 'Driver') ...[
                            const SizedBox(height: AppSpacing.lg),
                            _buildFormLabel('Driver License Number', isDark),
                            const SizedBox(height: AppSpacing.sm),
                            _buildFormTextField(
                              controller: licenseController,
                              hint: 'e.g., DVLA-1234567',
                              icon: Icons.badge_outlined,
                              isDark: isDark,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            _buildFormLabel('Vehicle Registration', isDark),
                            const SizedBox(height: AppSpacing.sm),
                            _buildFormTextField(
                              controller: vehicleController,
                              hint: 'e.g., GT 1234-26',
                              icon: Icons.local_shipping_outlined,
                              isDark: isDark,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            _buildFormLabel('Vehicle Type', isDark),
                            const SizedBox(height: AppSpacing.sm),
                            _buildFormTextField(
                              controller: vehicleTypeController,
                              hint: 'e.g., Refrigerated van',
                              icon: Icons.fire_truck_outlined,
                              isDark: isDark,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            _buildFormLabel('Capacity (kg)', isDark),
                            const SizedBox(height: AppSpacing.sm),
                            _buildFormTextField(
                              controller: vehicleCapacityController,
                              hint: 'e.g., 1500',
                              icon: Icons.scale_outlined,
                              isDark: isDark,
                              keyboardType: TextInputType.number,
                            ),
                          ],
                          if (errorText != null) ...[
                            const SizedBox(height: AppSpacing.lg),
                            _buildModalError(errorText!, isDark),
                          ],
                        ],
                      ),
                    ),
                  ),
                  _buildModalActions(
                    isDark: isDark,
                    isSaving: isSaving,
                    primaryLabel: isEdit ? 'Save Changes' : 'Add User',
                    primaryIcon: isEdit ? Icons.save : Icons.person_add,
                    onCancel: () => Navigator.pop(dialogContext),
                    onSave: save,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteUserDialog(
    BuildContext context,
    Map<String, dynamic> user,
    bool isDark,
  ) {
    bool isDeleting = false;
    String? errorText;

    showDialog(
      context: context,
      barrierDismissible: !isDeleting,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          Future<void> deleteUser() async {
            final navigator = Navigator.of(dialogContext);
            final messenger = ScaffoldMessenger.of(context);
            setDialogState(() {
              isDeleting = true;
              errorText = null;
            });
            try {
              await _api.deleteUser(user['id'].toString());
              await _loadUsers();
              if (!mounted || !dialogContext.mounted) return;
              navigator.pop();
              messenger.showSnackBar(
                SnackBar(
                  content: Text('${user['name']} deleted.'),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } catch (error) {
              if (!mounted) return;
              setDialogState(() {
                isDeleting = false;
                errorText = error.toString();
              });
            }
          }

          return Dialog(
            backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            ),
            child: Container(
              width: 420,
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
                    child: isDeleting
                        ? const SizedBox(
                            width: 34,
                            height: 34,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: AppColors.error,
                            ),
                          )
                        : const Icon(
                            Icons.person_off,
                            color: AppColors.error,
                            size: 40,
                          ),
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
                    'Are you sure you want to delete "${user['name']}"?',
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark ? Colors.white70 : AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    _buildModalError(errorText!, isDark),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              isDeleting ? null : () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isDeleting ? null : deleteUser,
                          icon: isDeleting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.delete, size: 18),
                          label: Text(isDeleting ? 'Deleting...' : 'Delete'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModalHeader({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback? onClose,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.h6.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildModalActions({
    required bool isDark,
    required bool isSaving,
    required String primaryLabel,
    required IconData primaryIcon,
    required VoidCallback onCancel,
    required VoidCallback onSave,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: isSaving ? null : onCancel,
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: isSaving ? null : onSave,
              icon: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(primaryIcon, size: 18),
              label: Text(isSaving ? 'Saving...' : primaryLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModalError(String message, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.error.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormLabel(String label, bool isDark) {
    return Text(
      label,
      style: AppTypography.bodyMedium.copyWith(
        fontWeight: FontWeight.w500,
        color: isDark ? Colors.white : AppColors.textPrimary,
      ),
    );
  }

  Widget _buildFormTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    TextInputType? keyboardType,
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
              : AppColors.textSecondary.withOpacity(0.5),
        ),
        prefixIcon: Icon(
          icon,
          color: isDark ? Colors.white54 : AppColors.textSecondary,
          size: 20,
        ),
        filled: true,
        fillColor:
            isDark ? Colors.white.withOpacity(0.05) : AppColors.neutral50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : AppColors.neutral200,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : AppColors.neutral200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
      ),
    );
  }

  Widget _buildFormDropdown({
    required String value,
    required List<String> items,
    required IconData icon,
    required bool isDark,
    required Function(String?)? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? Colors.white12 : AppColors.neutral200,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : items.first,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: isDark ? Colors.white54 : AppColors.textSecondary,
          ),
          dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontSize: 14,
          ),
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        color:
                            isDark ? Colors.white54 : AppColors.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          item,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? Colors.white12 : AppColors.neutral200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.apartment,
            size: 20,
            color: isDark ? Colors.white54 : AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? Colors.white54 : AppColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
