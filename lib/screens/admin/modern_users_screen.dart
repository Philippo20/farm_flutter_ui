import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/create_user_modal.dart';
import '../../core/widgets/user_search_field.dart';
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
            SizedBox(height: isMobile ? 8 : AppSpacing.xl),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                isMobile
                    ? _buildMobileStatsCards(isDark)
                    : _buildStatsCards(isDark),
                SizedBox(height: isMobile ? 16 : AppSpacing.xl),
                _buildControls(isDark, isMobile),
                SizedBox(height: isMobile ? 12 : AppSpacing.lg),
                if (isMobile)
                  _buildMobileUsersList(filteredUsers, isDark)
                else
                  _buildUsersTable(filteredUsers, isDark),
              ],
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
      padding: EdgeInsets.zero,
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

  Widget _buildSearchField(bool isDark) => UserSearchField(
        value: _searchQuery,
        onChanged: (value) => setState(() => _searchQuery = value),
      );

  Widget _buildMobileUsersList(
    List<Map<String, dynamic>> filteredUsers,
    bool isDark,
  ) {
    if (filteredUsers.isEmpty) return _buildEmptyState(isDark);
    return Column(
      children: [
        for (var index = 0; index < filteredUsers.length; index++) ...[
          _buildMobileUserCard(filteredUsers[index], isDark),
          if (index < filteredUsers.length - 1) const SizedBox(height: 12),
        ],
      ],
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
                  _getRoleColor((user['role'] ?? '').toString())),
              _buildMobileUserBadge(status, _getStatusColor(status)),
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
            const SizedBox(height: 12),
            detail(Icons.local_shipping_outlined, 'Vehicle type',
                user['vehicleType']),
          ],
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
                child: OutlinedButton.icon(
              onPressed: () => _showDeleteUserDialog(context, user, isDark),
              icon: const Icon(Icons.delete_outline, size: 16),
              label: const Text('Delete'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
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
              onPressed: () => _showEditUserDialog(context, user, isDark),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Edit user'),
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

  Future<void> _showUserFormDialog({
    required BuildContext context,
    required bool isDark,
    Map<String, dynamic>? user,
  }) async {
    final saved = await showCreateUserModal(context,
        roles: _roleOptions,
        departments: _roleOptions.map(_departmentForRole).toSet().toList(),
        includeAccountFields: true,
        departmentForRole: _departmentForRole,
        initialValues: user == null
            ? null
            : {
                'name': user['name'],
                'email': user['email'],
                'password': '',
                'phone': user['phone'],
                'address': user['address'],
                'role': user['role'],
                'department': _departmentForRole(user['role']),
                'status': user['status'],
                'license': user['driverLicenseNumber'],
                'vehicle': user['vehicle'],
                'vehicleType': user['vehicleType'],
                'capacity': user['vehicleCapacityKg'],
              }, onSubmit: (values) async {
      final phone = (values['phone'] as String).isEmpty
          ? '+233000000000'
          : values['phone'] as String;
      final address = (values['address'] as String).isEmpty
          ? 'Farm Estates'
          : values['address'] as String;
      if (user == null) {
        await _createUser(
            name: values['name'] as String,
            email: values['email'] as String,
            password: values['password'] as String,
            phone: phone,
            address: address,
            role: values['role'] as String,
            department: values['department'] as String,
            status: values['status'] as String,
            driverLicenseNumber: values['license'] as String,
            vehicle: values['vehicle'] as String,
            vehicleType: values['vehicleType'] as String,
            vehicleCapacityKg: values['capacity'] as double);
      } else {
        await _updateUser(
            user: user,
            name: values['name'] as String,
            email: values['email'] as String,
            password: values['password'] as String,
            phone: phone,
            address: address,
            role: values['role'] as String,
            department: values['department'] as String,
            status: values['status'] as String,
            driverLicenseNumber: values['license'] as String,
            vehicle: values['vehicle'] as String,
            vehicleType: values['vehicleType'] as String,
            vehicleCapacityKg: values['capacity'] as double);
      }
    });
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(user == null
              ? 'User created successfully.'
              : 'User updated successfully.'),
          backgroundColor: AppColors.success));
    }
  }

  void _showDeleteUserDialog(
    BuildContext context,
    Map<String, dynamic> user,
    bool isDark,
  ) {
    bool isDeleting = false;
    String? errorText;

    showAppDialog(
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

          return AppDialog(
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
}
