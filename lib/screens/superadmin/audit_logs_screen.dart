import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/modern_admin_header.dart';
import '../../core/widgets/superadmin_sidebar.dart';
import '../../providers/auth_provider.dart';

/// Audit Logs - View all system activities and user actions.
class AuditLogsScreen extends ConsumerStatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  ConsumerState<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends ConsumerState<AuditLogsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

  int _selectedNavIndex = 6;
  String _selectedScope = 'all';
  String _selectedCategory = 'All';
  String _selectedUser = 'All Users';
  String _searchQuery = '';

  final List<_AuditScope> _scopes = const [
    _AuditScope(
      id: 'all',
      name: 'Global Audit',
      subtitle: 'All platform and farm events',
      eventCount: '12.5K',
      criticalCount: '23',
      lastEvent: '2 min ago',
      icon: Icons.public_rounded,
      color: AppColors.primary,
      isGlobal: true,
    ),
    _AuditScope(
      id: 'platform',
      name: 'Platform Control',
      subtitle: 'Users, roles, billing, config, backups',
      eventCount: '4.8K',
      criticalCount: '9',
      lastEvent: '5 min ago',
      icon: Icons.admin_panel_settings_rounded,
      color: AppColors.info,
      isGlobal: true,
    ),
    _AuditScope(
      id: 'green-valley',
      name: 'Green Valley Farm',
      subtitle: 'Crops, sensors, stock, worker actions',
      eventCount: '2.4K',
      criticalCount: '4',
      lastEvent: '11 min ago',
      icon: Icons.agriculture_rounded,
      color: AppColors.success,
    ),
    _AuditScope(
      id: 'north-ridge',
      name: 'North Ridge Farm',
      subtitle: 'Harvest, maintenance, deliveries',
      eventCount: '1.9K',
      criticalCount: '3',
      lastEvent: '18 min ago',
      icon: Icons.terrain_rounded,
      color: AppColors.warning,
    ),
    _AuditScope(
      id: 'sunset-acres',
      name: 'Sunset Acres',
      subtitle: 'Fulfillment, QA, sales approvals',
      eventCount: '2.1K',
      criticalCount: '5',
      lastEvent: '29 min ago',
      icon: Icons.wb_sunny_rounded,
      color: AppColors.error,
    ),
  ];

  final List<_AuditLog> _auditLogs = const [
    _AuditLog(
      id: 'AL-23091',
      user: 'Sarah SuperAdmin',
      action: 'Approved global pricing policy for premium lettuce',
      category: 'Approve',
      timestamp: '2026-05-18 14:30',
      ip: '192.168.1.100',
      scope: 'platform',
      farm: 'Platform Control',
      severity: 'High',
      module: 'Pricing',
    ),
    _AuditLog(
      id: 'AL-23090',
      user: 'Sarah SuperAdmin',
      action: 'Created platform recovery backup',
      category: 'System',
      timestamp: '2026-05-18 14:10',
      ip: '192.168.1.100',
      scope: 'platform',
      farm: 'Platform Control',
      severity: 'Medium',
      module: 'Backup',
    ),
    _AuditLog(
      id: 'AL-23089',
      user: 'John Admin',
      action: 'Updated sensor threshold for greenhouse humidity',
      category: 'Update',
      timestamp: '2026-05-18 13:45',
      ip: '192.168.1.105',
      scope: 'green-valley',
      farm: 'Green Valley Farm',
      severity: 'Medium',
      module: 'Sensors',
    ),
    _AuditLog(
      id: 'AL-23088',
      user: 'Maya Technician',
      action: 'Deleted inactive sensor TEMP-045 after replacement',
      category: 'Delete',
      timestamp: '2026-05-18 13:12',
      ip: '192.168.1.144',
      scope: 'green-valley',
      farm: 'Green Valley Farm',
      severity: 'High',
      module: 'Sensors',
    ),
    _AuditLog(
      id: 'AL-23087',
      user: 'Alice Owner',
      action: 'Created harvest batch BATCH-156',
      category: 'Create',
      timestamp: '2026-05-18 12:56',
      ip: '192.168.1.110',
      scope: 'north-ridge',
      farm: 'North Ridge Farm',
      severity: 'Low',
      module: 'Harvest',
    ),
    _AuditLog(
      id: 'AL-23086',
      user: 'Sarah SuperAdmin',
      action: 'Suspended farm access pending compliance review',
      category: 'Suspend',
      timestamp: '2026-05-18 12:20',
      ip: '192.168.1.100',
      scope: 'sunset-acres',
      farm: 'Sunset Acres',
      severity: 'Critical',
      module: 'Compliance',
    ),
    _AuditLog(
      id: 'AL-23085',
      user: 'John Admin',
      action: 'Updated delivery route assignment',
      category: 'Update',
      timestamp: '2026-05-18 11:30',
      ip: '192.168.1.105',
      scope: 'north-ridge',
      farm: 'North Ridge Farm',
      severity: 'Low',
      module: 'Deliveries',
    ),
    _AuditLog(
      id: 'AL-23084',
      user: 'Quality Lead',
      action: 'Approved QA inspection for shipment QA-882',
      category: 'Approve',
      timestamp: '2026-05-18 10:48',
      ip: '192.168.1.132',
      scope: 'sunset-acres',
      farm: 'Sunset Acres',
      severity: 'Medium',
      module: 'Quality',
    ),
    _AuditLog(
      id: 'AL-23083',
      user: 'Sarah SuperAdmin',
      action: 'Updated role permissions for fulfillment manager',
      category: 'Update',
      timestamp: '2026-05-18 10:12',
      ip: '192.168.1.100',
      scope: 'platform',
      farm: 'Platform Control',
      severity: 'High',
      module: 'Users',
    ),
    _AuditLog(
      id: 'AL-23082',
      user: 'Care Team',
      action: 'Created irrigation exception log',
      category: 'Create',
      timestamp: '2026-05-18 09:35',
      ip: '192.168.1.121',
      scope: 'green-valley',
      farm: 'Green Valley Farm',
      severity: 'Low',
      module: 'Caretaker',
    ),
  ];

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
        _buildScopeGrid(isDark, isMobile),
        const SizedBox(height: AppSpacing.lg),
        _buildFilterPanel(isDark, isMobile),
        const SizedBox(height: AppSpacing.lg),
        _buildLogsPanel(isDark, isMobile, filteredLogs),
      ],
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
                  fontWeight: FontWeight.w800,
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
            fontWeight: FontWeight.w800,
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
              fontWeight: FontWeight.w800,
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

    return InkWell(
      onTap: () => setState(() => _selectedScope = scope.id),
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(AppSpacing.lg),
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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: scope.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(scope.icon, color: scope.color, size: 22),
                ),
                const Spacer(),
                _buildPill(scope.isGlobal ? 'Global' : 'Farm', scope.color),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              scope.name,
              style: AppTypography.bodyLarge.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w800,
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
    final categories = const [
      'All',
      'Create',
      'Update',
      'Delete',
      'Approve',
      'Suspend',
      'System',
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
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
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
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${log.id} • ${log.module} • ${log.ip}',
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
                fontWeight: FontWeight.w600,
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
                fontWeight: FontWeight.w600,
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
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${log.farm} • ${log.module}',
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
                  '${log.id} • ${log.timestamp}',
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
          fontWeight: FontWeight.w800,
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
              fontWeight: FontWeight.w700,
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
                            fontWeight: FontWeight.w800,
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
                  fontWeight: FontWeight.w800,
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
                fontWeight: FontWeight.w700,
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
                                fontWeight: FontWeight.bold,
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
                          fontWeight: FontWeight.w800,
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
              fontWeight: FontWeight.w700,
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
      'ID,Farm,User,Action,Category,Severity,Module,Timestamp,IP Address',
      ...logs.map(
        (log) =>
            '${log.id},${log.farm},"${log.user}","${log.action}",${log.category},${log.severity},${log.module},${log.timestamp},${log.ip}',
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
    "ip": "${log.ip}"
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
        'IP: ${log.ip}';
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
