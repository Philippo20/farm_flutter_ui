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
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Row(
        children: [
          SuperAdminSidebar(
            selectedIndex: 8,
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
                                Text('Backup & Restore', style: AppTypography.h4.copyWith(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)),
                                Text('Create backups and restore system data', style: AppTypography.bodyMedium.copyWith(color: isDark ? Colors.white70 : AppColors.textSecondary)),
                              ],
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            TextField(decoration: InputDecoration(labelText: 'Backup Name', border: OutlineInputBorder())),
            SizedBox(height: AppSpacing.md),
            Text('This will create a complete backup of all system data including users, farms, batches, and configurations.'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup created successfully!')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Create Backup'),
          ),
        ],
      ),
    );
  }
  
  void _showRestoreDialog(BuildContext context, Map<String, dynamic> backup, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to restore from "${backup['name']}"?'),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: AppColors.warning, size: 20),
                  SizedBox(width: 8),
                  Expanded(child: Text('This will overwrite all current data!', style: TextStyle(color: AppColors.warning, fontSize: 12))),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('System restored successfully!')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }
}
