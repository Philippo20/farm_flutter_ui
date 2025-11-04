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
  String _selectedMetric = 'Revenue';
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Row(
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
                                Text('Analytics Dashboard', style: AppTypography.h4.copyWith(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)),
                                Text('Comprehensive insights and performance metrics', style: AppTypography.bodyMedium.copyWith(color: isDark ? Colors.white70 : AppColors.textSecondary)),
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
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 2, child: _buildRevenueChart(isDark)),
                            const SizedBox(width: AppSpacing.lg),
                            Expanded(child: _buildProductionPieChart(isDark)),
                          ],
                        ),
                        
                        const SizedBox(height: AppSpacing.xl),
                        
                        // Second Row Charts
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildFarmPerformanceChart(isDark)),
                            const SizedBox(width: AppSpacing.lg),
                            Expanded(child: _buildSensorDataChart(isDark)),
                          ],
                        ),
                        
                        const SizedBox(height: AppSpacing.xl),
                        
                        // Performance Table
                        _buildPerformanceTable(isDark),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildKPICards(bool isDark) {
    final kpis = [
      {'title': 'Total Revenue', 'value': '\$420K', 'change': '+23.5%', 'trend': 'up', 'icon': Icons.attach_money, 'color': AppColors.success},
      {'title': 'Total Production', 'value': '12.5K', 'change': '+18.2%', 'trend': 'up', 'icon': Icons.inventory, 'color': AppColors.primary},
      {'title': 'Active Farms', 'value': '24', 'change': '+12.0%', 'trend': 'up', 'icon': Icons.agriculture, 'color': AppColors.info},
      {'title': 'Efficiency Rate', 'value': '94.2%', 'change': '+5.1%', 'trend': 'up', 'icon': Icons.trending_up, 'color': AppColors.warning},
    ];
    
    return Row(
      children: kpis.map((kpi) => Expanded(
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
                    child: Icon(kpi['icon'] as IconData, color: kpi['color'] as Color, size: 22),
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
      )).toList(),
    );
  }
  
  Widget _buildRevenueChart(bool isDark) {
    return Container(
      height: 350,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Revenue & Expenses Trend', style: AppTypography.h6.copyWith(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05), strokeWidth: 1)),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                        if (value.toInt() < labels.length) {
                          return Text(labels[value.toInt()], style: const TextStyle(fontSize: 10));
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [FlSpot(0, 85), FlSpot(1, 92), FlSpot(2, 88), FlSpot(3, 105), FlSpot(4, 115), FlSpot(5, 125)],
                    isCurved: true,
                    color: AppColors.success,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: AppColors.success.withOpacity(0.1)),
                  ),
                  LineChartBarData(
                    spots: [FlSpot(0, 45), FlSpot(1, 48), FlSpot(2, 52), FlSpot(3, 55), FlSpot(4, 58), FlSpot(5, 62)],
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
  
  Widget _buildProductionPieChart(bool isDark) {
    return Container(
      height: 350,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Production by Type', style: AppTypography.h6.copyWith(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(value: 35, title: 'Vegetables\n35%', color: AppColors.success, radius: 60, titleStyle: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                  PieChartSectionData(value: 25, title: 'Fruits\n25%', color: AppColors.warning, radius: 60, titleStyle: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                  PieChartSectionData(value: 20, title: 'Dairy\n20%', color: AppColors.info, radius: 60, titleStyle: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                  PieChartSectionData(value: 20, title: 'Eggs\n20%', color: AppColors.primary, radius: 60, titleStyle: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFarmPerformanceChart(bool isDark) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Farm Performance', style: AppTypography.h6.copyWith(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)),
          const SizedBox(height: AppSpacing.lg),
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
                      getTitlesWidget: (value, meta) {
                        final labels = ['Northern', 'Southern', 'Eastern', 'Western'];
                        if (value.toInt() < labels.length) {
                          return Text(labels[value.toInt()], style: const TextStyle(fontSize: 10));
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 95, color: AppColors.success, width: 20)]),
                  BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 88, color: AppColors.primary, width: 20)]),
                  BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 72, color: AppColors.warning, width: 20)]),
                  BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 91, color: AppColors.info, width: 20)]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSensorDataChart(bool isDark) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sensor Readings (24h)', style: AppTypography.h6.copyWith(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)),
          const SizedBox(height: AppSpacing.lg),
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
                    spots: [FlSpot(0, 22), FlSpot(4, 24), FlSpot(8, 23), FlSpot(12, 25), FlSpot(16, 24), FlSpot(20, 22), FlSpot(24, 23)],
                    isCurved: true,
                    color: Colors.orange,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: [FlSpot(0, 65), FlSpot(4, 68), FlSpot(8, 66), FlSpot(12, 70), FlSpot(16, 67), FlSpot(20, 65), FlSpot(24, 66)],
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 2,
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
  
  Widget _buildPerformanceTable(bool isDark) {
    final data = [
      {'farm': 'Northern Estate', 'revenue': '\$125K', 'production': '3.5K', 'efficiency': '95%', 'status': 'Excellent'},
      {'farm': 'Southern Estate', 'revenue': '\$85K', 'production': '2.8K', 'efficiency': '88%', 'status': 'Good'},
      {'farm': 'Eastern Farm', 'revenue': '\$65K', 'production': '2.1K', 'efficiency': '72%', 'status': 'Fair'},
      {'farm': 'Western Farm', 'revenue': '\$145K', 'production': '4.1K', 'efficiency': '91%', 'status': 'Excellent'},
    ];
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Farm Performance Summary', style: AppTypography.h6.copyWith(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)),
          const SizedBox(height: AppSpacing.lg),
          Table(
            border: TableBorder.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
            children: [
              TableRow(
                decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50),
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
                color: text == 'Excellent' ? AppColors.success.withOpacity(0.1) : text == 'Good' ? AppColors.info.withOpacity(0.1) : AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: text == 'Excellent' ? AppColors.success : text == 'Good' ? AppColors.info : AppColors.warning,
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
