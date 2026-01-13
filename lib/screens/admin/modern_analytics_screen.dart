import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/modern_admin_sidebar.dart';
import '../../core/widgets/modern_admin_header.dart';

/// Modern Analytics Dashboard with comprehensive charts and insights
class ModernAnalyticsScreen extends ConsumerStatefulWidget {
  const ModernAnalyticsScreen({super.key});

  @override
  ConsumerState<ModernAnalyticsScreen> createState() => _ModernAnalyticsScreenState();
}

class _ModernAnalyticsScreenState extends ConsumerState<ModernAnalyticsScreen> {
  String _selectedPeriod = 'Last 30 Days';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
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
              ModernAdminHeader(userName: 'Admin', onNotificationTap: () {}, onProfileTap: () {}),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title & Period Selector
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Analytics Dashboard',
                                  style: AppTypography.h4.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : AppColors.textPrimary)),
                              Text('Comprehensive insights and performance metrics',
                                  style: AppTypography.bodyMedium.copyWith(
                                      color: isDark ? Colors.white70 : AppColors.textSecondary)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : AppColors.neutral100,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            ),
                            child: DropdownButton<String>(
                              value: _selectedPeriod,
                              items: ['Last 7 Days', 'Last 30 Days', 'Last 90 Days', 'This Year']
                                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                                  .toList(),
                              onChanged: (v) => setState(() => _selectedPeriod = v!),
                              underline: const SizedBox(),
                              icon: const Icon(Icons.arrow_drop_down),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // KPI Cards
                      _buildKPICards(isDark),

                      const SizedBox(height: AppSpacing.xl),

                      // Charts Row
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 900;
                          if (isWide) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 2, child: _buildRevenueChart(isDark, false)),
                                const SizedBox(width: AppSpacing.lg),
                                Expanded(child: _buildProductionPieChart(isDark, false)),
                              ],
                            );
                          } else {
                            return Column(
                              children: [
                                _buildRevenueChart(isDark, false),
                                const SizedBox(height: AppSpacing.md),
                                _buildProductionPieChart(isDark, false),
                              ],
                            );
                          }
                        },
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // Second Row Charts
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 900;
                          if (isWide) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildFarmPerformanceChart(isDark, false)),
                                const SizedBox(width: AppSpacing.lg),
                                Expanded(child: _buildSensorDataChart(isDark, false)),
                              ],
                            );
                          } else {
                            return Column(
                              children: [
                                _buildFarmPerformanceChart(isDark, false),
                                const SizedBox(height: AppSpacing.md),
                                _buildSensorDataChart(isDark, false),
                              ],
                            );
                          }
                        },
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // Performance Table
                      _buildPerformanceTable(isDark, false),
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

  Widget _buildMobileLayout(bool isDark) {
    return Column(
      children: [
        ModernAdminHeader(userName: 'Admin', onNotificationTap: () {}, onProfileTap: () {}),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title & Period Selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Analytics Dashboard',
                              style: AppTypography.h5.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : AppColors.textPrimary)),
                          Text('Comprehensive insights',
                              style: AppTypography.bodySmall.copyWith(
                                  color: isDark ? Colors.white70 : AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : AppColors.neutral100,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedPeriod,
                        items: ['Last 7 Days', 'Last 30 Days', 'Last 90 Days', 'This Year']
                            .map((p) => DropdownMenuItem(
                                value: p, child: Text(p, style: const TextStyle(fontSize: 12))))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedPeriod = v!),
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down, size: 18),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                // KPI Cards (mobile optimized)
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSpacing.sm,
                  crossAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 1.3,
                  children: [
                    _buildMobileKPICard(
                        'Total Revenue', '\$420K', '+23.5%', AppColors.success, isDark),
                    _buildMobileKPICard('Production', '12.5K', '+18.2%', AppColors.primary, isDark),
                    _buildMobileKPICard('Active Farms', '24', '+12.0%', AppColors.info, isDark),
                    _buildMobileKPICard('Efficiency', '94.2%', '+5.1%', AppColors.warning, isDark),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                // Charts (mobile responsive)
                _buildRevenueChart(isDark, true),
                const SizedBox(height: AppSpacing.md),
                _buildProductionPieChart(isDark, true),
                const SizedBox(height: AppSpacing.md),
                _buildFarmPerformanceChart(isDark, true),
                const SizedBox(height: AppSpacing.md),
                _buildSensorDataChart(isDark, true),
                const SizedBox(height: AppSpacing.md),
                _buildPerformanceTable(isDark, true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileKPICard(String title, String value, String change, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 11, color: color.withOpacity(0.8), fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.arrow_upward, size: 12, color: AppColors.success),
              const SizedBox(width: 2),
              Text(change,
                  style: TextStyle(
                      fontSize: 10, color: AppColors.success, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(bool isDark) {
    final navItems = [
      {'icon': Icons.dashboard_outlined, 'label': 'Dashboard', 'index': 0, 'route': '/dashboard'},
      {'icon': Icons.people_outline, 'label': 'Users', 'index': 1, 'route': '/users'},
      {'icon': Icons.agriculture_outlined, 'label': 'Farms', 'index': 2, 'route': '/farms'},
      {'icon': Icons.sensors_outlined, 'label': 'Sensors', 'index': 3, 'route': '/sensors'},
      {'icon': Icons.analytics_outlined, 'label': 'Analytics', 'index': 4, 'route': '/analytics'},
      {'icon': Icons.settings_outlined, 'label': 'Settings', 'index': 5, 'route': '/settings'},
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
              final isSelected = index == 4; // Analytics screen is index 4

              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (index != 4) {
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

  Widget _buildKPICards(bool isDark) {
    final kpis = [
      {
        'title': 'Total Revenue',
        'value': '\$420K',
        'change': '+23.5%',
        'trend': 'up',
        'icon': Icons.attach_money,
        'color': AppColors.success
      },
      {
        'title': 'Total Production',
        'value': '12.5K',
        'change': '+18.2%',
        'trend': 'up',
        'icon': Icons.inventory,
        'color': AppColors.primary
      },
      {
        'title': 'Active Farms',
        'value': '24',
        'change': '+12.0%',
        'trend': 'up',
        'icon': Icons.agriculture,
        'color': AppColors.info
      },
      {
        'title': 'Efficiency Rate',
        'value': '94.2%',
        'change': '+5.1%',
        'trend': 'up',
        'icon': Icons.trending_up,
        'color': AppColors.warning
      },
    ];

    return Row(
      children: kpis
          .map((kpi) => Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: kpi != kpis.last ? AppSpacing.md : 0),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        (kpi['color'] as Color).withOpacity(0.15),
                        (kpi['color'] as Color).withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(color: (kpi['color'] as Color).withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: (kpi['color'] as Color).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            ),
                            child: Icon(kpi['icon'] as IconData,
                                color: kpi['color'] as Color, size: 22),
                          ),
                          Row(
                            children: [
                              Icon(
                                kpi['trend'] == 'up' ? Icons.arrow_upward : Icons.arrow_downward,
                                size: 14,
                                color: kpi['trend'] == 'up' ? AppColors.success : AppColors.error,
                              ),
                              Text(
                                kpi['change'] as String,
                                style: TextStyle(
                                  color: kpi['trend'] == 'up' ? AppColors.success : AppColors.error,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        kpi['value'] as String,
                        style: AppTypography.h4.copyWith(
                          fontWeight: FontWeight.bold,
                          color: kpi['color'] as Color,
                        ),
                      ),
                      Text(
                        kpi['title'] as String,
                        style: TextStyle(
                          color: (kpi['color'] as Color).withOpacity(0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildRevenueChart(bool isDark, bool isMobile) {
    return Container(
      height: isMobile ? 250 : 350,
      padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue & Expenses Trend',
            style: AppTypography.h6.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontSize: isMobile ? 14 : 18,
            ),
          ),
          SizedBox(height: isMobile ? AppSpacing.sm : AppSpacing.lg),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                        color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                        strokeWidth: 1)),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: isMobile ? 25 : 30,
                      getTitlesWidget: (value, meta) {
                        final labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                        if (value.toInt() < labels.length) {
                          return Text(
                            labels[value.toInt()],
                            style: TextStyle(fontSize: isMobile ? 9 : 10),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      FlSpot(0, 85),
                      FlSpot(1, 92),
                      FlSpot(2, 88),
                      FlSpot(3, 105),
                      FlSpot(4, 115),
                      FlSpot(5, 125)
                    ],
                    isCurved: true,
                    color: AppColors.success,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData:
                        BarAreaData(show: true, color: AppColors.success.withOpacity(0.1)),
                  ),
                  LineChartBarData(
                    spots: [
                      FlSpot(0, 45),
                      FlSpot(1, 48),
                      FlSpot(2, 52),
                      FlSpot(3, 55),
                      FlSpot(4, 58),
                      FlSpot(5, 62)
                    ],
                    isCurved: true,
                    color: AppColors.error,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductionPieChart(bool isDark, bool isMobile) {
    return Container(
      height: isMobile ? 250 : 350,
      padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Production by Type',
            style: AppTypography.h6.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontSize: isMobile ? 14 : 18,
            ),
          ),
          SizedBox(height: isMobile ? AppSpacing.sm : AppSpacing.lg),
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: isMobile ? 30 : 40,
                sections: [
                  PieChartSectionData(
                    value: 35,
                    title: isMobile ? '35%' : 'Vegetables\n35%',
                    color: AppColors.success,
                    radius: isMobile ? 45 : 60,
                    titleStyle: TextStyle(
                      fontSize: isMobile ? 10 : 11,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  PieChartSectionData(
                    value: 25,
                    title: isMobile ? '25%' : 'Fruits\n25%',
                    color: AppColors.warning,
                    radius: isMobile ? 45 : 60,
                    titleStyle: TextStyle(
                      fontSize: isMobile ? 10 : 11,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  PieChartSectionData(
                    value: 20,
                    title: isMobile ? '20%' : 'Dairy\n20%',
                    color: AppColors.info,
                    radius: isMobile ? 45 : 60,
                    titleStyle: TextStyle(
                      fontSize: isMobile ? 10 : 11,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  PieChartSectionData(
                    value: 20,
                    title: isMobile ? '20%' : 'Eggs\n20%',
                    color: AppColors.primary,
                    radius: isMobile ? 45 : 60,
                    titleStyle: TextStyle(
                      fontSize: isMobile ? 10 : 11,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMobile) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                _buildLegendItem('Vegetables', AppColors.success, isDark),
                _buildLegendItem('Fruits', AppColors.warning, isDark),
                _buildLegendItem('Dairy', AppColors.info, isDark),
                _buildLegendItem('Eggs', AppColors.primary, isDark),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.white70 : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildFarmPerformanceChart(bool isDark, bool isMobile) {
    return Container(
      height: isMobile ? 250 : 300,
      padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Farm Performance',
            style: AppTypography.h6.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontSize: isMobile ? 14 : 18,
            ),
          ),
          SizedBox(height: isMobile ? AppSpacing.sm : AppSpacing.lg),
          Expanded(
            child: BarChart(
              BarChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: isMobile ? 25 : 30,
                      getTitlesWidget: (value, meta) {
                        final labels = ['Northern', 'Southern', 'Eastern', 'Western'];
                        if (value.toInt() < labels.length) {
                          return Text(
                            labels[value.toInt()],
                            style: TextStyle(fontSize: isMobile ? 9 : 10),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: 95,
                        color: AppColors.success,
                        width: isMobile ? 15 : 20,
                      )
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: 88,
                        color: AppColors.primary,
                        width: isMobile ? 15 : 20,
                      )
                    ],
                  ),
                  BarChartGroupData(
                    x: 2,
                    barRods: [
                      BarChartRodData(
                        toY: 72,
                        color: AppColors.warning,
                        width: isMobile ? 15 : 20,
                      )
                    ],
                  ),
                  BarChartGroupData(
                    x: 3,
                    barRods: [
                      BarChartRodData(
                        toY: 91,
                        color: AppColors.info,
                        width: isMobile ? 15 : 20,
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorDataChart(bool isDark, bool isMobile) {
    return Container(
      height: isMobile ? 250 : 300,
      padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sensor Readings (24h)',
            style: AppTypography.h6.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontSize: isMobile ? 14 : 18,
            ),
          ),
          SizedBox(height: isMobile ? AppSpacing.sm : AppSpacing.lg),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: const FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      FlSpot(0, 22),
                      FlSpot(4, 24),
                      FlSpot(8, 23),
                      FlSpot(12, 25),
                      FlSpot(16, 24),
                      FlSpot(20, 22),
                      FlSpot(24, 23)
                    ],
                    isCurved: true,
                    color: Colors.orange,
                    barWidth: isMobile ? 1.5 : 2,
                    dotData: const FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: [
                      FlSpot(0, 65),
                      FlSpot(4, 68),
                      FlSpot(8, 66),
                      FlSpot(12, 70),
                      FlSpot(16, 67),
                      FlSpot(20, 65),
                      FlSpot(24, 66)
                    ],
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: isMobile ? 1.5 : 2,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceTable(bool isDark, bool isMobile) {
    final data = [
      {
        'farm': 'Northern Estate',
        'revenue': '\$125K',
        'production': '3.5K',
        'efficiency': '95%',
        'status': 'Excellent'
      },
      {
        'farm': 'Southern Estate',
        'revenue': '\$85K',
        'production': '2.8K',
        'efficiency': '88%',
        'status': 'Good'
      },
      {
        'farm': 'Eastern Farm',
        'revenue': '\$65K',
        'production': '2.1K',
        'efficiency': '72%',
        'status': 'Fair'
      },
      {
        'farm': 'Western Farm',
        'revenue': '\$145K',
        'production': '4.1K',
        'efficiency': '91%',
        'status': 'Excellent'
      },
    ];

    return Container(
      padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Farm Performance Summary',
            style: AppTypography.h6.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontSize: isMobile ? 14 : 18,
            ),
          ),
          SizedBox(height: isMobile ? AppSpacing.sm : AppSpacing.lg),
          isMobile
              ? Column(
                  children: data
                      .map((row) => Container(
                            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                              border: Border.all(
                                  color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  row['farm']!,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: isDark ? Colors.white : AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Revenue: ${row['revenue']}',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color:
                                                isDark ? Colors.white70 : AppColors.textSecondary)),
                                    Text('Production: ${row['production']}',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color:
                                                isDark ? Colors.white70 : AppColors.textSecondary)),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Efficiency: ${row['efficiency']}',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color:
                                                isDark ? Colors.white70 : AppColors.textSecondary)),
                                    _buildTableCell(row['status']!, false, isDark, isStatus: true),
                                  ],
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                )
              : Table(
                  border: TableBorder.all(
                      color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
                  children: [
                    TableRow(
                      decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50),
                      children: [
                        _buildTableCell('Farm', true, isDark),
                        _buildTableCell('Revenue', true, isDark),
                        _buildTableCell('Production', true, isDark),
                        _buildTableCell('Efficiency', true, isDark),
                        _buildTableCell('Status', true, isDark),
                      ],
                    ),
                    ...data.map((row) => TableRow(
                          children: [
                            _buildTableCell(row['farm']!, false, isDark),
                            _buildTableCell(row['revenue']!, false, isDark),
                            _buildTableCell(row['production']!, false, isDark),
                            _buildTableCell(row['efficiency']!, false, isDark),
                            _buildTableCell(row['status']!, false, isDark, isStatus: true),
                          ],
                        )),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildTableCell(String text, bool isHeader, bool isDark, {bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: isStatus
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: text == 'Excellent'
                    ? AppColors.success.withOpacity(0.1)
                    : text == 'Good'
                        ? AppColors.info.withOpacity(0.1)
                        : AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: text == 'Excellent'
                      ? AppColors.success
                      : text == 'Good'
                          ? AppColors.info
                          : AppColors.warning,
                ),
                textAlign: TextAlign.center,
              ),
            )
          : Text(
              text,
              style: TextStyle(
                fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
                fontSize: isHeader ? 12 : 13,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
    );
  }
}
