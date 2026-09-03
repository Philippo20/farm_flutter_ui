import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/packaging_supervisor_header.dart';
import '../../core/widgets/packaging_supervisor_sidebar.dart';
import '../../core/widgets/role_mobile_navigation.dart';
import '../../core/widgets/weather_info_chip.dart';
import '../../providers/auth_provider.dart';
import '../../services/fulfillment_data_service.dart';

/// Packaging Supervisor Dashboard - Redesigned
/// Package recording, waste tracking, and line progress control.
class PackagingSupervisorDashboardRedesigned extends ConsumerStatefulWidget {
  const PackagingSupervisorDashboardRedesigned({super.key});

  @override
  ConsumerState<PackagingSupervisorDashboardRedesigned> createState() =>
      _PackagingSupervisorDashboardRedesignedState();
}

class _PackagingSupervisorDashboardRedesignedState
    extends ConsumerState<PackagingSupervisorDashboardRedesigned> {
  int _selectedNavIndex = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  WeatherInfo? _weatherInfo;
  bool _isLoadingData = true;
  bool _hasDataError = false;
  double _progressValue = 0;
  double _wasteRate = 0;
  double _completedWeight = 0;

  List<Map<String, dynamic>> _lines = [
    {
      'line': 'Line A',
      'batch': 'LTC-24019',
      'crop': 'Romaine Lettuce',
      'progress': '76%',
      'output': '638 packs',
      'eta': '24 min',
      'status': 'On pace',
      'color': AppColors.success,
    },
    {
      'line': 'Line B',
      'batch': 'TMT-24022',
      'crop': 'Cherry Tomato',
      'progress': '48%',
      'output': '149 packs',
      'eta': '42 min',
      'status': 'Watch',
      'color': AppColors.warning,
    },
    {
      'line': 'Line C',
      'batch': 'BSL-24007',
      'crop': 'Sweet Basil',
      'progress': '91%',
      'output': '1,392 sleeves',
      'eta': '11 min',
      'status': 'Closing',
      'color': AppColors.primary,
    },
  ];

  List<Map<String, dynamic>> _activity = [
    {
      'title': 'Line C final count submitted',
      'subtitle': 'Ama K. recorded 1,392 herb sleeves',
      'time': '8 min ago',
      'color': AppColors.success,
    },
    {
      'title': 'Line B below expected pace',
      'subtitle': 'Throughput dropped to 126 packs/hr',
      'time': '18 min ago',
      'color': AppColors.warning,
    },
    {
      'title': 'Waste event requires review',
      'subtitle': 'Label mismatch on BSL-24007',
      'time': '31 min ago',
      'color': AppColors.error,
    },
  ];

  @override
  void initState() {
    super.initState();
    _weatherInfo = const WeatherInfo(condition: 'Sunny', temperature: 28.5);
    _loadPackagingData();
  }

  Future<void> _loadPackagingData() async {
    try {
      final snapshot = await FulfillmentDataService().load();
      if (mounted) {
        setState(() {
          _applySnapshot(snapshot);
          _isLoadingData = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
          _hasDataError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'Packaging Supervisor';
    final userEmail = authState.user?.email ?? 'packaging@farmestates.com';

    return Scaffold(
      key: _scaffoldKey,
      drawer: isMobile
          ? RoleMobileDrawer(
              userName: userName,
              userEmail: userEmail,
              userRole: 'Packaging Supervisor',
              selectedIndex: _selectedNavIndex,
              onItemSelected: (index) {
                setState(() => _selectedNavIndex = index);
              },
              items: packagingNavigationItems,
            )
          : null,
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: isMobile
          ? _buildMobileLayout(isDark, userName)
          : _buildDesktopLayout(isDark, userName, userEmail),
      floatingActionButton: !isMobile
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.pushNamed(
                context,
                '/package-recording',
              ),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add),
              label: const Text('Record Package'),
            )
          : null,
      bottomNavigationBar: isMobile
          ? RoleMobileBottomNav(
              selectedIndex: _selectedNavIndex,
              onItemSelected: (index) {
                setState(() => _selectedNavIndex = index);
              },
              items: packagingNavigationItems,
              defaultDynamicItem: packagingNavigationItems[4],
            )
          : null,
    );
  }

  Widget _buildDesktopLayout(bool isDark, String userName, String userEmail) {
    return Row(
      children: [
        PackagingSupervisorSidebar(
          selectedIndex: _selectedNavIndex,
          onItemSelected: (index) {
            setState(() => _selectedNavIndex = index);
          },
          userName: userName,
          userEmail: userEmail,
          userRole: 'Packaging Supervisor',
        ),
        Expanded(
          child: Column(
            children: [
              PackagingSupervisorHeader(
                userName: userName,
                weatherInfo: _weatherInfo,
                onNotificationTap: () {},
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: _buildDashboardContent(isDark, false),
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
        PackagingSupervisorHeader(
          userName: userName,
          weatherInfo: _weatherInfo,
          onNotificationTap: () {},
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              92,
            ),
            child: _buildDashboardContent(isDark, true),
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardContent(bool isDark, bool isMobile) {
    if (_isLoadingData) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_hasDataError) {
      return Text(
        'Unable to load packaging data from the backend.',
        style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHero(isDark, isMobile),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            _DashboardKpi(
              title: 'Packaging progress',
              value: '${_progressValue.toStringAsFixed(0)}%',
              subtitle: 'Across active lines',
              icon: Icons.pie_chart_outline,
              color: AppColors.primary,
            ),
            _DashboardKpi(
              title: 'Completed today',
              value: '${_completedWeight.toStringAsFixed(1)} kg',
              subtitle: 'Packages recorded',
              icon: Icons.inventory_2_outlined,
              color: AppColors.success,
            ),
            _DashboardKpi(
              title: 'Waste rate',
              value: '${_wasteRate.toStringAsFixed(1)}%',
              subtitle: 'Below 3% target',
              icon: Icons.delete_sweep_outlined,
              color: AppColors.error,
            ),
            _DashboardKpi(
              title: 'Line efficiency',
              value: '${(100 - _wasteRate).clamp(0, 100).toStringAsFixed(0)}%',
              subtitle: 'Current shift',
              icon: Icons.speed_outlined,
              color: AppColors.warning,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        _buildMainDashboardGrid(isDark),
      ],
    );
  }

  void _applySnapshot(FulfillmentSnapshot snapshot) {
    double number(Map<String, dynamic> item, List<String> keys) {
      for (final key in keys) {
        final parsed = double.tryParse(item[key]?.toString() ?? '');
        if (parsed != null) return parsed;
      }
      return 0;
    }

    String text(Map<String, dynamic> item, List<String> keys,
        [String fallback = '']) {
      for (final key in keys) {
        final value = item[key]?.toString().trim() ?? '';
        if (value.isNotEmpty) return value;
      }
      return fallback;
    }

    final fulfillments = snapshot.fulfillments;
    final totalPackaged = fulfillments.fold<double>(
      0,
      (sum, item) =>
          sum + number(item, ['total_packaged_weight', 'packaging_weight']),
    );
    final totalWaste = fulfillments.fold<double>(
      0,
      (sum, item) => sum + number(item, ['packaging_waste_weight']),
    );

    _lines = fulfillments.asMap().entries.map((entry) {
      final item = entry.value;
      final received = number(item, ['total_weight']);
      final packaged =
          number(item, ['total_packaged_weight', 'packaging_weight']);
      final progress =
          received > 0 ? (packaged / received * 100).clamp(0, 100) : 0.0;
      final status = text(item, ['status', 'delivery_status'], 'Pending');
      final isWatch = status.toLowerCase().contains('hold') || progress < 50;
      return <String, dynamic>{
        'line': 'Line ${String.fromCharCode(65 + entry.key)}',
        'batch': text(item, ['batch_number', 'batch_id'], 'Unassigned batch'),
        'crop': text(item, ['plant_variety', 'crop_variety', 'plant_type'],
            'Unassigned variety'),
        'progress': '${progress.toStringAsFixed(0)}%',
        'output': '${packaged.toStringAsFixed(1)} kg',
        'eta': text(item, ['eta'], 'Not set'),
        'status': status,
        'color': isWatch ? AppColors.warning : AppColors.success,
      };
    }).toList();

    _activity = fulfillments.take(5).map((item) {
      final batch = text(item, ['batch_number', 'batch_id'], 'Fulfillment');
      final status = text(item, ['status', 'delivery_status'], 'Updated');
      return <String, dynamic>{
        'title': '$batch updated',
        'subtitle': 'Packaging status: $status',
        'time': text(
            item, ['packaging_date_time', 'received_date_time'], 'Recently'),
        'color': status.toLowerCase().contains('hold')
            ? AppColors.warning
            : AppColors.success,
      };
    }).toList();

    _progressValue = _lines.isEmpty
        ? 0
        : _lines
                .map((line) =>
                    double.tryParse(
                        (line['progress'] as String).replaceAll('%', '')) ??
                    0)
                .reduce((a, b) => a + b) /
            _lines.length;
    _wasteRate = totalPackaged + totalWaste == 0
        ? 0
        : totalWaste / (totalPackaged + totalWaste) * 100;
    _completedWeight = totalPackaged;
  }

  Widget _buildHero(bool isDark, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withOpacity(isDark ? 0.22 : 0.14),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: const Icon(
                  Icons.precision_manufacturing_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Packaging Command Center',
                      style: AppTypography.h4.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: isMobile ? 24 : 28,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Supervise package recording, waste exceptions, and active line performance in one place.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white.withOpacity(0.88),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _HeroChip(
                  label: '${_lines.length} active lines',
                  icon: Icons.conveyor_belt),
              _HeroChip(
                  label:
                      '${_lines.where((line) => line['color'] == AppColors.warning).length} line watch',
                  icon: Icons.visibility_outlined),
              _HeroChip(
                  label: '${_activity.length} reviews pending',
                  icon: Icons.task_alt_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainDashboardGrid(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 980;

        if (!twoColumns) {
          return Column(
            children: [
              _buildLinePanel(isDark),
              const SizedBox(height: AppSpacing.md),
              _buildActionPanel(isDark),
              const SizedBox(height: AppSpacing.md),
              _buildActivityPanel(isDark),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: _buildLinePanel(isDark),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  _buildActionPanel(isDark),
                  const SizedBox(height: AppSpacing.md),
                  _buildActivityPanel(isDark),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLinePanel(bool isDark) {
    return _DashboardPanel(
      title: 'Active Packaging Lines',
      subtitle: 'Live production state by batch and line.',
      icon: Icons.conveyor_belt,
      color: AppColors.primary,
      child: Column(
        children: _lines.map((line) => _LineStatusRow(line: line)).toList(),
      ),
    );
  }

  Widget _buildActionPanel(bool isDark) {
    return _DashboardPanel(
      title: 'Priority Actions',
      subtitle: 'Fast paths for supervisor work.',
      icon: Icons.bolt_outlined,
      color: AppColors.warning,
      child: Column(
        children: [
          _ActionTile(
            title: 'Record package count',
            subtitle: 'Submit completed output by line',
            icon: Icons.inventory_2_outlined,
            color: AppColors.primary,
            route: '/package-recording',
          ),
          const SizedBox(height: AppSpacing.sm),
          _ActionTile(
            title: 'Review waste event',
            subtitle: 'Investigate label mismatch',
            icon: Icons.delete_sweep_outlined,
            color: AppColors.error,
            route: '/waste-tracking',
          ),
          const SizedBox(height: AppSpacing.sm),
          _ActionTile(
            title: 'Check line progress',
            subtitle: 'Line B needs pace review',
            icon: Icons.trending_up_outlined,
            color: AppColors.success,
            route: '/progress',
          ),
        ],
      ),
    );
  }

  Widget _buildActivityPanel(bool isDark) {
    return _DashboardPanel(
      title: 'Supervisor Activity',
      subtitle: 'Recent events from packaging operations.',
      icon: Icons.history_outlined,
      color: AppColors.success,
      child: Column(
        children: _activity
            .map((activity) => _ActivityRow(activity: activity))
            .toList(),
      ),
    );
  }

  Widget _buildBottomNavigation(bool isDark) {
    final navItems = [
      {
        'icon': Icons.dashboard_outlined,
        'label': 'Dashboard',
        'index': 0,
        'route': '/packaging_dashboard'
      },
      {
        'icon': Icons.inventory_outlined,
        'label': 'Record',
        'index': 1,
        'route': '/package-recording'
      },
      {
        'icon': Icons.delete_outline,
        'label': 'Waste',
        'index': 2,
        'route': '/waste-tracking'
      },
      {
        'icon': Icons.assessment_outlined,
        'label': 'Progress',
        'index': 3,
        'route': '/progress'
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
}

class _DashboardKpi extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _DashboardKpi({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width =
        MediaQuery.of(context).size.width < 600 ? double.infinity : 230.0;

    return Container(
      width: width,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: color.withOpacity(isDark ? 0.26 : 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.12 : 0.035),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          _IconBox(icon: icon, color: color),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MutedText(title),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.h5.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                _MutedText(subtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget child;

  const _DashboardPanel({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: color.withOpacity(isDark ? 0.24 : 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.14 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBox(icon: icon, color: color),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyLarge.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    _MutedText(subtitle),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _LineStatusRow extends StatelessWidget {
  final Map<String, dynamic> line;

  const _LineStatusRow({required this.line});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = line['color']! as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? Colors.white10 : AppColors.neutral200,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _IconBox(icon: Icons.conveyor_belt, color: color),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line['line']! as String,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${line['crop']} | ${line['batch']}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color:
                            isDark ? Colors.white70 : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(label: line['status']! as String, color: color),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _MetricBlock(
                  label: 'Progress',
                  value: line['progress']! as String,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _MetricBlock(
                  label: 'Output',
                  value: line['output']! as String,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child:
                    _MetricBlock(label: 'ETA', value: line['eta']! as String),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;

  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.04) : AppColors.neutral50,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isDark ? Colors.white10 : AppColors.neutral200,
          ),
        ),
        child: Row(
          children: [
            _IconBox(icon: icon, color: color),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  _MutedText(subtitle),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final Map<String, dynamic> activity;

  const _ActivityRow({required this.activity});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = activity['color']! as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? Colors.white10 : AppColors.neutral200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title']! as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                _MutedText(activity['subtitle']! as String),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _MutedText(activity['time']! as String),
        ],
      ),
    );
  }
}

class _MetricBlock extends StatelessWidget {
  final String label;
  final String value;

  const _MetricBlock({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? Colors.white10 : AppColors.neutral200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MutedText(label),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _HeroChip({
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconBox({
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 136),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _MutedText extends StatelessWidget {
  final String text;

  const _MutedText(this.text);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.caption.copyWith(
        color: isDark ? Colors.white60 : AppColors.textSecondary,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
