import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/farm_owner_sidebar.dart';
import '../../core/widgets/farm_owner_header.dart';
import '../../core/widgets/farm_owner_mobile_drawer.dart';
import '../../providers/auth_provider.dart';

/// Analytics Screen for Farm Owner
/// View farm performance analytics and insights
class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  int _selectedNavIndex = 3;
  String _selectedPeriod = 'Last 30 Days';
  String _selectedCrop = 'All Crops';
  String _selectedInputType = 'All Inputs';
  final Map<String, int?> _touchedPieIndex = {};
  final Map<String, String> _cardFilters = {};
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'Farm Owner';
    final userEmail = authState.user?.email ?? 'owner@farmestates.com';
    final userRole = 'Farm Owner';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      drawer: isMobile
          ? FarmOwnerMobileDrawer(
              selectedIndex: _selectedNavIndex,
              onItemSelected: (i) => setState(() => _selectedNavIndex = i),
              userName: userName,
            )
          : null,
      body: isMobile
          ? _buildMobileLayout(isDark, userName)
          : _buildDesktopLayout(isDark, userName, userEmail, userRole),
      bottomNavigationBar: isMobile ? _buildBottomNavigation(isDark) : null,
    );
  }

  Widget _buildDesktopLayout(bool isDark, String userName, String userEmail, String userRole) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth < 1200 && screenWidth >= 600;
    
    return Row(
      children: [
        FarmOwnerSidebar(
          selectedIndex: _selectedNavIndex,
          onItemSelected: (index) {
            setState(() => _selectedNavIndex = index);
          },
          userName: userName,
          userEmail: userEmail,
          userRole: userRole,
        ),
        Expanded(
          child: Column(
            children: [
              FarmOwnerHeader(
                userName: userName,
                onNotificationTap: () {},
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isTablet ? AppSpacing.md : AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(isDark),
                      SizedBox(height: isTablet ? AppSpacing.md : AppSpacing.lg),
                      _buildFarmDetailsCard(isDark),
                      SizedBox(height: isTablet ? AppSpacing.md : AppSpacing.lg),
                      _buildPerformanceCards(isDark),
                      SizedBox(height: isTablet ? AppSpacing.md : AppSpacing.lg),
                      _buildChartsSection(isDark),
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
        FarmOwnerHeader(
          userName: userName,
          onNotificationTap: () {},
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(isDark),
                const SizedBox(height: AppSpacing.md),
                _buildFarmDetailsCard(isDark),
                const SizedBox(height: AppSpacing.md),
                _buildPerformanceCards(isDark),
                const SizedBox(height: AppSpacing.md),
                _buildChartsSection(isDark),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth < 1200 && screenWidth >= 600;
    
    return Builder(
      builder: (context) {
        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your Farm Analytics',
                style: AppTypography.h4.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontSize: 20,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: _buildHeaderDropdown(
                  isDark,
                  value: _selectedPeriod,
                  items: const ['Last 7 Days', 'Last 30 Days', 'Last 3 Months', 'Last Year'],
                  onChanged: (value) => setState(() => _selectedPeriod = value),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _buildHeaderDropdown(
                      isDark,
                      value: _selectedCrop,
                      items: const ['All Crops', 'Tomatoes', 'Onions', 'Peppers', 'Other'],
                      onChanged: (value) => setState(() => _selectedCrop = value),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _buildHeaderDropdown(
                      isDark,
                      value: _selectedInputType,
                      items: const ['All Inputs', 'Seeds', 'Nutrients', 'Water', 'Packaging'],
                      onChanged: (value) => setState(() => _selectedInputType = value),
                    ),
                  ),
                ],
              ),
            ],
          );
        }
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Your Farm Analytics',
                style: AppTypography.h4.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontSize: isTablet ? 22 : 24,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            _buildHeaderDropdown(
              isDark,
              value: _selectedPeriod,
              items: const ['Last 7 Days', 'Last 30 Days', 'Last 3 Months', 'Last Year'],
              onChanged: (value) => setState(() => _selectedPeriod = value),
              fontSize: isTablet ? 12 : 13,
            ),
            const SizedBox(width: AppSpacing.sm),
            _buildHeaderDropdown(
              isDark,
              value: _selectedCrop,
              items: const ['All Crops', 'Tomatoes', 'Onions', 'Peppers', 'Other'],
              onChanged: (value) => setState(() => _selectedCrop = value),
              fontSize: isTablet ? 12 : 13,
            ),
            const SizedBox(width: AppSpacing.sm),
            _buildHeaderDropdown(
              isDark,
              value: _selectedInputType,
              items: const ['All Inputs', 'Seeds', 'Nutrients', 'Water', 'Packaging'],
              onChanged: (value) => setState(() => _selectedInputType = value),
              fontSize: isTablet ? 12 : 13,
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeaderDropdown(
    bool isDark, {
    required String? value,
    required List<String> items,
    required ValueChanged<String> onChanged,
    double fontSize = 13,
  }) {
    final safeValue = (value != null && items.contains(value)) ? value : items.first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : AppColors.neutral100,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08),
        ),
      ),
      child: DropdownButton<String>(
        value: safeValue,
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(
              item,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontSize: fontSize,
              ),
            ),
          );
        }).toList(),
        onChanged: (value) => onChanged(value ?? safeValue),
        underline: const SizedBox(),
        icon: Icon(
          Icons.arrow_drop_down,
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
        dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
        style: TextStyle(
          color: isDark ? Colors.white : AppColors.textPrimary,
          fontSize: fontSize,
        ),
      ),
    );
  }

  Widget _buildPerformanceCards(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth < 1200 && screenWidth >= 600;
    
    final metrics = [
      {
        'title': 'Total Revenue',
        'value': '\$105,000',
        'change': '+23%',
        'isPositive': true,
        'icon': Icons.trending_up,
        'color': AppColors.success,
      },
      {
        'title': 'Total Yield',
        'value': '850 kg',
        'change': '+15%',
        'isPositive': true,
        'icon': Icons.inventory,
        'color': AppColors.info,
      },
      {
        'title': 'Profit Margin',
        'value': '18.5%',
        'change': '+2.1%',
        'isPositive': true,
        'icon': Icons.percent,
        'color': AppColors.primary,
      },
      {
        'title': 'Avg. Daily Revenue',
        'value': '\$1,250',
        'change': '+4%',
        'isPositive': true,
        'icon': Icons.show_chart,
        'color': AppColors.warning,
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = isMobile ? 2 : (isTablet ? 2 : 4);
        final childAspectRatio = isMobile ? 1.3 : (isTablet ? 1.6 : 1.8);

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: isMobile ? AppSpacing.sm : AppSpacing.md,
          mainAxisSpacing: isMobile ? AppSpacing.sm : AppSpacing.md,
          children: metrics.map((metric) {
            return Container(
              padding: EdgeInsets.all(isMobile ? AppSpacing.sm : (isTablet ? AppSpacing.sm : AppSpacing.md)),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.1) : AppColors.neutral200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: EdgeInsets.all(isMobile ? 6 : (isTablet ? 7 : 8)),
                        decoration: BoxDecoration(
                          color: (metric['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Icon(
                          metric['icon'] as IconData,
                          color: metric['color'] as Color,
                          size: isMobile ? 18 : (isTablet ? 19 : 20),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (metric['isPositive'] as bool)
                              ? AppColors.success.withOpacity(0.1)
                              : AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              (metric['isPositive'] as bool) ? Icons.trending_up : Icons.trending_down,
                              size: isMobile ? 10 : 12,
                              color: (metric['isPositive'] as bool) ? AppColors.success : AppColors.error,
                            ),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                metric['change'] as String,
                                style: AppTypography.caption.copyWith(
                                  color: (metric['isPositive'] as bool) ? AppColors.success : AppColors.error,
                                  fontSize: isMobile ? 9 : 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isMobile ? AppSpacing.xs : AppSpacing.sm),
                  Text(
                    metric['value'] as String,
                    style: AppTypography.h5.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      fontSize: isMobile ? 20 : (isTablet ? 22 : 24),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    metric['title'] as String,
                    style: AppTypography.caption.copyWith(
                      color: isDark ? Colors.white.withOpacity(0.6) : AppColors.textSecondary,
                      fontSize: isMobile ? 11 : (isTablet ? 11.5 : 12),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildFarmDetailsCard(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth < 1200 && screenWidth >= 600;

    final details = [
      {'label': 'Farm Name', 'value': 'Green Valley Farm'},
      {'label': 'Primary Crop', 'value': 'Tomatoes'},
      {'label': 'Farm Size', 'value': '32 acres'},
      {'label': 'Location', 'value': 'Lusaka, Zambia'},
    ];

    return Container(
      padding: EdgeInsets.all(isMobile ? AppSpacing.md : (isTablet ? AppSpacing.lg : AppSpacing.xl)),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
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
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.agriculture_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Farm Details',
                style: AppTypography.h6.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? AppSpacing.md : AppSpacing.lg),
          Wrap(
            spacing: isMobile ? AppSpacing.md : AppSpacing.lg,
            runSpacing: AppSpacing.md,
            children: details.map((detail) {
              return SizedBox(
                width: isMobile ? double.infinity : 220,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail['label'] as String,
                      style: AppTypography.caption.copyWith(
                        color: isDark ? Colors.white60 : AppColors.textSecondary,
                        fontSize: isMobile ? 11 : 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detail['value'] as String,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontSize: isMobile ? 13 : 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth < 1200 && screenWidth >= 600;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Farm Revenue Trend',
          style: AppTypography.h5.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontSize: isMobile ? 18 : (isTablet ? 20 : 22),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          height: isMobile ? 180 : (isTablet ? 190 : 200),
          padding: EdgeInsets.all(isMobile ? AppSpacing.sm : AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.1) : AppColors.neutral200,
            ),
          ),
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: 6,
              minY: 10,
              maxY: 28,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 4,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    interval: 4,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '\$${value.toStringAsFixed(0)}k',
                        style: AppTypography.caption.copyWith(
                          color: isDark ? Colors.white54 : AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                      if (value.toInt() < 0 || value.toInt() >= labels.length) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        labels[value.toInt()],
                        style: AppTypography.caption.copyWith(
                          color: isDark ? Colors.white54 : AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                handleBuiltInTouches: true,
                touchTooltipData: LineTouchTooltipData(
                  tooltipRoundedRadius: 8,
                  tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  tooltipMargin: 12,
                  getTooltipColor: (touchedSpot) =>
                      isDark ? const Color(0xFF111827) : Colors.white,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      return LineTooltipItem(
                        '\$${spot.y.toStringAsFixed(0)}k',
                        AppTypography.caption.copyWith(
                          color: isDark ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  isCurved: true,
                  color: AppColors.success,
                  barWidth: 3,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                      radius: 4.5,
                      color: AppColors.success,
                      strokeWidth: 2.5,
                      strokeColor: isDark ? AppColors.surfaceDark : Colors.white,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.success.withOpacity(0.12),
                  ),
                  spots: const [
                    FlSpot(0, 12),
                    FlSpot(1, 18),
                    FlSpot(2, 16),
                    FlSpot(3, 22),
                    FlSpot(4, 19),
                    FlSpot(5, 26),
                    FlSpot(6, 24),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: isMobile ? AppSpacing.lg : AppSpacing.xl),
        Text(
          'Insights',
          style: AppTypography.h5.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontSize: isMobile ? 18 : (isTablet ? 20 : 22),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = isMobile
                ? double.infinity
                : (constraints.maxWidth - AppSpacing.md) / 2;
            return Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: _buildPieChartCard(
                    isDark,
                    title: 'Input Usage',
                    centerLabel: 'Total',
                    centerValue: '1,240 units',
                    slices: const [
                      _ChartSlice(color: AppColors.primary, value: 34, label: 'Seeds'),
                      _ChartSlice(color: AppColors.success, value: 22, label: 'Nutrients'),
                      _ChartSlice(color: AppColors.info, value: 28, label: 'Water'),
                      _ChartSlice(color: AppColors.warning, value: 16, label: 'Packaging'),
                    ],
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _buildPieChartCard(
                    isDark,
                    title: 'Yield by Crop',
                    centerLabel: 'Harvest',
                    centerValue: '850 kg',
                    slices: const [
                      _ChartSlice(color: AppColors.success, value: 48, label: 'Tomatoes'),
                      _ChartSlice(color: AppColors.primary, value: 22, label: 'Onions'),
                      _ChartSlice(color: AppColors.info, value: 18, label: 'Peppers'),
                      _ChartSlice(color: AppColors.warning, value: 12, label: 'Other'),
                    ],
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _buildBarChartCard(
                    isDark,
                    title: 'Input Cost by Category',
                    totalLabel: 'Total Cost',
                    totalValue: '\$12.4k',
                    bars: const [
                      _BarChartItem(label: 'Seeds', value: 4200, color: AppColors.primary),
                      _BarChartItem(label: 'Nutrients', value: 2900, color: AppColors.success),
                      _BarChartItem(label: 'Water', value: 3100, color: AppColors.info),
                      _BarChartItem(label: 'Packaging', value: 2200, color: AppColors.warning),
                    ],
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _buildLineChartCard(
                    isDark,
                    title: 'Water Usage Trend',
                    subtitle: 'Last 7 days',
                    points: const [40, 55, 48, 62, 58, 70, 64],
                    lineColor: AppColors.info,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _buildMonthlyCostCard(
                    isDark,
                    title: 'Monthly Input Cost',
                    values: const [
                      _MonthlyCost(month: 'Aug', value: 1800),
                      _MonthlyCost(month: 'Sep', value: 2200),
                      _MonthlyCost(month: 'Oct', value: 2100),
                      _MonthlyCost(month: 'Nov', value: 2600),
                      _MonthlyCost(month: 'Dec', value: 2400),
                      _MonthlyCost(month: 'Jan', value: 2900),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildPieChartCard(
    bool isDark, {
    required String title,
    required String centerLabel,
    required String centerValue,
    required List<_ChartSlice> slices,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth < 1200 && screenWidth >= 600;
    final safeIndex = _touchedPieIndex[title];
    final isValidIndex =
        safeIndex != null && safeIndex >= 0 && safeIndex < slices.length;
    final selectedFilter = _cardFilters[title] ?? 'All';

    return Container(
      padding: EdgeInsets.all(isMobile ? AppSpacing.md : (isTablet ? AppSpacing.lg : AppSpacing.xl)),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.h6.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              _buildCardFilter(
                isDark,
                title: title,
                value: selectedFilter,
                options: const ['All', 'Last 7 days', 'Last 30 days', 'This season'],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              SizedBox(
                width: isMobile ? 120 : 140,
                height: isMobile ? 120 : 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: isMobile ? 28 : 34,
                        sections: slices.asMap().entries.map((entry) {
                          final index = entry.key;
                          final slice = entry.value;
                          final isTouched = isValidIndex && safeIndex == index;
                          return PieChartSectionData(
                            color: slice.color,
                            value: slice.value,
                            showTitle: false,
                            radius: isMobile
                                ? (isTouched ? 30 : 24)
                                : (isTouched ? 34 : 28),
                          );
                        }).toList(),
                        pieTouchData: PieTouchData(
                          enabled: true,
                          touchCallback: (event, response) {
                            final touched = response?.touchedSection;
                            final index = touched?.touchedSectionIndex ?? -1;
                            setState(() {
                              if (index < 0 || index >= slices.length) {
                                _touchedPieIndex[title] = null;
                              } else {
                                _touchedPieIndex[title] = index;
                              }
                            });
                          },
                        ),
                        borderData: FlBorderData(show: false),
                      ),
                    ),
                    if (isValidIndex)
                      Align(
                        alignment: Alignment.topRight,
                        child: _buildPieTooltip(
                          slices[safeIndex!],
                          isDark,
                        ),
                      ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          centerLabel,
                          style: AppTypography.caption.copyWith(
                            color: isDark ? Colors.white60 : AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          centerValue,
                          style: AppTypography.bodyLarge.copyWith(
                            color: isDark ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: slices.map((slice) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: slice.color,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              slice.label,
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark ? Colors.white70 : AppColors.textSecondary,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${slice.value}%',
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark ? Colors.white : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPieTooltip(_ChartSlice slice, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      margin: const EdgeInsets.only(top: 6, right: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        '${slice.label}: ${slice.value.toStringAsFixed(0)}%',
        style: AppTypography.caption.copyWith(
          color: isDark ? Colors.white : AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCardFilter(
    bool isDark, {
    required String title,
    required String value,
    required List<String> options,
  }) {
    return PopupMenuButton<String>(
      tooltip: 'Filter',
      offset: const Offset(0, 38),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      onSelected: (selected) {
        setState(() {
          _cardFilters[title] = selected;
        });
      },
      itemBuilder: (context) => options
          .map(
            (option) => PopupMenuItem(
              value: option,
              child: Row(
                children: [
                  Icon(
                    option == value ? Icons.check_circle : Icons.circle_outlined,
                    size: 16,
                    color: option == value ? AppColors.primary : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(option),
                ],
              ),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : AppColors.neutral100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08),
          ),
        ),
        child: Row(
          children: [
            Text(
              value,
              style: AppTypography.caption.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChartCard(
    bool isDark, {
    required String title,
    required String totalLabel,
    required String totalValue,
    required List<_BarChartItem> bars,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth < 1200 && screenWidth >= 600;
    final maxValue = bars.map((b) => b.value).reduce((a, b) => a > b ? a : b).toDouble();
    final selectedFilter = _cardFilters[title] ?? 'All';

    return Container(
      padding: EdgeInsets.all(isMobile ? AppSpacing.md : (isTablet ? AppSpacing.lg : AppSpacing.xl)),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.h6.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              _buildCardFilter(
                isDark,
                title: title,
                value: selectedFilter,
                options: const ['All', 'This month', 'Last month', 'YTD'],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text(
                totalLabel,
                style: AppTypography.caption.copyWith(
                  color: isDark ? Colors.white60 : AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                totalValue,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: isMobile ? 160 : 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceBetween,
                maxY: maxValue == 0 ? 1 : maxValue * 1.15,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxValue == 0 ? 1 : maxValue / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      interval: maxValue == 0 ? 1 : maxValue / 4,
                      getTitlesWidget: (value, meta) => Text(
                        '\$${value.toStringAsFixed(0)}',
                        style: AppTypography.caption.copyWith(
                          color: isDark ? Colors.white54 : AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= bars.length) return const SizedBox.shrink();
                        return Text(
                          bars[index].label,
                          style: AppTypography.caption.copyWith(
                            color: isDark ? Colors.white70 : AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    tooltipMargin: 12,
                    getTooltipColor: (group) =>
                        isDark ? const Color(0xFF111827) : Colors.white,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '\$${rod.toY.toStringAsFixed(0)}',
                        AppTypography.caption.copyWith(
                          color: isDark ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: bars.asMap().entries.map((entry) {
                  final index = entry.key;
                  final bar = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: bar.value,
                        width: 18,
                        borderRadius: BorderRadius.circular(6),
                        color: bar.color,
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChartCard(
    bool isDark, {
    required String title,
    required String subtitle,
    required List<double> points,
    required Color lineColor,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth < 1200 && screenWidth >= 600;
    final selectedFilter = _cardFilters[title] ?? 'All';

    return Container(
      padding: EdgeInsets.all(isMobile ? AppSpacing.md : (isTablet ? AppSpacing.lg : AppSpacing.xl)),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.h6.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              _buildCardFilter(
                isDark,
                title: title,
                value: selectedFilter,
                options: const ['All', '7 days', '14 days', '30 days'],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTypography.caption.copyWith(
              color: isDark ? Colors.white60 : AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: isMobile ? 140 : 160,
            width: double.infinity,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: points.length - 1,
                minY: 0,
                maxY: points.reduce((a, b) => a > b ? a : b) * 1.2,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 10,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 10,
                      getTitlesWidget: (value, meta) => Text(
                        value.toStringAsFixed(0),
                        style: AppTypography.caption.copyWith(
                          color: isDark ? Colors.white54 : AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: false,
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    tooltipMargin: 12,
                    getTooltipColor: (touchedSpot) =>
                        isDark ? const Color(0xFF111827) : Colors.white,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          '${spot.y.toStringAsFixed(0)} L',
                          AppTypography.caption.copyWith(
                            color: isDark ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    color: lineColor,
                    barWidth: 3,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                      radius: 4.5,
                      color: lineColor,
                      strokeWidth: 2.5,
                      strokeColor: isDark ? AppColors.surfaceDark : Colors.white,
                    ),
                  ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: lineColor.withOpacity(0.12),
                    ),
                    spots: points
                        .asMap()
                        .entries
                        .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyCostCard(
    bool isDark, {
    required String title,
    required List<_MonthlyCost> values,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth < 1200 && screenWidth >= 600;
    final maxValue = values.map((v) => v.value).reduce((a, b) => a > b ? a : b).toDouble();
    final selectedFilter = _cardFilters[title] ?? 'All';

    return Container(
      padding: EdgeInsets.all(isMobile ? AppSpacing.md : (isTablet ? AppSpacing.lg : AppSpacing.xl)),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.h6.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              _buildCardFilter(
                isDark,
                title: title,
                value: selectedFilter,
                options: const ['6 months', 'YTD', '12 months'],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: isMobile ? 140 : 160,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceBetween,
                maxY: maxValue == 0 ? 1 : maxValue * 1.2,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxValue == 0 ? 1 : maxValue / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: maxValue == 0 ? 1 : maxValue / 4,
                      getTitlesWidget: (value, meta) => Text(
                        '\$${value.toStringAsFixed(0)}',
                        style: AppTypography.caption.copyWith(
                          color: isDark ? Colors.white54 : AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= values.length) return const SizedBox.shrink();
                        return Text(
                          values[index].month,
                          style: AppTypography.caption.copyWith(
                            color: isDark ? Colors.white70 : AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    tooltipMargin: 12,
                    getTooltipColor: (group) =>
                        isDark ? const Color(0xFF111827) : Colors.white,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '\$${rod.toY.toStringAsFixed(0)}',
                        AppTypography.caption.copyWith(
                          color: isDark ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: values.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: item.value,
                        width: 16,
                        borderRadius: BorderRadius.circular(6),
                        color: AppColors.primary.withOpacity(0.9),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(bool isDark) {
    final navItems = [
      {
        'icon': Icons.dashboard_outlined,
        'label': 'Dashboard',
        'index': 0,
        'route': '/farm-owner'
      },
      {
        'icon': Icons.agriculture_outlined,
        'label': 'Farm',
        'index': 1,
        'route': '/farm-owner/farm'
      },
      {
        'icon': Icons.account_balance_wallet_outlined,
        'label': 'Wallet',
        'index': 2,
        'route': '/farm-owner/digital-wallet'
      },
      {
        'icon': Icons.analytics_outlined,
        'label': 'Analytics',
        'index': 3,
        'route': '/farm-owner/analytics'
      },
      {
        'icon': Icons.assessment_outlined,
        'label': 'Reports',
        'index': 4,
        'route': '/farm-owner/reports'
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
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: navItems.take(5).map((item) {
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
                              : (isDark ? Colors.white.withOpacity(0.5) : AppColors.textSecondary),
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
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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

class _ChartSlice {
  final Color color;
  final double value;
  final String label;

  const _ChartSlice({
    required this.color,
    required this.value,
    required this.label,
  });
}

class _BarChartItem {
  final String label;
  final double value;
  final Color color;

  const _BarChartItem({
    required this.label,
    required this.value,
    required this.color,
  });
}

class _MonthlyCost {
  final String month;
  final double value;

  const _MonthlyCost({
    required this.month,
    required this.value,
  });
}
