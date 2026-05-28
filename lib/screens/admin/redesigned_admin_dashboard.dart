import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/modern_admin_header.dart';
import '../../core/widgets/modern_admin_sidebar.dart';

class RedesignedAdminDashboard extends ConsumerStatefulWidget {
  const RedesignedAdminDashboard({super.key});

  @override
  ConsumerState<RedesignedAdminDashboard> createState() =>
      _RedesignedAdminDashboardState();
}

class _RedesignedAdminDashboardState
    extends ConsumerState<RedesignedAdminDashboard> {
  String _selectedPeriod = 'Today';
  String _selectedFarm = 'All Farms';

  final List<String> _farms = const [
    'All Farms',
    'Northern Estate',
    'Southern Estate',
    'Eastern Farm',
    'Western Farm',
  ];

  final List<_DashboardMetric> _metrics = const [
    _DashboardMetric(
      title: 'Managed Farms',
      value: '12',
      helper: '10 active, 2 onboarding',
      trend: '+2 this quarter',
      icon: Icons.agriculture_rounded,
      color: AppColors.primary,
      progress: .82,
    ),
    _DashboardMetric(
      title: 'Team Members',
      value: '148',
      helper: '92 field users online',
      trend: '+14.8%',
      icon: Icons.groups_2_rounded,
      color: AppColors.chartBlue,
      progress: .74,
    ),
    _DashboardMetric(
      title: 'Sensor Health',
      value: '96%',
      helper: '482 of 503 reporting',
      trend: '7 need service',
      icon: Icons.sensors_rounded,
      color: AppColors.chartTeal,
      progress: .96,
    ),
    _DashboardMetric(
      title: 'Open Alerts',
      value: '18',
      helper: '4 critical escalations',
      trend: '-9 today',
      icon: Icons.warning_amber_rounded,
      color: AppColors.warning,
      progress: .38,
    ),
    _DashboardMetric(
      title: 'Inventory Coverage',
      value: '31d',
      helper: 'Packaging and inputs',
      trend: '5 low-stock items',
      icon: Icons.inventory_2_rounded,
      color: AppColors.chartPurple,
      progress: .68,
    ),
    _DashboardMetric(
      title: 'Deliveries Today',
      value: '42',
      helper: '34 dispatched, 8 pending',
      trend: '91% on-time',
      icon: Icons.local_shipping_rounded,
      color: AppColors.chartOrange,
      progress: .91,
    ),
  ];

  final List<_OperationShortcut> _shortcuts = const [
    _OperationShortcut(
      title: 'User Administration',
      description: 'Manage roles, access, and farm team assignments.',
      route: '/users',
      icon: Icons.people_alt_rounded,
      color: AppColors.chartBlue,
    ),
    _OperationShortcut(
      title: 'Farm Operations',
      description: 'Review farm status, managers, locations, and capacity.',
      route: '/farms',
      icon: Icons.agriculture_rounded,
      color: AppColors.primary,
    ),
    _OperationShortcut(
      title: 'Sensor Command',
      description: 'Monitor telemetry health and device availability.',
      route: '/sensors',
      icon: Icons.sensors_rounded,
      color: AppColors.chartTeal,
    ),
    _OperationShortcut(
      title: 'Analytics Center',
      description: 'Track production, climate trends, and operational KPIs.',
      route: '/analytics',
      icon: Icons.analytics_rounded,
      color: AppColors.chartPurple,
    ),
    _OperationShortcut(
      title: 'Inventory Control',
      description: 'Audit global stock, farm allocations, and shortages.',
      route: '/inventory-admin',
      icon: Icons.inventory_2_rounded,
      color: AppColors.warning,
    ),
    _OperationShortcut(
      title: 'Delivery Control',
      description: 'Coordinate dispatches, ETAs, and farm fulfillment status.',
      route: '/deliveries-admin',
      icon: Icons.local_shipping_rounded,
      color: AppColors.chartOrange,
    ),
  ];

  final List<_FarmPerformance> _farmPerformance = const [
    _FarmPerformance(
      name: 'Northern Estate',
      manager: 'Kojo Mensah',
      health: 96,
      yieldScore: 91,
      alerts: 2,
      status: 'Excellent',
      color: AppColors.success,
    ),
    _FarmPerformance(
      name: 'Southern Estate',
      manager: 'Ama Boateng',
      health: 88,
      yieldScore: 84,
      alerts: 5,
      status: 'Stable',
      color: AppColors.primary,
    ),
    _FarmPerformance(
      name: 'Eastern Farm',
      manager: 'Esi Asante',
      health: 79,
      yieldScore: 76,
      alerts: 8,
      status: 'Watch',
      color: AppColors.warning,
    ),
  ];

  final List<_AdminAlert> _alerts = const [
    _AdminAlert(
      title: 'Hydroponic Zone B moisture variance',
      farm: 'Eastern Farm',
      severity: 'High',
      time: '12 min ago',
      icon: Icons.water_drop_rounded,
      color: AppColors.error,
    ),
    _AdminAlert(
      title: 'Packaging stock below reorder point',
      farm: 'Global Inventory',
      severity: 'Medium',
      time: '32 min ago',
      icon: Icons.inventory_rounded,
      color: AppColors.warning,
    ),
    _AdminAlert(
      title: 'Delivery route adjusted for Northern Estate',
      farm: 'Delivery Control',
      severity: 'Info',
      time: '1 hr ago',
      icon: Icons.route_rounded,
      color: AppColors.info,
    ),
  ];

  final List<_ActivityItem> _activities = const [
    _ActivityItem(
      title: 'New caretaker assigned to Southern Estate',
      detail: 'Role and farm permissions approved',
      time: '09:42 AM',
      icon: Icons.badge_rounded,
    ),
    _ActivityItem(
      title: 'Sensor calibration completed',
      detail: '18 devices synced across Northern Estate',
      time: '08:15 AM',
      icon: Icons.tune_rounded,
    ),
    _ActivityItem(
      title: 'Inventory transfer approved',
      detail: 'Nutrients moved from hub to Eastern Farm',
      time: 'Yesterday',
      icon: Icons.swap_horiz_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: isMobile ? _buildMobileLayout(isDark) : _buildDesktopLayout(isDark),
      bottomNavigationBar: isMobile ? _buildBottomNavigation(isDark) : null,
    );
  }

  Widget _buildDesktopLayout(bool isDark) {
    return Row(
      children: [
        const ModernAdminSidebar(
          selectedIndex: 0,
          onItemSelected: _noopNav,
          userName: 'Admin',
          userEmail: 'admin@farmestates.com',
          userRole: 'Administrator',
        ),
        Expanded(
          child: Column(
            children: [
              ModernAdminHeader(
                userName: 'Admin',
                farms: _farms,
                selectedFarm: _selectedFarm,
                onFarmChanged: (farm) {
                  if (farm != null) setState(() => _selectedFarm = farm);
                },
                onNotificationTap: _showNotifications,
                onProfileTap: _showProfileMenu,
              ),
              Expanded(child: _buildContent(isDark, AppSpacing.xl)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(bool isDark) {
    return Column(
      children: [
        ModernAdminHeader(
          userName: 'Admin',
          farms: _farms,
          selectedFarm: _selectedFarm,
          onFarmChanged: (farm) {
            if (farm != null) setState(() => _selectedFarm = farm);
          },
          onNotificationTap: _showNotifications,
          onProfileTap: _showProfileMenu,
        ),
        Expanded(child: _buildContent(isDark, AppSpacing.md)),
      ],
    );
  }

  Widget _buildContent(bool isDark, double padding) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHero(isDark),
          const SizedBox(height: AppSpacing.lg),
          _buildPeriodFilter(isDark),
          const SizedBox(height: AppSpacing.lg),
          _buildMetricsGrid(),
          const SizedBox(height: AppSpacing.xl),
          _buildOperationsGrid(isDark),
          const SizedBox(height: AppSpacing.xl),
          _buildInsightSection(isDark),
          const SizedBox(height: AppSpacing.xl),
          _buildFarmPerformanceSection(isDark),
          const SizedBox(height: AppSpacing.xl),
          _buildActivityFeed(isDark),
        ],
      ),
    );
  }

  Widget _buildHero(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.primaryDark.withValues(alpha: .85),
                  const Color(0xFF123F2A),
                  AppColors.surfaceDark,
                ]
              : [
                  const Color(0xFFE9F8EA),
                  const Color(0xFFF8FFF3),
                  Colors.white,
                ],
        ),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: .08)
              : AppColors.primary.withValues(alpha: .16),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? .08 : .12),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          return Flex(
            direction: compact ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: compact ? 0 : 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildScopePill(isDark),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Admin Operations Dashboard',
                      style: AppTypography.h3.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Central view for farm operations, people, sensors, inventory, and delivery execution across $_selectedFarm.',
                      style: AppTypography.bodyLarge.copyWith(
                        color: isDark
                            ? Colors.white.withValues(alpha: .74)
                            : AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              if (!compact) const SizedBox(width: AppSpacing.xl),
              SizedBox(height: compact ? AppSpacing.lg : 0),
              Expanded(
                flex: compact ? 0 : 2,
                child: _buildHeroPanel(isDark),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildScopePill(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: .08)
            : AppColors.primary.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: .10)
              : AppColors.primary.withValues(alpha: .16),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_user_rounded,
            size: 17,
            color: isDark ? Colors.white : AppColors.primaryDark,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Administrator Control Layer',
            style: AppTypography.label.copyWith(
              color: isDark ? Colors.white : AppColors.primaryDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroPanel(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.white)
            .withValues(alpha: isDark ? .08 : .82),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: .10)
              : AppColors.neutral300.withValues(alpha: .72),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroPanelRow(
            isDark,
            Icons.task_alt_rounded,
            'Operational readiness',
            '94%',
            AppColors.success,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildHeroPanelRow(
            isDark,
            Icons.priority_high_rounded,
            'Critical items',
            '4',
            AppColors.error,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildHeroPanelRow(
            isDark,
            Icons.schedule_rounded,
            'SLA performance',
            '91%',
            AppColors.info,
          ),
        ],
      ),
    );
  }

  Widget _buildHeroPanelRow(
    bool isDark,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .16),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark
                  ? Colors.white.withValues(alpha: .74)
                  : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: AppTypography.titleMedium.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodFilter(bool isDark) {
    const periods = ['Today', 'Week', 'Month', 'Quarter'];

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: periods.map((period) {
        final selected = _selectedPeriod == period;
        return ChoiceChip(
          label: Text(period),
          selected: selected,
          onSelected: (_) => setState(() => _selectedPeriod = period),
          selectedColor: AppColors.primary.withValues(alpha: .14),
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          side: BorderSide(
            color: selected
                ? AppColors.primary.withValues(alpha: .55)
                : (isDark
                    ? Colors.white.withValues(alpha: .10)
                    : AppColors.neutral300),
          ),
          checkmarkColor: AppColors.primary,
          labelStyle: AppTypography.label.copyWith(
            color: selected
                ? AppColors.primary
                : (isDark ? Colors.white : AppColors.textSecondary),
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMetricsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1200
            ? 3
            : width >= 760
                ? 2
                : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _metrics.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: width < 430 ? 1.35 : 1.72,
          ),
          itemBuilder: (context, index) => _MetricCard(metric: _metrics[index]),
        );
      },
    );
  }

  Widget _buildOperationsGrid(bool isDark) {
    return _DashboardSection(
      title: 'Operations Console',
      subtitle: 'Fast access to the admin areas used to run daily operations.',
      trailing: _buildTextButton('System Settings', '/settings'),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final columns = width >= 1100
              ? 3
              : width >= 720
                  ? 2
                  : 1;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _shortcuts.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: width < 430 ? 1.38 : 1.9,
            ),
            itemBuilder: (context, index) {
              return _OperationCard(
                shortcut: _shortcuts[index],
                onTap: () => Navigator.pushReplacementNamed(
                  context,
                  _shortcuts[index].route,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInsightSection(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 900;
        final children = [
          Expanded(
            flex: stacked ? 0 : 3,
            child: _buildAlertPanel(isDark),
          ),
          SizedBox(
              width: stacked ? 0 : AppSpacing.md,
              height: stacked ? AppSpacing.md : 0),
          Expanded(
            flex: stacked ? 0 : 2,
            child: _buildPriorityPanel(isDark),
          ),
        ];

        return stacked
            ? Column(children: children)
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children);
      },
    );
  }

  Widget _buildAlertPanel(bool isDark) {
    return _Panel(
      title: 'Operational Alerts',
      subtitle: 'Items that need admin review',
      child: Column(
        children: _alerts
            .map(
              (alert) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _AlertRow(alert: alert),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildPriorityPanel(bool isDark) {
    final priorities = [
      (
        'Approve 3 inventory transfers',
        Icons.approval_rounded,
        AppColors.primary
      ),
      (
        'Review 4 critical sensor alerts',
        Icons.sensors_rounded,
        AppColors.error
      ),
      (
        'Confirm today delivery exceptions',
        Icons.local_shipping_rounded,
        AppColors.warning
      ),
    ];

    return _Panel(
      title: 'Today\'s Priorities',
      subtitle: 'Admin tasks ordered by impact',
      child: Column(
        children: priorities.map((priority) {
          return Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: _cardDecoration(context),
            child: Row(
              children: [
                Icon(priority.$2, color: priority.$3, size: 22),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    priority.$1,
                    style: AppTypography.bodyMedium.copyWith(
                      color: _textColor(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFarmPerformanceSection(bool isDark) {
    return _DashboardSection(
      title: 'Farm Performance Snapshot',
      subtitle: 'Live operating score by farm and manager.',
      trailing: _buildTextButton('View Farms', '/farms'),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 920 ? 3 : 1;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _farmPerformance.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: constraints.maxWidth < 430 ? 1.35 : 1.55,
            ),
            itemBuilder: (context, index) {
              return _FarmPerformanceCard(farm: _farmPerformance[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildActivityFeed(bool isDark) {
    return _Panel(
      title: 'Recent Admin Activity',
      subtitle: 'Latest changes across users, farms, inventory, and sensors',
      child: Column(
        children: _activities
            .map(
              (activity) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _ActivityRow(activity: activity),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildTextButton(String label, String route) {
    return TextButton.icon(
      onPressed: () => Navigator.pushReplacementNamed(context, route),
      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
      label: Text(label),
    );
  }

  Widget _buildBottomNavigation(bool isDark) {
    const items = [
      (Icons.dashboard_rounded, 'Dashboard', '/dashboard'),
      (Icons.people_alt_rounded, 'Users', '/users'),
      (Icons.agriculture_rounded, 'Farms', '/farms'),
      (Icons.sensors_rounded, 'Sensors', '/sensors'),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: .08)
                : AppColors.neutral300,
          ),
        ),
      ),
      child: Row(
        children: items.map((item) {
          final selected = item.$2 == 'Dashboard';
          return Expanded(
            child: InkWell(
              onTap: () {
                if (!selected) Navigator.pushReplacementNamed(context, item.$3);
              },
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary.withValues(alpha: .14)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.$1,
                      size: 21,
                      color: selected
                          ? AppColors.primary
                          : (isDark
                              ? Colors.white.withValues(alpha: .68)
                              : AppColors.textSecondary),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.$2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: selected
                            ? AppColors.primary
                            : (isDark
                                ? Colors.white.withValues(alpha: .68)
                                : AppColors.textSecondary),
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showNotifications() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notifications panel coming soon')),
    );
  }

  void _showProfileMenu() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Admin profile panel coming soon')),
    );
  }
}

void _noopNav(int _) {}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final _DashboardMetric metric;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: metric.color.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: Icon(metric.icon, color: metric.color, size: 24),
              ),
              const Spacer(),
              Text(
                metric.trend,
                style: AppTypography.caption.copyWith(
                  color: metric.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            metric.value,
            style: AppTypography.h3.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            metric.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyLarge.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            metric.helper,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              color: _mutedTextColor(context),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            child: LinearProgressIndicator(
              value: metric.progress,
              minHeight: 6,
              backgroundColor: metric.color.withValues(alpha: .12),
              valueColor: AlwaysStoppedAnimation(metric.color),
            ),
          ),
        ],
      ),
    );
  }
}

class _OperationCard extends StatelessWidget {
  const _OperationCard({required this.shortcut, required this.onTap});

  final _OperationShortcut shortcut;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: _cardDecoration(context),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: shortcut.color.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(shortcut.icon, color: shortcut.color, size: 27),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shortcut.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleSmall.copyWith(
                        color: _textColor(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      shortcut.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: _mutedTextColor(context),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: _mutedTextColor(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FarmPerformanceCard extends StatelessWidget {
  const _FarmPerformanceCard({required this.farm});

  final _FarmPerformance farm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      farm.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleSmall.copyWith(
                        color: _textColor(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      farm.manager,
                      style: AppTypography.bodySmall.copyWith(
                        color: _mutedTextColor(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(label: farm.status, color: farm.color),
            ],
          ),
          const Spacer(),
          _ScoreRow(
              label: 'Farm health', value: farm.health, color: farm.color),
          const SizedBox(height: AppSpacing.md),
          _ScoreRow(
            label: 'Yield score',
            value: farm.yieldScore,
            color: AppColors.chartBlue,
          ),
          const Spacer(),
          Row(
            children: [
              Icon(
                Icons.notifications_active_rounded,
                size: 18,
                color: farm.alerts > 5 ? AppColors.warning : AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${farm.alerts} active alerts',
                style: AppTypography.bodySmall.copyWith(
                  color: _mutedTextColor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({required this.alert});

  final _AdminAlert alert;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _cardDecoration(context),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: alert.color.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Icon(alert.icon, color: alert.color, size: 23),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                    color: _textColor(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${alert.farm} • ${alert.time}',
                  style: AppTypography.bodySmall.copyWith(
                    color: _mutedTextColor(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _StatusBadge(label: alert.severity, color: alert.color),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity});

  final _ActivityItem activity;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: .12),
            shape: BoxShape.circle,
          ),
          child: Icon(activity.icon, color: AppColors.primary, size: 21),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Container(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: .08)
                      : AppColors.neutral300,
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.title,
                        style: AppTypography.bodyMedium.copyWith(
                          color: _textColor(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        activity.detail,
                        style: AppTypography.bodySmall.copyWith(
                          color: _mutedTextColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  activity.time,
                  style: AppTypography.caption.copyWith(
                    color: _mutedTextColor(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color: _mutedTextColor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '$value%',
              style: AppTypography.bodySmall.copyWith(
                color: _textColor(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          child: LinearProgressIndicator(
            value: value / 100,
            minHeight: 7,
            backgroundColor: color.withValues(alpha: .12),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withValues(alpha: .24)),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DashboardSection extends StatelessWidget {
  const _DashboardSection({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: title, subtitle: subtitle, trailing: trailing),
        const SizedBox(height: AppSpacing.md),
        child,
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: title, subtitle: subtitle),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.titleMedium.copyWith(
                  color: _textColor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.bodySmall.copyWith(
                  color: _mutedTextColor(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

BoxDecoration _cardDecoration(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return BoxDecoration(
    color: isDark ? AppColors.surfaceDark : Colors.white,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(
      color: isDark
          ? Colors.white.withValues(alpha: .08)
          : AppColors.neutral300.withValues(alpha: .72),
    ),
    boxShadow: [
      if (!isDark)
        BoxShadow(
          color: Colors.black.withValues(alpha: .045),
          blurRadius: 20,
          offset: const Offset(0, 12),
        ),
    ],
  );
}

Color _textColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? Colors.white
      : AppColors.textPrimary;
}

Color _mutedTextColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? Colors.white.withValues(alpha: .68)
      : AppColors.textSecondary;
}

class _DashboardMetric {
  const _DashboardMetric({
    required this.title,
    required this.value,
    required this.helper,
    required this.trend,
    required this.icon,
    required this.color,
    required this.progress,
  });

  final String title;
  final String value;
  final String helper;
  final String trend;
  final IconData icon;
  final Color color;
  final double progress;
}

class _OperationShortcut {
  const _OperationShortcut({
    required this.title,
    required this.description,
    required this.route,
    required this.icon,
    required this.color,
  });

  final String title;
  final String description;
  final String route;
  final IconData icon;
  final Color color;
}

class _FarmPerformance {
  const _FarmPerformance({
    required this.name,
    required this.manager,
    required this.health,
    required this.yieldScore,
    required this.alerts,
    required this.status,
    required this.color,
  });

  final String name;
  final String manager;
  final int health;
  final int yieldScore;
  final int alerts;
  final String status;
  final Color color;
}

class _AdminAlert {
  const _AdminAlert({
    required this.title,
    required this.farm,
    required this.severity,
    required this.time,
    required this.icon,
    required this.color,
  });

  final String title;
  final String farm;
  final String severity;
  final String time;
  final IconData icon;
  final Color color;
}

class _ActivityItem {
  const _ActivityItem({
    required this.title,
    required this.detail,
    required this.time,
    required this.icon,
  });

  final String title;
  final String detail;
  final String time;
  final IconData icon;
}
