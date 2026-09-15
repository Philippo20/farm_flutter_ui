import 'dart:math' as math;
import 'package:intl/intl.dart';
import '../../../core/utils/registered_sensor_readings.dart';
import '../../../core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Add to pubspec.yaml

class SecondRow extends StatefulWidget {
  final bool isDark;
  final List<Map<String, dynamic>> sensors;
  final List<Map<String, dynamic>> readings;
  final Map<String, List<String>> sensorSerials;
  final double? liveTemperature;
  final List<double>? liveTemperatureHistory;
  final Map<String, int> sensorCounts;
  final Map<String, int> activeSensorCounts;

  const SecondRow({
    super.key,
    required this.isDark,
    this.sensors = const [],
    this.readings = const [],
    this.sensorSerials = const {},
    this.liveTemperature,
    this.liveTemperatureHistory,
    this.sensorCounts = const {},
    this.activeSensorCounts = const {},
  });

  @override
  State<SecondRow> createState() => _SecondRowState();
}

class _SecondRowState extends State<SecondRow> {
  @override
  Widget build(BuildContext context) {
    final sensors = widget.sensors.where((s) => ['humidity', 'temperature', 'water_temperature'].contains(registeredSensorType(s))).toList()
      ..sort((a,b) => sensorText(a, ['serial_number', r'$id', 'id']).compareTo(sensorText(b, ['serial_number', r'$id', 'id'])));
    return Column(children: [
      _buildTempHumTitleContainer(context),
      const SizedBox(height: 16),
      _IndicatorsCard(isDark: widget.isDark),
      if (sensors.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text('No registered sensors assigned.')),
      for (final type in ['humidity', 'temperature', 'water_temperature'])
        for (final sensor in sensors.where((s) => registeredSensorType(s) == type)) ...[
          const SizedBox(height: 16),
          _registeredCard(sensor, type),
        ],
    ]);
  }

  Widget _registeredCard(Map<String, dynamic> sensor, String type) {
    final rows = readingsForRegisteredSensor(sensor, widget.readings);
    final value = rows.isEmpty ? null : registeredReadingValue(rows.last);
    final activity = latestSensorActivity(rows);
    final chart = List.generate(activity.length, (i) => FlSpot(registeredReadingTime(activity[i])!.millisecondsSinceEpoch / 1000, registeredReadingValue(activity[i])!));
    final serial = sensorText(sensor, ['serial_number', r'$id', 'sensor_id', 'id']);
    final unit = sensorText(sensor, ['unit', 'measurement_unit']);
    final card = type == 'humidity'
      ? _humidityCard(humidity: value, isDark: widget.isDark, chartData: chart, serial: serial, unit: unit)
      : type == 'temperature'
        ? _temperatureCard(temperature: value, isDark: widget.isDark, chartData: chart, serial: serial, unit: unit)
        : _waterTemperatureCard(waterTemp: value, isDark: widget.isDark, chartData: chart, serial: serial, unit: unit);
    return KeyedSubtree(key: ValueKey(sensorText(sensor, [r'$id', 'sensor_id', 'id', 'serial_number'])), child: card);
  }

