import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/superadmin_sidebar.dart';
import '../../core/widgets/modern_admin_header.dart';
import '../../providers/auth_provider.dart';

/// Super Admin Farm Management - Manage all farms with approval workflow
class FarmManagementScreen extends ConsumerStatefulWidget {
  const FarmManagementScreen({super.key});

  @override
  ConsumerState<FarmManagementScreen> createState() =>
      _FarmManagementScreenState();
}

class _FarmManagementScreenState extends ConsumerState<FarmManagementScreen> {
  String _selectedFilter = 'All';
  int _selectedNavIndex = 2;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Map<String, dynamic>> _farms = [
    {
      'id': 'F001',
      'name': 'Green Valley Farm',
      'owner': 'Alice Owner',
      'location': 'North Region',
      'tier': 'Premium',
      'status': 'Active',
      'batches': 12,
      'created': '2024-01-15'
    },
    {
      'id': 'F002',
      'name': 'Sunny Acres',
      'owner': 'Tom Davis',
      'location': 'East Hills',
      'tier': 'Standard',
      'status': 'Pending',
      'batches': 0,
      'created': '2024-10-29'
    },
    {
      'id': 'F003',
      'name': 'Harvest Moon Farm',
      'owner': 'Emma Wilson',
      'location': 'West Valley',
      'tier': 'Premium',
      'status': 'Active',
      'batches': 8,
      'created': '2024-02-20'
    },
    {
      'id': 'F004',
      'name': 'Golden Fields',
      'owner': 'Mike Brown',
      'location': 'South Plains',
      'tier': 'Basic',
      'status': 'Active',
      'batches': 5,
      'created': '2024-03-10'
    },
    {
      'id': 'F005',
      'name': 'Riverside Farm',
      'owner': 'Sarah Green',
      'location': 'Central District',
      'tier': 'Standard',
      'status': 'Suspended',
      'batches': 3,
      'created': '2024-04-05'
    },
    {
      'id': 'F006',
      'name': 'Mountain View Farm',
      'owner': 'David Lee',
      'location': 'Highland Area',
      'tier': 'Premium',
      'status': 'Active',
      'batches': 15,
      'created': '2024-01-25'
    },
    {
      'id': 'F007',
      'name': 'Valley Fresh Farms',
      'owner': 'Lisa Chen',
      'location': 'Valley Region',
      'tier': 'Standard',
      'status': 'Pending',
      'batches': 0,
      'created': '2024-10-28'
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth < 1200 && screenWidth >= 600;

    final filteredFarms = _selectedFilter == 'All'
        ? _farms
        : _farms.where((f) => f['status'] == _selectedFilter).toList();

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
              filteredFarms: filteredFarms,
              firstName: firstName,
            )
          : _buildDesktopLayout(
              isDark: isDark,
              filteredFarms: filteredFarms,
              userName: userName,
              userEmail: userEmail,
              firstName: firstName,
              isTablet: isTablet,
            ),
    );
  }

  Widget _buildDesktopLayout({
    required bool isDark,
    required List<Map<String, dynamic>> filteredFarms,
    required String userName,
    required String userEmail,
    required String firstName,
    required bool isTablet,
  }) {
    return Row(
      children: [
        SuperAdminSidebar(
          selectedIndex: 2,
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
                  child: _buildFarmContent(
                    isDark: isDark,
                    filteredFarms: filteredFarms,
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
    required List<Map<String, dynamic>> filteredFarms,
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
            child: _buildFarmContent(
              isDark: isDark,
              filteredFarms: filteredFarms,
              isCompact: true,
              isMobile: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFarmContent({
    required bool isDark,
    required List<Map<String, dynamic>> filteredFarms,
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
          _buildFarmCards(filteredFarms, isDark)
        else
          _buildFarmTable(filteredFarms, isDark),
      ],
    );
  }

  Widget _buildHeaderSection(bool isDark, bool isCompact) {
    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Farm Management',
            style: AppTypography.h5.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage farms, approve registrations, and monitor operations',
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showAddFarmDialog(context, isDark),
              icon: const Icon(Icons.add_business, size: 18),
              label: const Text('Add Farm'),
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
              'Farm Management',
              style: AppTypography.h4.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            Text(
              'Manage farms, approve registrations, and monitor operations',
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _showAddFarmDialog(context, isDark),
          icon: const Icon(Icons.add_business, size: 20),
          label: const Text('Add Farm'),
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

  Widget _buildFarmTable(
      List<Map<String, dynamic>> filteredFarms, bool isDark) {
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
                  'All Farms',
                  style: AppTypography.h6.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${filteredFarms.length} records',
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? Colors.white60 : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildFarmTableHeader(isDark),
          const SizedBox(height: AppSpacing.sm),
          ...filteredFarms.map((f) => _buildFarmRow(f, isDark)),
        ],
      ),
    );
  }

  Widget _buildFarmTableHeader(bool isDark) {
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
          _buildTableHeader('Farm', flex: 3, isDark: isDark),
          _buildTableHeader('Location', flex: 2, isDark: isDark),
          _buildTableHeader('Tier', isDark: isDark),
          _buildTableHeader('Batches', isDark: isDark),
          _buildTableHeader('Status', isDark: isDark),
          _buildTableHeader('Created', isDark: isDark),
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

  Widget _buildFarmActionButtons(Map<String, dynamic> farm, bool isDark) {
    final isPending = farm['status'] == 'Pending';
    return SizedBox(
      width: 88,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (isPending) ...[
            _buildTableIconAction(
              Icons.check_circle,
              AppColors.success,
              () => _approveFarm(farm),
              'Approve',
            ),
            _buildTableIconAction(
              Icons.cancel,
              AppColors.error,
              () => _rejectFarm(farm),
              'Reject',
            ),
          ] else ...[
            _buildTableIconAction(
              Icons.edit_outlined,
              AppColors.primary,
              () => _showEditFarmDialog(context, farm, isDark),
              'Edit',
            ),
            _buildTableIconAction(
              farm['status'] == 'Suspended'
                  ? Icons.check_circle_outline
                  : Icons.block,
              farm['status'] == 'Suspended'
                  ? AppColors.success
                  : AppColors.error,
              () => _toggleSuspend(farm),
              farm['status'] == 'Suspended' ? 'Activate' : 'Suspend',
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

  Widget _buildFarmCards(
      List<Map<String, dynamic>> filteredFarms, bool isDark) {
    return Column(
      children: [
        for (final farm in filteredFarms) _buildMobileFarmCard(farm, isDark),
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
        'title': 'Total Farms',
        'value': '24',
        'icon': Icons.agriculture,
        'color': AppColors.success
      },
      {
        'title': 'Active',
        'value': '20',
        'icon': Icons.check_circle,
        'color': AppColors.primary
      },
      {
        'title': 'Pending',
        'value': '2',
        'icon': Icons.pending,
        'color': AppColors.warning
      },
      {
        'title': 'Suspended',
        'value': '2',
        'icon': Icons.block,
        'color': AppColors.error
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        final statColor = stat['color'] as Color;
        return Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: statColor.withOpacity(isDark ? 0.15 : 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: statColor.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child:
                    Icon(stat['icon'] as IconData, color: statColor, size: 18),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      stat['value'] as String,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: statColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      stat['title'] as String,
                      style: TextStyle(
                          fontSize: 10, color: statColor.withOpacity(0.8)),
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

  Widget _buildFarmRow(Map<String, dynamic> farm, bool isDark) {
    final statusColor = _statusColor(farm['status']);
    final tierColor = _tierColor(farm['tier']);

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
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: const Icon(Icons.agriculture,
                      color: AppColors.success, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(farm['name'],
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textPrimary)),
                      Text('${farm['id']} • Owner: ${farm['owner']}',
                          style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.white54
                                  : AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              farm['location'],
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(child: _buildBadge(farm['tier'], tierColor)),
          Expanded(
            child: Text(
              '${farm['batches']}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(child: _buildBadge(farm['status'], statusColor)),
          Expanded(
            child: Text(
              farm['created'],
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white60 : AppColors.textSecondary,
              ),
            ),
          ),
          _buildFarmActionButtons(farm, isDark),
        ],
      ),
    );
  }

  Widget _buildMobileFarmCard(Map<String, dynamic> farm, bool isDark) {
    final statusColor = _statusColor(farm['status']);
    final tierColor = _tierColor(farm['tier']);
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Icon(Icons.agriculture,
                    color: AppColors.success, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      farm['name'],
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
                      'Owner: ${farm['owner']}',
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
                  farm['status'],
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
              _buildInfoPill('Location', farm['location'], isDark),
              _buildInfoPill('Tier', farm['tier'], isDark,
                  valueColor: tierColor),
              _buildInfoPill('Batches', '${farm['batches']} batches', isDark),
              _buildInfoPill('Created', farm['created'], isDark),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (farm['status'] == 'Pending') ...[
                  IconButton(
                    onPressed: () => _approveFarm(farm),
                    icon: const Icon(Icons.check_circle, size: 20),
                    color: AppColors.success,
                    tooltip: 'Approve',
                  ),
                  IconButton(
                    onPressed: () => _rejectFarm(farm),
                    icon: const Icon(Icons.cancel, size: 20),
                    color: AppColors.error,
                    tooltip: 'Reject',
                  ),
                ] else ...[
                  IconButton(
                    onPressed: () => _showEditFarmDialog(context, farm, isDark),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    color: AppColors.primary,
                  ),
                  IconButton(
                    onPressed: () => _toggleSuspend(farm),
                    icon: Icon(
                        farm['status'] == 'Suspended'
                            ? Icons.check_circle_outline
                            : Icons.block,
                        size: 18),
                    color: farm['status'] == 'Suspended'
                        ? AppColors.success
                        : AppColors.error,
                    tooltip:
                        farm['status'] == 'Suspended' ? 'Activate' : 'Suspend',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPill(String label, String value, bool isDark,
      {Color? valueColor}) {
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
          color:
              valueColor ?? (isDark ? Colors.white70 : AppColors.textSecondary),
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

  Color _tierColor(String tier) {
    switch (tier) {
      case 'Premium':
        return Colors.purple;
      case 'Standard':
        return AppColors.info;
      case 'Basic':
        return AppColors.textSecondary;
      default:
        return AppColors.textSecondary;
    }
  }

  void _approveFarm(Map<String, dynamic> farm) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${farm['name']} approved successfully!')),
    );
  }

  void _rejectFarm(Map<String, dynamic> farm) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${farm['name']} rejected')),
    );
  }

  void _toggleSuspend(Map<String, dynamic> farm) {
    final action = farm['status'] == 'Suspended' ? 'activated' : 'suspended';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${farm['name']} $action')),
    );
  }

  void _showAddFarmDialog(BuildContext context, bool isDark) {
    final nameController = TextEditingController();
    final ownerController = TextEditingController();
    final locationController = TextEditingController();
    String selectedTier = 'Standard';
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
            width: isMobile ? double.infinity : 500,
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
                        AppColors.success,
                        AppColors.success.withOpacity(0.8)
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
                        child: const Icon(Icons.add_business,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add New Farm',
                              style: AppTypography.h6.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Register a new farm in the system',
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
                        _buildFormLabel('Farm Name', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildTextField(
                            controller: nameController,
                            hint: 'Enter farm name',
                            icon: Icons.agriculture,
                            isDark: isDark),
                        const SizedBox(height: AppSpacing.lg),
                        _buildFormLabel('Owner', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildTextField(
                            controller: ownerController,
                            hint: 'Enter owner name',
                            icon: Icons.person_outline,
                            isDark: isDark),
                        const SizedBox(height: AppSpacing.lg),
                        _buildFormLabel('Location', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildTextField(
                            controller: locationController,
                            hint: 'Enter farm location',
                            icon: Icons.location_on_outlined,
                            isDark: isDark),
                        const SizedBox(height: AppSpacing.lg),
                        _buildFormLabel('Subscription Tier', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildDropdownField(
                          value: selectedTier,
                          items: ['Basic', 'Standard', 'Premium'],
                          icon: Icons.star_outline,
                          isDark: isDark,
                          onChanged: (value) =>
                              setDialogState(() => selectedTier = value!),
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
                          child: Text('Cancel',
                              style: TextStyle(
                                  color: isDark
                                      ? Colors.white70
                                      : AppColors.textSecondary)),
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
                                content: Row(children: [
                                  const Icon(Icons.check_circle,
                                      color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(
                                      '${nameController.text.isEmpty ? "Farm" : nameController.text} added successfully!'),
                                ]),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusMd)),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Farm'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
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

  void _showEditFarmDialog(
      BuildContext context, Map<String, dynamic> farm, bool isDark) {
    final nameController = TextEditingController(text: farm['name']);
    final ownerController = TextEditingController(text: farm['owner']);
    final locationController = TextEditingController(text: farm['location']);
    String selectedTier = farm['tier'];
    String selectedStatus = farm['status'];
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
            width: isMobile ? double.infinity : 500,
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
                        AppColors.success,
                        AppColors.success.withOpacity(0.8)
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
                            Text('Edit Farm',
                                style: AppTypography.h6.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                            Text('Update farm information',
                                style: AppTypography.bodySmall
                                    .copyWith(color: Colors.white70)),
                          ],
                        ),
                      ),
                      IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white70)),
                    ],
                  ),
                ),

                // Farm Preview
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
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: const Icon(Icons.agriculture,
                            color: AppColors.success, size: 24),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(farm['name'],
                                style: AppTypography.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.textPrimary)),
                            Text(
                                'ID: ${farm['id']} • ${farm['batches']} batches',
                                style: AppTypography.bodySmall.copyWith(
                                    color: isDark
                                        ? Colors.white60
                                        : AppColors.textSecondary)),
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
                        _buildFormLabel('Farm Name', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildTextField(
                            controller: nameController,
                            hint: 'Enter farm name',
                            icon: Icons.agriculture,
                            isDark: isDark),
                        const SizedBox(height: AppSpacing.lg),
                        _buildFormLabel('Owner', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildTextField(
                            controller: ownerController,
                            hint: 'Enter owner name',
                            icon: Icons.person_outline,
                            isDark: isDark),
                        const SizedBox(height: AppSpacing.lg),
                        _buildFormLabel('Location', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildTextField(
                            controller: locationController,
                            hint: 'Enter farm location',
                            icon: Icons.location_on_outlined,
                            isDark: isDark),
                        const SizedBox(height: AppSpacing.lg),
                        if (!isMobile)
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFormLabel('Tier', isDark),
                                    const SizedBox(height: AppSpacing.sm),
                                    _buildDropdownField(
                                        value: selectedTier,
                                        items: ['Basic', 'Standard', 'Premium'],
                                        icon: Icons.star_outline,
                                        isDark: isDark,
                                        onChanged: (v) => setDialogState(
                                            () => selectedTier = v!)),
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
                                        items: [
                                          'Active',
                                          'Pending',
                                          'Suspended'
                                        ],
                                        icon: Icons.toggle_on_outlined,
                                        isDark: isDark,
                                        onChanged: (v) => setDialogState(
                                            () => selectedStatus = v!)),
                                  ],
                                ),
                              ),
                            ],
                          )
                        else ...[
                          _buildFormLabel('Tier', isDark),
                          const SizedBox(height: AppSpacing.sm),
                          _buildDropdownField(
                              value: selectedTier,
                              items: ['Basic', 'Standard', 'Premium'],
                              icon: Icons.star_outline,
                              isDark: isDark,
                              onChanged: (v) =>
                                  setDialogState(() => selectedTier = v!)),
                          const SizedBox(height: AppSpacing.lg),
                          _buildFormLabel('Status', isDark),
                          const SizedBox(height: AppSpacing.sm),
                          _buildDropdownField(
                              value: selectedStatus,
                              items: ['Active', 'Pending', 'Suspended'],
                              icon: Icons.toggle_on_outlined,
                              isDark: isDark,
                              onChanged: (v) =>
                                  setDialogState(() => selectedStatus = v!)),
                        ],
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
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showDeleteFarmDialog(context, farm, isDark);
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
                          child: Text('Cancel',
                              style: TextStyle(
                                  color: isDark
                                      ? Colors.white70
                                      : AppColors.textSecondary)),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(children: [
                                  const Icon(Icons.check_circle,
                                      color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text('${nameController.text} updated!')
                                ]),
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
                            backgroundColor: AppColors.success,
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

  void _showDeleteFarmDialog(
      BuildContext context, Map<String, dynamic> farm, bool isDark) {
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
                    shape: BoxShape.circle),
                child: const Icon(Icons.delete_forever,
                    color: AppColors.error, size: 40),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Delete Farm?',
                  style: AppTypography.h5.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary)),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Are you sure you want to delete "${farm['name']}"? This will remove all associated data.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? Colors.white70 : AppColors.textSecondary),
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
                      child: Text('Cancel',
                          style: TextStyle(
                              color: isDark
                                  ? Colors.white70
                                  : AppColors.textSecondary)),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(children: [
                              const Icon(Icons.delete, color: Colors.white),
                              const SizedBox(width: 8),
                              Text('${farm['name']} deleted')
                            ]),
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
    return Text(label,
        style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppColors.textPrimary));
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      required String hint,
      required IconData icon,
      required bool isDark,
      TextInputType keyboardType = TextInputType.text}) {
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
            borderSide: BorderSide(
                color: isDark ? Colors.white12 : AppColors.neutral200)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: BorderSide(
                color: isDark ? Colors.white12 : AppColors.neutral200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: const BorderSide(color: AppColors.success, width: 2)),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
      ),
    );
  }

  Widget _buildDropdownField(
      {required String value,
      required List<String> items,
      required IconData icon,
      required bool isDark,
      required Function(String?) onChanged}) {
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
                  child: Row(children: [
                    Icon(icon,
                        color:
                            isDark ? Colors.white54 : AppColors.textSecondary,
                        size: 20),
                    const SizedBox(width: AppSpacing.md),
                    Text(item)
                  ])))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
