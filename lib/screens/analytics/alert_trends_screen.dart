import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/mock_farm_data.dart';

/// Alert Trends Analytics Screen
/// Displays alert trends, patterns, and analytics
class AlertTrendsScreen extends ConsumerStatefulWidget {
  const AlertTrendsScreen({super.key});

  @override
  ConsumerState<AlertTrendsScreen> createState() => _AlertTrendsScreenState();
}

class _AlertTrendsScreenState extends ConsumerState<AlertTrendsScreen> {
  String _selectedPeriod = '7d';
  final List<String> _periods = ['24h', '7d', '30d', '90d'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stats = MockFarmData.getAlertStats();

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: const Text('Alert Trends'),
        actions: [
          IconButton(
            onPressed: () => _exportTrends(),
            icon: const Icon(Icons.download),
            tooltip: 'Export',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period Selector
            _buildPeriodSelector(isDark),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Alert Frequency Chart
            _buildFrequencyChart(isDark),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Severity Distribution
            Row(
              children: [
                Expanded(child: _buildSeverityPieChart(isDark)),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: _buildSensorDistribution(isDark)),
              ],
            ),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Key Metrics
            _buildKeyMetrics(stats, isDark),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Peak Hours Heatmap
            _buildPeakHoursHeatmap(isDark),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Resolution Time Analysis
            _buildResolutionTimeChart(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        children: [
          Text(
            'Time Period:',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: SegmentedButton<String>(
              segments: _periods.map((period) {
                return ButtonSegment(value: period, label: Text(period));
              }).toList(),
              selected: {_selectedPeriod},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() => _selectedPeriod = newSelection.first);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencyChart(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Alert Frequency Over Time',
            style: AppTypography.h6.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark ? Colors.white10 : Colors.black12,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => Text(
                        'D${value.toInt()}',
                        style: AppTypography.bodySmall.copyWith(fontSize: 10),
                      ),
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: _generateFrequencyData(),
                    isCurved: true,
                    color: AppColors.error,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.error.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityPieChart(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'By Severity',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: 30,
                    title: 'High',
                    color: AppColors.error,
                    radius: 60,
                    titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  PieChartSectionData(
                    value: 50,
                    title: 'Medium',
                    color: AppColors.warning,
                    radius: 60,
                    titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  PieChartSectionData(
                    value: 20,
                    title: 'Low',
                    color: AppColors.info,
                    radius: 60,
                    titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorDistribution(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'By Sensor Type',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 20,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const sensors = ['Temp', 'Hum', 'pH', 'EC', 'CO₂'];
                        return Text(
                          sensors[value.toInt() % sensors.length],
                          style: AppTypography.bodySmall.copyWith(fontSize: 9),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(5, (index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: (15 - index * 2).toDouble(),
                        color: AppColors.primary,
                        width: 16,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyMetrics(Map<String, dynamic> stats, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Total Alerts',
            stats['total'].toString(),
            Icons.notifications,
            AppColors.info,
            isDark,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildMetricCard(
            'Avg Resolution',
            '2.5h',
            Icons.timer,
            AppColors.success,
            isDark,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildMetricCard(
            'Reduction',
            '-15%',
            Icons.trending_down,
            AppColors.success,
            isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTypography.h6.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white60 : AppColors.textSecondary,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPeakHoursHeatmap(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Peak Alert Hours',
            style: AppTypography.h6.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(24, (hour) {
              final intensity = (hour >= 6 && hour <= 18) ? 0.7 : 0.3;
              return Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(intensity),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    hour.toString().padLeft(2, '0'),
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildResolutionTimeChart(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Average Resolution Time by Severity',
            style: AppTypography.h6.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildResolutionBar('High Severity', 1.5, AppColors.error, isDark),
          const SizedBox(height: AppSpacing.sm),
          _buildResolutionBar('Medium Severity', 3.2, AppColors.warning, isDark),
          const SizedBox(height: AppSpacing.sm),
          _buildResolutionBar('Low Severity', 5.8, AppColors.info, isDark),
        ],
      ),
    );
  }

  Widget _buildResolutionBar(String label, double hours, Color color, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            Text(
              '${hours}h',
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: hours / 10,
          backgroundColor: isDark ? Colors.white10 : Colors.black12,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  List<FlSpot> _generateFrequencyData() {
    return List.generate(7, (index) {
      return FlSpot(index.toDouble(), (10 + index * 2 - index % 3).toDouble());
    });
  }

  void _exportTrends() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting alert trends...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
