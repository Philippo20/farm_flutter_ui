import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/modern_admin_header.dart';
import '../../core/widgets/modern_admin_sidebar.dart';

class ModernAnalyticsScreen extends ConsumerStatefulWidget {
  const ModernAnalyticsScreen({super.key});

  @override
  ConsumerState<ModernAnalyticsScreen> createState() =>
      _ModernAnalyticsScreenState();
}

class _ModernAnalyticsScreenState extends ConsumerState<ModernAnalyticsScreen> {
  String _selectedPeriod = 'Last 30 Days';
  String _selectedFarm = 'All Farms';

  final List<String> _farms = const [
    'All Farms',
    'Northern Estate',
    'Southern Estate',
    'Eastern Farm',
    'Western Farm',
  ];

  final List<_FarmAnalytics> _farmAnalytics = const [
    _FarmAnalytics(
      name: 'Northern Estate',
      revenue: 142000,
      productionKg: 38500,
      efficiency: 94,
      yieldPerAcre: 82,
      sensorHealth: 98,
      risk: 'Low',
      color: AppColors.success,
    ),
    _FarmAnalytics(
      name: 'Southern Estate',
      revenue: 116000,
      productionKg: 31200,
      efficiency: 88,
      yieldPerAcre: 76,
      sensorHealth: 92,
      risk: 'Low',
      color: AppColors.primary,
    ),
    _FarmAnalytics(
      name: 'Eastern Farm',
      revenue: 93000,
      productionKg: 26700,
      efficiency: 79,
      yieldPerAcre: 69,
      sensorHealth: 86,
      risk: 'Watch',
      color: AppColors.warning,
    ),
    _FarmAnalytics(
      name: 'Western Farm',
      revenue: 69000,
      productionKg: 21800,
      efficiency: 73,
      yieldPerAcre: 63,
      sensorHealth: 81,
      risk: 'High',
      color: AppColors.error,
    ),
  ];

  List<_FarmAnalytics> get _visibleFarms {
    if (_selectedFarm == 'All Farms') return _farmAnalytics;
    return _farmAnalytics.where((farm) => farm.name == _selectedFarm).toList();
  }

