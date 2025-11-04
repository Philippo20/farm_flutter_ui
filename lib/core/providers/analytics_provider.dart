import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Analytics Data Model
class AnalyticsData {
  final int totalBatches;
  final int activeBatches;
  final int completedBatches;
  final double totalRevenue;
  final double totalCosts;
  final double profitMargin;
  final int totalPlants;
  final int harvestedPlants;
  final double yieldEfficiency;
  final List<ChartDataPoint> productionTrend;
  final List<ChartDataPoint> revenueTrend;
  final Map<String, int> batchesByStatus;
  final Map<String, double> revenueByFarm;

  AnalyticsData({
    required this.totalBatches,
    required this.activeBatches,
    required this.completedBatches,
    required this.totalRevenue,
    required this.totalCosts,
    required this.profitMargin,
    required this.totalPlants,
    required this.harvestedPlants,
    required this.yieldEfficiency,
    required this.productionTrend,
    required this.revenueTrend,
    required this.batchesByStatus,
    required this.revenueByFarm,
  });
}

/// Chart Data Point
class ChartDataPoint {
  final String label;
  final double value;
  final DateTime date;

  ChartDataPoint({
    required this.label,
    required this.value,
    required this.date,
  });
}

/// Time Range Filter
enum TimeRange {
  week('Last 7 Days'),
  month('Last 30 Days'),
  quarter('Last 90 Days'),
  year('Last Year');

  final String label;
  const TimeRange(this.label);
}

/// Analytics State Notifier
class AnalyticsNotifier extends StateNotifier<AnalyticsData> {
  AnalyticsNotifier() : super(_generateMockAnalytics(TimeRange.month));

  TimeRange _currentRange = TimeRange.month;

  void setTimeRange(TimeRange range) {
    _currentRange = range;
    state = _generateMockAnalytics(range);
  }

  TimeRange get currentRange => _currentRange;

  /// Generate mock analytics data
  static AnalyticsData _generateMockAnalytics(TimeRange range) {
    final now = DateTime.now();
    final days = range == TimeRange.week ? 7 : range == TimeRange.month ? 30 : range == TimeRange.quarter ? 90 : 365;

    // Production trend
    final productionTrend = List.generate(days ~/ 7, (index) {
      final date = now.subtract(Duration(days: (days ~/ 7 - index - 1) * 7));
      return ChartDataPoint(
        label: '${date.month}/${date.day}',
        value: 50 + (index * 10) + (index % 3 * 5).toDouble(),
        date: date,
      );
    });

    // Revenue trend
    final revenueTrend = List.generate(days ~/ 7, (index) {
      final date = now.subtract(Duration(days: (days ~/ 7 - index - 1) * 7));
      return ChartDataPoint(
        label: '${date.month}/${date.day}',
        value: 5000 + (index * 800) + (index % 2 * 300).toDouble(),
        date: date,
      );
    });

    return AnalyticsData(
      totalBatches: 156,
      activeBatches: 45,
      completedBatches: 98,
      totalRevenue: 485000,
      totalCosts: 312000,
      profitMargin: 35.7,
      totalPlants: 12500,
      harvestedPlants: 11200,
      yieldEfficiency: 89.6,
      productionTrend: productionTrend,
      revenueTrend: revenueTrend,
      batchesByStatus: {
        'Nursery': 12,
        'Growing': 18,
        'Harvesting': 8,
        'Completed': 98,
        'Cancelled': 13,
      },
      revenueByFarm: {
        'Green Valley': 125000,
        'Sunny Acres': 98000,
        'Fresh Farms': 87000,
        'Urban Greens': 95000,
        'Hydro Haven': 80000,
      },
    );
  }
}

/// Analytics Provider
final analyticsProvider = StateNotifierProvider<AnalyticsNotifier, AnalyticsData>((ref) {
  return AnalyticsNotifier();
});

/// Current Time Range Provider
final timeRangeProvider = Provider<TimeRange>((ref) {
  return ref.watch(analyticsProvider.notifier).currentRange;
});
