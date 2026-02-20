import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/farm_manager_header.dart';
import '../../core/widgets/farm_manager_sidebar.dart';
import '../../core/widgets/farm_manager_mobile_drawer.dart';
import '../../providers/auth_provider.dart';

/// Team Management Screen for Farm Manager
/// Manage staff across farms, roles, and performance
class TeamManagementScreen extends ConsumerStatefulWidget {
  const TeamManagementScreen({super.key});

  @override
  ConsumerState<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends ConsumerState<TeamManagementScreen> {
  int _selectedNavIndex = 7;
  String _searchQuery = '';
  String _selectedStatus = 'All';
  String _selectedRole = 'All Roles';
  String _selectedFarm = 'All Farms';
  final _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _sortColumn = 'Status';
  bool _sortAsc = true;

  final List<Map<String, dynamic>> _teamMembers = [
    {
      'name': 'Kwame Asante',
      'role': 'Lead Caretaker',
      'farm': 'Green Valley Farm',
      'status': 'Active',
      'avatar': 'KA',
      'tasks': 12,
      'completed': 11,
      'performance': 0.92,
      'phone': '+233 24 567 8901',
      'email': 'kwame@farmestates.com',
      'joinedDate': 'Jan 2024',
      'specialty': 'Crop Management',
    },
    {
      'name': 'Ama Mensah',
      'role': 'Irrigation Specialist',
      'farm': 'Green Valley Farm',
      'status': 'Active',
      'avatar': 'AM',
      'tasks': 8,
      'completed': 7,
      'performance': 0.85,
      'phone': '+233 20 345 6789',
      'email': 'ama@farmestates.com',
      'joinedDate': 'Mar 2024',
      'specialty': 'Water Systems',
    },
    {
      'name': 'Yaw Owusu',
      'role': 'Lead Caretaker',
      'farm': 'Sunrise Acres',
      'status': 'Active',
      'avatar': 'YO',
      'tasks': 15,
      'completed': 13,
      'performance': 0.88,
      'phone': '+233 24 111 2222',
      'email': 'yaw@farmestates.com',
      'joinedDate': 'Dec 2023',
      'specialty': 'Soil Management',
    },
    {
      'name': 'Abena Frimpong',
      'role': 'Pest Control Specialist',
      'farm': 'Sunrise Acres',
      'status': 'Active',
      'avatar': 'AF',
      'tasks': 9,
      'completed': 7,
      'performance': 0.75,
      'phone': '+233 20 333 4444',
      'email': 'abena@farmestates.com',
      'joinedDate': 'Apr 2024',
      'specialty': 'Pest Management',
    },
    {
      'name': 'Kofi Boateng',
      'role': 'Technician',
      'farm': 'Green Valley Farm',
      'status': 'Active',
      'avatar': 'KB',
      'tasks': 10,
      'completed': 7,
      'performance': 0.7,
      'phone': '+233 27 890 1234',
      'email': 'kofi@farmestates.com',
      'joinedDate': 'Feb 2024',
      'specialty': 'Equipment Maintenance',
    },
    {
      'name': 'Efua Darko',
      'role': 'Harvester',
      'farm': 'Green Valley Farm',
      'status': 'On Leave',
      'avatar': 'ED',
      'tasks': 6,
      'completed': 4,
      'performance': 0.6,
      'phone': '+233 55 123 4567',
      'email': 'efua@farmestates.com',
      'joinedDate': 'May 2024',
      'specialty': 'Harvest Operations',
    },
    {
      'name': 'Nana Agyei',
      'role': 'Field Supervisor',
      'farm': 'Sunrise Acres',
      'status': 'Active',
      'avatar': 'NA',
      'tasks': 11,
      'completed': 9,
      'performance': 0.82,
      'phone': '+233 55 555 6666',
      'email': 'nana@farmestates.com',
      'joinedDate': 'Jan 2024',
      'specialty': 'Field Operations',
    },
    {
      'name': 'Fatima Alhassan',
      'role': 'Irrigation Specialist',
      'farm': 'Golden Harvest Farm',
      'status': 'Active',
      'avatar': 'FA',
      'tasks': 8,
      'completed': 6,
      'performance': 0.72,
      'phone': '+233 24 444 5555',
      'email': 'fatima@farmestates.com',
      'joinedDate': 'Apr 2024',
      'specialty': 'Canal Systems',
    },
    {
      'name': 'Salifu Bamba',
      'role': 'Harvester',
      'farm': 'Golden Harvest Farm',
      'status': 'Inactive',
      'avatar': 'SB',
      'tasks': 4,
      'completed': 1,
      'performance': 0.3,
      'phone': '+233 27 666 7777',
      'email': 'salifu@farmestates.com',
      'joinedDate': 'May 2024',
      'specialty': 'Grain Processing',
    },
    {
      'name': 'Ama Owusu',
      'role': 'Farm Owner',
      'farm': 'Green Valley Farm',
      'status': 'Active',
      'avatar': 'AO',
      'tasks': 6,
      'completed': 5,
      'performance': 0.86,
      'phone': '+233 24 700 1122',
      'email': 'ama.owusu@farmestates.com',
      'joinedDate': 'Aug 2023',
      'specialty': 'Operations Oversight',
    },
    {
      'name': 'Daniel Mensah',
      'role': 'Farm Owner',
      'farm': 'Sunrise Acres',
      'status': 'Active',
      'avatar': 'DM',
      'tasks': 4,
      'completed': 4,
      'performance': 0.95,
      'phone': '+233 20 800 3344',
      'email': 'daniel.mensah@farmestates.com',
      'joinedDate': 'Nov 2022',
      'specialty': 'Strategic Planning',
    },
    {
      'name': 'Akosua Boateng',
      'role': 'Farm Owner',
      'farm': 'Golden Harvest Farm',
      'status': 'On Leave',
      'avatar': 'AB',
      'tasks': 3,
      'completed': 2,
      'performance': 0.62,
      'phone': '+233 55 900 7788',
      'email': 'akosua.boateng@farmestates.com',
      'joinedDate': 'Mar 2023',
      'specialty': 'Finance & Compliance',
    },
  ];

  List<Map<String, dynamic>> get _filteredMembers {
    var result = _teamMembers;
    if (_selectedStatus != 'All') {
      result = result.where((m) => (m['status'] ?? '') == _selectedStatus).toList();
    }
    if (_selectedRole != 'All Roles') {
      result = result.where((m) => (m['role'] ?? '') == _selectedRole).toList();
    }
    if (_selectedFarm != 'All Farms') {
      result = result.where((m) => (m['farm'] ?? '') == _selectedFarm).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((m) {
        return (m['name']?.toString() ?? '').toLowerCase().contains(q) ||
            (m['role']?.toString() ?? '').toLowerCase().contains(q) ||
            (m['farm']?.toString() ?? '').toLowerCase().contains(q);
      }).toList();
    }
    return result;
  }

  int get _activeCount =>
      _teamMembers.where((m) => (m['status'] ?? '') == 'Active').length;
  int get _onLeaveCount =>
      _teamMembers.where((m) => (m['status'] ?? '') == 'On Leave').length;
  int get _inactiveCount =>
      _teamMembers.where((m) => (m['status'] ?? '') == 'Inactive').length;

  List<String> get _roleFilters {
    final roles = _teamMembers.map((m) => m['role'] as String).toSet().toList()..sort();
    return ['All Roles', ...roles];
  }

  List<String> get _farmFilters {
    final farms = _teamMembers.map((m) => m['farm'] as String).toSet().toList()..sort();
    return ['All Farms', ...farms];
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'Farm Manager';
    final userEmail = authState.user?.email ?? 'manager@farmestates.com';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      drawer: isMobile
          ? FarmManagerMobileDrawer(
              selectedIndex: _selectedNavIndex,
              onItemSelected: (index) => setState(() => _selectedNavIndex = index),
              userName: userName,
            )
          : null,
      body: isMobile
          ? _buildMobileLayout(isDark, userName)
          : _buildDesktopLayout(isDark, userName, userEmail),
      bottomNavigationBar: isMobile ? _buildBottomNavigation(isDark) : null,
    );
  }


