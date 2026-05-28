import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/modern_admin_header.dart';
import '../../core/widgets/superadmin_sidebar.dart';
import '../../providers/auth_provider.dart';

/// Backup & Restore - System data backup and restore operations.
class BackupRestoreScreen extends ConsumerStatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  ConsumerState<BackupRestoreScreen> createState() =>
      _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends ConsumerState<BackupRestoreScreen> {
  int _selectedNavIndex = 8;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _selectedScope = 'global';

  final List<_BackupRecord> _backups = const [
    _BackupRecord(
      id: 'GBK-1048',
      name: 'Platform Recovery Point',
      date: '2026-05-18 02:00',
      size: '18.6 GB',
      type: 'Automated',
      status: 'Verified',
      scope: 'global',
      farm: 'Global Platform',
      retention: '90 days',
    ),
    _BackupRecord(
      id: 'GBK-1047',
      name: 'Pre-Release Snapshot',
      date: '2026-05-17 21:15',
      size: '18.2 GB',
      type: 'Manual',
      status: 'Verified',
      scope: 'global',
      farm: 'Global Platform',
      retention: '180 days',
    ),
    _BackupRecord(
      id: 'FRM-332',
      name: 'Green Valley Daily Backup',
      date: '2026-05-18 01:35',
      size: '4.8 GB',
      type: 'Automated',
      status: 'Verified',
      scope: 'green-valley',
      farm: 'Green Valley Farm',
      retention: '45 days',
    ),
    _BackupRecord(
      id: 'FRM-331',
      name: 'North Ridge Crop Ledger',
      date: '2026-05-18 01:20',
      size: '3.7 GB',
      type: 'Automated',
      status: 'Verified',
      scope: 'north-ridge',
      farm: 'North Ridge Farm',
      retention: '45 days',
    ),
    _BackupRecord(
      id: 'FRM-330',
      name: 'Sunset Acres Manual Export',
      date: '2026-05-17 18:45',
      size: '5.1 GB',
      type: 'Manual',
      status: 'Verified',
      scope: 'sunset-acres',
      farm: 'Sunset Acres',
      retention: '60 days',
    ),
    _BackupRecord(
      id: 'FRM-329',
      name: 'Riverbend Incremental Backup',
      date: '2026-05-17 01:10',
      size: '2.9 GB',
      type: 'Automated',
      status: 'Pending Review',
      scope: 'riverbend',
      farm: 'Riverbend Farm',
      retention: '30 days',
    ),
  ];

  final List<_FarmBackupSummary> _farmBackups = const [
    _FarmBackupSummary(
      id: 'global',
      name: 'Global Platform',
      subtitle: 'All farms, users, permissions, finance, inventory',
      lastBackup: 'Today, 02:00',
      backupSize: '18.6 GB',
      restorePoint: 'Verified',
      coverage: '100%',
      icon: Icons.public_rounded,
      color: AppColors.primary,
      isGlobal: true,
    ),
    _FarmBackupSummary(
      id: 'green-valley',
      name: 'Green Valley Farm',
      subtitle: 'Crops, sensors, inventory, local reports',
      lastBackup: 'Today, 01:35',
      backupSize: '4.8 GB',
      restorePoint: 'Verified',
      coverage: '100%',
      icon: Icons.agriculture_rounded,
      color: AppColors.success,
    ),
    _FarmBackupSummary(
      id: 'north-ridge',
      name: 'North Ridge Farm',
      subtitle: 'Harvest, workers, maintenance, local ledger',
      lastBackup: 'Today, 01:20',
      backupSize: '3.7 GB',
      restorePoint: 'Verified',
      coverage: '98%',
      icon: Icons.terrain_rounded,
      color: AppColors.info,
    ),
    _FarmBackupSummary(
      id: 'sunset-acres',
      name: 'Sunset Acres',
      subtitle: 'Sales, packaging, QA, deliveries',
      lastBackup: 'Yesterday, 18:45',
      backupSize: '5.1 GB',
      restorePoint: 'Verified',
      coverage: '100%',
      icon: Icons.wb_sunny_rounded,
      color: AppColors.warning,
    ),
    _FarmBackupSummary(
      id: 'riverbend',
      name: 'Riverbend Farm',
      subtitle: 'Field notes, stock, compliance records',
      lastBackup: 'Yesterday, 01:10',
      backupSize: '2.9 GB',
      restorePoint: 'Review',
      coverage: '94%',
      icon: Icons.water_drop_rounded,
      color: AppColors.error,
    ),
  ];

  List<_BackupRecord> get _visibleBackups {
    if (_selectedScope == 'all') return _backups;
    return _backups.where((backup) => backup.scope == _selectedScope).toList();
  }

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
          ? _buildMobileLayout(isDark, firstName)
          : _buildDesktopLayout(isDark, userName, userEmail, firstName),
    );
  }

  Widget _buildDesktopLayout(
    bool isDark,
    String userName,
    String userEmail,
    String firstName,
  ) {
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
                  child: _buildContent(isDark, isMobile: false),
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
            child: _buildContent(isDark, isMobile: true),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(bool isDark, {required bool isMobile}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHero(isDark, isMobile),
        const SizedBox(height: AppSpacing.lg),
        _buildScopeCards(isDark, isMobile),
        const SizedBox(height: AppSpacing.lg),
        _buildOperationalPanel(isDark, isMobile),
        const SizedBox(height: AppSpacing.lg),
        _buildBackupHistory(isDark, isMobile),
      ],
    );
  }

  Widget _buildHero(bool isDark, bool isMobile) {
    final selectedSummary = _farmBackups.firstWhere(
      (summary) => summary.id == _selectedScope,
      orElse: () => _farmBackups.first,
    );

    return Container(
      padding: EdgeInsets.all(isMobile ? AppSpacing.lg : AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF10251E),
                  const Color(0xFF0D1721),
                ]
              : [
                  const Color(0xFFEFFAF4),
                  const Color(0xFFE9F2FF),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: isDark
              ? Colors.white10
              : AppColors.primary.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.06),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroText(isDark),
                const SizedBox(height: AppSpacing.lg),
                _buildHeroStatus(selectedSummary, isDark),
                const SizedBox(height: AppSpacing.md),
                _buildHeroActions(isDark, isMobile),
              ],
            )
          : Row(
              children: [
                Expanded(child: _buildHeroText(isDark)),
                const SizedBox(width: AppSpacing.xl),
                SizedBox(
                  width: 320,
                  child: _buildHeroStatus(selectedSummary, isDark),
                ),
                const SizedBox(width: AppSpacing.lg),
                SizedBox(
                  width: 180,
                  child: _buildHeroActions(isDark, isMobile),
                ),
              ],
            ),
    );
  }

  Widget _buildHeroText(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            border:
                Border.all(color: AppColors.primary.withValues(alpha: 0.24)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.verified_user_rounded,
                color: AppColors.primary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Disaster recovery command center',
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? Colors.white : AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Backup & Restore',
          style: AppTypography.h4.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Manage global platform recovery points and individual farm backups from one controlled workflow.',
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? Colors.white70 : AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroStatus(_FarmBackupSummary summary, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedScope == 'global' ? 'Global Coverage' : 'Selected Farm',
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white60 : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: summary.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(summary.icon, color: summary.color, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.name,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${summary.coverage} coverage',
                      style: AppTypography.bodySmall.copyWith(
                        color:
                            isDark ? Colors.white60 : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildMiniMetric('Last backup', summary.lastBackup, isDark),
          const SizedBox(height: 8),
          _buildMiniMetric('Restore point', summary.restorePoint, isDark),
        ],
      ),
    );
  }

  Widget _buildHeroActions(bool isDark, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () => _showCreateBackupDialog(context, isDark),
          icon: const Icon(Icons.backup_rounded, size: 18),
          label: const Text('Create Backup'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.event_repeat_rounded, size: 18),
          label: const Text('Schedule'),
          style: OutlinedButton.styleFrom(
            foregroundColor: isDark ? Colors.white : AppColors.textPrimary,
            side: BorderSide(
              color: isDark ? Colors.white24 : AppColors.neutral300,
            ),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScopeCards(bool isDark, bool isMobile) {
    final cards = [
      _FarmBackupSummary(
        id: 'all',
        name: 'All Backups',
        subtitle: 'Complete backup history across platform and farms',
        lastBackup: 'Live view',
        backupSize: '35.1 GB',
        restorePoint: 'Mixed',
        coverage: 'Portfolio',
        icon: Icons.dashboard_customize_rounded,
        color: AppColors.primary,
        isGlobal: true,
      ),
      ..._farmBackups,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Backup Scope',
          'Switch between global recovery and individual farm backup control.',
          isDark,
        ),
        const SizedBox(height: AppSpacing.md),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isMobile ? 1 : 3,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: isMobile ? 1.8 : 1.65,
          ),
          itemBuilder: (context, index) {
            final summary = cards[index];
            return _buildFarmBackupCard(summary, isDark);
          },
        ),
      ],
    );
  }

  Widget _buildFarmBackupCard(_FarmBackupSummary summary, bool isDark) {
    final isSelected = _selectedScope == summary.id;

    return InkWell(
      onTap: () => setState(() => _selectedScope = summary.id),
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isSelected
              ? summary.color.withValues(alpha: isDark ? 0.2 : 0.12)
              : (isDark ? AppColors.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: isSelected
                ? summary.color.withValues(alpha: 0.65)
                : (isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.07)),
            width: isSelected ? 1.4 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.04),
              blurRadius: isSelected ? 18 : 10,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: summary.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(summary.icon, color: summary.color, size: 22),
                ),
                const Spacer(),
                _buildStatusPill(
                  summary.isGlobal ? 'Global' : summary.restorePoint,
                  summary.color,
                  isDark,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              summary.name,
              style: AppTypography.bodyLarge.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              summary.subtitle,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white60 : AppColors.textSecondary,
                height: 1.35,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: _buildMetricBlock(
                    'Last backup',
                    summary.lastBackup,
                    isDark,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildMetricBlock('Size', summary.backupSize, isDark),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationalPanel(bool isDark, bool isMobile) {
    final actions = [
      _BackupAction(
        title: 'Export Archive',
        subtitle: 'Download encrypted backup bundle',
        icon: Icons.download_rounded,
        color: AppColors.info,
      ),
      _BackupAction(
        title: 'Import Snapshot',
        subtitle: 'Validate and stage a restore package',
        icon: Icons.upload_file_rounded,
        color: AppColors.success,
      ),
      _BackupAction(
        title: 'Retention Rules',
        subtitle: 'Configure global and farm retention windows',
        icon: Icons.rule_folder_rounded,
        color: AppColors.warning,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.07),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Recovery Operations',
            'Controlled actions for secure exports, imports, and retention policy.',
            isDark,
          ),
          const SizedBox(height: AppSpacing.md),
          if (isMobile)
            Column(
              children: actions
                  .map(
                    (action) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _buildActionTile(action, isDark),
                    ),
                  )
                  .toList(),
            )
          else
            Row(
              children: actions
                  .map(
                    (action) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: action == actions.last ? 0 : AppSpacing.md,
                        ),
                        child: _buildActionTile(action, isDark),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildActionTile(_BackupAction action, bool isDark) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: action.color.withValues(alpha: isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: action.color.withValues(alpha: 0.24)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: action.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(action.icon, color: action.color, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action.title,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    action.subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark ? Colors.white60 : AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.white38 : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupHistory(bool isDark, bool isMobile) {
    final backups = _visibleBackups;
    final activeLabel = _selectedScope == 'all'
        ? 'All backup records'
        : _farmBackups
            .firstWhere(
              (summary) => summary.id == _selectedScope,
              orElse: () => _farmBackups.first,
            )
            .name;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.07),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      'Backup History',
                      activeLabel,
                      isDark,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildHistoryMeta(backups.length, isDark),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _buildSectionHeader(
                        'Backup History',
                        activeLabel,
                        isDark,
                      ),
                    ),
                    _buildHistoryMeta(backups.length, isDark),
                  ],
                ),
          const SizedBox(height: AppSpacing.md),
          if (isMobile)
            ...backups.map((backup) => _buildMobileBackupCard(backup, isDark))
          else
            _buildBackupTable(backups, isDark),
        ],
      ),
    );
  }

  Widget _buildBackupTable(List<_BackupRecord> backups, bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : AppColors.neutral50,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Row(
            children: [
              _buildTableHeader('Backup', flex: 3, isDark: isDark),
              _buildTableHeader('Scope', flex: 2, isDark: isDark),
              _buildTableHeader('Size', isDark: isDark),
              _buildTableHeader('Type', isDark: isDark),
              _buildTableHeader('Status', isDark: isDark),
              const SizedBox(width: 128),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...backups.map((backup) => _buildBackupRow(backup, isDark)),
      ],
    );
  }

  Widget _buildBackupRow(_BackupRecord backup, bool isDark) {
    final statusColor = backup.status == 'Verified'
        ? AppColors.success
        : backup.status == 'Pending Review'
            ? AppColors.warning
            : AppColors.error;
    final typeColor =
        backup.type == 'Automated' ? AppColors.info : AppColors.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color:
            isDark ? Colors.white.withValues(alpha: 0.03) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
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
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: const Icon(
                    Icons.folder_zip_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        backup.name,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${backup.id} • ${backup.date}',
                        style: AppTypography.bodySmall.copyWith(
                          color:
                              isDark ? Colors.white60 : AppColors.textSecondary,
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
              backup.farm,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              backup.size,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: _buildStatusPill(backup.type, typeColor, isDark)),
          Expanded(child: _buildStatusPill(backup.status, statusColor, isDark)),
          SizedBox(
            width: 128,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildIconAction(
                  Icons.restore_rounded,
                  AppColors.success,
                  () => _showRestoreDialog(context, backup, isDark),
                  'Restore',
                ),
                _buildIconAction(
                  Icons.download_rounded,
                  AppColors.primary,
                  () {},
                  'Download',
                ),
                _buildIconAction(
                  Icons.delete_outline_rounded,
                  AppColors.error,
                  () {},
                  'Delete',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileBackupCard(_BackupRecord backup, bool isDark) {
    final statusColor = backup.status == 'Verified'
        ? AppColors.success
        : backup.status == 'Pending Review'
            ? AppColors.warning
            : AppColors.error;
    final typeColor =
        backup.type == 'Automated' ? AppColors.info : AppColors.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color:
            isDark ? Colors.white.withValues(alpha: 0.03) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Icon(
                  Icons.folder_zip_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      backup.name,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      backup.farm,
                      style: AppTypography.bodySmall.copyWith(
                        color:
                            isDark ? Colors.white60 : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _buildInfoChip(backup.size, Icons.storage_rounded, isDark),
              _buildInfoChip(
                backup.type,
                Icons.autorenew_rounded,
                isDark,
                color: typeColor,
              ),
              _buildInfoChip(
                backup.status,
                Icons.verified_rounded,
                isDark,
                color: statusColor,
              ),
              _buildInfoChip(backup.retention, Icons.policy_rounded, isDark),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  backup.date,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? Colors.white54 : AppColors.textSecondary,
                  ),
                ),
              ),
              _buildIconAction(
                Icons.restore_rounded,
                AppColors.success,
                () => _showRestoreDialog(context, backup, isDark),
                'Restore',
              ),
              _buildIconAction(
                Icons.download_rounded,
                AppColors.primary,
                () {},
                'Download',
              ),
              _buildIconAction(
                Icons.delete_outline_rounded,
                AppColors.error,
                () {},
                'Delete',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.h6.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: AppTypography.bodySmall.copyWith(
            color: isDark ? Colors.white60 : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniMetric(String label, String value, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white54 : AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: AppTypography.bodySmall.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricBlock(String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white54 : AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryMeta(int count, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: isDark ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Text(
        '$count recovery point${count == 1 ? '' : 's'}',
        style: AppTypography.bodySmall.copyWith(
          color: isDark ? Colors.white : AppColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildStatusPill(String text, Color color, bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.18 : 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(color: color.withValues(alpha: 0.24)),
        ),
        child: Text(
          text,
          style: AppTypography.bodySmall.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
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

  Widget _buildInfoChip(
    String text,
    IconData icon,
    bool isDark, {
    Color? color,
  }) {
    final chipColor =
        color ?? (isDark ? Colors.white70 : AppColors.textSecondary);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: chipColor.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: chipColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTypography.bodySmall.copyWith(
              color: chipColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconAction(
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

  void _showCreateBackupDialog(BuildContext context, bool isDark) {
    final nameController = TextEditingController(
      text: 'Backup_${DateTime.now().toString().split(' ')[0]}',
    );
    String selectedType = 'Full Backup';
    String selectedScope = _selectedScope == 'all' ? 'global' : _selectedScope;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          ),
          insetPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? AppSpacing.md : AppSpacing.xxl,
            vertical: AppSpacing.xl,
          ),
          child: SizedBox(
            width: isMobile ? double.infinity : 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withValues(alpha: 0.82),
                      ],
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
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: const Icon(
                          Icons.backup_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Create Backup',
                              style: AppTypography.h6.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Choose global platform or farm-specific scope',
                              style: AppTypography.bodySmall.copyWith(
                                color: Colors.white70,
                              ),
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
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFormLabel('Backup Name', isDark),
                      const SizedBox(height: AppSpacing.sm),
                      _buildTextField(
                        controller: nameController,
                        hint: 'Enter backup name',
                        icon: Icons.badge_outlined,
                        isDark: isDark,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildFormLabel('Backup Scope', isDark),
                      const SizedBox(height: AppSpacing.sm),
                      _buildDropdownField(
                        value: selectedScope,
                        items: _farmBackups.map((farm) => farm.id).toList(),
                        labels: {
                          for (final farm in _farmBackups) farm.id: farm.name,
                        },
                        icon: Icons.account_tree_rounded,
                        isDark: isDark,
                        onChanged: (value) =>
                            setDialogState(() => selectedScope = value!),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildFormLabel('Backup Type', isDark),
                      const SizedBox(height: AppSpacing.sm),
                      _buildDropdownField(
                        value: selectedType,
                        items: const [
                          'Full Backup',
                          'Database Only',
                          'Files Only',
                          'Configuration',
                        ],
                        icon: Icons.folder_zip_rounded,
                        isDark: isDark,
                        onChanged: (value) =>
                            setDialogState(() => selectedType = value!),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(
                              color: AppColors.info.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: AppColors.info,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'The backup will be encrypted, verified, and added to the selected recovery scope.',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.info,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.03)
                        : AppColors.neutral50,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(AppSpacing.radiusXl),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                            ),
                            side: BorderSide(
                              color: isDark
                                  ? Colors.white24
                                  : AppColors.neutral300,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusMd),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white70
                                  : AppColors.textSecondary,
                            ),
                          ),
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
                                content: const Row(
                                  children: [
                                    Icon(Icons.check_circle,
                                        color: Colors.white),
                                    SizedBox(width: 8),
                                    Text('Backup created successfully.'),
                                  ],
                                ),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusMd,
                                  ),
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.backup_rounded, size: 18),
                          label: const Text('Create Backup'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusMd),
                            ),
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

  void _showRestoreDialog(
    BuildContext context,
    _BackupRecord backup,
    bool isDark,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
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
                  color: AppColors.warning.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.restore_rounded,
                  color: AppColors.warning,
                  size: 40,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Restore Backup?',
                style: AppTypography.h5.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'This will restore the selected backup scope.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : AppColors.neutral50,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: isDark
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.folder_zip_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            backup.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color:
                                  isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${backup.farm} • ${backup.date} • ${backup.size}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white60
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border:
                      Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        backup.scope == 'global'
                            ? 'Global restore affects all farms and platform records.'
                            : 'Farm restore affects only ${backup.farm} records.',
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        side: BorderSide(
                          color: isDark ? Colors.white24 : AppColors.neutral300,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color:
                              isDark ? Colors.white70 : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.white),
                                SizedBox(width: 8),
                                Text('Restore started successfully.'),
                              ],
                            ),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusMd),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.restore_rounded, size: 18),
                      label: const Text('Restore'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warning,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
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

  Widget _buildFormLabel(String label, bool isDark) => Text(
        label,
        style: AppTypography.bodyMedium.copyWith(
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
      );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
  }) {
    return TextFormField(
      controller: controller,
      style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark
              ? Colors.white38
              : AppColors.textSecondary.withValues(alpha: 0.5),
        ),
        prefixIcon: Icon(
          icon,
          color: isDark ? Colors.white54 : AppColors.textSecondary,
          size: 20,
        ),
        filled: true,
        fillColor:
            isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.neutral50,
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

  Widget _buildDropdownField({
    required String value,
    required List<String> items,
    required IconData icon,
    required bool isDark,
    required ValueChanged<String?> onChanged,
    Map<String, String>? labels,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color:
            isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? Colors.white12 : AppColors.neutral200,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
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
                      Expanded(child: Text(labels?[item] ?? item)),
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
}

class _BackupRecord {
  const _BackupRecord({
    required this.id,
    required this.name,
    required this.date,
    required this.size,
    required this.type,
    required this.status,
    required this.scope,
    required this.farm,
    required this.retention,
  });

  final String id;
  final String name;
  final String date;
  final String size;
  final String type;
  final String status;
  final String scope;
  final String farm;
  final String retention;
}

class _FarmBackupSummary {
  const _FarmBackupSummary({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.lastBackup,
    required this.backupSize,
    required this.restorePoint,
    required this.coverage,
    required this.icon,
    required this.color,
    this.isGlobal = false,
  });

  final String id;
  final String name;
  final String subtitle;
  final String lastBackup;
  final String backupSize;
  final String restorePoint;
  final String coverage;
  final IconData icon;
  final Color color;
  final bool isGlobal;
}

class _BackupAction {
  const _BackupAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
}
