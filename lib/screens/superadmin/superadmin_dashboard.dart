import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/modern_admin_header.dart';
import '../../core/widgets/superadmin_sidebar.dart';
import '../../providers/auth_provider.dart';

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

  final List<_DashboardMetric> _metrics = const [
    _DashboardMetric(
      label: 'Users',
      value: '248',
      detail: '7 pending approvals',
      icon: Icons.people_alt_rounded,
      color: AppColors.primary,
      route: '/superadmin/users',
    ),
    _DashboardMetric(
      label: 'Farms',
      value: '24',
      detail: '2 pending onboarding',
      icon: Icons.agriculture_rounded,
      color: AppColors.success,
      route: '/superadmin/farms',
    ),
    _DashboardMetric(
      label: 'Plant Types',
      value: '45',
      detail: '8 categories managed',
      icon: Icons.local_florist_rounded,
      color: AppColors.info,
      route: '/superadmin/plants',
    ),
    _DashboardMetric(
      label: 'Hub Pricing',
      value: '42',
      detail: 'spoke farm price records',
      icon: Icons.price_change_rounded,
      color: AppColors.warning,
      route: '/superadmin/pricing',
    ),
    _DashboardMetric(
      label: 'Inventory',
      value: '\$1.24M',
      detail: 'global stock value',
      icon: Icons.inventory_2_rounded,
      color: AppColors.success,
      route: '/superadmin/inventory',
    ),
    _DashboardMetric(
      label: 'Deliveries',
      value: '38',
      detail: 'active farm deliveries',
      icon: Icons.local_shipping_rounded,
      color: AppColors.info,
      route: '/superadmin/deliveries',
    ),
    _DashboardMetric(
      label: 'Sensors',
      value: '503',
      detail: 'global IoT devices monitored',
      icon: Icons.sensors_rounded,
      color: AppColors.chartTeal,
      route: '/superadmin/sensors',
    ),
  ];

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
                onProfileTap: () {},
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
          onProfileTap: () {},
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHero(isDark, isMobile),
        const SizedBox(height: AppSpacing.lg),
        _buildMetricGrid(isDark, isMobile, isTablet),
        const SizedBox(height: AppSpacing.lg),
        _buildOperationsGrid(isDark, isMobile, isTablet),
        const SizedBox(height: AppSpacing.lg),
        _buildGovernanceRow(isDark, isMobile),
        const SizedBox(height: AppSpacing.lg),
        _buildActivityPanel(isDark),
      ],
    );
  }

  Widget _buildHero(bool isDark, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? AppSpacing.lg : AppSpacing.xl),
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
                _buildHeroCopy(isDark),
                const SizedBox(height: AppSpacing.lg),
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
                  fontWeight: FontWeight.w800,
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
            fontWeight: FontWeight.w800,
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
          _buildHeroLine('Platform health', '98%', AppColors.success, isDark),
          const SizedBox(height: AppSpacing.sm),
          _buildHeroLine('Backup coverage', '100%', AppColors.primary, isDark),
          const SizedBox(height: AppSpacing.sm),
          _buildHeroLine('Open approvals', '9', AppColors.warning, isDark),
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
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w800,
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
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    metric.label,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark ? Colors.white70 : AppColors.textSecondary,
                      fontWeight: FontWeight.w800,
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
                      fontWeight: FontWeight.w800,
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
        value: '9',
        color: AppColors.warning,
        icon: Icons.pending_actions_rounded,
        route: '/superadmin/users',
      ),
      _GovernancePanel(
        title: 'Audit Risk',
        subtitle: 'High-severity global and farm events',
        value: '23',
        color: AppColors.error,
        icon: Icons.gpp_maybe_rounded,
        route: '/superadmin/audit',
      ),
      _GovernancePanel(
        title: 'Restore Readiness',
        subtitle: 'Global and farm backups verified',
        value: '100%',
        color: AppColors.success,
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
                      fontWeight: FontWeight.w800,
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
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityPanel(bool isDark) {
    final activities = const [
      _ActivityItem(
        title: 'Hub pricing updated',
        subtitle: 'Green Valley Spoke Farm changed lettuce bulk price to hub',
        time: '12 min ago',
        icon: Icons.price_change_rounded,
        color: AppColors.warning,
      ),
      _ActivityItem(
        title: 'Farm backup verified',
        subtitle: 'North Ridge Farm backup passed restore validation',
        time: '45 min ago',
        icon: Icons.backup_rounded,
        color: AppColors.success,
      ),
      _ActivityItem(
        title: 'Packaging stock threshold reached',
        subtitle: 'Reusable crates dropped below preferred warehouse level',
        time: '2 hrs ago',
        icon: Icons.inventory_2_rounded,
        color: AppColors.info,
      ),
      _ActivityItem(
        title: 'Audit event escalated',
        subtitle: 'Sunset Acres compliance suspension recorded',
        time: '4 hrs ago',
        icon: Icons.manage_search_rounded,
        color: AppColors.error,
      ),
    ];

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
          ...activities.map((activity) => _buildActivityRow(activity, isDark)),
        ],
      ),
    );
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
                    fontWeight: FontWeight.w800,
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
              fontWeight: FontWeight.w600,
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