  Widget _buildDesktopLayout(bool isDark, String userName, String userEmail) {
    return Row(
      children: [
        FarmManagerSidebar(
          selectedIndex: _selectedNavIndex,
          onItemSelected: (i) => setState(() => _selectedNavIndex = i),
          userName: userName,
          userEmail: userEmail,
          userRole: 'Farm Manager',
        ),
        Expanded(
          child: Column(
            children: [
              FarmManagerHeader(userName: userName),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: _buildContent(isDark, false),
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
        FarmManagerHeader(
          userName: userName,
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: _buildContent(isDark, true),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(bool isDark, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPageHeader(isDark, isMobile),
        SizedBox(height: isMobile ? 16 : 24),
        _buildStatsRow(isDark, isMobile),
        SizedBox(height: isMobile ? 16 : 24),
        _buildRoleQuickFilters(isDark),
        SizedBox(height: isMobile ? 12 : 16),
        _buildFilters(isDark),
        SizedBox(height: isMobile ? 16 : 24),
        _buildTeamSection(isDark, isMobile),
      ],
    );
  }

  Widget _buildPageHeader(bool isDark, bool isMobile) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Team',
                style: (isMobile ? AppTypography.h5 : AppTypography.h4).copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage staff across farms, roles, and performance',
                style: AppTypography.bodyMedium.copyWith(
                  fontSize: isMobile ? 12 : 13,
                  color: isDark ? Colors.white60 : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (!isMobile)
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invite sent to new team member')),
              );
            },
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
            label: const Text('Invite'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
            ),
          ),
      ],
    );
  }

