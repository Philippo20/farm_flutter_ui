import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/modern_dashboard_scaffold.dart';
import '../../core/widgets/technician_mobile_bottom_nav.dart';
import '../../core/widgets/technician_sidebar.dart';
import '../../core/widgets/role_mobile_navigation.dart';
import '../../core/widgets/technician_header.dart';
import '../../core/widgets/weather_time_widget.dart';
import '../../core/widgets/weather_info_chip.dart';
import '../../providers/auth_provider.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../services/superadmin_api_service.dart';

/// Technician Dashboard - Redesigned
/// Maintenance and technical support
class TechnicianDashboardRedesigned extends ConsumerStatefulWidget {
  const TechnicianDashboardRedesigned({super.key});

  @override
  ConsumerState<TechnicianDashboardRedesigned> createState() =>
      _TechnicianDashboardRedesignedState();
}

class _TechnicianDashboardRedesignedState
    extends ConsumerState<TechnicianDashboardRedesigned> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedNavIndex = 0;
  WeatherInfo? _weatherInfo;
  final SuperAdminApiService _api = SuperAdminApiService();
  Timer? _refreshTimer;
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _alerts = [];
  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> _sensors = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadDashboardData(silent: true),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDashboardData({bool silent = false}) async {
    if (!silent && mounted) setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _api.getAlerts(),
        _api.getFarmTasks(),
        _api.getSensors(),
      ]);
      if (!mounted) return;
      final user = ref.read(currentUserProvider);
      final farmIds = user?.farmId == null ? <String>{} : {user!.farmId!};
      final userId = user?.id ?? '';
      bool belongsToTechnician(Map<String, dynamic> item) {
        final assignedTo = _value(item, ['assigned_to_id', 'technician_id']);
        final farmId = _value(item, ['farm_id', 'farmId']);
        if (assignedTo.isNotEmpty) return assignedTo == userId;
        if (farmIds.isNotEmpty && farmId.isNotEmpty) {
          return farmIds.contains(farmId);
        }
        return true;
      }

      setState(() {
        _alerts = results[0].where(belongsToTechnician).toList();
        _tasks = results[1].where(belongsToTechnician).toList();
        _sensors = results[2].where(belongsToTechnician).toList();
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
      });
    }
  }

  String _value(Map<String, dynamic> data, List<String> keys,
      [String fallback = '']) {
    for (final key in keys) {
      final value = data[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return fallback;
  }

  bool _isResolved(Map<String, dynamic> alert) {
    return alert['resolved'] == true ||
        _value(alert, ['status']).toLowerCase() == 'resolved';
  }

  bool _isOnline(Map<String, dynamic> sensor) {
    final status = _value(sensor, ['status']).toLowerCase();
    return status == 'online' || status == 'active' || status == 'operational';
  }

  bool _isToday(String value) {
    final date = DateTime.tryParse(value);
    final now = DateTime.now();
    return date != null &&
        date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'Technician';
    final userEmail = authState.user?.email ?? 'technician@farmestates.com';
    final userRole = 'Technician';

    return Scaffold(
      key: _scaffoldKey,
      drawer: isMobile
          ? RoleMobileDrawer(
              userName: userName,
              userEmail: userEmail,
              userRole: userRole,
              selectedIndex: _selectedNavIndex,
              onItemSelected: (_) {},
              items: technicianNavigationItems,
            )
          : null,
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: isMobile
          ? _buildMobileLayout(isDark, userName)
          : _buildDesktopLayout(isDark, userName, userEmail, userRole),
      floatingActionButton: !isMobile
          ? FloatingActionButton.extended(
              onPressed: () {},
              backgroundColor: AppColors.error,
              icon: const Icon(Icons.add),
              label: const Text('Report Issue'),
            )
          : null,
      bottomNavigationBar: isMobile
          ? TechnicianMobileBottomNav(
              selectedIndex: _selectedNavIndex,
              onItemSelected: (index) =>
                  setState(() => _selectedNavIndex = index),
            )
          : null,
    );
  }

  Widget _buildDesktopLayout(
      bool isDark, String userName, String userEmail, String userRole) {
    return Row(
      children: [
        // Sidebar
        TechnicianSidebar(
          selectedIndex: _selectedNavIndex,
          onItemSelected: (index) {
            setState(() {
              _selectedNavIndex = index;
            });
          },
          userName: userName,
          userEmail: userEmail,
          userRole: userRole,
        ),

        // Main Content
        Expanded(
          child: Column(
            children: [
              // Header
              TechnicianHeader(
                userName: userName,
                weatherInfo: _weatherInfo,
                onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                onNotificationTap: () {
                  // Handle notifications
                },
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: _isLoading
                      ? const Center(child: AdminDataSkeleton(rowCount: 5))
                      : _errorMessage != null
                          ? _buildErrorState(isDark)
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Weather & Time Widget
                                const WeatherTimeWidget(),

                                const SizedBox(height: AppSpacing.lg),

                                // Compact Stats Section
                                _buildStatsSection(context),

                                const SizedBox(height: AppSpacing.xl),

                                // Alert Summary
                                _buildAlertSummary(isDark),

                                const SizedBox(height: AppSpacing.xl),

                                // Section Title
                                Text(
                                  'Farm Asset Monitoring',
                                  style: AppTypography.h5.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                  ),
                                ),

                                const SizedBox(height: AppSpacing.md),

                                // Asset Monitoring Grid
                                _buildAssetMonitoringGrid(context),

                                const SizedBox(height: AppSpacing.xl),

                                // Section Title
                                Text(
                                  'Maintenance Tasks',
                                  style: AppTypography.h5.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                  ),
                                ),

                                const SizedBox(height: AppSpacing.md),

                                // Features Grid
                                _buildFeaturesGrid(context),
                              ],
                            ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(bool isDark, String userName) {
    return Column(
      children: [
        TechnicianHeader(
          userName: userName,
          weatherInfo: _weatherInfo,
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
          onNotificationTap: () {
            // Handle notifications
          },
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: _isLoading
                ? const Center(child: AdminDataSkeleton(rowCount: 5))
                : _errorMessage != null
                    ? _buildErrorState(isDark)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Weather & Time Widget
                          const WeatherTimeWidget(),

                          const SizedBox(height: AppSpacing.md),

                          // Compact Stats Section
                          Transform.translate(
                            offset: const Offset(0, -90),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildStatsSection(context),

                                const SizedBox(height: 12),

                                // Alert Summary
                                _buildAlertSummary(isDark),

                                const SizedBox(height: 12),

                                Text(
                                  'Farm Asset Monitoring',
                                  style: AppTypography.h5.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                Transform.translate(
                                  offset: const Offset(0, -60),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Asset Monitoring Grid
                                      _buildAssetMonitoringGrid(context),

                                      const SizedBox(height: 12),

                                      // Section Title
                                      Text(
                                        'Maintenance Tasks',
                                        style: AppTypography.h5.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: isDark
                                              ? Colors.white
                                              : AppColors.textPrimary,
                                        ),
                                      ),

                                      const SizedBox(height: 8),

                                      // Features Grid
                                      Transform.translate(
                                        offset: const Offset(0, 60),
                                        child: _buildFeaturesGrid(context),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation(bool isDark) {
    final navItems = [
      {
        'icon': Icons.dashboard_outlined,
        'label': 'Dashboard',
        'index': 0,
        'route': '/technician_dashboard'
      },
      {
        'icon': Icons.sensors_outlined,
        'label': 'Sensors',
        'index': 1,
        'route': '/sensor-management'
      },
      {
        'icon': Icons.build_outlined,
        'label': 'Maintenance',
        'index': 2,
        'route': '/maintenance-schedule'
      },
      {
        'icon': Icons.history_outlined,
        'label': 'History',
        'index': 3,
        'route': '/repair-history'
      },
      {
        'icon': Icons.settings_outlined,
        'label': 'Settings',
        'index': 4,
        'route': '/technician-settings'
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.08),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: navItems.map((item) {
              final index = item['index'] as int;
              final route = item['route'] as String;
              final isSelected = index == _selectedNavIndex;

              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (_selectedNavIndex != index) {
                        setState(() => _selectedNavIndex = index);
                        try {
                          Navigator.pushReplacementNamed(context, route);
                        } catch (e) {
                          try {
                            Navigator.pushNamed(context, route);
                          } catch (e2) {
                            debugPrint('Navigation error: $e2');
                          }
                        }
                      }
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item['icon'] as IconData,
                          size: 24,
                          color: isSelected
                              ? AppColors.primary
                              : (isDark
                                  ? Colors.white.withOpacity(0.5)
                                  : AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['label'] as String,
                          style: AppTypography.caption.copyWith(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark
                                    ? Colors.white.withOpacity(0.5)
                                    : AppColors.textSecondary),
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined,
                size: 42,
                color: isDark ? Colors.white54 : AppColors.textSecondary),
            const SizedBox(height: 8),
            Text('Unable to load technician dashboard',
                style: AppTypography.h6.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary)),
            const SizedBox(height: AppSpacing.sm),
            Text(_errorMessage ?? 'Please try again.',
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: _loadDashboardData,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertSummary(bool isDark) {
    final active = _alerts.where((alert) => !_isResolved(alert)).toList();
    final critical = active
        .where((alert) {
          final severity =
              _value(alert, ['severity', 'priority']).toLowerCase();
          return severity == 'critical' || severity == 'high';
        })
        .take(3)
        .toList();
    final countBySeverity = (String severity) => active
        .where((alert) =>
            _value(alert, ['severity', 'priority']).toLowerCase() == severity)
        .length;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border:
            Border.all(color: isDark ? Colors.white10 : AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.notifications_active_outlined,
                color: AppColors.info),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
                child: Text('System Alerts',
                    style: AppTypography.h6.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ))),
            Text('${active.length} active',
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? Colors.white60 : AppColors.textSecondary,
                )),
          ]),
          const SizedBox(height: AppSpacing.md),
          Row(children: [
            _alertMetric('Critical', '${countBySeverity('critical')}',
                AppColors.error, isDark),
            _alertMetric('Warning', '${countBySeverity('warning')}',
                AppColors.warning, isDark),
            _alertMetric(
                'Info', '${countBySeverity('info')}', AppColors.info, isDark),
          ]),
          if (critical.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            ...critical.map((alert) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Text(
                    _value(alert, ['message', 'title'], 'Technical alert'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark ? Colors.white70 : AppColors.textSecondary,
                    ),
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _alertMetric(String label, String value, Color color, bool isDark) {
    return Expanded(
      child: Row(children: [
        Icon(Icons.circle, size: 8, color: color),
        const SizedBox(width: 6),
        Text('$label $value',
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            )),
      ]),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    final openIssues = _alerts.where((alert) => !_isResolved(alert)).length;
    final resolvedToday = _alerts.where((alert) {
      return _isResolved(alert) &&
          _isToday(_value(alert, ['updated_at', r'$updatedAt']));
    }).length;
    final dueToday = _tasks
        .where((task) =>
            _isToday(_value(task, ['due_date', 'scheduled_date'])) &&
            _value(task, ['status']).toLowerCase() != 'completed')
        .length;
    final onlineSensors = _sensors.where(_isOnline).length;
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 800 ? 4 : 2;
        final isMobile = constraints.maxWidth < 600;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          childAspectRatio: isMobile ? 2.55 : 3.2,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            CompactStatCard(
              title: 'Open Issues',
              value: '$openIssues',
              icon: Icons.warning_amber,
              color: AppColors.error,
            ),
            CompactStatCard(
              title: 'Resolved Today',
              value: '$resolvedToday',
              icon: Icons.check_circle,
              color: AppColors.success,
            ),
            CompactStatCard(
              title: 'Maintenance Due',
              value: '$dueToday',
              icon: Icons.build,
              color: AppColors.warning,
            ),
            CompactStatCard(
              title: 'System Status',
              value: _sensors.isEmpty
                  ? '0%'
                  : '${(onlineSensors * 100 / _sensors.length).round()}%',
              icon: Icons.speed,
              color: AppColors.primary,
            ),
          ],
        );
      },
    );
  }

  Widget _buildAssetMonitoringGrid(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 800 ? 4 : 2;
        // Adjust aspect ratio for mobile to prevent overflow
        final childAspectRatio = isMobile ? 1.4 : 1.2;
        final grouped = <String, List<Map<String, dynamic>>>{};
        for (final sensor in _sensors) {
          final type =
              _value(sensor, ['sensor_type', 'type', 'category'], 'Sensors');
          grouped.putIfAbsent(type, () => []).add(sensor);
        }
        final cards = grouped.entries.take(4).map((entry) {
          final online = entry.value.where(_isOnline).length;
          final color = online == entry.value.length && entry.value.isNotEmpty
              ? AppColors.success
              : online > 0
                  ? AppColors.warning
                  : AppColors.textSecondary;
          return _buildAssetCard(
            context,
            isDark,
            entry.key,
            Icons.sensors,
            color,
            '$online/${entry.value.length} Online',
            online == entry.value.length && entry.value.isNotEmpty
                ? 'All operational'
                : 'Needs attention',
            () => Navigator.pushNamed(context, '/sensor-management'),
            isMobile,
          );
        }).toList();
        if (cards.isEmpty) {
          cards.add(_buildAssetCard(
            context,
            isDark,
            'Sensors',
            Icons.sensors,
            AppColors.textSecondary,
            '0 connected',
            'No sensors assigned',
            () => Navigator.pushNamed(context, '/sensor-management'),
            isMobile,
          ));
        }

        return GridView.count(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: isMobile ? AppSpacing.sm : AppSpacing.md,
          mainAxisSpacing: isMobile ? AppSpacing.sm : AppSpacing.md,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: cards,
        );
      },
    );
  }

  Widget _buildAssetCard(
      BuildContext context,
      bool isDark,
      String title,
      IconData icon,
      Color color,
      String status,
      String subtitle,
      VoidCallback onTap,
      bool isMobile) {
    // Check if this card has an action (not empty callback)
    final hasAction = title == 'Sensors'; // Only Sensors card has navigation

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: EdgeInsets.all(isMobile ? AppSpacing.sm : AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: hasAction
                ? color.withOpacity(0.3)
                : (isDark ? Colors.white10 : Colors.black12),
            width: hasAction ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding:
                      EdgeInsets.all(isMobile ? AppSpacing.sm : AppSpacing.md),
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.12), shape: BoxShape.circle),
                  child: Icon(icon, size: isMobile ? 28 : 32, color: color),
                ),
                if (hasAction)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: isMobile ? 6 : AppSpacing.sm),
            Flexible(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontSize: isMobile ? 13 : 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: isMobile ? 3 : 4),
            Flexible(
              child: Text(
                status,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: color,
                  fontSize: isMobile ? 11 : 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: isMobile ? 2 : 2),
            Flexible(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(
                        color:
                            isDark ? Colors.white60 : AppColors.textSecondary,
                        fontSize: isMobile ? 9 : 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (hasAction) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      size: isMobile ? 12 : 14,
                      color: color,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesGrid(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 800 ? 4 : 2;
        // Adjust aspect ratio for mobile to prevent overflow
        final childAspectRatio = isMobile ? 1.4 : 1.2;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: isMobile ? AppSpacing.sm : AppSpacing.md,
          mainAxisSpacing: isMobile ? AppSpacing.sm : AppSpacing.md,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildFeatureCard(
              context,
              isDark,
              'Report Issue',
              Icons.report_problem,
              AppColors.error,
              '${_alerts.where((alert) => !_isResolved(alert)).length} open issues',
              () => Navigator.pushNamed(context, '/maintenance-schedule'),
              isMobile,
            ),
            _buildFeatureCard(
              context,
              isDark,
              'View Solutions',
              Icons.lightbulb_outline,
              AppColors.warning,
              'Knowledge base',
              () => Navigator.pushNamed(context, '/maintenance-schedule'),
              isMobile,
            ),
            _buildFeatureCard(
              context,
              isDark,
              'Schedule Maintenance',
              Icons.event,
              AppColors.info,
              '${_tasks.where((task) => _isToday(_value(task, [
                        'due_date',
                        'scheduled_date'
                      ]))).length} tasks due',
              () => Navigator.pushNamed(context, '/maintenance-schedule'),
              isMobile,
            ),
            _buildFeatureCard(
              context,
              isDark,
              'Request Items',
              Icons.shopping_cart,
              AppColors.primary,
              'Order supplies',
              () => Navigator.pushNamed(context, '/maintenance-schedule'),
              isMobile,
            ),
            _buildFeatureCard(
              context,
              isDark,
              'Asset Check',
              Icons.inventory,
              AppColors.success,
              'Verify equipment',
              () {},
              isMobile,
            ),
            _buildFeatureCard(
              context,
              isDark,
              'System Status',
              Icons.monitor_heart,
              AppColors.info,
              '${_sensors.isEmpty ? 0 : (_sensors.where(_isOnline).length * 100 / _sensors.length).round()}% operational',
              () {},
              isMobile,
            ),
            _buildFeatureCard(
              context,
              isDark,
              'Repair History',
              Icons.history,
              AppColors.warning,
              'View past fixes',
              () => Navigator.pushNamed(context, '/repair-history'),
              isMobile,
            ),
            _buildFeatureCard(
              context,
              isDark,
              'Settings',
              Icons.settings_outlined,
              AppColors.textSecondary,
              'Preferences',
              () => Navigator.pushNamed(context, '/technician-settings'),
              isMobile,
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    bool isDark,
    String title,
    IconData icon,
    Color color,
    String subtitle,
    VoidCallback onTap,
    bool isMobile,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: EdgeInsets.all(isMobile ? AppSpacing.sm : AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black12,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(isMobile ? AppSpacing.sm : AppSpacing.md),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: isMobile ? 28 : 32,
                color: color,
              ),
            ),
            SizedBox(height: isMobile ? 6 : AppSpacing.sm),
            Flexible(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontSize: isMobile ? 13 : 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: isMobile ? 3 : 4),
            Flexible(
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? Colors.white60 : AppColors.textSecondary,
                  fontSize: isMobile ? 10 : 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