  _AnalyticsTotals get _totals {
    final farms = _visibleFarms;
    final revenue = farms.fold<double>(0, (sum, farm) => sum + farm.revenue);
    final production =
        farms.fold<double>(0, (sum, farm) => sum + farm.productionKg);
    final efficiency =
        farms.fold<double>(0, (sum, farm) => sum + farm.efficiency) /
            farms.length;
    final sensorHealth =
        farms.fold<double>(0, (sum, farm) => sum + farm.sensorHealth) /
            farms.length;
    return _AnalyticsTotals(
      revenue: revenue,
      productionKg: production,
      efficiency: efficiency.round(),
      sensorHealth: sensorHealth.round(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 700;

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
        ModernAdminSidebar(selectedIndex: 4, onItemSelected: (_) {}),
        Expanded(
          child: Column(
            children: [
              ModernAdminHeader(
                userName: 'Admin',
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

  Widget _buildMobileLayout(bool isDark) {
    return Column(
      children: [
        ModernAdminHeader(
          userName: 'Admin',
          onNotificationTap: () {},
          onProfileTap: () {},
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
        _buildScopeControls(isDark),
        const SizedBox(height: AppSpacing.lg),
        _buildKpiGrid(isDark),
        const SizedBox(height: AppSpacing.lg),
        _buildPrimaryCharts(isDark),
        const SizedBox(height: AppSpacing.lg),
        _buildFarmComparison(isDark),
        const SizedBox(height: AppSpacing.lg),
        _buildInsights(isDark),
      ],
    );
  }

  Widget _buildHero(bool isDark, bool isMobile) {
    final totals = _totals;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? AppSpacing.lg : AppSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF102A43),
                  const Color(0xFF123B2F),
                  AppColors.surfaceDark,
                ]
              : [
                  const Color(0xFFEAF4FF),
                  const Color(0xFFF1FFF5),
                  Colors.white,
                ],
        ),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.primary.withValues(alpha: 0.14),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.10),
              blurRadius: 28,
              offset: const Offset(0, 16),
            ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 820;
          return Flex(
            direction: stacked ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: stacked ? 0 : 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildScopePill(isDark),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Farm Analytics Command Center',
                      style: AppTypography.h3.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _selectedFarm == 'All Farms'
                          ? 'Global view of production, revenue, sensor reliability, and farm efficiency across the full operation.'
                          : 'Focused performance view for $_selectedFarm with production, revenue, sensor, and risk indicators.',
                      style: AppTypography.bodyLarge.copyWith(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.72)
                            : AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              if (!stacked) const SizedBox(width: AppSpacing.xl),
              if (stacked) const SizedBox(height: AppSpacing.lg),
              Expanded(
                flex: stacked ? 0 : 2,
                child: _buildHeroScorecard(isDark, totals),
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
        color: AppColors.info.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.analytics_rounded,
            size: 17,
            color: isDark ? Colors.white : AppColors.info,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            _selectedFarm == 'All Farms'
                ? 'Global farm intelligence'
                : 'Individual farm intelligence',
            style: AppTypography.label.copyWith(
              color: isDark ? Colors.white : AppColors.info,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroScorecard(bool isDark, _AnalyticsTotals totals) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : AppColors.neutral300,
        ),
      ),
      child: Column(
        children: [
          _scoreRow(
            isDark,
            Icons.payments_rounded,
            'Revenue',
            _money(totals.revenue),
            AppColors.success,
          ),
          const SizedBox(height: AppSpacing.md),
          _scoreRow(
            isDark,
            Icons.inventory_2_rounded,
            'Production',
            '${(totals.productionKg / 1000).toStringAsFixed(1)}K kg',
            AppColors.primary,
          ),
          const SizedBox(height: AppSpacing.md),
          _scoreRow(
            isDark,
            Icons.speed_rounded,
            'Efficiency',
            '${totals.efficiency}%',
            AppColors.warning,
          ),
        ],
      ),
    );
  }

  Widget _scoreRow(
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
            color: color.withValues(alpha: 0.14),
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
                  ? Colors.white.withValues(alpha: 0.72)
                  : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: AppTypography.titleSmall.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildScopeControls(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _cardDecoration(isDark),
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _dropdown(
            label: 'Analytics Scope',
            value: _selectedFarm,
            items: _farms,
            isDark: isDark,
            onChanged: (value) => setState(() => _selectedFarm = value!),
          ),
          _dropdown(
            label: 'Period',
            value: _selectedPeriod,
            items: const [
              'Last 7 Days',
              'Last 30 Days',
              'Last 90 Days',
              'This Year',
            ],
            isDark: isDark,
            onChanged: (value) => setState(() => _selectedPeriod = value!),
          ),
          _ScopeChip(
            icon: Icons.public_rounded,
            label: _selectedFarm == 'All Farms'
                ? 'Comparing all farms'
                : 'Focused on one farm',
            color: _selectedFarm == 'All Farms'
                ? AppColors.info
                : AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> items,
    required bool isDark,
    required ValueChanged<String?> onChanged,
  }) {
    return SizedBox(
      width: 230,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : AppColors.neutral50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : AppColors.neutral300,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKpiGrid(bool isDark) {
    final totals = _totals;
    final kpis = [
      _AnalyticsKpi(
        label: 'Revenue',
        value: _money(totals.revenue),
        change: '+18.6%',
        icon: Icons.payments_rounded,
        color: AppColors.success,
      ),
      _AnalyticsKpi(
        label: 'Production',
        value: '${(totals.productionKg / 1000).toStringAsFixed(1)}K kg',
        change: '+11.2%',
        icon: Icons.inventory_2_rounded,
        color: AppColors.primary,
      ),
      _AnalyticsKpi(
        label: 'Efficiency',
        value: '${totals.efficiency}%',
        change: '+5.4%',
        icon: Icons.speed_rounded,
        color: AppColors.warning,
      ),
      _AnalyticsKpi(
        label: 'Sensor Health',
        value: '${totals.sensorHealth}%',
        change: '+2.1%',
        icon: Icons.sensors_rounded,
        color: AppColors.info,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1050
            ? 4
            : constraints.maxWidth >= 620
                ? 2
                : 1;
        final cardWidth =
            (constraints.maxWidth - (AppSpacing.md * (columns - 1))) / columns;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: kpis
              .map((kpi) => SizedBox(
                    width: cardWidth,
                    child: _KpiCard(kpi: kpi, isDark: isDark),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildPrimaryCharts(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 980;
        final children = [
          Expanded(
            flex: wide ? 3 : 0,
            child: _TrendChart(
              title: _selectedFarm == 'All Farms'
                  ? 'Global Revenue vs Production'
                  : 'Farm Revenue vs Production',
              isDark: isDark,
            ),
          ),
          SizedBox(
              width: wide ? AppSpacing.md : 0,
              height: wide ? 0 : AppSpacing.md),
          Expanded(
            flex: wide ? 2 : 0,
            child: _SensorReliabilityChart(isDark: isDark),
          ),
        ];

        return wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children)
            : Column(children: children);
      },
    );
  }

  Widget _buildFarmComparison(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: _selectedFarm == 'All Farms'
                ? 'Farm Performance Comparison'
                : 'Farm Performance Detail',
            subtitle:
                'Revenue, yield, efficiency, sensor health, and risk by farm.',
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1100
                  ? 2
                  : constraints.maxWidth >= 760
                      ? 2
                      : 1;
              final cardWidth =
                  (constraints.maxWidth - (AppSpacing.md * (columns - 1))) /
                      columns;
              return Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: _visibleFarms
                    .map((farm) => SizedBox(
                          width: cardWidth,
                          child: _FarmComparisonCard(
                            farm: farm,
                            isDark: isDark,
                            onSelect: () =>
                                setState(() => _selectedFarm = farm.name),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInsights(bool isDark) {
    final farmLabel =
        _selectedFarm == 'All Farms' ? 'all farms' : _selectedFarm;
    final insights = [
      _InsightItem(
        title: 'Revenue momentum is strongest in Northern Estate',
        detail: _selectedFarm == 'All Farms'
            ? 'Northern Estate contributes 34% of current period revenue.'
            : '$farmLabel revenue is tracking above its 90-day baseline.',
        icon: Icons.trending_up_rounded,
        color: AppColors.success,
      ),
      _InsightItem(
        title: 'Sensor reliability impacts yield confidence',
        detail:
            'Zones below 88% sensor health should be prioritized for calibration.',
        icon: Icons.sensors_rounded,
        color: AppColors.info,
      ),
      _InsightItem(
        title: 'Water and nutrient variance requires review',
        detail:
            'Moisture trends are below target in lower-performing farm zones.',
        icon: Icons.water_drop_rounded,
        color: AppColors.warning,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Operational Insights',
            subtitle: 'Recommended admin actions based on current analytics.',
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.md),
          ...insights.map(
            (insight) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _InsightRow(insight: insight, isDark: isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(bool isDark) {
    const items = [
      _MobileNavItem(Icons.dashboard_outlined, 'Dashboard', '/dashboard'),
      _MobileNavItem(Icons.people_outline, 'Users', '/users'),
      _MobileNavItem(Icons.agriculture_outlined, 'Farms', '/farms'),
      _MobileNavItem(Icons.sensors_outlined, 'Sensors', '/sensors'),
      _MobileNavItem(Icons.analytics_outlined, 'Analytics', '/analytics'),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : AppColors.neutral300,
          ),
        ),
      ),
      child: Row(
        children: items.map((item) {
          final selected = item.label == 'Analytics';
          return Expanded(
            child: InkWell(
              onTap: () {
                if (!selected) {
                  Navigator.pushReplacementNamed(context, item.route);
                }
              },
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.14)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.icon,
                      size: 21,
                      color: selected
                          ? AppColors.primary
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.62)
                              : AppColors.textSecondary),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        fontSize: 10,
                        color: selected
                            ? AppColors.primary
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.62)
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

  String _money(double value) {
    if (value >= 1000000) return '\$${(value / 1000000).toStringAsFixed(2)}M';
    return '\$${(value / 1000).toStringAsFixed(0)}K';
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.kpi, required this.isDark});

  final _AnalyticsKpi kpi;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _cardDecoration(isDark),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: kpi.color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Icon(kpi.icon, color: kpi.color, size: 25),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kpi.value,
                  style: AppTypography.titleMedium.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  kpi.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.64)
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          _ScopeChip(
              icon: Icons.arrow_upward_rounded,
              label: kpi.change,
              color: kpi.color),
        ],
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.title, required this.isDark});

  final String title;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 360,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: title,
            subtitle: 'Monthly revenue and production index trends.',
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 160,
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.05),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        const labels = [
                          'Jan',
                          'Feb',
                          'Mar',
                          'Apr',
                          'May',
                          'Jun'
                        ];
                        final index = value.toInt();
                        if (index < 0 || index >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          labels[index],
                          style: AppTypography.caption.copyWith(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.54)
                                : AppColors.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  _line(
                    AppColors.success,
                    const [
                      FlSpot(0, 82),
                      FlSpot(1, 94),
                      FlSpot(2, 88),
                      FlSpot(3, 114),
                      FlSpot(4, 128),
                      FlSpot(5, 142),
                    ],
                  ),
                  _line(
                    AppColors.primary,
                    const [
                      FlSpot(0, 65),
                      FlSpot(1, 72),
                      FlSpot(2, 78),
                      FlSpot(3, 86),
                      FlSpot(4, 98),
                      FlSpot(5, 111),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            children: const [
              _Legend(label: 'Revenue Index', color: AppColors.success),
              _Legend(label: 'Production Index', color: AppColors.primary),
            ],
          ),
        ],
      ),
    );
  }

  LineChartBarData _line(Color color, List<FlSpot> spots) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 3,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: color.withValues(alpha: 0.10),
      ),
    );
  }
}

class _SensorReliabilityChart extends StatelessWidget {
  const _SensorReliabilityChart({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 360,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Sensor Reliability',
            subtitle: 'Average telemetry health by system.',
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: BarChart(
              BarChartData(
                maxY: 100,
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.05),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const labels = ['Temp', 'Hum', 'pH', 'Moist'];
                        final index = value.toInt();
                        if (index < 0 || index >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          labels[index],
                          style: AppTypography.caption.copyWith(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.54)
                                : AppColors.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  _bar(0, 96, AppColors.success),
                  _bar(1, 92, AppColors.info),
                  _bar(2, 86, AppColors.warning),
                  _bar(3, 81, AppColors.error),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _bar(int x, double value, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value,
          width: 24,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [color.withValues(alpha: 0.62), color],
          ),
        ),
      ],
    );
  }
}

class _FarmComparisonCard extends StatelessWidget {
  const _FarmComparisonCard({
    required this.farm,
    required this.isDark,
    required this.onSelect,
  });

  final _FarmAnalytics farm;
  final bool isDark;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.025)
                : AppColors.neutral50,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.04),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      farm.name,
                      style: AppTypography.titleSmall.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _ScopeChip(
                    icon: Icons.shield_rounded,
                    label: farm.risk,
                    color: farm.color,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _MetricColumn(
                      label: 'Revenue',
                      value: '\$${(farm.revenue / 1000).toStringAsFixed(0)}K',
                      isDark: isDark,
                    ),
                  ),
                  Expanded(
                    child: _MetricColumn(
                      label: 'Production',
                      value:
                          '${(farm.productionKg / 1000).toStringAsFixed(1)}K kg',
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _ProgressLine(
                label: 'Efficiency',
                value: farm.efficiency,
                color: AppColors.warning,
                isDark: isDark,
              ),
              const SizedBox(height: AppSpacing.sm),
              _ProgressLine(
                label: 'Sensor health',
                value: farm.sensorHealth,
                color: AppColors.info,
                isDark: isDark,
              ),
              const SizedBox(height: AppSpacing.sm),
              _ProgressLine(
                label: 'Yield / acre',
                value: farm.yieldPerAcre,
                color: AppColors.primary,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  final String label;
  final int value;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.64)
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '$value%',
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
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
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

class _MetricColumn extends StatelessWidget {
  const _MetricColumn({
    required this.label,
    required this.value,
    required this.isDark,
  });

  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AppTypography.bodyLarge.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: isDark
                ? Colors.white.withValues(alpha: 0.58)
                : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({required this.insight, required this.isDark});

  final _InsightItem insight;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.025)
            : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: insight.color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Icon(insight.icon, color: insight.color, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  insight.detail,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.62)
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  final String title;
  final String subtitle;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.titleMedium.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: AppTypography.bodySmall.copyWith(
            color: isDark
                ? Colors.white.withValues(alpha: 0.62)
                : AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ScopeChip extends StatelessWidget {
  const _ScopeChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: AppTypography.caption),
      ],
    );
  }
}

BoxDecoration _cardDecoration(bool isDark) {
  return BoxDecoration(
    color: isDark ? AppColors.surfaceDark : Colors.white,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(
      color: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : AppColors.neutral300.withValues(alpha: 0.72),
    ),
    boxShadow: [
      if (!isDark)
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.045),
          blurRadius: 20,
          offset: const Offset(0, 12),
        ),
    ],
  );
}

class _AnalyticsTotals {
  const _AnalyticsTotals({
    required this.revenue,
    required this.productionKg,
    required this.efficiency,
    required this.sensorHealth,
  });

  final double revenue;
  final double productionKg;
  final int efficiency;
  final int sensorHealth;
}

class _FarmAnalytics {
  const _FarmAnalytics({
    required this.name,
    required this.revenue,
    required this.productionKg,
    required this.efficiency,
    required this.yieldPerAcre,
    required this.sensorHealth,
    required this.risk,
    required this.color,
  });

  final String name;
  final double revenue;
  final double productionKg;
  final int efficiency;
  final int yieldPerAcre;
  final int sensorHealth;
  final String risk;
  final Color color;
}

class _AnalyticsKpi {
  const _AnalyticsKpi({
    required this.label,
    required this.value,
    required this.change,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String change;
  final IconData icon;
  final Color color;
}

class _InsightItem {
  const _InsightItem({
    required this.title,
    required this.detail,
    required this.icon,
    required this.color,
  });

  final String title;
  final String detail;
  final IconData icon;
  final Color color;
}

class _MobileNavItem {
  const _MobileNavItem(this.icon, this.label, this.route);

  final IconData icon;
  final String label;
  final String route;
}