  Widget _buildStatsRow(bool isDark, bool isMobile) {
    final stats = [
      {'label': 'Total Members', 'value': '${_teamMembers.length}', 'icon': Icons.groups_rounded, 'color': AppColors.primary},
      {'label': 'Active', 'value': '$_activeCount', 'icon': Icons.check_circle_rounded, 'color': AppColors.success},
      {'label': 'On Leave', 'value': '$_onLeaveCount', 'icon': Icons.pause_circle_rounded, 'color': AppColors.warning},
      {'label': 'Inactive', 'value': '$_inactiveCount', 'icon': Icons.remove_circle_rounded, 'color': AppColors.error},
    ];

    return GridView.count(
      crossAxisCount: isMobile ? 2 : 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: isMobile ? 2.0 : 2.6,
      children: stats.map((s) => _buildStatCard(s, isDark, isMobile)).toList(),
    );
  }

  Widget _buildStatCard(Map<String, dynamic> stat, bool isDark, bool isMobile) {
    final color = stat['color'] as Color;
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : AppColors.neutral200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(stat['icon'] as IconData, size: isMobile ? 18 : 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  stat['value'] as String,
                  style: AppTypography.h6.copyWith(
                    fontSize: isMobile ? 18 : 22,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                Text(
                  stat['label'] as String,
                  style: AppTypography.caption.copyWith(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
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
  }

  Widget _buildFilters(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            style: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white : AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search team members...',
              hintStyle: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white38 : AppColors.textSecondary),
              prefixIcon: Icon(Icons.search, size: 20, color: isDark ? Colors.white38 : AppColors.textSecondary),
              filled: true,
              fillColor: isDark ? Colors.white.withOpacity(0.05) : AppColors.neutral50,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.06) : AppColors.neutral200)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.primary.withOpacity(0.5))),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 700;
              if (compact) {
                return Column(
                  children: [
                    _buildFilterDropdown('Role', _selectedRole, _roleFilters, (v) => setState(() => _selectedRole = v!), isDark),
                    const SizedBox(height: AppSpacing.sm),
                    _buildFilterDropdown('Farm', _selectedFarm, _farmFilters, (v) => setState(() => _selectedFarm = v!), isDark),
                    const SizedBox(height: AppSpacing.sm),
                    _buildFilterDropdown('Status', _selectedStatus, const ['All', 'Active', 'On Leave', 'Inactive'], (v) => setState(() => _selectedStatus = v!), isDark),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: _buildFilterDropdown('Role', _selectedRole, _roleFilters, (v) => setState(() => _selectedRole = v!), isDark)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: _buildFilterDropdown('Farm', _selectedFarm, _farmFilters, (v) => setState(() => _selectedFarm = v!), isDark)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: _buildFilterDropdown('Status', _selectedStatus, const ['All', 'Active', 'On Leave', 'Inactive'], (v) => setState(() => _selectedStatus = v!), isDark)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRoleQuickFilters(bool isDark) {
    final roles = _roleFilters.where((r) => r != 'All Roles').toList();
    final chips = ['All Roles', ...roles];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final role = chips[index];
          final isSelected = _selectedRole == role;
          return FilterChip(
            label: Text(
              role,
              style: AppTypography.bodySmall.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : AppColors.textPrimary),
              ),
            ),
            selected: isSelected,
            onSelected: (_) => setState(() => _selectedRole = role),
            backgroundColor: isDark ? Colors.white.withOpacity(0.05) : AppColors.neutral100,
            selectedColor: AppColors.primary,
            checkmarkColor: Colors.white,
            side: BorderSide(
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? Colors.white10 : AppColors.neutral200),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          );
        },
      ),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : AppColors.textSecondary)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : AppColors.neutral100,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
              items: items.map((item) => DropdownMenuItem(value: item, child: Text(item, style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary)))).toList(),
              onChanged: onChanged,
              icon: Icon(Icons.arrow_drop_down, color: isDark ? Colors.white54 : AppColors.textSecondary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeamSection(bool isDark, bool isMobile) {
    final members = _sortedMembers(_filteredMembers);
    if (isMobile) {
      return _buildTeamColumn(
        title: 'Team Members',
        icon: Icons.groups_rounded,
        color: AppColors.info,
        members: members,
        isDark: isDark,
        isMobile: isMobile,
      );
    }

    final owners = members.where((m) => (m['role'] ?? '') == 'Farm Owner').toList();
    final others = members.where((m) => (m['role'] ?? '') != 'Farm Owner').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTeamColumn(
          title: 'Team Members',
          icon: Icons.groups_rounded,
          color: AppColors.info,
          members: others,
          isDark: isDark,
          isMobile: isMobile,
        ),
        const SizedBox(height: 16),
        _buildTeamColumn(
          title: 'Farm Owners',
          icon: Icons.verified_user_rounded,
          color: AppColors.primary,
          members: owners,
          isDark: isDark,
          isMobile: isMobile,
        ),
      ],
    );
  }

  Widget _buildTeamColumn({
    required String title,
    required IconData icon,
    required Color color,
    required List<Map<String, dynamic>> members,
    required bool isDark,
    required bool isMobile,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : AppColors.neutral200),
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(isMobile ? 14 : 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 18, color: color),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: AppTypography.titleSmall.copyWith(
                      fontSize: isMobile ? 15 : 17,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${members.length}',
                      style: AppTypography.caption.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (members.isEmpty)
              _buildEmptyState(isDark)
            else if (isMobile)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: members.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: isDark ? Colors.white.withOpacity(0.06) : AppColors.neutral200),
                itemBuilder: (_, i) => _buildMemberCard(members[i], isDark, isMobile),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: _buildTableHeader(isDark),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: members.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildMemberRow(members[i], isDark, i % 2 == 1),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(8),
        border: Border(bottom: BorderSide(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: _buildSortableHeader('Member', isDark),
          ),
          Expanded(
            flex: 2,
            child: _buildSortableHeader('Role', isDark),
          ),
          Expanded(
            flex: 2,
            child: _buildSortableHeader('Farm', isDark),
          ),
          Expanded(
            flex: 2,
            child: _buildSortableHeader('Phone', isDark),
          ),
          Expanded(
            flex: 2,
            child: _buildSortableHeader('Performance', isDark),
          ),
          Expanded(
            flex: 2,
            child: _buildSortableHeader('Status', isDark),
          ),
          Expanded(
            flex: 1,
            child: Text('Actions', textAlign: TextAlign.end, style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700, color: isDark ? Colors.white60 : AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _buildSortableHeader(String label, bool isDark) {
    final isActive = _sortColumn == label;
    final icon = isActive
        ? (_sortAsc ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded)
        : Icons.unfold_more_rounded;
    final baseStyle = GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.3,
      color: isDark ? Colors.white38 : AppColors.textSecondary,
    );

    return InkWell(
      onTap: () {
        setState(() {
          if (_sortColumn == label) {
            _sortAsc = !_sortAsc;
          } else {
            _sortColumn = label;
            _sortAsc = true;
          }
        });
      },
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: baseStyle.copyWith(
                      color: isActive
                          ? (isDark ? Colors.white70 : AppColors.textPrimary)
                          : baseStyle.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  icon,
                  size: 14,
                  color: isActive
                      ? (isDark ? Colors.white70 : AppColors.textPrimary)
                      : (isDark ? Colors.white38 : AppColors.textSecondary),
                ),
              ],
            ),
            if (label == 'Status' && _sortColumn == 'Status')
              Text(
                'then Performance',
                style: baseStyle.copyWith(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white38 : AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberRow(Map<String, dynamic> member, bool isDark, bool isEven) {
    final status = member['status'] as String? ?? 'Active';
    final statusColor = _statusColor(status);
    final performance = (member['performance'] as double?) ?? 0.0;
    final tasks = member['tasks'] as int? ?? 0;
    final completed = member['completed'] as int? ?? 0;
    final isOwner = (member['role'] as String?) == 'Farm Owner';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showMemberDetails(member, isDark),
        hoverColor: isDark ? Colors.white.withOpacity(0.04) : AppColors.neutral50,
        splashColor: isDark ? Colors.white24 : AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isEven
                ? (isDark ? Colors.white.withOpacity(0.02) : AppColors.neutral50.withOpacity(0.5))
                : Colors.transparent,
            border: Border(bottom: BorderSide(color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04))),
          ),
          child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: isDark ? Colors.white10 : AppColors.neutral100,
                    child: Text(
                      member['avatar'] ?? '',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member['name'] ?? '',
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          member['email'] ?? '',
                          style: AppTypography.caption.copyWith(
                            color: isDark ? Colors.white54 : AppColors.textSecondary,
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
            Expanded(
              flex: 2,
              child: Text(
                member['role'] ?? '',
                style: AppTypography.bodySmall.copyWith(color: isDark ? Colors.white70 : AppColors.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                member['farm'] ?? '',
                style: AppTypography.bodySmall.copyWith(color: isDark ? Colors.white70 : AppColors.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Icon(Icons.phone_outlined, size: 14, color: isDark ? Colors.white38 : AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      member['phone'] ?? '',
                      style: AppTypography.bodySmall.copyWith(color: isDark ? Colors.white70 : AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: isOwner
                  ? Text(
                      '—',
                      style: AppTypography.caption.copyWith(
                        color: isDark ? Colors.white54 : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: performance,
                              minHeight: 6,
                              backgroundColor: isDark ? Colors.white.withOpacity(0.08) : AppColors.neutral200,
                              valueColor: AlwaysStoppedAnimation(_progressColor(performance)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(performance * 100).toInt()}%',
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            color: _progressColor(performance),
                          ),
                        ),
                      ],
                    ),
            ),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      status,
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!isOwner)
                    Text(
                      '$completed/$tasks',
                      style: AppTypography.caption.copyWith(
                        color: isDark ? Colors.white54 : AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Message',
                      onPressed: () {},
                      icon: Icon(Icons.message_outlined, size: 18, color: isDark ? Colors.white70 : AppColors.textSecondary),
                    ),
                    IconButton(
                      tooltip: 'Assign Task',
                      onPressed: () {},
                      icon: Icon(Icons.task_alt_rounded, size: 18, color: isDark ? Colors.white70 : AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _sortedMembers(List<Map<String, dynamic>> members) {
    final sorted = List<Map<String, dynamic>>.from(members);
    const statusRank = {
      'Active': 0,
      'On Leave': 1,
      'Inactive': 2,
    };

    int compareValues(dynamic a, dynamic b) {
      if (a == null && b == null) return 0;
      if (a == null) return -1;
      if (b == null) return 1;
      if (a is num && b is num) return a.compareTo(b);
      return a.toString().toLowerCase().compareTo(b.toString().toLowerCase());
    }

    sorted.sort((a, b) {
      dynamic aVal;
      dynamic bVal;
      switch (_sortColumn) {
        case 'Role':
          aVal = a['role'];
          bVal = b['role'];
          break;
        case 'Farm':
          aVal = a['farm'];
          bVal = b['farm'];
          break;
        case 'Phone':
          aVal = a['phone'];
          bVal = b['phone'];
          break;
        case 'Performance':
          aVal = a['performance'];
          bVal = b['performance'];
          break;
        case 'Status':
          aVal = statusRank[a['status']] ?? 99;
          bVal = statusRank[b['status']] ?? 99;
          break;
        case 'Member':
        default:
          aVal = a['name'];
          bVal = b['name'];
      }
      var result = compareValues(aVal, bVal);
      if (_sortColumn == 'Status' && result == 0) {
        final perfA = a['performance'] ?? 0;
        final perfB = b['performance'] ?? 0;
        result = compareValues(perfB, perfA);
      }
      return _sortAsc ? result : -result;
    });

    return sorted;
  }

  Widget _buildMemberCard(Map<String, dynamic> member, bool isDark, bool isMobile) {
    final status = member['status'] as String? ?? 'Active';
    final statusColor = _statusColor(status);
    final performance = (member['performance'] as double?) ?? 0.0;
    final tasks = member['tasks'] as int? ?? 0;
    final completed = member['completed'] as int? ?? 0;
    final isOwner = (member['role'] as String?) == 'Farm Owner';

    return InkWell(
      onTap: () => _showMemberDetails(member, isDark),
      hoverColor: isDark ? Colors.white.withOpacity(0.04) : AppColors.neutral50,
      splashColor: isDark ? Colors.white24 : AppColors.primary.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 20, vertical: 14),
        child: Column(
          children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: isDark ? Colors.white10 : AppColors.neutral100,
                child: Text(
                  member['avatar'] ?? '',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member['name'] ?? '',
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${member['role']} • ${member['farm']}',
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor)),
                    const SizedBox(width: 5),
                    Text(
                      status,
                      style: AppTypography.caption.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _memberInfoChip(Icons.work_outline_rounded, member['specialty'] ?? '', isDark),
              const SizedBox(width: 8),
              _memberInfoChip(Icons.calendar_month_rounded, 'Since ${member['joinedDate'] ?? ''}', isDark),
            ],
          ),
          const SizedBox(height: 10),
            if (!isOwner) ...[
              Row(
                children: [
                  Text('Tasks: ', style: AppTypography.caption.copyWith(fontSize: 11, color: isDark ? Colors.white38 : AppColors.textSecondary)),
                  Text(
                    '$completed/$tasks completed',
                    style: AppTypography.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : AppColors.textPrimary),
                  ),
                  const Spacer(),
                  Text(
                    '${(performance * 100).toInt()}%',
                    style: AppTypography.bodySmall.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: _progressColor(performance)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: performance,
                  minHeight: 5,
                  backgroundColor: isDark ? Colors.white.withOpacity(0.08) : AppColors.neutral200,
                  valueColor: AlwaysStoppedAnimation(_progressColor(performance)),
                ),
              ),
              const SizedBox(height: 10),
            ],
          Row(
            children: [
              Icon(Icons.phone_outlined, size: 13, color: isDark ? Colors.white38 : AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(member['phone'] ?? '', style: AppTypography.caption.copyWith(fontSize: 11, color: isDark ? Colors.white54 : AppColors.textSecondary)),
              const Spacer(),
              Icon(Icons.email_outlined, size: 13, color: isDark ? Colors.white38 : AppColors.textSecondary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  member['email'] ?? '',
                  style: AppTypography.caption.copyWith(fontSize: 11, color: isDark ? Colors.white54 : AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Message sent to ${member['name']}')),
                    );
                  },
                  icon: const Icon(Icons.message_rounded, size: 16),
                  label: const Text('Message'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white70 : AppColors.textSecondary,
                    side: BorderSide(color: isDark ? Colors.white.withOpacity(0.12) : AppColors.neutral300),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Task assigned to ${member['name']}')),
                    );
                  },
                  icon: const Icon(Icons.task_alt_rounded, size: 16),
                  label: const Text('Assign Task'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
          ],
        ),
      ),
    );
  }

  void _showMemberDetails(Map<String, dynamic> member, bool isDark) {
    final status = member['status'] as String? ?? 'Active';
    final statusColor = _statusColor(status);
    final performance = (member['performance'] as double?) ?? 0.0;
    final tasks = member['tasks'] as int? ?? 0;
    final completed = member['completed'] as int? ?? 0;
    final isOwner = (member['role'] as String?) == 'Farm Owner';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Container(
          width: 440,
          padding: const EdgeInsets.all(0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [statusColor.withOpacity(0.8), statusColor]),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: Text(
                        member['avatar'] ?? '',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member['name'] ?? '',
                            style: AppTypography.titleMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            member['role'] ?? '',
                            style: AppTypography.bodySmall.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70, size: 22),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _detailRow(Icons.business_rounded, 'Farm', member['farm'] ?? '', isDark),
                    _detailRow(Icons.work_outline_rounded, 'Specialty', member['specialty'] ?? '', isDark),
                    _detailRow(Icons.calendar_month_rounded, 'Joined', member['joinedDate'] ?? '', isDark),
                    _detailRow(Icons.phone_outlined, 'Phone', member['phone'] ?? '', isDark),
                    _detailRow(Icons.email_outlined, 'Email', member['email'] ?? '', isDark),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text('Status', style: AppTypography.caption.copyWith(color: isDark ? Colors.white54 : AppColors.textSecondary)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: statusColor.withOpacity(0.3)),
                          ),
                          child: Text(
                            status,
                            style: AppTypography.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (!isOwner) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : AppColors.neutral200),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Task Progress',
                                  style: AppTypography.bodySmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white70 : AppColors.textPrimary,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '$completed/$tasks',
                                  style: AppTypography.bodySmall.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: _progressColor(performance),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: LinearProgressIndicator(
                                value: performance,
                                minHeight: 8,
                                backgroundColor: isDark ? Colors.white.withOpacity(0.08) : AppColors.neutral200,
                                valueColor: AlwaysStoppedAnimation(_progressColor(performance)),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Completion', style: AppTypography.caption.copyWith(color: isDark ? Colors.white38 : AppColors.textSecondary)),
                                Text(
                                  '${(performance * 100).toInt()}%',
                                  style: AppTypography.bodySmall.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: _progressColor(performance),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Close'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark ? Colors.white70 : AppColors.textSecondary,
                          side: BorderSide(color: isDark ? Colors.white.withOpacity(0.12) : AppColors.neutral300),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.message_rounded, size: 16),
                        label: const Text('Message'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
    );
  }

  Widget _detailRow(IconData icon, String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : AppColors.neutral100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: isDark ? Colors.white54 : AppColors.textSecondary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.caption.copyWith(color: isDark ? Colors.white38 : AppColors.textSecondary)),
                Text(
                  value,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _memberInfoChip(IconData icon, String label, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : AppColors.neutral200),
        ),
        child: Row(
          children: [
            Icon(icon, size: 13, color: isDark ? Colors.white38 : AppColors.textSecondary),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500, color: isDark ? Colors.white54 : AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Icon(Icons.groups_outlined, size: 42, color: isDark ? Colors.white38 : AppColors.textSecondary),
          const SizedBox(height: 8),
          Text('No team members found', style: AppTypography.bodyMedium.copyWith(color: isDark ? Colors.white70 : AppColors.textSecondary)),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Active':
        return AppColors.success;
      case 'On Leave':
        return AppColors.warning;
      case 'Inactive':
        return AppColors.neutral500;
      default:
        return AppColors.info;
    }
  }

  Color _progressColor(double progress) {
    if (progress >= 0.8) return AppColors.success;
    if (progress >= 0.6) return AppColors.info;
    if (progress >= 0.4) return AppColors.warning;
    return AppColors.error;
  }

  Widget _buildBottomNavigation(bool isDark) {
    final navItems = [
      {'icon': Icons.dashboard_outlined, 'label': 'Dashboard', 'index': 0, 'route': '/farm-manager'},
      {'icon': Icons.agriculture_outlined, 'label': 'Farms', 'index': 1, 'route': '/farm-manager/farms'},
      {'icon': Icons.inventory_2_outlined, 'label': 'Inventory', 'index': 2, 'route': '/farm-manager/inventory'},
      {'icon': Icons.local_shipping_outlined, 'label': 'Deliveries', 'index': 3, 'route': '/farm-manager/deliveries'},
      {'icon': Icons.assessment_outlined, 'label': 'Reports', 'index': 4, 'route': '/farm-manager/reports'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.1), blurRadius: 10, offset: const Offset(0, -2))],
        border: Border(top: BorderSide(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08), width: 1)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: navItems.map((item) {
              final index = item['index'] as int;
              final route = item['route'] as String;
              final isSelected = index == _selectedNavIndex;

              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (_selectedNavIndex != index) {
                        setState(() => _selectedNavIndex = index);
                        try {
                          Navigator.pushReplacementNamed(context, route);
                        } catch (e) {
                          Navigator.pushNamed(context, route);
                        }
                      }
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item['icon'] as IconData,
                          size: 24,
                          color: isSelected ? AppColors.primary : (isDark ? Colors.white.withOpacity(0.5) : AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['label'] as String,
                          style: AppTypography.caption.copyWith(
                            color: isSelected ? AppColors.primary : (isDark ? Colors.white.withOpacity(0.5) : AppColors.textSecondary),
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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
}