  Widget _areaChart(List<FlSpot> source, Color color, bool isDark) {
    if (source.isEmpty) return const SizedBox(height: 150, child: Center(child: Text('No reading history')));
    // A timestamp identifies one observation. Avoid vertical curves at duplicate times.
    final byTime = <double, FlSpot>{for (final point in source) point.x: point};
    final ordered = byTime.values.toList()..sort((a,b) => a.x.compareTo(b.x));
    final origin = ordered.first.x;
    final points = ordered.map((point) => FlSpot(point.x - origin, point.y)).toList();
    // Leave room for the latest point and its rounded stroke inside the plot.
    final timeSpan = points.last.x - points.first.x;
    final edgeRoom = timeSpan > 0 ? timeSpan * .035 : 1.0;
    final low = points.map((p) => p.y).reduce(math.min);
    final high = points.map((p) => p.y).reduce(math.max);
    final padding = math.max((high - low) * .2, math.max(high.abs() * .01, .1));
    String time(double x) => DateFormat('h:mm:ss a').format(DateTime.fromMillisecondsSinceEpoch(((origin + x) * 1000).round()).toLocal());
    return Tooltip(message: 'Latest continuous readings, up to 15 minutes. Gaps over one minute start a new segment.', child: SizedBox(height: 150, child: LineChart(LineChartData(
        minX: points.first.x - edgeRoom,
        maxX: points.last.x + edgeRoom,
        minY: low - padding, maxY: high + padding,
        clipData: const FlClipData.all(),
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(touchTooltipData: LineTouchTooltipData(
          fitInsideHorizontally: true, fitInsideVertically: true,
          maxContentWidth: 130,
          getTooltipColor: (_) => isDark ? Colors.grey.shade900 : Colors.white,
          getTooltipItems: (spots) => spots.map((spot) => LineTooltipItem(
            '${spot.y.toStringAsFixed(2)}\n${time(spot.x)}\nLatest activity (up to 15 min)',
            AppTypography.bodySmall.copyWith(color: isDark ? Colors.white : Colors.black87),
          )).toList(),
        )),
        lineBarsData: [LineChartBarData(
          spots: points, isCurved: true, curveSmoothness: .4,
          preventCurveOverShooting: true,
          preventCurveOvershootingThreshold: 1,
          color: color, barWidth: 2.5, isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            checkToShowDot: (spot, _) => spot.x == points.last.x,
            getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
              radius: 3, color: color, strokeWidth: 1.5,
              strokeColor: isDark ? Colors.grey[850]! : Colors.white,
            ),
          ),
          belowBarData: BarAreaData(show: true, gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: isDark ? .30 : .24),
              color.withValues(alpha: isDark ? .04 : .02),
            ],
          )),
        )],
      ), duration: Duration.zero)));
  }


  Widget _buildTempHumTitleContainer(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: widget.isDark ? Colors.grey[800] : Colors.redAccent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: widget.isDark ? Colors.grey[700]! : Colors.grey[300]!,
            width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon with rounded transparent background
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: widget.isDark
                  ? Colors.redAccent.withOpacity(0.2)
                  : Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.cloud_circle_rounded,
              color: widget.isDark ? Colors.redAccent : Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // Title
          Expanded(
            child: Text(
              'Temperature & Humidity',
              style: AppTypography.font(
                fontSize: AppTypography.cardTitleSize,
                fontWeight: AppTypography.headingWeight,
                color: widget.isDark ? Colors.white : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _IndicatorsCard({required bool isDark}) {
    final tempCount = widget.sensorCounts['temperature'] ?? 0;
    final humidityCount = widget.sensorCounts['humidity'] ?? 0;
    final waterTempCount = widget.sensorCounts['water_temperature'] ?? 0;
    final activeTemp = (widget.activeSensorCounts['temperature'] ?? 0) > 0;
    final activeHumidity = (widget.activeSensorCounts['humidity'] ?? 0) > 0;
    final activeWaterTemp =
        (widget.activeSensorCounts['water_temperature'] ?? 0) > 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: _indicatorCard(
              icon: Icons.thermostat,
              label: "Temp",
              status: tempCount == 0
                  ? "NO SENSOR"
                  : (activeTemp ? "ACTIVE" : "OFFLINE"),
              count: tempCount,
              isActive: activeTemp,
              color: Colors.orange,
              isDark: isDark,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: _indicatorCard(
              icon: Icons.water_drop,
              label: "Humidity",
              status: humidityCount == 0
                  ? "NO SENSOR"
                  : (activeHumidity ? "ACTIVE" : "OFFLINE"),
              count: humidityCount,
              isActive: activeHumidity,
              color: Colors.blue,
              isDark: isDark,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: _indicatorCard(
              icon: Icons.water,
              label: "Water Temp",
              status: waterTempCount == 0
                  ? "NO SENSOR"
                  : (activeWaterTemp ? "ACTIVE" : "OFFLINE"),
              count: waterTempCount,
              isActive: activeWaterTemp,
              color: Colors.teal,
              isDark: isDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _indicatorCard({
    required IconData icon,
    required String label,
    required String status,
    required int count,
    required bool isActive,
    required Color color,
    required bool isDark,
  }) {
    final isOnline = count > 0 && isActive;
    final effectiveColor = isOnline ? color : Colors.grey;
    final statusColor = count == 0
        ? Colors.grey
        : (isActive
            ? (isDark ? Colors.greenAccent : Colors.green)
            : Colors.red);

    return Container(
      //width: 100,
      padding: const EdgeInsets.fromLTRB(5, 15, 5, 11),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: effectiveColor.withOpacity(isOnline ? 0.2 : 0.12),
                ),
                child: Icon(icon, color: effectiveColor, size: 24),
              ),
              Positioned(
                right: -8,
                top: -8,
                child: _sensorCountBadge(count, isOnline, isDark),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTypography.font(
                fontSize: AppTypography.bodySize,
                fontWeight: AppTypography.labelWeight,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: Text(
              status,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTypography.font(
                fontSize: AppTypography.captionSize,
                fontWeight: AppTypography.headingWeight,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sensorCountBadge(int count, bool isOnline, bool isDark) {
    return Container(
      constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: isOnline
            ? (isDark ? Colors.greenAccent : Colors.green)
            : Colors.grey,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isDark ? Colors.grey[850]! : Colors.grey[100]!,
          width: 2,
        ),
      ),
      child: Text(
        count.toString(),
        textAlign: TextAlign.center,
        style: AppTypography.font(
          fontSize: AppTypography.microSize,
          fontWeight: AppTypography.headingWeight,
          color: count == 0 ? Colors.white : Colors.white,
          height: 1,
        ),
      ),
    );
  }

  Widget _serialLabel(String serial) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
    child: Text('Serial: ${serial.isEmpty ? 'Not provided' : serial}', style: AppTypography.bodySmall.copyWith(color: widget.isDark ? Colors.white60 : Colors.black54)),
  );

  Widget _humidityCard({
    required double? humidity,
    required String serial,
    required String unit,
    required bool isDark,
    required List<FlSpot> chartData,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title & Icon
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Humidity',
                  style: AppTypography.font(
                    fontSize: AppTypography.cardTitleSize,
                    fontWeight: AppTypography.headingWeight,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Icon(
                  Icons.water_drop,
                  color: isDark ? Colors.blue[200] : Colors.blue[700],
                ),
              ],
            ),
          ),

          _serialLabel(serial),
          // Humidity Value
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text(
              humidity == null ? 'No reading' : '${humidity.toStringAsFixed(1)} $unit',
              style: AppTypography.font(
                fontSize: AppTypography.metricSize,
                fontWeight: AppTypography.headingWeight,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),

          // Line Chart without ClipRRect
          Padding(
            padding:
                const EdgeInsets.fromLTRB(10, 0, 12, 0), // paddings, child: ),
            child: _areaChart(chartData, Colors.blue, isDark),
          ),
        ],
      ),
    );
  }

  Widget _temperatureCard({
    required double? temperature,
    required String serial,
    required String unit,
    required bool isDark,
    required List<FlSpot> chartData,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title & Icon
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Temperature',
                  style: AppTypography.font(
                    fontSize: AppTypography.cardTitleSize,
                    fontWeight: AppTypography.headingWeight,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Icon(
                  Icons.thermostat_rounded,
                  color: isDark ? Colors.orange[200] : Colors.orange[700],
                ),
              ],
            ),
          ),

          _serialLabel(serial),
          // Temperature Value
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text(
              temperature == null ? 'No reading' : '${temperature.toStringAsFixed(1)} $unit',
              style: AppTypography.font(
                fontSize: AppTypography.metricSize,
                fontWeight: AppTypography.headingWeight,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),

          // Line Chart
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 12, 0),
            child: _areaChart(chartData, Colors.orange, isDark),
          ),
        ],
      ),
    );
  }

  Widget _waterTemperatureCard({
    required double? waterTemp,
    required String serial,
    required String unit,
    required bool isDark,
    required List<FlSpot> chartData,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title & Icon
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Water Temperature',
                  style: AppTypography.font(
                    fontSize: AppTypography.cardTitleSize,
                    fontWeight: AppTypography.headingWeight,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Icon(
                  Icons.opacity_rounded,
                  color: isDark ? Colors.teal[200] : Colors.teal[700],
                ),
              ],
            ),
          ),

          // Value
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text(
              waterTemp == null ? 'No reading' : '${waterTemp.toStringAsFixed(1)} $unit',
              style: AppTypography.font(
                fontSize: AppTypography.metricSize,
                fontWeight: AppTypography.headingWeight,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),

          // Line Chart
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 12, 0),
            child: _areaChart(chartData, Colors.cyan, isDark),
          ),
        ],
      ),
    );
  }
}
