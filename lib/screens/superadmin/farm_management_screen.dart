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
  ConsumerState<FarmManagementScreen> createState() => _FarmManagementScreenState();
}

class _FarmManagementScreenState extends ConsumerState<FarmManagementScreen> {
  String _selectedFilter = 'All';
  
  final List<Map<String, dynamic>> _farms = [
    {'id': 'F001', 'name': 'Green Valley Farm', 'owner': 'Alice Owner', 'location': 'North Region', 'tier': 'Premium', 'status': 'Active', 'batches': 12, 'created': '2024-01-15'},
    {'id': 'F002', 'name': 'Sunny Acres', 'owner': 'Tom Davis', 'location': 'East Hills', 'tier': 'Standard', 'status': 'Pending', 'batches': 0, 'created': '2024-10-29'},
    {'id': 'F003', 'name': 'Harvest Moon Farm', 'owner': 'Emma Wilson', 'location': 'West Valley', 'tier': 'Premium', 'status': 'Active', 'batches': 8, 'created': '2024-02-20'},
    {'id': 'F004', 'name': 'Golden Fields', 'owner': 'Mike Brown', 'location': 'South Plains', 'tier': 'Basic', 'status': 'Active', 'batches': 5, 'created': '2024-03-10'},
    {'id': 'F005', 'name': 'Riverside Farm', 'owner': 'Sarah Green', 'location': 'Central District', 'tier': 'Standard', 'status': 'Suspended', 'batches': 3, 'created': '2024-04-05'},
    {'id': 'F006', 'name': 'Mountain View Farm', 'owner': 'David Lee', 'location': 'Highland Area', 'tier': 'Premium', 'status': 'Active', 'batches': 15, 'created': '2024-01-25'},
    {'id': 'F007', 'name': 'Valley Fresh Farms', 'owner': 'Lisa Chen', 'location': 'Valley Region', 'tier': 'Standard', 'status': 'Pending', 'batches': 0, 'created': '2024-10-28'},
  ];
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);
    
    final filteredFarms = _selectedFilter == 'All' 
        ? _farms 
        : _farms.where((f) => f['status'] == _selectedFilter).toList();
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Row(
        children: [
          SuperAdminSidebar(
            selectedIndex: 2,
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
                                Text('Farm Management', style: AppTypography.h4.copyWith(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)),
                                Text('Manage farms, approve registrations, and monitor operations', style: AppTypography.bodyMedium.copyWith(color: isDark ? Colors.white70 : AppColors.textSecondary)),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _showAddFarmDialog(context, isDark),
                              icon: const Icon(Icons.add_business, size: 20),
                              label: const Text('Add Farm'),
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
                        
                        // Farms Table
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
                              Text('All Farms (${filteredFarms.length})', style: AppTypography.h6.copyWith(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)),
                              const SizedBox(height: AppSpacing.lg),
                              ...filteredFarms.map((f) => _buildFarmRow(f, isDark)),
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
      {'title': 'Total Farms', 'value': '24', 'icon': Icons.agriculture, 'color': AppColors.success},
      {'title': 'Active', 'value': '20', 'icon': Icons.check_circle, 'color': AppColors.primary},
      {'title': 'Pending Approval', 'value': '2', 'icon': Icons.pending, 'color': AppColors.warning},
      {'title': 'Suspended', 'value': '2', 'icon': Icons.block, 'color': AppColors.error},
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
  
  Widget _buildFarmRow(Map<String, dynamic> farm, bool isDark) {
    Color statusColor;
    switch (farm['status']) {
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
    
    Color tierColor;
    switch (farm['tier']) {
      case 'Premium':
        tierColor = Colors.purple;
        break;
      case 'Standard':
        tierColor = AppColors.info;
        break;
      case 'Basic':
        tierColor = AppColors.textSecondary;
        break;
      default:
        tierColor = AppColors.textSecondary;
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: const Icon(Icons.agriculture, color: AppColors.success, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(farm['name'], style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isDark ? Colors.white : AppColors.textPrimary)),
                Text('Owner: ${farm['owner']}', style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : AppColors.textSecondary)),
              ],
            ),
          ),
          Expanded(
            child: Text(farm['location'], style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : AppColors.textSecondary)),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: tierColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Text(farm['tier'], style: TextStyle(color: tierColor, fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
            ),
          ),
          Expanded(
            child: Text('${farm['batches']} batches', style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : AppColors.textSecondary)),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Text(farm['status'], style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
            ),
          ),
          Row(
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
                  icon: Icon(farm['status'] == 'Suspended' ? Icons.check_circle_outline : Icons.block, size: 18),
                  color: farm['status'] == 'Suspended' ? AppColors.success : AppColors.error,
                  tooltip: farm['status'] == 'Suspended' ? 'Activate' : 'Suspend',
                ),
              ],
            ],
          ),
        ],
      ),
    );
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Farm'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              TextField(decoration: InputDecoration(labelText: 'Farm Name', border: OutlineInputBorder())),
              SizedBox(height: AppSpacing.md),
              TextField(decoration: InputDecoration(labelText: 'Owner', border: OutlineInputBorder())),
              SizedBox(height: AppSpacing.md),
              TextField(decoration: InputDecoration(labelText: 'Location', border: OutlineInputBorder())),
              SizedBox(height: AppSpacing.md),
              TextField(decoration: InputDecoration(labelText: 'Tier', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Farm added successfully!')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Add Farm'),
          ),
        ],
      ),
    );
  }
  
  void _showEditFarmDialog(BuildContext context, Map<String, dynamic> farm, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Farm'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(decoration: InputDecoration(labelText: 'Farm Name', border: const OutlineInputBorder()), controller: TextEditingController(text: farm['name'])),
              const SizedBox(height: AppSpacing.md),
              TextField(decoration: InputDecoration(labelText: 'Owner', border: const OutlineInputBorder()), controller: TextEditingController(text: farm['owner'])),
              const SizedBox(height: AppSpacing.md),
              TextField(decoration: InputDecoration(labelText: 'Location', border: const OutlineInputBorder()), controller: TextEditingController(text: farm['location'])),
              const SizedBox(height: AppSpacing.md),
              TextField(decoration: InputDecoration(labelText: 'Tier', border: const OutlineInputBorder()), controller: TextEditingController(text: farm['tier'])),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Farm updated successfully!')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
