import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  String _selectedUser = 'All Users';
  String _searchQuery = '';
  DateTimeRange? _selectedDateRange;
  int _selectedNavIndex = 6;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final userName = user?.name ?? 'Super Admin';
    final userEmail = user?.email ?? '';
    final firstName = userName.split(' ').first;
    
    // Apply all filters
    List<Map<String, dynamic>> filteredLogs = _auditLogs;
    
    // Category filter
    if (_selectedFilter != 'All') {
      filteredLogs = filteredLogs.where((log) => log['category'] == _selectedFilter).toList();
    }
    
    // User filter
    if (_selectedUser != 'All Users') {
      filteredLogs = filteredLogs.where((log) => log['user'] == _selectedUser).toList();
    }
    
    // Search filter
    if (_searchQuery.isNotEmpty) {
      filteredLogs = filteredLogs.where((log) => 
        log['action'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
        log['user'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
        log['id'].toString().toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    // Date range filter
    if (_selectedDateRange != null) {
      filteredLogs = filteredLogs.where((log) {
        final logDate = DateTime.tryParse(log['timestamp'].toString().split(' ').first.replaceAll('-', '/'));
        if (logDate == null) return true;
        return logDate.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) &&
               logDate.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }
    
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
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
          ? _buildMobileLayout(isDark, firstName, filteredLogs)
          : _buildDesktopLayout(isDark, userName, userEmail, firstName, filteredLogs),
    );
  }
  
  Widget _buildDesktopLayout(bool isDark, String userName, String userEmail, String firstName, List<Map<String, dynamic>> filteredLogs) {
    return Row(
      children: [
        SuperAdminSidebar(
          selectedIndex: 6,
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
                  child: _buildContent(isDark, filteredLogs),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildMobileLayout(bool isDark, String firstName, List<Map<String, dynamic>> filteredLogs) {
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
            child: _buildMobileContent(isDark, filteredLogs),
          ),
        ),
      ],
    );
  }
  
  Widget _buildMobileContent(bool isDark, List<Map<String, dynamic>> filteredLogs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header - Mobile
        Text(
          'Audit Logs',
          style: AppTypography.h5.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'System activity history',
          style: AppTypography.bodySmall.copyWith(
            color: isDark ? Colors.white70 : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        
        // Action buttons - Mobile
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showAdvancedFilterDialog(context, isDark),
                icon: const Icon(Icons.filter_list, size: 16),
                label: Text(_hasActiveFilters() ? 'Filters*' : 'Filter', style: const TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  side: _hasActiveFilters() ? BorderSide(color: AppColors.primary) : null,
                  foregroundColor: _hasActiveFilters() ? AppColors.primary : null,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showExportDialog(context, isDark, filteredLogs),
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Export', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: AppSpacing.lg),
        
        // Stats - Mobile Grid
        _buildMobileStats(isDark),
        
        const SizedBox(height: AppSpacing.lg),
        
        // Filters
        _buildFilters(isDark),
        
        const SizedBox(height: AppSpacing.md),
        
        // Logs List - Mobile Cards
        Text(
          'Activity Log (${filteredLogs.length})',
          style: AppTypography.h6.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...filteredLogs.map((log) => _buildMobileLogCard(log, isDark)),
      ],
    );
  }
  
  Widget _buildContent(bool isDark, List<Map<String, dynamic>> filteredLogs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Audit Logs', style: AppTypography.h4.copyWith(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)),
                  Text('Complete system activity history and user actions', style: AppTypography.bodyMedium.copyWith(color: isDark ? Colors.white70 : AppColors.textSecondary)),
                ],
              ),
            ),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showAdvancedFilterDialog(context, isDark),
                  icon: const Icon(Icons.filter_list, size: 18),
                  label: Text(_hasActiveFilters() ? 'Filters (Active)' : 'Filter'),
                  style: _hasActiveFilters() ? OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.primary),
                    foregroundColor: AppColors.primary,
                  ) : null,
                ),
                const SizedBox(width: AppSpacing.sm),
                ElevatedButton.icon(
                  onPressed: () => _showExportDialog(context, isDark, filteredLogs),
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
    );
  }
  
  Widget _buildMobileStats(bool isDark) {
    final stats = [
      {'title': 'Total Logs', 'value': '12.5K', 'icon': Icons.history, 'color': AppColors.primary},
      {'title': 'Today', 'value': '156', 'icon': Icons.today, 'color': AppColors.success},
      {'title': 'This Week', 'value': '842', 'icon': Icons.date_range, 'color': AppColors.info},
      {'title': 'Critical', 'value': '23', 'icon': Icons.warning, 'color': AppColors.error},
    ];
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1.7,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(stat['icon'] as IconData, color: statColor, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      stat['title'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        color: statColor.withOpacity(0.9),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                stat['value'] as String,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: statColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
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
    final categoryData = _getCategoryData(log['category']);
    final categoryColor = categoryData['color'] as Color;
    final categoryIcon = categoryData['icon'] as IconData;
    
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
            onPressed: () => _showLogDetailsDialog(context, log, isDark),
            icon: const Icon(Icons.visibility, size: 18),
            color: AppColors.primary,
            tooltip: 'View Details',
          ),
        ],
      ),
    );
  }
  
  Widget _buildMobileLogCard(Map<String, dynamic> log, bool isDark) {
    final categoryData = _getCategoryData(log['category']);
    final categoryColor = categoryData['color'] as Color;
    final categoryIcon = categoryData['icon'] as IconData;
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(categoryIcon, color: categoryColor, size: 14),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log['action'],
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'by ${log['user']}',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.white60 : AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  log['category'],
                  style: TextStyle(
                    color: categoryColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(Icons.schedule, size: 12, color: isDark ? Colors.white54 : AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                log['timestamp'],
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.white54 : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Icon(Icons.computer, size: 12, color: isDark ? Colors.white54 : AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                log['ip'],
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.white54 : AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 28,
                height: 28,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => _showLogDetailsDialog(context, log, isDark),
                  icon: const Icon(Icons.visibility, size: 16),
                  color: AppColors.primary,
                  tooltip: 'View Details',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  void _showLogDetailsDialog(BuildContext context, Map<String, dynamic> log, bool isDark) {
    final categoryData = _getCategoryData(log['category']);
    final categoryColor = categoryData['color'] as Color;
    final categoryIcon = categoryData['icon'] as IconData;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusXl)),
        insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? AppSpacing.md : AppSpacing.xxl, vertical: AppSpacing.xl),
        child: Container(
          width: isMobile ? double.infinity : 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [categoryColor, categoryColor.withOpacity(0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                      child: Icon(categoryIcon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Audit Log Details', style: AppTypography.h6.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                          Text('ID: ${log['id']}', style: AppTypography.bodySmall.copyWith(color: Colors.white70)),
                        ],
                      ),
                    ),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white70)),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Action
                    _buildDetailRow('Action', log['action'], Icons.flash_on, categoryColor, isDark),
                    const SizedBox(height: AppSpacing.lg),
                    // Category
                    _buildDetailRow('Category', log['category'], categoryIcon, categoryColor, isDark, isChip: true),
                    const SizedBox(height: AppSpacing.lg),
                    // User Info Section
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.05) : AppColors.neutral50,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('User Information', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : AppColors.textSecondary)),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: AppColors.primary.withOpacity(0.1),
                                child: Text(
                                  log['user'].toString().substring(0, 1).toUpperCase(),
                                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(log['user'], style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textPrimary)),
                                    Row(
                                      children: [
                                        const Icon(Icons.computer, size: 12, color: AppColors.textSecondary),
                                        const SizedBox(width: 4),
                                        Text(log['ip'], style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : AppColors.textSecondary)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    // Timestamp
                    _buildDetailRow('Timestamp', log['timestamp'], Icons.schedule, AppColors.info, isDark),
                    const SizedBox(height: AppSpacing.lg),
                    // Additional Info
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(color: AppColors.info.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: AppColors.info, size: 20),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(child: Text('This log entry was automatically generated by the system.', style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : AppColors.textSecondary))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Actions
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppSpacing.radiusXl)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(children: [const Icon(Icons.copy, color: Colors.white, size: 18), const SizedBox(width: 8), const Text('Log copied to clipboard!')]),
                              backgroundColor: AppColors.info,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('Copy'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                          side: BorderSide(color: isDark ? Colors.white24 : AppColors.neutral300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: categoryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                        ),
                        child: const Text('Close'),
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
  
  Widget _buildDetailRow(String label, String value, IconData icon, Color color, bool isDark, {bool isChip = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : AppColors.textSecondary)),
              const SizedBox(height: 2),
              if (isChip)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(AppSpacing.radiusFull)),
                  child: Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
                )
              else
                Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isDark ? Colors.white : AppColors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }
  
  Map<String, dynamic> _getCategoryData(String category) {
    switch (category) {
      case 'Create':
        return {'color': AppColors.success, 'icon': Icons.add_circle};
      case 'Update':
        return {'color': AppColors.info, 'icon': Icons.edit};
      case 'Delete':
        return {'color': AppColors.error, 'icon': Icons.delete};
      case 'Approve':
        return {'color': AppColors.primary, 'icon': Icons.check_circle};
      case 'Suspend':
        return {'color': AppColors.warning, 'icon': Icons.block};
      case 'System':
        return {'color': Colors.purple, 'icon': Icons.settings};
      default:
        return {'color': AppColors.textSecondary, 'icon': Icons.info};
    }
  }

  bool _hasActiveFilters() {
    return _selectedUser != 'All Users' || 
           _searchQuery.isNotEmpty || 
           _selectedDateRange != null;
  }

  List<String> _getUniqueUsers() {
    final users = _auditLogs.map((log) => log['user'] as String).toSet().toList();
    users.sort();
    return ['All Users', ...users];
  }

  void _showAdvancedFilterDialog(BuildContext context, bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusXl)),
          insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? AppSpacing.md : AppSpacing.xxl, vertical: AppSpacing.xl),
          child: Container(
            width: isMobile ? double.infinity : 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                        child: const Icon(Icons.filter_list, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Advanced Filters', style: AppTypography.h6.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                            Text('Refine your search results', style: AppTypography.bodySmall.copyWith(color: Colors.white70)),
                          ],
                        ),
                      ),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white70)),
                    ],
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search
                      Text('Search', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : AppColors.textSecondary)),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by action, user, or ID...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setDialogState(() {});
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                          filled: true,
                          fillColor: isDark ? Colors.white.withOpacity(0.05) : AppColors.neutral50,
                          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                        ),
                        onChanged: (value) => setDialogState(() {}),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      
                      // User Filter
                      Text('Filter by User', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : AppColors.textSecondary)),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        decoration: BoxDecoration(
                          border: Border.all(color: isDark ? Colors.white24 : AppColors.neutral300),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          color: isDark ? Colors.white.withOpacity(0.05) : AppColors.neutral50,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedUser,
                            isExpanded: true,
                            dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
                            items: _getUniqueUsers().map((user) => DropdownMenuItem(
                              value: user,
                              child: Text(user, style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary)),
                            )).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setDialogState(() => _selectedUser = value);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      
                      // Date Range
                      Text('Date Range', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : AppColors.textSecondary)),
                      const SizedBox(height: AppSpacing.sm),
                      InkWell(
                        onTap: () async {
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2024),
                            lastDate: DateTime.now(),
                            initialDateRange: _selectedDateRange,
                            builder: (context, child) => Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.fromSeed(
                                  seedColor: AppColors.primary,
                                  brightness: isDark ? Brightness.dark : Brightness.light,
                                ),
                              ),
                              child: child!,
                            ),
                          );
                          if (picked != null) {
                            setDialogState(() => _selectedDateRange = picked);
                          }
                        },
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            border: Border.all(color: isDark ? Colors.white24 : AppColors.neutral300),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            color: isDark ? Colors.white.withOpacity(0.05) : AppColors.neutral50,
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, size: 18, color: isDark ? Colors.white54 : AppColors.textSecondary),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  _selectedDateRange != null
                                      ? '${_selectedDateRange!.start.toString().split(' ').first} - ${_selectedDateRange!.end.toString().split(' ').first}'
                                      : 'Select date range...',
                                  style: TextStyle(
                                    color: _selectedDateRange != null
                                        ? (isDark ? Colors.white : AppColors.textPrimary)
                                        : (isDark ? Colors.white54 : AppColors.textSecondary),
                                  ),
                                ),
                              ),
                              if (_selectedDateRange != null)
                                IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () => setDialogState(() => _selectedDateRange = null),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Active Filters Summary
                      if (_hasActiveFilters() || _searchController.text.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.info.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            border: Border.all(color: AppColors.info.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: AppColors.info, size: 18),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  'Active filters will be applied when you click Apply',
                                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : AppColors.textSecondary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Actions
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppSpacing.radiusXl)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setDialogState(() {
                              _searchController.clear();
                              _selectedUser = 'All Users';
                              _selectedDateRange = null;
                            });
                            setState(() {
                              _searchQuery = '';
                              _selectedUser = 'All Users';
                              _selectedDateRange = null;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                            side: BorderSide(color: isDark ? Colors.white24 : AppColors.neutral300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                          ),
                          child: const Text('Clear All'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _searchQuery = _searchController.text;
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                          ),
                          child: const Text('Apply Filters'),
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

  void _showExportDialog(BuildContext context, bool isDark, List<Map<String, dynamic>> logs) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    String selectedFormat = 'CSV';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusXl)),
          insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? AppSpacing.md : AppSpacing.xxl, vertical: AppSpacing.xl),
          child: Container(
            width: isMobile ? double.infinity : 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.success, AppColors.success.withOpacity(0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                        child: const Icon(Icons.download, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Export Audit Logs', style: AppTypography.h6.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                            Text('${logs.length} records to export', style: AppTypography.bodySmall.copyWith(color: Colors.white70)),
                          ],
                        ),
                      ),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white70)),
                    ],
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Export Format
                      Text('Export Format', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : AppColors.textSecondary)),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: _buildFormatOption('CSV', Icons.table_chart, selectedFormat == 'CSV', isDark, () => setDialogState(() => selectedFormat = 'CSV')),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _buildFormatOption('JSON', Icons.data_object, selectedFormat == 'JSON', isDark, () => setDialogState(() => selectedFormat = 'JSON')),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _buildFormatOption('PDF', Icons.picture_as_pdf, selectedFormat == 'PDF', isDark, () => setDialogState(() => selectedFormat = 'PDF')),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      
                      // Export Summary
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.05) : AppColors.neutral50,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                        ),
                        child: Column(
                          children: [
                            _buildExportSummaryRow('Total Records', '${logs.length}', isDark),
                            _buildExportSummaryRow('Date Range', _selectedDateRange != null ? '${_selectedDateRange!.start.toString().split(' ').first} - ${_selectedDateRange!.end.toString().split(' ').first}' : 'All time', isDark),
                            _buildExportSummaryRow('Category', _selectedFilter, isDark),
                            _buildExportSummaryRow('Format', selectedFormat, isDark),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      
                      // Info
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(color: AppColors.info.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: AppColors.info, size: 18),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'Export will include all filtered results with current filters applied.',
                                style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Actions
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppSpacing.radiusXl)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                            side: BorderSide(color: isDark ? Colors.white24 : AppColors.neutral300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _exportLogs(logs, selectedFormat, isDark);
                          },
                          icon: const Icon(Icons.download, size: 18),
                          label: Text('Export $selectedFormat'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
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

  Widget _buildFormatOption(String format, IconData icon, bool isSelected, bool isDark, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : (isDark ? Colors.white.withOpacity(0.05) : AppColors.neutral50),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: isSelected ? AppColors.primary : (isDark ? Colors.white10 : AppColors.neutral200)),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : (isDark ? Colors.white54 : AppColors.textSecondary), size: 24),
            const SizedBox(height: 4),
            Text(format, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? AppColors.primary : (isDark ? Colors.white : AppColors.textPrimary))),
          ],
        ),
      ),
    );
  }

  Widget _buildExportSummaryRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : AppColors.textSecondary)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textPrimary)),
        ],
      ),
    );
  }

  void _exportLogs(List<Map<String, dynamic>> logs, String format, bool isDark) {
    String exportData = '';
    
    switch (format) {
      case 'CSV':
        // Create CSV header
        exportData = 'ID,User,Action,Category,Timestamp,IP Address\n';
        // Add data rows
        for (final log in logs) {
          exportData += '${log['id']},${log['user']},"${log['action']}",${log['category']},${log['timestamp']},${log['ip']}\n';
        }
        break;
      case 'JSON':
        // Create JSON
        exportData = '[\n';
        for (int i = 0; i < logs.length; i++) {
          final log = logs[i];
          exportData += '  {\n';
          exportData += '    "id": "${log['id']}",\n';
          exportData += '    "user": "${log['user']}",\n';
          exportData += '    "action": "${log['action']}",\n';
          exportData += '    "category": "${log['category']}",\n';
          exportData += '    "timestamp": "${log['timestamp']}",\n';
          exportData += '    "ip": "${log['ip']}"\n';
          exportData += '  }${i < logs.length - 1 ? ',' : ''}\n';
        }
        exportData += ']';
        break;
      case 'PDF':
        // For PDF we'll just simulate - actual PDF generation would need a package
        exportData = 'AUDIT LOGS REPORT\n';
        exportData += '================\n\n';
        exportData += 'Generated: ${DateTime.now()}\n';
        exportData += 'Total Records: ${logs.length}\n\n';
        for (final log in logs) {
          exportData += '---\n';
          exportData += 'ID: ${log['id']}\n';
          exportData += 'User: ${log['user']}\n';
          exportData += 'Action: ${log['action']}\n';
          exportData += 'Category: ${log['category']}\n';
          exportData += 'Timestamp: ${log['timestamp']}\n';
          exportData += 'IP: ${log['ip']}\n';
        }
        break;
    }
    
    // Copy to clipboard
    Clipboard.setData(ClipboardData(text: exportData));
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Export Successful!', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('${logs.length} records copied to clipboard as $format', style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }
}
