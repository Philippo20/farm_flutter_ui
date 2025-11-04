import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../models/enums.dart';

/// Sensor History Screen
/// Displays historical sensor data with interactive charts
class SensorHistoryScreen extends ConsumerStatefulWidget {
  const SensorHistoryScreen({super.key});

  @override
  ConsumerState<SensorHistoryScreen> createState() => _SensorHistoryScreenState();
}

class _SensorHistoryScreenState extends ConsumerState<SensorHistoryScreen> {
  String _selectedPeriod = '24h';
  SensorType _selectedSensor = SensorType.temperature;
  
  final List<String> _periods = ['24h', '7d', '30d', '90d'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: const Text('Sensor History'),
        actions: [
          IconButton(
            onPressed: () => _exportData(),
            icon: const Icon(Icons.download),
            tooltip: 'Export Data',
          ),
          IconButton(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sensor Selection
            _buildSensorSelector(isDark),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Period Selection
            _buildPeriodSelector(isDark),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Main Chart
            _buildMainChart(isDark),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Statistics Cards
            _buildStatisticsCards(isDark),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Data Table
            _buildDataTable(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Sensor',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: SensorType.values.map((sensor) {
              final isSelected = _selectedSensor == sensor;
              return FilterChip(
                label: Text(sensor.displayName),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedSensor = sensor;
                  });
                },
                backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
                selectedColor: _getSensorColor(sensor).withOpacity(0.2),
                checkmarkColor: _getSensorColor(sensor),
                labelStyle: AppTypography.bodySmall.copyWith(
                  color: isSelected ? _getSensorColor(sensor) : (isDark ? Colors.white70 : AppColors.textPrimary),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                side: BorderSide(
                  color: isSelected ? _getSensorColor(sensor) : (isDark ? Colors.white24 : Colors.black12),
                ),
              );
            }).toList(),
          ),
        ],
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
                return ButtonSegment(
                  value: period,
                  label: Text(period),
                );
              }).toList(),
              selected: {_selectedPeriod},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _selectedPeriod = newSelection.first;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainChart(bool isDark) {
    final chartData = _generateChartData();
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getSensorIcon(_selectedSensor),
                color: _getSensorColor(_selectedSensor),
                size: 24,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${_selectedSensor.displayName} History',
                style: AppTypography.h6.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                _selectedPeriod,
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? Colors.white60 : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 1,
                  verticalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: isDark ? Colors.white10 : Colors.black12,
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: isDark ? Colors.white10 : Colors.black12,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          _getTimeLabel(value.toInt()),
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 10,
                            color: isDark ? Colors.white60 : AppColors.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(1),
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 10,
                            color: isDark ? Colors.white60 : AppColors.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.black12,
                  ),
                ),
                minX: 0,
                maxX: chartData.length.toDouble() - 1,
                minY: _getMinY(),
                maxY: _getMaxY(),
                lineBarsData: [
                  LineChartBarData(
                    spots: chartData,
                    isCurved: true,
                    color: _getSensorColor(_selectedSensor),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: _getSensorColor(_selectedSensor).withOpacity(0.1),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                      return touchedBarSpots.map((barSpot) {
                        return LineTooltipItem(
                          '${barSpot.y.toStringAsFixed(1)} ${_selectedSensor.unit}',
                          AppTypography.bodySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards(bool isDark) {
    final stats = _calculateStatistics();
    
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Average',
            '${stats['avg']?.toStringAsFixed(1)} ${_selectedSensor.unit}',
            Icons.show_chart,
            AppColors.info,
            isDark,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildStatCard(
            'Maximum',
            '${stats['max']?.toStringAsFixed(1)} ${_selectedSensor.unit}',
            Icons.arrow_upward,
            AppColors.error,
            isDark,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildStatCard(
            'Minimum',
            '${stats['min']?.toStringAsFixed(1)} ${_selectedSensor.unit}',
            Icons.arrow_downward,
            AppColors.success,
            isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable(bool isDark) {
    final data = _generateTableData();
    
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
            'Recent Readings',
            style: AppTypography.h6.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                DataColumn(
                  label: Text(
                    'Time',
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Value',
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Status',
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              rows: data.map((row) {
                return DataRow(
                  cells: [
                    DataCell(Text(row['time'] as String)),
                    DataCell(Text('${row['value']} ${_selectedSensor.unit}')),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(row['status'] as String).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        ),
                        child: Text(
                          row['status'] as String,
                          style: AppTypography.bodySmall.copyWith(
                            color: _getStatusColor(row['status'] as String),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _generateChartData() {
    final random = DateTime.now().millisecondsSinceEpoch;
    final dataPoints = _selectedPeriod == '24h' ? 24 : (_selectedPeriod == '7d' ? 7 : 30);
    
    return List.generate(dataPoints, (index) {
      double value;
      switch (_selectedSensor) {
        case SensorType.temperature:
          value = 18 + (random % 5) + (index % 3);
          break;
        case SensorType.humidity:
          value = 55 + (random % 15) + (index % 5);
          break;
        case SensorType.ph:
          value = 5.8 + (random % 10) / 10;
          break;
        case SensorType.ec:
          value = 1.0 + (random % 5) / 10;
          break;
        case SensorType.co2:
          value = 800 + (random % 400);
          break;
        default:
          value = 20 + (random % 10);
      }
      return FlSpot(index.toDouble(), value);
    });
  }

  List<Map<String, dynamic>> _generateTableData() {
    return List.generate(10, (index) {
      final time = DateTime.now().subtract(Duration(hours: index));
      return {
        'time': '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
        'value': (18 + index % 5).toStringAsFixed(1),
        'status': index % 3 == 0 ? 'Optimal' : (index % 3 == 1 ? 'Warning' : 'Normal'),
      };
    });
  }

  Map<String, double> _calculateStatistics() {
    final data = _generateChartData();
    final values = data.map((spot) => spot.y).toList();
    
    return {
      'avg': values.reduce((a, b) => a + b) / values.length,
      'max': values.reduce((a, b) => a > b ? a : b),
      'min': values.reduce((a, b) => a < b ? a : b),
    };
  }

  double _getMinY() {
    switch (_selectedSensor) {
      case SensorType.temperature:
        return 15;
      case SensorType.humidity:
        return 40;
      case SensorType.ph:
        return 5.0;
      case SensorType.ec:
        return 0.5;
      case SensorType.co2:
        return 400;
      default:
        return 0;
    }
  }

  double _getMaxY() {
    switch (_selectedSensor) {
      case SensorType.temperature:
        return 25;
      case SensorType.humidity:
        return 80;
      case SensorType.ph:
        return 7.0;
      case SensorType.ec:
        return 2.0;
      case SensorType.co2:
        return 1500;
      default:
        return 100;
    }
  }

  String _getTimeLabel(int index) {
    if (_selectedPeriod == '24h') {
      return '${index}h';
    } else if (_selectedPeriod == '7d') {
      return 'D$index';
    } else {
      return 'D$index';
    }
  }

  Color _getSensorColor(SensorType type) {
    switch (type) {
      case SensorType.temperature:
        return AppColors.warning;
      case SensorType.humidity:
        return AppColors.info;
      case SensorType.ph:
        return Colors.purple;
      case SensorType.ec:
        return Colors.orange;
      case SensorType.co2:
        return Colors.grey;
      case SensorType.light:
        return Colors.amber;
      default:
        return AppColors.primary;
    }
  }

  IconData _getSensorIcon(SensorType type) {
    switch (type) {
      case SensorType.temperature:
        return Icons.thermostat;
      case SensorType.humidity:
        return Icons.water_drop;
      case SensorType.ph:
        return Icons.science;
      case SensorType.ec:
        return Icons.electric_bolt;
      case SensorType.co2:
        return Icons.air;
      case SensorType.light:
        return Icons.light_mode;
      default:
        return Icons.sensors;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'optimal':
        return AppColors.success;
      case 'warning':
        return AppColors.warning;
      case 'critical':
        return AppColors.error;
      default:
        return AppColors.info;
    }
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting sensor data...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
