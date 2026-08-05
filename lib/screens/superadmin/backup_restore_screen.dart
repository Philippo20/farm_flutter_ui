import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/modern_admin_header.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../core/widgets/superadmin_sidebar.dart';
import '../../providers/auth_provider.dart';
import '../../services/superadmin_api_service.dart';
import '../../utils/backup_download_launcher.dart';

/// Backup & Restore - System data backup and restore operations.
class BackupRestoreScreen extends ConsumerStatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  ConsumerState<BackupRestoreScreen> createState() =>
      _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends ConsumerState<BackupRestoreScreen> {
  int _selectedNavIndex = 9;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _selectedScope = 'global';
  final SuperAdminApiService _apiService = SuperAdminApiService();

  List<_BackupRecord> _backups = [];
  List<_FarmBackupSummary> _farmBackups = [];
  bool _isLoading = true;
  bool _isCreatingBackup = false;
  bool _isRunningRecoveryAction = false;
  String? _loadError;

  List<_BackupRecord> get _visibleBackups {
    if (_selectedScope == 'all') return _backups;
    return _backups.where((backup) => backup.scope == _selectedScope).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final backups = await _apiService.getBackups();
      if (!mounted) return;
      final records = backups.map(_mapBackupRecord).toList()
        ..sort((a, b) => b.sortDate.compareTo(a.sortDate));
      setState(() {
        _backups = records;
        _farmBackups = _buildFarmSummaries(records);
        _isLoading = false;
        if (!_farmBackups.any((summary) => summary.id == _selectedScope)) {
          _selectedScope = 'global';
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = error.toString();
        _farmBackups = _buildFarmSummaries(_backups);
      });
    }
  }

  _BackupRecord _mapBackupRecord(Map<String, dynamic> doc) {
    final createdAt =
        (doc['created_at'] ?? doc[r'$createdAt'] ?? '').toString();
    final sortDate = DateTime.tryParse(createdAt)?.toLocal() ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final fileName = (doc['file_name'] ?? 'Farm Estates backup').toString();
    final scope = (doc['scope'] ?? 'global').toString();
    final farm = (doc['farm'] ?? 'Global Platform').toString();
    final retentionDays = int.tryParse('${doc['retention_days'] ?? 90}') ?? 90;
    final sizeBytes = int.tryParse('${doc['size_bytes'] ?? 0}') ?? 0;
    final collections =
        doc['collections'] is List ? (doc['collections'] as List).length : 0;

    return _BackupRecord(
      id: (doc['id'] ?? doc[r'$id'] ?? '').toString(),
      name: fileName,
      date: _formatDate(sortDate),
      size: _formatBytes(sizeBytes),
      type: (doc['backup_type'] ?? 'Manual').toString(),
      status: (doc['status'] ?? 'Verified').toString(),
      scope: scope,
      farm: farm,
      retention: '$retentionDays days',
      retentionDays: retentionDays,
      sizeBytes: sizeBytes,
      sortDate: sortDate,
      collectionsCount: collections,
    );
  }

  List<_FarmBackupSummary> _buildFarmSummaries(List<_BackupRecord> records) {
    final globalRecords =
        records.where((record) => record.scope == 'global').toList();
    final summaries = <_FarmBackupSummary>[
      _buildSummary(
        id: 'global',
        name: 'Global Platform',
        subtitle: 'All farms, users, permissions, finance, inventory',
        records: globalRecords.isEmpty ? records : globalRecords,
        icon: Icons.public_rounded,
        color: AppColors.primary,
        isGlobal: true,
      ),
    ];

    final farmScopes = records
        .where((record) => record.scope != 'global')
        .map((record) => record.scope)
        .toSet()
        .toList()
      ..sort();

    final colors = [
      AppColors.success,
      AppColors.info,
      AppColors.warning,
      AppColors.error,
    ];
    for (var index = 0; index < farmScopes.length; index++) {
      final scope = farmScopes[index];
      final scopedRecords =
          records.where((record) => record.scope == scope).toList();
      summaries.add(
        _buildSummary(
          id: scope,
          name: scopedRecords.first.farm,
          subtitle: 'Farm-level recovery records',
          records: scopedRecords,
          icon: Icons.agriculture_rounded,
          color: colors[index % colors.length],
        ),
      );
    }
    return summaries;
  }

  _FarmBackupSummary _buildSummary({
    required String id,
    required String name,
    required String subtitle,
    required List<_BackupRecord> records,
    required IconData icon,
    required Color color,
    bool isGlobal = false,
  }) {
    final totalBytes = records.fold<int>(
      0,
      (total, record) => total + record.sizeBytes,
    );
    final latest = records.isEmpty ? null : records.first;
    return _FarmBackupSummary(
      id: id,
      name: name,
      subtitle: subtitle,
      lastBackup: latest?.date ?? 'No backups yet',
      backupSize: _formatBytes(totalBytes),
      restorePoint: latest?.status ?? 'Pending',
      coverage: records.isEmpty ? '0 records' : '${records.length} records',
      icon: icon,
      color: color,
      isGlobal: isGlobal,
    );
  }

  String _formatDate(DateTime date) {
    if (date.millisecondsSinceEpoch == 0) return 'Unknown date';
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var size = bytes.toDouble();
    var unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    return '${size.toStringAsFixed(size >= 10 || unitIndex == 0 ? 0 : 1)} ${units[unitIndex]}';
  }

  Future<void> _createBackup({
    required BuildContext context,
    required String name,
    required String scope,
    required String type,
  }) async {
    setState(() => _isCreatingBackup = true);
    try {
      final notes = [
        if (name.trim().isNotEmpty) name.trim(),
        type,
        scope,
      ].join(' | ');
      await _apiService.createBackup(notes: notes);
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Backup created successfully.'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      );
      await _loadBackups();
    } catch (error) {
      rethrow;
    } finally {
      if (mounted) setState(() => _isCreatingBackup = false);
    }
  }

  Future<void> _requestDownload(_BackupRecord backup) async {
    try {
      final result = await _apiService.getBackupDownload(backup.id);
      if (!mounted) return;
      final url = (result['download_url'] ?? '').toString();
      if (url.isEmpty) {
        _showSnackBar('Download link could not be generated.', AppColors.error);
        return;
      }
      final opened = await openBackupDownload(url);
      if (!mounted) return;
      _showSnackBar(
        opened
            ? 'Download opened for ${backup.name}.'
            : 'Download link ready: $url',
        AppColors.success,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      );
    }
  }

  void _confirmDeleteBackup(_BackupRecord backup, bool isDark) {
    var isDeleting = false;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => Dialog(
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
                    color: AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                    size: 40,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Delete Backup?',
                  style: AppTypography.h5.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'This will remove the selected backup from Appwrite storage and backup history.',
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
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '${backup.farm} | ${backup.date} | ${backup.size}',
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
                    border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.error,
                        size: 20,
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'This action cannot be undone. The storage file and metadata record will both be deleted.',
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
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
                        onPressed: isDeleting
                            ? null
                            : () => Navigator.pop(dialogContext),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          side: BorderSide(
                            color:
                                isDark ? Colors.white24 : AppColors.neutral300,
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
                      child: ElevatedButton.icon(
                        onPressed: isDeleting
                            ? null
                            : () async {
                                setDialogState(() => isDeleting = true);
                                await _deleteBackup(backup);
                                if (dialogContext.mounted) {
                                  Navigator.pop(dialogContext);
                                }
                              },
                        icon: isDeleting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.delete_outline_rounded,
                                size: 18),
                        label: Text(isDeleting ? 'Deleting...' : 'Delete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
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
      ),
    );
  }

  Future<void> _deleteBackup(_BackupRecord backup) async {
    try {
      await _apiService.deleteBackup(backup.id);
      if (!mounted) return;
      _showSnackBar('Backup deleted successfully.', AppColors.success);
      await _loadBackups();
    } catch (error) {
      if (!mounted) return;
      _showSnackBar(error.toString(), AppColors.error);
    }
  }

  Future<void> _exportSelectedArchive() async {
    final candidates = _visibleBackups;
    if (candidates.isEmpty) {
      _showSnackBar(
        'No backup is available for the selected scope.',
        AppColors.warning,
      );
      return;
    }
    await _requestDownload(candidates.first);
  }

  Future<void> _importSnapshot() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return;

    final file = picked.files.single;
    final bytes = file.bytes;
    if (bytes == null) {
      _showSnackBar(
        'Could not read the selected backup file.',
        AppColors.error,
      );
      return;
    }

    setState(() => _isRunningRecoveryAction = true);
    try {
      await _apiService.restoreBackup(
        fileName: file.name,
        fileBytes: bytes,
        replaceCollections: true,
      );
      if (!mounted) return;
      _showSnackBar('Restore completed successfully.', AppColors.success);
      await _loadBackups();
    } catch (error) {
      if (!mounted) return;
      _showSnackBar(error.toString(), AppColors.error);
    } finally {
      if (mounted) setState(() => _isRunningRecoveryAction = false);
    }
  }

  void _showRetentionDialog(bool isDark) {
    final scopedBackups = _visibleBackups;
    final controller = TextEditingController(
      text: scopedBackups.isNotEmpty
          ? scopedBackups.first.retentionDays.toString()
          : '90',
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        title: Text(
          'Retention Rules',
          style:
              TextStyle(color: isDark ? Colors.white : AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              scopedBackups.isEmpty
                  ? 'No backup records are available for this scope yet.'
                  : 'Apply retention days to ${scopedBackups.length} backup record(s) in the selected scope.',
              style: TextStyle(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Retention Days',
                hintText: 'Example: 90',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: scopedBackups.isEmpty || _isRunningRecoveryAction
                ? null
                : () async {
                    final days = int.tryParse(controller.text.trim());
                    if (days == null || days < 1 || days > 3650) {
                      _showSnackBar(
                        'Retention days must be between 1 and 3650.',
                        AppColors.error,
                      );
                      return;
                    }
                    Navigator.pop(dialogContext);
                    await _updateRetention(scopedBackups, days);
                  },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateRetention(List<_BackupRecord> backups, int days) async {
    setState(() => _isRunningRecoveryAction = true);
    try {
      for (final backup in backups) {
        await _apiService.updateBackupRetention(
          id: backup.id,
          retentionDays: days,
        );
      }
      if (!mounted) return;
      _showSnackBar('Retention rules updated.', AppColors.success);
      await _loadBackups();
    } catch (error) {
      if (!mounted) return;
      _showSnackBar(error.toString(), AppColors.error);
    } finally {
      if (mounted) setState(() => _isRunningRecoveryAction = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    );
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
      bottomNavigationBar: isMobile
          ? SuperAdminMobileBottomNav(
              selectedIndex: 9,
              onItemSelected: (_) {},
            )
          : null,
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
          selectedIndex: 9,
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
        if (_loadError != null) ...[
          _buildSyncStatus(isDark),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (_isLoading)
          const AdminDataSkeleton(rowCount: 5)
        else ...[
          _buildScopeCards(isDark, isMobile),
          const SizedBox(height: AppSpacing.lg),
          _buildOperationalPanel(isDark, isMobile),
          const SizedBox(height: AppSpacing.lg),
          _buildBackupHistory(isDark, isMobile),
        ],
      ],
    );
  }

  Widget _buildSyncStatus(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppColors.error, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              _loadError ?? 'Unable to sync backup records.',
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: _loadBackups,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(bool isDark, bool isMobile) {
    final selectedSummary = _farmBackups.isEmpty
        ? _buildSummary(
            id: 'global',
            name: 'Global Platform',
            subtitle: 'All farms, users, permissions, finance, inventory',
            records: const [],
            icon: Icons.public_rounded,
            color: AppColors.primary,
            isGlobal: true,
          )
        : _farmBackups.firstWhere(
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
                  fontWeight: FontWeight.w500,
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
            fontWeight: FontWeight.w600,
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
              fontWeight: FontWeight.w500,
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
                        fontWeight: FontWeight.w500,
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
          onPressed: _isCreatingBackup
              ? null
              : () => _showCreateBackupDialog(context, isDark),
          icon: const Icon(Icons.backup_rounded, size: 18),
          label: Text(_isCreatingBackup ? 'Creating...' : 'Create Backup'),
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
                fontWeight: FontWeight.w500,
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
      onTap: _isRunningRecoveryAction
          ? null
          : () {
              switch (action.title) {
                case 'Export Archive':
                  _exportSelectedArchive();
                  break;
                case 'Import Snapshot':
                  _importSnapshot();
                  break;
                case 'Retention Rules':
                  _showRetentionDialog(isDark);
                  break;
              }
            },
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
                      fontWeight: FontWeight.w500,
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
        : _farmBackups.isEmpty
            ? 'Global Platform'
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
          if (backups.isEmpty)
            _buildEmptyBackups(isDark)
          else if (isMobile)
            ...backups.map((backup) => _buildMobileBackupCard(backup, isDark))
          else
            _buildBackupTable(backups, isDark),
        ],
      ),
    );
  }

  Widget _buildEmptyBackups(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color:
            isDark ? Colors.white.withValues(alpha: 0.03) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.folder_zip_outlined,
            color: isDark ? Colors.white38 : AppColors.textSecondary,
            size: 34,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No backup records found',
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Create a backup to store the first recovery point in Appwrite.',
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white60 : AppColors.textSecondary,
            ),
          ),
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
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${backup.id} | ${backup.date}',
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
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              backup.size,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
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
                  () => _requestDownload(backup),
                  'Download',
                ),
                _buildIconAction(
                  Icons.delete_outline_rounded,
                  AppColors.error,
                  () => _confirmDeleteBackup(backup, isDark),
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
                        fontWeight: FontWeight.w500,
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
                () => _requestDownload(backup),
                'Download',
              ),
              _buildIconAction(
                Icons.delete_outline_rounded,
                AppColors.error,
                () => _confirmDeleteBackup(backup, isDark),
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
            fontWeight: FontWeight.w600,
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
            fontWeight: FontWeight.w500,
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
              fontWeight: FontWeight.w500,
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
          fontWeight: FontWeight.w500,
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
            fontWeight: FontWeight.w500,
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
          fontWeight: FontWeight.w500,
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
              fontWeight: FontWeight.w500,
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
    bool isDialogCreating = false;
    String? dialogError;
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
                                fontWeight: FontWeight.w600,
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
                        onPressed: isDialogCreating
                            ? null
                            : () => Navigator.pop(context),
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
                        items: _farmBackups.isEmpty
                            ? const ['global']
                            : _farmBackups.map((farm) => farm.id).toList(),
                        labels: {
                          if (_farmBackups.isEmpty) 'global': 'Global Platform',
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
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (dialogError != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                            border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.28),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: AppColors.error,
                                size: 20,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  dialogError!,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w500,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
                          onPressed: isDialogCreating
                              ? null
                              : () => Navigator.pop(context),
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
                          onPressed: isDialogCreating || _isCreatingBackup
                              ? null
                              : () async {
                                  setDialogState(() {
                                    isDialogCreating = true;
                                    dialogError = null;
                                  });
                                  try {
                                    await _createBackup(
                                      context: context,
                                      name: nameController.text,
                                      scope: selectedScope,
                                      type: selectedType,
                                    );
                                  } catch (error) {
                                    if (!context.mounted) return;
                                    setDialogState(() {
                                      dialogError = error.toString();
                                      isDialogCreating = false;
                                    });
                                    return;
                                  }
                                  if (context.mounted) {
                                    setDialogState(
                                        () => isDialogCreating = false);
                                  }
                                },
                          icon: isDialogCreating
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.backup_rounded, size: 18),
                          label: Text(
                            isDialogCreating ? 'Creating...' : 'Create Backup',
                          ),
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
                  fontWeight: FontWeight.w600,
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
                              fontWeight: FontWeight.w500,
                              color:
                                  isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${backup.farm} | ${backup.date} | ${backup.size}',
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
                          fontWeight: FontWeight.w500,
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
          fontWeight: FontWeight.w500,
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
    required this.retentionDays,
    required this.sizeBytes,
    required this.sortDate,
    required this.collectionsCount,
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
  final int retentionDays;
  final int sizeBytes;
  final DateTime sortDate;
  final int collectionsCount;
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
