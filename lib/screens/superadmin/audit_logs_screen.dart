import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/superadmin_sidebar.dart';
import '../../core/widgets/modern_admin_header.dart';
import '../../providers/auth_provider.dart';

/// Audit Logs - View all system activities and user actions
class AuditLogsScreen extends ConsumerStatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  ConsumerState<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends ConsumerState<AuditLogsScreen> {
  String _selectedFilter = 'All';
  
  final List<Map<String, dynamic>> _auditLogs = [
    {'id': 'AL001', 'user': 'Sarah SuperAdmin', 'action': 'Created plant type "Cherry Tomatoes"', 'category': 'Create', 'timestamp': '2024-10-31 14:30', 'ip': '192.168.1.100'},
    {'id': 'AL002', 'user': 'Sarah SuperAdmin', 'action': 'Approved user "John Smith"', 'category': 'Approve', 'timestamp': '2024-10-31 12:15', 'ip': '192.168.1.100'},
    {'id': 'AL003', 'user': 'John Admin', 'action': 'Updated farm "Green Valley Farm"', 'category': 'Update', 'timestamp': '2024-10-31 11:45', 'ip': '192.168.1.105'},
    {'id': 'AL004', 'user': 'Sarah SuperAdmin', 'action': 'Set pricing for "Lettuce - 500g"', 'category': 'Update', 'timestamp': '2024-10-31 10:20', 'ip': '192.168.1.100'},
    {'id': 'AL005', 'user': 'John Admin', 'action': 'Deleted sensor "TEMP-045"', 'category': 'Delete', 'timestamp': '2024-10-31 09:30', 'ip': '192.168.1.105'},
    {'id': 'AL006', 'user': 'Sarah SuperAdmin', 'action': 'Created system backup', 'category': 'System', 'timestamp': '2024-10-31 08:00', 'ip': '192.168.1.100'},
    {'id': 'AL007', 'user': 'Alice Owner', 'action': 'Added batch "BATCH-156"', 'category': 'Create', 'timestamp': '2024-10-30 16:45', 'ip': '192.168.1.110'},
    {'id': 'AL008', 'user': 'Sarah SuperAdmin', 'action': 'Suspended farm "Riverside Farm"', 'category': 'Suspend', 'timestamp': '2024-10-30 14:20', 'ip': '192.168.1.100'},
    {'id': 'AL009', 'user': 'John Admin', 'action': 'Updated user role for "Bob Caretaker"', 'category': 'Update', 'timestamp': '2024-10-30 11:30', 'ip': '192.168.1.105'},
    {'id': 'AL010', 'user': 'Sarah SuperAdmin', 'action': 'Configured system notifications', 'category': 'System', 'timestamp': '2024-10-30 09:15', 'ip': '192.168.1.100'},
  ];
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);
    
    final filteredLogs = _selectedFilter == 'All' 
        ? _auditLogs 
        : _auditLogs.where((log) => log['category'] == _selectedFilter).toList();
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Row(
        children: [
          SuperAdminSidebar(
            selectedIndex: 6,
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
                                Text('Audit Logs', style: AppTypography.h4.copyWith(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)),
                                Text('Complete system activity history and user actions', style: AppTypography.bodyMedium.copyWith(color: isDark ? Colors.white70 : AppColors.textSecondary)),
                              ],
                            ),
                            Row(
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(Icons.filter_list, size: 18),
                                  label: const Text('Filter'),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                ElevatedButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(Icons.download, size: 18),
                                  label: const Text('Export'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
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
                        
                        // Logs Table
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
                              Text('Activity Log (${filteredLogs.length})', style: AppTypography.h6.copyWith(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)),
                              const SizedBox(height: AppSpacing.lg),
                              ...filteredLogs.map((log) => _buildLogRow(log, isDark)),
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
      {'title': 'Total Logs', 'value': '12.5K', 'icon': Icons.history, 'color': AppColors.primary},
      {'title': 'Today', 'value': '156', 'icon': Icons.today, 'color': AppColors.success},
      {'title': 'This Week', 'value': '842', 'icon': Icons.date_range, 'color': AppColors.info},
      {'title': 'Critical Actions', 'value': '23', 'icon': Icons.warning, 'color': AppColors.error},
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
    final filters = ['All', 'Create', 'Update', 'Delete', 'Approve', 'Suspend', 'System'];
    
    return Wrap(
      spacing: AppSpacing.sm,
      children: filters.map((filter) => ChoiceChip(
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
      )).toList(),
    );
  }
  
  Widget _buildLogRow(Map<String, dynamic> log, bool isDark) {
    Color categoryColor;
    IconData categoryIcon;
    
    switch (log['category']) {
      case 'Create':
        categoryColor = AppColors.success;
        categoryIcon = Icons.add_circle;
        break;
      case 'Update':
        categoryColor = AppColors.info;
        categoryIcon = Icons.edit;
        break;
      case 'Delete':
        categoryColor = AppColors.error;
        categoryIcon = Icons.delete;
        break;
      case 'Approve':
        categoryColor = AppColors.primary;
        categoryIcon = Icons.check_circle;
        break;
      case 'Suspend':
        categoryColor = AppColors.warning;
        categoryIcon = Icons.block;
        break;
      case 'System':
        categoryColor = Colors.purple;
        categoryIcon = Icons.settings;
        break;
      default:
        categoryColor = AppColors.textSecondary;
        categoryIcon = Icons.info;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(categoryIcon, color: categoryColor, size: 16),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log['action'], style: TextStyle(fontSize: 13, color: isDark ? Colors.white : AppColors.textPrimary)),
                Text('by ${log['user']}', style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : AppColors.textSecondary)),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Text(log['category'], style: TextStyle(color: categoryColor, fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
            ),
          ),
          Expanded(
            child: Text(log['timestamp'], style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : AppColors.textSecondary)),
          ),
          Expanded(
            child: Row(
              children: [
                const Icon(Icons.computer, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(log['ip'], style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : AppColors.textSecondary)),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.visibility, size: 18),
            color: AppColors.primary,
            tooltip: 'View Details',
          ),
        ],
      ),
    );
  }
}
