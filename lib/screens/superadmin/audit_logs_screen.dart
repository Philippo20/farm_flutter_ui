import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/modern_admin_header.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../core/widgets/superadmin_sidebar.dart';
import '../../providers/auth_provider.dart';
import '../../services/superadmin_api_service.dart';

/// Audit Logs - View all system activities and user actions.
class AuditLogsScreen extends ConsumerStatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  ConsumerState<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends ConsumerState<AuditLogsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

  int _selectedNavIndex = 7;
  String _selectedScope = 'all';
  String _selectedCategory = 'All';
  String _selectedUser = 'All Users';
  String _searchQuery = '';
  bool _isLoadingAudits = false;
  String? _auditsError;
  final SuperAdminApiService _api = SuperAdminApiService();

  final List<_AuditLog> _auditLogs = [];
  final Map<String, String> _actorNamesByKey = {};

  List<_AuditScope> get _scopes => [
        _buildAuditScope(
          id: 'all',
          name: 'Global Audit',
          subtitle: 'All backend audit events',
          icon: Icons.public_rounded,
          color: AppColors.primary,
          isGlobal: true,
        ),
        _buildAuditScope(
          id: 'platform',
          name: 'Platform Control',
          subtitle: 'Users, roles, settings, and admin changes',
          icon: Icons.admin_panel_settings_rounded,
          color: AppColors.info,
          isGlobal: true,
        ),
        _buildAuditScope(
          id: 'farm',
          name: 'Farm Operations',
          subtitle: 'Farms, crops, batches, sensors, and caretaker activity',
          icon: Icons.agriculture_rounded,
          color: AppColors.success,
        ),
        _buildAuditScope(
          id: 'commerce',
          name: 'Commercial Flow',
          subtitle: 'Pricing, packaging, inventory, fulfillment, and sales',
          icon: Icons.storefront_rounded,
          color: AppColors.warning,
        ),
      ];

  _AuditScope _buildAuditScope({
    required String id,
    required String name,
    required String subtitle,
    required IconData icon,
    required Color color,
    bool isGlobal = false,
  }) {
    final logs = _logsForScope(id);
    final highRisk = logs
        .where((log) => log.severity == 'High' || log.severity == 'Critical')
        .length;
    return _AuditScope(
      id: id,
      name: name,
      subtitle: subtitle,
      eventCount: logs.length.toString(),
      criticalCount: highRisk.toString(),
      lastEvent: _lastActivityLabel(logs),
      icon: icon,
      color: color,
      isGlobal: isGlobal,
    );
  }

  List<_AuditLog> _logsForScope(String scope) {
    if (scope == 'all') return _auditLogs;
    return _auditLogs.where((log) => log.scope == scope).toList();
  }

  String _lastActivityLabel(List<_AuditLog> logs) {
    if (logs.isEmpty) return '-';
    return logs.first.timestamp;
  }

  @override
  void initState() {
    super.initState();
    _loadAudits();
  }

  Future<void> _loadAudits() async {
    setState(() {
      _isLoadingAudits = true;
      _auditsError = null;
      _auditLogs.clear();
    });

    try {
      final results = await Future.wait([
        _api.getAudits(),
        _api.getUsers(),
      ]);
      if (!mounted) return;
      _actorNamesByKey
        ..clear()
        ..addAll(_buildActorNameLookup(results[1]));
      final audits = results[0];
      final mappedAudits = audits.map(_mapAuditDocument).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      setState(() {
        _auditLogs
          ..clear()
          ..addAll(mappedAudits);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _auditsError = error.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoadingAudits = false);
      }
    }
  }

  _AuditLog _mapAuditDocument(Map<String, dynamic> doc) {
    final category = _categoryLabel(doc['action_type']);
    final role = (doc['performed_by_role'] ?? '').toString();
    final actor = _actorLabel(doc['performed_by_id'], role);
    return _AuditLog(
      id: (doc[r'$id'] ?? doc['audit_id'] ?? doc['id'] ?? '').toString(),
      user: actor,
      action: (doc['action_details'] ?? category).toString(),
      category: category,
      timestamp: _dateLabel(doc['timestamp'] ?? doc[r'$createdAt']),
      ip: (doc['ip_address'] ?? '-').toString(),
      scope: _scopeForCollection(doc['collection_name']),
      farm: (doc['collection_name'] ?? 'Platform Control').toString(),
      severity: _severityForStatus(doc['status']),
      module:
          role.isEmpty ? (doc['collection_name'] ?? 'System').toString() : role,
      previousData: (doc['previous_data'] ?? '').toString(),
      newData: (doc['new_data'] ?? '').toString(),
    );
  }

  Map<String, String> _buildActorNameLookup(List<Map<String, dynamic>> users) {
    final lookup = <String, String>{};
    for (final user in users) {
      final name = (user['name'] ?? '').toString().trim();
      if (name.isEmpty) continue;
      for (final key in [
        user[r'$id'],
        user['id'],
        user['user_id'],
        user['email'],
        name,
      ]) {
        final normalized = key?.toString().trim().toLowerCase();
        if (normalized != null && normalized.isNotEmpty) {
          lookup[normalized] = name;
        }
      }
    }
    return lookup;
  }

  String _actorLabel(dynamic value, String role) {
    final raw = value?.toString().trim() ?? '';
    final normalized = raw.toLowerCase();
    final currentUser = ref.read(currentUserProvider);
    final currentName = currentUser?.name.trim() ?? '';

    if (raw.isEmpty || normalized == 'system') {
      if (role.toLowerCase().contains('superadmin') && currentName.isNotEmpty) {
        return currentName;
      }
      return 'System';
    }

    return _actorNamesByKey[normalized] ?? raw;
  }

  String _categoryLabel(dynamic value) {
    final text = value?.toString() ?? 'System';
    if (text == 'Approval') return 'Approve';
    if (text == 'Suspension') return 'Suspend';
    return _labelFromSnakeCase(text);
  }

  String _severityForStatus(dynamic value) {
    final text = value?.toString().toLowerCase() ?? '';
    if (text.contains('failed')) return 'High';
    if (text.contains('pending')) return 'Medium';
    return 'Low';
  }

  String _scopeForCollection(dynamic value) {
    final text = value?.toString().toLowerCase() ?? '';
    if (text.contains('user') ||
        text.contains('role') ||
        text.contains('wallet') ||
        text.contains('backup') ||
        text.contains('setting') ||
        text.contains('platform')) {
      return 'platform';
    }
    if (text.contains('farm') ||
        text.contains('crop') ||
        text.contains('plant') ||
        text.contains('batch') ||
        text.contains('sensor') ||
        text.contains('threshold') ||
        text.contains('grow') ||
        text.contains('caretaker')) {
      return 'farm';
    }
    if (text.contains('pricing') ||
        text.contains('price') ||
        text.contains('package') ||
        text.contains('inventory') ||
        text.contains('fulfillment') ||
        text.contains('sales') ||
        text.contains('delivery') ||
        text.contains('quality')) {
      return 'commerce';
    }
    return 'platform';
  }

  String _labelFromSnakeCase(String value) {
    return value
        .replaceAll('_', ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  String _dateLabel(dynamic value) {
    final text = value?.toString() ?? '';
    if (text.length >= 16) return text.substring(0, 16).replaceFirst('T', ' ');
    return text.isEmpty ? '-' : text;
  }

  List<_AuditLog> get _filteredLogs {
    var logs = _auditLogs;

    if (_selectedScope != 'all') {
      logs = logs.where((log) => log.scope == _selectedScope).toList();
    }

    if (_selectedCategory != 'All') {
      logs = logs.where((log) => log.category == _selectedCategory).toList();
    }

    if (_selectedUser != 'All Users') {
      logs = logs.where((log) => log.user == _selectedUser).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      logs = logs
          .where(
            (log) =>
                log.id.toLowerCase().contains(query) ||
                log.user.toLowerCase().contains(query) ||
                log.action.toLowerCase().contains(query) ||
                log.farm.toLowerCase().contains(query) ||
                log.module.toLowerCase().contains(query),
          )
          .toList();
    }

    return logs;
  }

  bool get _hasActiveFilters =>
      _selectedScope != 'all' ||
      _selectedCategory != 'All' ||
      _selectedUser != 'All Users' ||
      _searchQuery.trim().isNotEmpty;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    final filteredLogs = _filteredLogs;

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
          ? _buildMobileLayout(isDark, firstName, filteredLogs)
          : _buildDesktopLayout(
              isDark,
              userName,
              userEmail,
              firstName,
              filteredLogs,
            ),
      bottomNavigationBar: isMobile
          ? SuperAdminMobileBottomNav(
              selectedIndex: 7,
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
    List<_AuditLog> filteredLogs,
  ) {
    return Row(
      children: [
        SuperAdminSidebar(
          selectedIndex: 7,
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
                  child: _buildContent(isDark, filteredLogs, isMobile: false),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(
    bool isDark,
    String firstName,
    List<_AuditLog> filteredLogs,
  ) {
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
            child: _buildContent(isDark, filteredLogs, isMobile: true),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(
    bool isDark,
    List<_AuditLog> filteredLogs, {
    required bool isMobile,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHero(isDark, isMobile, filteredLogs),
        const SizedBox(height: AppSpacing.lg),
        if (_auditsError != null) ...[
          _buildSyncStatus(isDark),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (_isLoadingAudits && _auditLogs.isEmpty)
          const AdminDataSkeleton()
        else ...[
          _buildScopeGrid(isDark, isMobile),
          const SizedBox(height: AppSpacing.lg),
          _buildFilterPanel(isDark, isMobile),
          const SizedBox(height: AppSpacing.lg),
          _buildLogsPanel(isDark, isMobile, filteredLogs),
        ],
      ],
    );
  }

  Widget _buildSyncStatus(bool isDark) {
    final hasError = _auditsError != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: hasError
            ? AppColors.error.withValues(alpha: 0.08)
            : AppColors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.error),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Could not refresh audit logs: $_auditsError',
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Refresh audit logs',
            onPressed: _isLoadingAudits ? null : _loadAudits,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(
    bool isDark,
    bool isMobile,
    List<_AuditLog> filteredLogs,
  ) {
    final selectedScope = _scopes.firstWhere(
      (scope) => scope.id == _selectedScope,
      orElse: () => _scopes.first,
    );

    return Container(
      padding: EdgeInsets.all(isMobile ? AppSpacing.lg : AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF111C24), const Color(0xFF08141D)]
              : [const Color(0xFFF1F7FF), const Color(0xFFEFFAF4)],
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
                _buildHeroMetrics(isDark, selectedScope, filteredLogs),
                const SizedBox(height: AppSpacing.md),
                _buildHeroActions(isDark, filteredLogs),
              ],
            )
          : Row(
              children: [
                Expanded(child: _buildHeroText(isDark)),
                const SizedBox(width: AppSpacing.xl),
                SizedBox(
                  width: 330,
                  child: _buildHeroMetrics(isDark, selectedScope, filteredLogs),
                ),
                const SizedBox(width: AppSpacing.lg),
                SizedBox(
                  width: 170,
                  child: _buildHeroActions(isDark, filteredLogs),
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
              horizontal: AppSpacing.md, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: isDark ? 0.18 : 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            border: Border.all(color: AppColors.info.withValues(alpha: 0.24)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.manage_search_rounded,
                  color: AppColors.info, size: 16),
              const SizedBox(width: 8),
              Text(
                'Global audit intelligence',
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? Colors.white : AppColors.info,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Audit Logs',
          style: AppTypography.h4.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Review platform-wide events or drill into individual farm activity with traceable users, modules, IP addresses, and severity.',
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? Colors.white70 : AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroMetrics(
    bool isDark,
    _AuditScope selectedScope,
    List<_AuditLog> filteredLogs,
  ) {
    final criticalVisible = filteredLogs
        .where((log) => log.severity == 'Critical' || log.severity == 'High')
        .length;

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
            selectedScope.name,
            style: AppTypography.bodyLarge.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildMiniMetric('Visible events', '${filteredLogs.length}', isDark),
          const SizedBox(height: 8),
          _buildMiniMetric('High risk', '$criticalVisible', isDark),
          const SizedBox(height: 8),
          _buildMiniMetric('Last activity', selectedScope.lastEvent, isDark),
        ],
      ),
    );
  }

  Widget _buildHeroActions(bool isDark, List<_AuditLog> filteredLogs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () => _showExportDialog(context, isDark, filteredLogs),
          icon: const Icon(Icons.download_rounded, size: 18),
          label: const Text('Export Logs'),
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
          onPressed: _clearFilters,
          icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
          label: const Text('Clear'),
          style: OutlinedButton.styleFrom(
            foregroundColor: isDark ? Colors.white : AppColors.textPrimary,
            side: BorderSide(
              color: _hasActiveFilters
                  ? AppColors.primary
                  : (isDark ? Colors.white24 : AppColors.neutral300),
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

  Widget _buildScopeGrid(bool isDark, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Audit Scope',
          'Switch between all events, platform control, or individual farm logs.',
          isDark,
        ),
        const SizedBox(height: AppSpacing.md),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _scopes.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isMobile ? 1 : 3,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: isMobile ? 1.9 : 1.65,
          ),
          itemBuilder: (context, index) =>
              _buildScopeCard(_scopes[index], isDark),
        ),
      ],
    );
  }

  Widget _buildScopeCard(_AuditScope scope, bool isDark) {
    final isSelected = _selectedScope == scope.id;
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return InkWell(
      onTap: () => setState(() => _selectedScope = scope.id),
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
        decoration: BoxDecoration(
          color: isSelected
              ? scope.color.withValues(alpha: isDark ? 0.2 : 0.12)
              : (isDark ? AppColors.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: isSelected
                ? scope.color.withValues(alpha: 0.65)
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
                  padding: EdgeInsets.all(isMobile ? 8 : 10),
                  decoration: BoxDecoration(
                    color: scope.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(scope.icon,
                      color: scope.color, size: isMobile ? 20 : 22),
                ),
                const Spacer(),
                _buildPill(scope.isGlobal ? 'Global' : 'Farm', scope.color),
              ],
            ),
            SizedBox(height: isMobile ? AppSpacing.sm : AppSpacing.md),
            Text(
              scope.name,
              style: AppTypography.bodyLarge.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              scope.subtitle,
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
                    child:
                        _buildMetricBlock('Events', scope.eventCount, isDark)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                    child: _buildMetricBlock(
                        'Critical', scope.criticalCount, isDark)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPanel(bool isDark, bool isMobile) {
    final users = ['All Users', ..._auditLogs.map((log) => log.user).toSet()];
    final categories = [
      'All',
      ..._auditLogs
          .map((log) => log.category)
          .where((item) => item.isNotEmpty)
          .toSet(),
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
            'Filters',
            'Search by event, user, module, farm, or ID.',
            isDark,
          ),
          const SizedBox(height: AppSpacing.md),
          isMobile
              ? Column(
                  children: [
                    _buildSearchField(isDark),
                    const SizedBox(height: AppSpacing.md),
                    _buildDropdown(
                      value: _selectedUser,
                      items: users.toList(),
                      icon: Icons.person_search_rounded,
                      isDark: isDark,
                      onChanged: (value) =>
                          setState(() => _selectedUser = value!),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(flex: 2, child: _buildSearchField(isDark)),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _buildDropdown(
                        value: _selectedUser,
                        items: users.toList(),
                        icon: Icons.person_search_rounded,
                        isDark: isDark,
                        onChanged: (value) =>
                            setState(() => _selectedUser = value!),
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: categories.map((category) {
              final isSelected = _selectedCategory == category;
              return ChoiceChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) setState(() => _selectedCategory = category);
                },
                selectedColor: AppColors.primary.withValues(alpha: 0.18),
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.white,
                side: BorderSide(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? Colors.white12 : AppColors.neutral200),
                ),
                labelStyle: TextStyle(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? Colors.white70 : AppColors.textSecondary),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsPanel(
    bool isDark,
    bool isMobile,
    List<_AuditLog> filteredLogs,
  ) {
    final activeScope = _scopes
        .firstWhere((scope) => scope.id == _selectedScope,
            orElse: () => _scopes.first)
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
                    _buildSectionHeader('Activity Log', activeScope, isDark),
                    const SizedBox(height: AppSpacing.md),
                    _buildRecordCount(filteredLogs.length, isDark),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _buildSectionHeader(
                          'Activity Log', activeScope, isDark),
                    ),
                    _buildRecordCount(filteredLogs.length, isDark),
                  ],
                ),
          const SizedBox(height: AppSpacing.md),
          if (filteredLogs.isEmpty)
            _buildEmptyState(isDark)
          else if (isMobile)
            ...filteredLogs.map((log) => _buildMobileLogCard(log, isDark))
          else
            _buildLogTable(filteredLogs, isDark),
        ],
      ),
    );
  }

  Widget _buildLogTable(List<_AuditLog> logs, bool isDark) {
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
              _buildTableHeader('Event', flex: 3, isDark: isDark),
              _buildTableHeader('Scope', flex: 2, isDark: isDark),
              _buildTableHeader('User', flex: 2, isDark: isDark),
              _buildTableHeader('Severity', isDark: isDark),
              _buildTableHeader('Time', isDark: isDark),
              const SizedBox(width: 48),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...logs.map((log) => _buildLogRow(log, isDark)),
      ],
    );
  }

  Widget _buildLogRow(_AuditLog log, bool isDark) {
    final category = _categoryStyle(log.category);
    final severity = _severityStyle(log.severity);

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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: category.color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(category.icon, color: category.color, size: 18),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log.action,
                        style: AppTypography.bodyMedium.copyWith(
                          color: isDark ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${log.id} | ${log.module} | ${log.ip}',
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
              log.farm,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              log.user,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(child: _buildPill(log.severity, severity.color)),
          Expanded(
            child: Text(
              log.timestamp,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white60 : AppColors.textSecondary,
              ),
            ),
          ),
          SizedBox(
            width: 48,
            child: IconButton(
              onPressed: () => _showLogDetails(context, log, isDark),
              icon: const Icon(Icons.visibility_outlined, size: 18),
              color: AppColors.primary,
              tooltip: 'View details',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLogCard(_AuditLog log, bool isDark) {
    final category = _categoryStyle(log.category);
    final severity = _severityStyle(log.severity);

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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(category.icon, color: category.color, size: 18),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.action,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${log.farm} | ${log.module}',
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
              _buildPill(log.category, category.color),
              _buildPill(log.severity, severity.color),
              _buildPill(log.user, AppColors.primary),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${log.id} | ${log.timestamp}',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? Colors.white54 : AppColors.textSecondary,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _showLogDetails(context, log, isDark),
                icon: const Icon(Icons.visibility_outlined, size: 18),
                color: AppColors.primary,
                tooltip: 'View details',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(bool isDark) {
    return TextField(
      controller: _searchController,
      style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary),
      onSubmitted: (value) => setState(() => _searchQuery = value),
      decoration: InputDecoration(
        hintText: 'Search audit events...',
        hintStyle: TextStyle(
          color: isDark ? Colors.white38 : AppColors.textSecondary,
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: isDark ? Colors.white54 : AppColors.textSecondary,
        ),
        suffixIcon: _searchController.text.isEmpty
            ? IconButton(
                onPressed: () =>
                    setState(() => _searchQuery = _searchController.text),
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                color: AppColors.primary,
              )
            : IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                icon: const Icon(Icons.close_rounded, size: 18),
                color: isDark ? Colors.white54 : AppColors.textSecondary,
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
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required IconData icon,
    required bool isDark,
    required ValueChanged<String?> onChanged,
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
                        size: 18,
                        color:
                            isDark ? Colors.white54 : AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: Text(item)),
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

  Widget _buildRecordCount(int count, bool isDark) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: isDark ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Text(
        '$count event${count == 1 ? '' : 's'}',
        style: AppTypography.bodySmall.copyWith(
          color: isDark ? Colors.white : AppColors.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPill(String text, Color color) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
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

  Widget _buildEmptyState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color:
            isDark ? Colors.white.withValues(alpha: 0.03) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        children: [
          Icon(
            Icons.manage_search_rounded,
            color: isDark ? Colors.white38 : AppColors.textSecondary,
            size: 42,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No audit events match the current filters.',
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? Colors.white70 : AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showLogDetails(BuildContext context, _AuditLog log, bool isDark) {
    final category = _categoryStyle(log.category);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        child: Container(
          width: 460,
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: category.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Icon(category.icon, color: category.color, size: 24),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Audit Event Details',
                          style: AppTypography.h6.copyWith(
                            color:
                                isDark ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          log.id,
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark
                                ? Colors.white60
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.white70 : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                log.action,
                style: AppTypography.bodyLarge.copyWith(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildDetailRow('Farm / Scope', log.farm, isDark),
              _buildDetailRow('User', log.user, isDark),
              _buildDetailRow('Module', log.module, isDark),
              _buildDetailRow('Category', log.category, isDark),
              _buildDetailRow('Severity', log.severity, isDark),
              _buildDetailRow('Timestamp', log.timestamp, isDark),
              _buildDetailRow('IP Address', log.ip, isDark),
              if (log.previousData.trim().isNotEmpty)
                _buildDetailRow('Previous Data', log.previousData, isDark),
              if (log.newData.trim().isNotEmpty)
                _buildDetailRow('New Data', log.newData, isDark),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _formatLog(log)));
                    Navigator.pop(context);
                    _showSnack('Audit event copied to clipboard.');
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copy Event'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white54 : AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(
    BuildContext context,
    bool isDark,
    List<_AuditLog> logs,
  ) {
    String selectedFormat = 'CSV';
    final isMobile = MediaQuery.of(context).size.width < 600;

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
            width: isMobile ? double.infinity : 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.success,
                        AppColors.success.withValues(alpha: 0.82),
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
                          Icons.download_rounded,
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
                              'Export Audit Logs',
                              style: AppTypography.h6.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${logs.length} filtered records',
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
                      Text(
                        'Export Format',
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w500,
                          color:
                              isDark ? Colors.white70 : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: ['CSV', 'JSON', 'PDF'].map((format) {
                          final icon = format == 'CSV'
                              ? Icons.table_chart_rounded
                              : format == 'JSON'
                                  ? Icons.data_object_rounded
                                  : Icons.picture_as_pdf_rounded;
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: format == 'PDF' ? 0 : AppSpacing.sm,
                              ),
                              child: _buildFormatOption(
                                format,
                                icon,
                                selectedFormat == format,
                                isDark,
                                () => setDialogState(
                                  () => selectedFormat = format,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : AppColors.neutral50,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(
                            color: isDark
                                ? Colors.white10
                                : Colors.black.withValues(alpha: 0.05),
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildExportSummaryRow(
                              'Scope',
                              _scopes
                                  .firstWhere(
                                    (scope) => scope.id == _selectedScope,
                                    orElse: () => _scopes.first,
                                  )
                                  .name,
                              isDark,
                            ),
                            _buildExportSummaryRow(
                              'Category',
                              _selectedCategory,
                              isDark,
                            ),
                            _buildExportSummaryRow(
                              'User',
                              _selectedUser,
                              isDark,
                            ),
                            _buildExportSummaryRow(
                              'Total Records',
                              '${logs.length}',
                              isDark,
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
                            _exportLogs(logs, selectedFormat);
                          },
                          icon: const Icon(Icons.download_rounded, size: 18),
                          label: Text('Export $selectedFormat'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
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

  Widget _buildFormatOption(
    String format,
    IconData icon,
    bool isSelected,
    bool isDark,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : AppColors.neutral50),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? Colors.white10 : AppColors.neutral200),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? Colors.white54 : AppColors.textSecondary),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              format,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? Colors.white : AppColors.textPrimary),
              ),
            ),
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
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _selectedScope = 'all';
      _selectedCategory = 'All';
      _selectedUser = 'All Users';
      _searchQuery = '';
    });
  }

  _AuditStyle _categoryStyle(String category) {
    switch (category) {
      case 'Create':
        return const _AuditStyle(
            Icons.add_circle_outline_rounded, AppColors.success);
      case 'Update':
        return const _AuditStyle(Icons.edit_note_rounded, AppColors.info);
      case 'Delete':
        return const _AuditStyle(Icons.delete_outline_rounded, AppColors.error);
      case 'Approve':
        return const _AuditStyle(Icons.verified_rounded, AppColors.success);
      case 'Suspend':
        return const _AuditStyle(
            Icons.pause_circle_outline_rounded, AppColors.warning);
      case 'System':
        return const _AuditStyle(
            Icons.settings_suggest_rounded, AppColors.primary);
      default:
        return const _AuditStyle(Icons.history_rounded, AppColors.primary);
    }
  }

  _AuditStyle _severityStyle(String severity) {
    switch (severity) {
      case 'Critical':
        return const _AuditStyle(Icons.priority_high_rounded, AppColors.error);
      case 'High':
        return const _AuditStyle(
            Icons.warning_amber_rounded, AppColors.warning);
      case 'Medium':
        return const _AuditStyle(Icons.info_outline_rounded, AppColors.info);
      default:
        return const _AuditStyle(
            Icons.check_circle_outline_rounded, AppColors.success);
    }
  }

  void _exportLogs(List<_AuditLog> logs, String format) {
    final data = switch (format) {
      'JSON' => _exportJson(logs),
      'PDF' => _exportReport(logs),
      _ => _exportCsv(logs),
    };

    Clipboard.setData(ClipboardData(text: data));
    _showSnack('${logs.length} audit records copied as $format.');
  }

  String _exportCsv(List<_AuditLog> logs) {
    final rows = [
      'ID,Farm,User,Action,Category,Severity,Module,Timestamp,IP Address,Previous Data,New Data',
      ...logs.map(
        (log) =>
            '${log.id},${log.farm},"${log.user}","${log.action}",${log.category},${log.severity},${log.module},${log.timestamp},${log.ip},"${log.previousData}","${log.newData}"',
      ),
    ];
    return rows.join('\n');
  }

  String _exportJson(List<_AuditLog> logs) {
    final rows = logs.map((log) {
      return '''
  {
    "id": "${log.id}",
    "farm": "${log.farm}",
    "user": "${log.user}",
    "action": "${log.action}",
    "category": "${log.category}",
    "severity": "${log.severity}",
    "module": "${log.module}",
    "timestamp": "${log.timestamp}",
    "ip": "${log.ip}",
    "previousData": "${log.previousData}",
    "newData": "${log.newData}"
  }''';
    }).join(',\n');
    return '[\n$rows\n]';
  }

  String _exportReport(List<_AuditLog> logs) {
    final buffer = StringBuffer()
      ..writeln('AUDIT LOGS REPORT')
      ..writeln('=================')
      ..writeln('Scope: $_selectedScope')
      ..writeln('Category: $_selectedCategory')
      ..writeln('User: $_selectedUser')
      ..writeln('Total Records: ${logs.length}')
      ..writeln();

    for (final log in logs) {
      buffer
        ..writeln(_formatLog(log))
        ..writeln('---');
    }
    return buffer.toString();
  }

  String _formatLog(_AuditLog log) {
    return 'ID: ${log.id}\n'
        'Farm: ${log.farm}\n'
        'User: ${log.user}\n'
        'Action: ${log.action}\n'
        'Category: ${log.category}\n'
        'Severity: ${log.severity}\n'
        'Module: ${log.module}\n'
        'Timestamp: ${log.timestamp}\n'
        'IP: ${log.ip}\n'
        'Previous Data: ${log.previousData.isEmpty ? "-" : log.previousData}\n'
        'New Data: ${log.newData.isEmpty ? "-" : log.newData}';
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    );
  }
}

class _AuditLog {
  const _AuditLog({
    required this.id,
    required this.user,
    required this.action,
    required this.category,
    required this.timestamp,
    required this.ip,
    required this.scope,
    required this.farm,
    required this.severity,
    required this.module,
    required this.previousData,
    required this.newData,
  });

  final String id;
  final String user;
  final String action;
  final String category;
  final String timestamp;
  final String ip;
  final String scope;
  final String farm;
  final String severity;
  final String module;
  final String previousData;
  final String newData;
}

class _AuditScope {
  const _AuditScope({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.eventCount,
    required this.criticalCount,
    required this.lastEvent,
    required this.icon,
    required this.color,
    this.isGlobal = false,
  });

  final String id;
  final String name;
  final String subtitle;
  final String eventCount;
  final String criticalCount;
  final String lastEvent;
  final IconData icon;
  final Color color;
  final bool isGlobal;
}

class _AuditStyle {
  const _AuditStyle(this.icon, this.color);

  final IconData icon;
  final Color color;
}
