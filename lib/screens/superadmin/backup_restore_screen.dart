import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/superadmin_sidebar.dart';
import '../../core/widgets/modern_admin_header.dart';
import '../../providers/auth_provider.dart';

/// Backup & Restore - System data backup and restore operations
class BackupRestoreScreen extends ConsumerStatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  ConsumerState<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends ConsumerState<BackupRestoreScreen> {
  int _selectedNavIndex = 8;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  final List<Map<String, dynamic>> _backups = [
    {'id': 'BK001', 'name': 'Daily Backup - Oct 31', 'date': '2024-10-31 02:00', 'size': '2.4 GB', 'type': 'Auto', 'status': 'Complete'},
    {'id': 'BK002', 'name': 'Manual Backup - Pre-Update', 'date': '2024-10-30 14:30', 'size': '2.3 GB', 'type': 'Manual', 'status': 'Complete'},
    {'id': 'BK003', 'name': 'Daily Backup - Oct 30', 'date': '2024-10-30 02:00', 'size': '2.3 GB', 'type': 'Auto', 'status': 'Complete'},
    {'id': 'BK004', 'name': 'Weekly Backup - Week 43', 'date': '2024-10-27 02:00', 'size': '2.2 GB', 'type': 'Auto', 'status': 'Complete'},
    {'id': 'BK005', 'name': 'Daily Backup - Oct 29', 'date': '2024-10-29 02:00', 'size': '2.3 GB', 'type': 'Auto', 'status': 'Complete'},
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
          ? _buildMobileLayout(isDark, firstName)
          : _buildDesktopLayout(isDark, userName, userEmail, firstName),
    );
  }
  
  Widget _buildDesktopLayout(bool isDark, String userName, String userEmail, String firstName) {
    return Row(
      children: [
        SuperAdminSidebar(
          selectedIndex: 8,
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
                  child: _buildContent(isDark),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildMobileLayout(bool isDark, String firstName) {
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
            child: _buildMobileContent(isDark),
          ),
        ),
      ],
    );
  }
  
  Widget _buildMobileContent(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header - Mobile
        Text(
          'Backup & Restore',
          style: AppTypography.h5.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Create backups and restore system data',
          style: AppTypography.bodySmall.copyWith(
            color: isDark ? Colors.white70 : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showCreateBackupDialog(context, isDark),
            icon: const Icon(Icons.backup, size: 18),
            label: const Text('Create Backup'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            ),
          ),
        ),
        
        const SizedBox(height: AppSpacing.lg),
        
        // Stats - Mobile Grid
        _buildMobileStats(isDark),
        
        const SizedBox(height: AppSpacing.lg),
        
        // Quick Actions - Mobile
        _buildMobileQuickActions(isDark),
        
        const SizedBox(height: AppSpacing.lg),
        
        // Backups List - Mobile Cards
        Text(
          'Available Backups',
          style: AppTypography.h6.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ..._backups.map((backup) => _buildMobileBackupCard(backup, isDark)),
      ],
    );
  }
  
  Widget _buildContent(bool isDark) {
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
                  Text('Backup & Restore', style: AppTypography.h4.copyWith(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)),
                  Text('Create backups and restore system data', style: AppTypography.bodyMedium.copyWith(color: isDark ? Colors.white70 : AppColors.textSecondary)),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _showCreateBackupDialog(context, isDark),
              icon: const Icon(Icons.backup, size: 20),
              label: const Text('Create Backup'),
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
        
        // Quick Actions
        _buildQuickActions(isDark),
        
        const SizedBox(height: AppSpacing.xl),
        
        // Backups Table
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
              Text('Available Backups', style: AppTypography.h6.copyWith(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)),
              const SizedBox(height: AppSpacing.lg),
              ..._backups.map((backup) => _buildBackupRow(backup, isDark)),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildMobileStats(bool isDark) {
    final stats = [
      {'title': 'Total Backups', 'value': '45', 'icon': Icons.backup, 'color': AppColors.primary},
      {'title': 'Total Size', 'value': '98.5 GB', 'icon': Icons.storage, 'color': AppColors.info},
      {'title': 'Last Backup', 'value': '2 hrs ago', 'icon': Icons.schedule, 'color': AppColors.success},
      {'title': 'Auto Backup', 'value': 'Enabled', 'icon': Icons.autorenew, 'color': AppColors.warning},
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
  
  Widget _buildMobileQuickActions(bool isDark) {
    final actions = [
      {'title': 'Export', 'icon': Icons.download, 'color': AppColors.info},
      {'title': 'Import', 'icon': Icons.upload, 'color': AppColors.success},
      {'title': 'Schedule', 'icon': Icons.event, 'color': AppColors.warning},
    ];
    
    return Row(
      children: actions.map((action) {
        final actionColor = action['color'] as Color;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: action != actions.last ? AppSpacing.sm : 0),
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: actionColor.withOpacity(isDark ? 0.15 : 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: actionColor.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Icon(action['icon'] as IconData, color: actionColor, size: 22),
                    const SizedBox(height: 4),
                    Text(
                      action['title'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildMobileBackupCard(Map<String, dynamic> backup, bool isDark) {
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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Icon(Icons.backup, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      backup['name'],
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      backup['date'],
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _buildInfoChip(backup['size'], Icons.storage, isDark),
              const SizedBox(width: AppSpacing.sm),
              _buildInfoChip(
                backup['type'],
                backup['type'] == 'Auto' ? Icons.autorenew : Icons.touch_app,
                isDark,
                color: backup['type'] == 'Auto' ? AppColors.info : AppColors.warning,
              ),
              const SizedBox(width: AppSpacing.sm),
              _buildInfoChip(
                backup['status'],
                Icons.check_circle,
                isDark,
                color: AppColors.success,
              ),
              const Spacer(),
              SizedBox(
                width: 32,
                height: 32,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => _showRestoreDialog(context, backup, isDark),
                  icon: const Icon(Icons.restore, size: 18),
                  color: AppColors.success,
                  tooltip: 'Restore',
                ),
              ),
              SizedBox(
                width: 32,
                height: 32,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {},
                  icon: const Icon(Icons.download, size: 18),
                  color: AppColors.primary,
                  tooltip: 'Download',
                ),
              ),
              SizedBox(
                width: 32,
                height: 32,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {},
                  icon: const Icon(Icons.delete_outline, size: 18),
                  color: AppColors.error,
                  tooltip: 'Delete',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoChip(String text, IconData icon, bool isDark, {Color? color}) {
    final chipColor = color ?? (isDark ? Colors.white54 : AppColors.textSecondary);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: chipColor),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(fontSize: 10, color: chipColor, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStats(bool isDark) {
    final stats = [
      {'title': 'Total Backups', 'value': '45', 'icon': Icons.backup, 'color': AppColors.primary},
      {'title': 'Total Size', 'value': '98.5 GB', 'icon': Icons.storage, 'color': AppColors.info},
      {'title': 'Last Backup', 'value': '2 hours ago', 'icon': Icons.schedule, 'color': AppColors.success},
      {'title': 'Auto Backup', 'value': 'Enabled', 'icon': Icons.autorenew, 'color': AppColors.warning},
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
  
  Widget _buildQuickActions(bool isDark) {
    final actions = [
      {'title': 'Export Data', 'subtitle': 'Export to CSV/JSON', 'icon': Icons.download, 'color': AppColors.info},
      {'title': 'Import Data', 'subtitle': 'Import from file', 'icon': Icons.upload, 'color': AppColors.success},
      {'title': 'Schedule Backup', 'subtitle': 'Configure auto backup', 'icon': Icons.event, 'color': AppColors.warning},
    ];
    
    return Row(
      children: actions.map((action) => Expanded(
        child: Container(
          margin: EdgeInsets.only(right: action != actions.last ? AppSpacing.md : 0),
          child: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: (action['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: (action['color'] as Color).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(action['icon'] as IconData, color: action['color'] as Color, size: 24),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(action['title'] as String, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : AppColors.textPrimary)),
                        Text(action['subtitle'] as String, style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      )).toList(),
    );
  }
  
  Widget _buildBackupRow(Map<String, dynamic> backup, bool isDark) {
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
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: const Icon(Icons.backup, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(backup['name'], style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isDark ? Colors.white : AppColors.textPrimary)),
                Text(backup['date'], style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : AppColors.textSecondary)),
              ],
            ),
          ),
          Expanded(
            child: Text(backup['size'], style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : AppColors.textSecondary)),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: backup['type'] == 'Auto' ? AppColors.info.withOpacity(0.1) : AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Text(
                backup['type'],
                style: TextStyle(
                  color: backup['type'] == 'Auto' ? AppColors.info : AppColors.warning,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Text(backup['status'], style: const TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _showRestoreDialog(context, backup, isDark),
                icon: const Icon(Icons.restore, size: 18),
                color: AppColors.success,
                tooltip: 'Restore',
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.download, size: 18),
                color: AppColors.primary,
                tooltip: 'Download',
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.delete_outline, size: 18),
                color: AppColors.error,
                tooltip: 'Delete',
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  void _showCreateBackupDialog(BuildContext context, bool isDark) {
    final nameController = TextEditingController(text: 'Backup_${DateTime.now().toString().split(' ')[0]}');
    String selectedType = 'Full Backup';
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
            width: isMobile ? double.infinity : 450,
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
                      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(AppSpacing.radiusMd)), child: const Icon(Icons.backup, color: Colors.white, size: 24)),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Create Backup', style: AppTypography.h6.copyWith(color: Colors.white, fontWeight: FontWeight.bold)), Text('Backup system data', style: AppTypography.bodySmall.copyWith(color: Colors.white70))])),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white70)),
                    ],
                  ),
                ),
                // Form
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFormLabel('Backup Name', isDark),
                      const SizedBox(height: AppSpacing.sm),
                      _buildTextField(controller: nameController, hint: 'Enter backup name', icon: Icons.badge_outlined, isDark: isDark),
                      const SizedBox(height: AppSpacing.lg),
                      _buildFormLabel('Backup Type', isDark),
                      const SizedBox(height: AppSpacing.sm),
                      _buildDropdownField(value: selectedType, items: ['Full Backup', 'Database Only', 'Files Only', 'Configuration'], icon: Icons.folder_zip, isDark: isDark, onChanged: (v) => setDialogState(() => selectedType = v!)),
                      const SizedBox(height: AppSpacing.lg),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(color: AppColors.info.withOpacity(0.1), borderRadius: BorderRadius.circular(AppSpacing.radiusMd), border: Border.all(color: AppColors.info.withOpacity(0.3))),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: AppColors.info, size: 20),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(child: Text('This will create a backup of all selected system data.', style: TextStyle(color: AppColors.info, fontSize: 12))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Actions
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppSpacing.radiusXl))),
                  child: Row(
                    children: [
                      Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: AppSpacing.md), side: BorderSide(color: isDark ? Colors.white24 : AppColors.neutral300), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd))), child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondary)))),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(flex: 2, child: ElevatedButton.icon(onPressed: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: [const Icon(Icons.check_circle, color: Colors.white), const SizedBox(width: 8), const Text('Backup created successfully!')]), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)))); }, icon: const Icon(Icons.backup, size: 18), label: const Text('Create Backup'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: AppSpacing.md), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd))))),
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
  
  void _showRestoreDialog(BuildContext context, Map<String, dynamic> backup, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusXl)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.restore, color: AppColors.warning, size: 40)),
              const SizedBox(height: AppSpacing.lg),
              Text('Restore Backup?', style: AppTypography.h5.copyWith(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)),
              const SizedBox(height: AppSpacing.sm),
              Text('You are about to restore from:', textAlign: TextAlign.center, style: AppTypography.bodyMedium.copyWith(color: isDark ? Colors.white70 : AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : AppColors.neutral50, borderRadius: BorderRadius.circular(AppSpacing.radiusMd), border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08))),
                child: Row(
                  children: [
                    Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.folder_zip, color: AppColors.primary, size: 20)),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(backup['name'], style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textPrimary)), Text('${backup['date']} • ${backup['size']}', style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : AppColors.textSecondary))])),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(AppSpacing.radiusMd), border: Border.all(color: AppColors.error.withOpacity(0.3))),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: AppColors.error, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text('This will overwrite all current data!', style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w500))),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: AppSpacing.md), side: BorderSide(color: isDark ? Colors.white24 : AppColors.neutral300), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd))), child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondary)))),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: ElevatedButton.icon(onPressed: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: [const Icon(Icons.check_circle, color: Colors.white), const SizedBox(width: 8), const Text('System restored successfully!')]), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)))); }, icon: const Icon(Icons.restore, size: 18), label: const Text('Restore'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: AppSpacing.md), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd))))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Helper widgets
  Widget _buildFormLabel(String label, bool isDark) => Text(label, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textPrimary));
  
  Widget _buildTextField({required TextEditingController controller, required String hint, required IconData icon, required bool isDark}) {
    return TextFormField(
      controller: controller, style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary),
      decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: isDark ? Colors.white38 : AppColors.textSecondary.withOpacity(0.5)), prefixIcon: Icon(icon, color: isDark ? Colors.white54 : AppColors.textSecondary, size: 20), filled: true, fillColor: isDark ? Colors.white.withOpacity(0.05) : AppColors.neutral50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd), borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.neutral200)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd), borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.neutral200)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd), borderSide: const BorderSide(color: AppColors.primary, width: 2)), contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md)),
    );
  }
  
  Widget _buildDropdownField({required String value, required List<String> items, required IconData icon, required bool isDark, required Function(String?) onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : AppColors.neutral50, borderRadius: BorderRadius.circular(AppSpacing.radiusMd), border: Border.all(color: isDark ? Colors.white12 : AppColors.neutral200)),
      child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: value, isExpanded: true, icon: Icon(Icons.keyboard_arrow_down, color: isDark ? Colors.white54 : AppColors.textSecondary), dropdownColor: isDark ? AppColors.surfaceDark : Colors.white, style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary, fontSize: 14), items: items.map((item) => DropdownMenuItem(value: item, child: Row(children: [Icon(icon, color: isDark ? Colors.white54 : AppColors.textSecondary, size: 20), const SizedBox(width: AppSpacing.md), Text(item)]))).toList(), onChanged: onChanged)),
    );
  }
}
