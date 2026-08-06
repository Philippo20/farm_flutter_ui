import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/modern_admin_header.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../core/widgets/superadmin_sidebar.dart';
import '../../providers/auth_provider.dart';
import '../../services/superadmin_api_service.dart';

/// Super Admin Dashboard - platform command center.
class SuperAdminDashboard extends ConsumerStatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  ConsumerState<SuperAdminDashboard> createState() =>
      _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends ConsumerState<SuperAdminDashboard> {
  int _selectedNavIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final SuperAdminApiService _api = SuperAdminApiService();

  final List<_DashboardMetric> _metrics = [];
  final List<Map<String, dynamic>> _users = [];
  final List<Map<String, dynamic>> _farms = [];
  final List<Map<String, dynamic>> _plantTypes = [];
  final List<Map<String, dynamic>> _cropVarieties = [];
  final List<Map<String, dynamic>> _packages = [];
  final List<Map<String, dynamic>> _pricing = [];
  final List<Map<String, dynamic>> _inventory = [];
  final List<Map<String, dynamic>> _fulfillments = [];
  final List<Map<String, dynamic>> _sensors = [];
  final List<Map<String, dynamic>> _audits = [];
  final List<Map<String, dynamic>> _backups = [];
  bool _isLoadingDashboard = true;
  String? _dashboardError;

  @override
  void initState() {
    super.initState();
    _loadDashboardMetrics();
  }

  Future<void> _loadDashboardMetrics() async {
    setState(() {
      _isLoadingDashboard = true;
      _dashboardError = null;
    });

    try {
      final results = await Future.wait([
        _api.getUsers(),
        _api.getFarms(),
        _api.getPlantTypes(),
        _api.getCrops(),
        _api.getPackages(),
        _api.getPricing(),
        _api.getInventory(),
        _api.getFulfillments(),
        _api.getSensors(),
        _api.getAudits(),
        _api.getBackups(),
      ]);
      if (!mounted) return;
      final users = results[0];
      final farms = results[1];
      final plantTypes = results[2];
      final cropVarieties = results[3];
      final packages = results[4];
      final pricing = results[5];
      final inventory = results[6];
      final fulfillments = results[7];
      final sensors = results[8];
      final audits = results[9];
      final backups = results[10];
      final inventoryValue = inventory.fold<double>(
        0,
        (sum, item) {
          final value = item['total_value'];
          if (value is num) return sum + value.toDouble();
          return sum + (double.tryParse(value?.toString() ?? '') ?? 0);
        },
      );
      setState(() {
        _users
          ..clear()
          ..addAll(users);
        _farms
          ..clear()
          ..addAll(farms);
        _plantTypes
          ..clear()
          ..addAll(plantTypes);
        _cropVarieties
          ..clear()
          ..addAll(cropVarieties);
        _packages
          ..clear()
          ..addAll(packages);
        _pricing
          ..clear()
          ..addAll(pricing);
        _inventory
          ..clear()
          ..addAll(inventory);
        _fulfillments
          ..clear()
          ..addAll(fulfillments);
        _sensors
          ..clear()
          ..addAll(sensors);
        _audits
          ..clear()
          ..addAll(audits);
        _backups
          ..clear()
          ..addAll(backups);
        _metrics
          ..clear()
          ..addAll([
            _metric(
              label: 'Users',
              value: '${users.length}',
              detail: 'database user records',
              icon: Icons.people_alt_rounded,
              color: AppColors.primary,
              route: '/superadmin/users',
            ),
            _metric(
              label: 'Farms',
              value: '${farms.length}',
              detail: 'registered farm records',
              icon: Icons.agriculture_rounded,
              color: AppColors.success,
              route: '/superadmin/farms',
            ),
            _metric(
              label: 'Plant Types',
              value: '${plantTypes.length}',
              detail: 'crop catalog records',
              icon: Icons.local_florist_rounded,
              color: AppColors.info,
              route: '/superadmin/plants',
            ),
            _metric(
              label: 'Crop Varieties',
              value: '${cropVarieties.length}',
              detail: 'variety records',
              icon: Icons.grass_rounded,
              color: AppColors.success,
              route: '/superadmin/crop-varieties',
            ),
            _metric(
              label: 'Packaging',
              value: '${packages.length}',
              detail: 'packaging records',
              icon: Icons.inventory_2_rounded,
              color: AppColors.warning,
              route: '/superadmin/packaging',
            ),
            _metric(
              label: 'Hub Pricing',
              value: '${pricing.length}',
              detail: 'price records',
              icon: Icons.price_change_rounded,
              color: AppColors.warning,
              route: '/superadmin/pricing',
            ),
            _metric(
              label: 'Inventory',
              value: 'GHS ${inventoryValue.toStringAsFixed(0)}',
              detail: 'global stock value',
              icon: Icons.inventory_2_rounded,
              color: AppColors.success,
              route: '/superadmin/inventory',
            ),
            _metric(
              label: 'Deliveries',
              value: '${fulfillments.length}',
              detail: 'fulfillment records',
              icon: Icons.local_shipping_rounded,
              color: AppColors.info,
              route: '/superadmin/deliveries',
            ),
            _metric(
              label: 'Sensors',
              value: '${sensors.length}',
              detail: 'registered telemetry devices',
              icon: Icons.sensors_rounded,
              color: AppColors.chartTeal,
              route: '/superadmin/sensors',
            ),
            _metric(
              label: 'Backups',
              value: '${backups.length}',
              detail: 'available restore points',
              icon: Icons.backup_rounded,
              color: AppColors.primary,
              route: '/superadmin/backup',
            ),
          ]);
        _isLoadingDashboard = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _metrics.clear();
        _users.clear();
        _farms.clear();
        _plantTypes.clear();
        _cropVarieties.clear();
        _packages.clear();
        _pricing.clear();
        _inventory.clear();
        _fulfillments.clear();
        _sensors.clear();
        _audits.clear();
        _backups.clear();
        _isLoadingDashboard = false;
        _dashboardError = error.toString();
      });
    }
  }

  _DashboardMetric _metric({
    required String label,
    required String value,
    required String detail,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    return _DashboardMetric(
      label: label,
      value: value,
      detail: detail,
      icon: icon,
      color: color,
      route: route,
    );
  }

  int get _openApprovals {
    return _users.where(_isPendingRecord).length +
        _farms.where(_isPendingRecord).length;
  }

  int get _highRiskAudits {
    return _audits.where((audit) {
      final status = (audit['status'] ?? '').toString().toLowerCase();
      final details = (audit['action_details'] ?? '').toString().toLowerCase();
      return status.contains('failed') ||
          status.contains('critical') ||
          status.contains('high') ||
          details.contains('failed') ||
          details.contains('suspend') ||
          details.contains('delete');
    }).length;
  }

  int get _platformHealth {
    if (_users.isEmpty && _farms.isEmpty && _sensors.isEmpty) return 0;
    var score = 100;
    score -= (_openApprovals * 3).clamp(0, 30);
    score -= (_highRiskAudits * 2).clamp(0, 30);
    score -= (_inactiveSensors * 2).clamp(0, 20);
    if (_backups.isEmpty) score -= 15;
    return score.clamp(0, 100);
  }

  int get _inactiveSensors {
    return _sensors.where((sensor) {
      final status = (sensor['status'] ?? '').toString().toLowerCase();
      return status.contains('inactive') ||
          status.contains('faulty') ||
          status.contains('maintenance');
    }).length;
  }

  String get _backupCoverageLabel {
    if (_backups.isEmpty) return '0 backups';
    final farmsWithBackups = _backups
        .map((backup) => (backup['scope_id'] ??
                backup['farm_id'] ??
                backup['farm_name'] ??
                backup['scope'])
            ?.toString()
            .trim())
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .toSet()
        .length;
    if (_farms.isEmpty) return '${_backups.length} backups';
    return '$farmsWithBackups / ${_farms.length} farms';
  }

  bool _isPendingRecord(Map<String, dynamic> record) {
    final status = (record['status'] ?? record['approval_status'] ?? '')
        .toString()
        .toLowerCase();
    return status.contains('pending') ||
        status.contains('review') ||
        status.contains('submitted');
  }

  final List<_DashboardAction> _actions = const [
    _DashboardAction(
      title: 'User Management',
      subtitle: 'Approve users and control platform roles',
      icon: Icons.manage_accounts_rounded,
      color: AppColors.primary,
      route: '/superadmin/users',
    ),
    _DashboardAction(
      title: 'Farm Management',
      subtitle: 'Approve farms and monitor operational status',
      icon: Icons.agriculture_rounded,
      color: AppColors.success,
      route: '/superadmin/farms',
    ),
    _DashboardAction(
      title: 'Plant Types',
      subtitle: 'Categories, maturity units, and crop catalog',
      icon: Icons.eco_rounded,
      color: AppColors.info,
      route: '/superadmin/plants',
    ),
    _DashboardAction(
      title: 'Crop Varieties',
      subtitle: 'Varieties, growing ranges, and seed specifications',
      icon: Icons.grass_rounded,
      color: AppColors.success,
      route: '/superadmin/crop-varieties',
    ),
    _DashboardAction(
      title: 'Packaging',
      subtitle: 'Materials, stock levels, and unit costs',
      icon: Icons.inventory_2_rounded,
      color: AppColors.warning,
      route: '/superadmin/packaging',
    ),
    _DashboardAction(
      title: 'Hub Pricing',
      subtitle: 'Spoke farm selling and bulk prices to hub',
      icon: Icons.price_change_rounded,
      color: AppColors.warning,
      route: '/superadmin/pricing',
    ),
    _DashboardAction(
      title: 'IoT Sensors',
      subtitle: 'Global sensor fleet, telemetry, and diagnostics',
      icon: Icons.sensors_rounded,
      color: AppColors.chartTeal,
      route: '/superadmin/sensors',
    ),
    _DashboardAction(
      title: 'Audit Logs',
      subtitle: 'Global and spoke farm governance trail',
      icon: Icons.manage_search_rounded,
      color: AppColors.info,
      route: '/superadmin/audit',
    ),
    _DashboardAction(
      title: 'Backups',
      subtitle: 'Global and individual farm restore points',
      icon: Icons.backup_rounded,
      color: AppColors.primary,
      route: '/superadmin/backup',
    ),
    _DashboardAction(
      title: 'System Config',
      subtitle: 'Security, automation, and platform settings',
      icon: Icons.settings_applications_rounded,
      color: AppColors.error,
      route: '/superadmin/config',
    ),
    _DashboardAction(
      title: 'Deliveries',
      subtitle: 'Global delivery control and farm logistics',
      icon: Icons.local_shipping_rounded,
      color: AppColors.success,
      route: '/superadmin/deliveries',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth < 1200 && screenWidth >= 600;
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
          : _buildDesktopLayout(
              isDark,
              userName,
              userEmail,
              firstName,
              isTablet,
            ),
      bottomNavigationBar: isMobile
          ? SuperAdminMobileBottomNav(
              selectedIndex: 0,
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
    bool isTablet,
  ) {
    return Row(
      children: [
        SuperAdminSidebar(
          selectedIndex: 0,
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
                onProfileTap: () => Navigator.of(context).pushNamed('/profile'),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: _buildDashboardContent(
                    isDark: isDark,
                    isMobile: false,
                    isTablet: isTablet,
                  ),
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
          onProfileTap: () => Navigator.of(context).pushNamed('/profile'),
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.md,
              top: _isLoadingDashboard ? 0 : AppSpacing.md,
              bottom: AppSpacing.md,
            ),
            child: _buildDashboardContent(
              isDark: isDark,
              isMobile: true,
              isTablet: false,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardContent({
    required bool isDark,
    required bool isMobile,
    required bool isTablet,
  }) {
    if (_isLoadingDashboard) {
      return AdminDataSkeleton(rowCount: 6, compact: isMobile);
    }

    if (_dashboardError != null) {
      return _buildDashboardError(isDark);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHero(isDark, isMobile),
        Transform.translate(
          offset: Offset(0, isMobile ? -56 : 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: isMobile ? AppSpacing.sm : AppSpacing.lg),
              _buildMetricGrid(isDark, isMobile, isTablet),
              const SizedBox(height: AppSpacing.lg),
              _buildOperationsGrid(isDark, isMobile, isTablet),
              const SizedBox(height: AppSpacing.lg),
              _buildGovernanceRow(isDark, isMobile),
              const SizedBox(height: AppSpacing.lg),
              _buildActivityPanel(isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardError(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: _panelDecoration(isDark),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.error),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Unable to load dashboard data',
            style: AppTypography.titleMedium.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _dashboardError!,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: _loadDashboardMetrics,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(bool isDark, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF10251E), const Color(0xFF0D1721)]
              : [const Color(0xFFEFFAF4), const Color(0xFFE9F2FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: isDark
              ? Colors.white10
              : AppColors.primary.withValues(alpha: 0.12),
        ),
        boxShadow: isMobile
            ? null
            : [
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
                _buildHeroCopy(isDark),
                const SizedBox(height: AppSpacing.sm),
                _buildHeroStatus(isDark),
              ],
            )
          : Row(
              children: [
                Expanded(child: _buildHeroCopy(isDark)),
                const SizedBox(width: AppSpacing.xl),
                SizedBox(width: 340, child: _buildHeroStatus(isDark)),
              ],
            ),
    );
  }

  Widget _buildHeroCopy(bool isDark) {
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
                Icons.admin_panel_settings_rounded,
                color: AppColors.primary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Super Admin Command Center',
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
          'Platform Control Dashboard',
          style: AppTypography.h4.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Monitor farms, users, plant catalog, packaging, hub pricing, inventory, deliveries, audit, backups, and platform configuration from one executive view.',
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? Colors.white70 : AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroStatus(bool isDark) {
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
        children: [
          _buildHeroLine(
            'Platform health',
            '$_platformHealth%',
            _platformHealth >= 80 ? AppColors.success : AppColors.warning,
            isDark,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildHeroLine(
            'Backup coverage',
            _backupCoverageLabel,
            _backups.isEmpty ? AppColors.warning : AppColors.primary,
            isDark,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildHeroLine(
            'Open approvals',
            '$_openApprovals',
            _openApprovals > 0 ? AppColors.warning : AppColors.success,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildHeroLine(String label, String value, Color color, bool isDark) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white60 : AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricGrid(bool isDark, bool isMobile, bool isTablet) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _metrics.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 1 : (isTablet ? 2 : 3),
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: isMobile ? 2.7 : 2.45,
      ),
      itemBuilder: (context, index) =>
          _buildMetricCard(_metrics[index], isDark),
    );
  }

  Widget _buildMetricCard(_DashboardMetric metric, bool isDark) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, metric.route),
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: _panelDecoration(isDark),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: metric.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(metric.icon, color: metric.color, size: 24),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    metric.value,
                    style: AppTypography.h5.copyWith(
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    metric.label,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark ? Colors.white70 : AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    metric.detail,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark ? Colors.white54 : AppColors.textSecondary,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: metric.color),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationsGrid(bool isDark, bool isMobile, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Platform Operations',
          'Jump into the core Super Admin control surfaces.',
          isDark,
        ),
        const SizedBox(height: AppSpacing.md),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _actions.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isMobile ? 1 : (isTablet ? 2 : 3),
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: isMobile ? 2.85 : 2.35,
          ),
          itemBuilder: (context, index) =>
              _buildActionCard(_actions[index], isDark),
        ),
      ],
    );
  }

  Widget _buildActionCard(_DashboardAction action, bool isDark) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, action.route),
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: action.color.withValues(alpha: isDark ? 0.14 : 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: action.color.withValues(alpha: 0.24)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: action.color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(action.icon, color: action.color, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    action.title,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
            Icon(Icons.arrow_forward_rounded, color: action.color, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildGovernanceRow(bool isDark, bool isMobile) {
    final panels = [
      _GovernancePanel(
        title: 'Approval Queue',
        subtitle: 'Users and farms waiting for review',
        value: '$_openApprovals',
        color: _openApprovals > 0 ? AppColors.warning : AppColors.success,
        icon: Icons.pending_actions_rounded,
        route: '/superadmin/users',
      ),
      _GovernancePanel(
        title: 'Audit Risk',
        subtitle: 'High-severity global and farm events',
        value: '$_highRiskAudits',
        color: _highRiskAudits > 0 ? AppColors.error : AppColors.success,
        icon: Icons.gpp_maybe_rounded,
        route: '/superadmin/audit',
      ),
      _GovernancePanel(
        title: 'Restore Readiness',
        subtitle: 'Global and farm backups verified',
        value: _backups.isEmpty ? '0' : '${_backups.length}',
        color: _backups.isEmpty ? AppColors.warning : AppColors.success,
        icon: Icons.verified_user_rounded,
        route: '/superadmin/backup',
      ),
    ];

    return isMobile
        ? Column(
            children: panels
                .map(
                  (panel) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _buildGovernanceCard(panel, isDark),
                  ),
                )
                .toList(),
          )
        : Row(
            children: panels
                .map(
                  (panel) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: panel == panels.last ? 0 : AppSpacing.md,
                      ),
                      child: _buildGovernanceCard(panel, isDark),
                    ),
                  ),
                )
                .toList(),
          );
  }

  Widget _buildGovernanceCard(_GovernancePanel panel, bool isDark) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, panel.route),
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: _panelDecoration(isDark),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: panel.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(panel.icon, color: panel.color, size: 24),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    panel.title,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    panel.subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark ? Colors.white60 : AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              panel.value,
              style: AppTypography.h6.copyWith(
                color: panel.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityPanel(bool isDark) {
    final activities = _activityItems;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _panelDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSectionHeader(
                  'Executive Activity',
                  'Recent platform events from operational modules.',
                  isDark,
                ),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, '/superadmin/audit'),
                child: const Text('View Audit'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (activities.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : AppColors.neutral50,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: isDark
                      ? Colors.white10
                      : Colors.black.withValues(alpha: 0.04),
                ),
              ),
              child: Text(
                'No audit activity has been recorded yet.',
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? Colors.white60 : AppColors.textSecondary,
                ),
              ),
            )
          else
            ...activities
                .map((activity) => _buildActivityRow(activity, isDark)),
        ],
      ),
    );
  }

  List<_ActivityItem> get _activityItems {
    final sortedAudits = [..._audits]..sort((a, b) {
        return _parseDate(b['timestamp'] ?? b[r'$createdAt']).compareTo(
          _parseDate(a['timestamp'] ?? a[r'$createdAt']),
        );
      });
    return sortedAudits.take(5).map((audit) {
      final collection = (audit['collection_name'] ?? 'Platform').toString();
      final actionType = _labelFromSnakeCase(
        (audit['action_type'] ?? 'System event').toString(),
      );
      final details = (audit['action_details'] ?? '').toString().trim();
      return _ActivityItem(
        title: actionType,
        subtitle: details.isEmpty ? collection : details,
        time: _timeAgo(audit['timestamp'] ?? audit[r'$createdAt']),
        icon: _iconForCollection(collection),
        color: _colorForAudit(audit),
      );
    }).toList();
  }

  Widget _buildActivityRow(_ActivityItem activity, bool isDark) {
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
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: activity.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(activity.icon, color: activity.color, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  activity.subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            activity.time,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white54 : AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
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

  String _labelFromSnakeCase(String value) {
    return value
        .replaceAll('_', ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  DateTime _parseDate(dynamic value) {
    return DateTime.tryParse(value?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _timeAgo(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed == null) return '-';
    final difference = DateTime.now().difference(parsed.toLocal());
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes} min ago';
    if (difference.inDays < 1) return '${difference.inHours} hr ago';
    return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
  }

  IconData _iconForCollection(String collection) {
    final value = collection.toLowerCase();
    if (value.contains('user')) return Icons.manage_accounts_rounded;
    if (value.contains('farm')) return Icons.agriculture_rounded;
    if (value.contains('price')) return Icons.price_change_rounded;
    if (value.contains('package')) return Icons.inventory_2_rounded;
    if (value.contains('inventory')) return Icons.inventory_rounded;
    if (value.contains('fulfillment') || value.contains('delivery')) {
      return Icons.local_shipping_rounded;
    }
    if (value.contains('backup')) return Icons.backup_rounded;
    if (value.contains('sensor')) return Icons.sensors_rounded;
    return Icons.manage_search_rounded;
  }

  Color _colorForAudit(Map<String, dynamic> audit) {
    final status = (audit['status'] ?? '').toString().toLowerCase();
    final collection =
        (audit['collection_name'] ?? '').toString().toLowerCase();
    if (status.contains('failed') || status.contains('error')) {
      return AppColors.error;
    }
    if (status.contains('pending')) return AppColors.warning;
    if (collection.contains('farm') || collection.contains('sensor')) {
      return AppColors.success;
    }
    if (collection.contains('price') || collection.contains('package')) {
      return AppColors.warning;
    }
    return AppColors.info;
  }

  BoxDecoration _panelDecoration(bool isDark) {
    return BoxDecoration(
      color: isDark ? AppColors.surfaceDark : Colors.white,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      border: Border.all(
        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.07),
      ),
      boxShadow: isDark
          ? null
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
    );
  }
}

class _DashboardMetric {
  const _DashboardMetric({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    required this.color,
    required this.route,
  });

  final String label;
  final String value;
  final String detail;
  final IconData icon;
  final Color color;
  final String route;
}

class _DashboardAction {
  const _DashboardAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;
}

class _GovernancePanel {
  const _GovernancePanel({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.color,
    required this.icon,
    required this.route,
  });

  final String title;
  final String subtitle;
  final String value;
  final Color color;
  final IconData icon;
  final String route;
}

class _ActivityItem {
  const _ActivityItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  final Color color;
}
