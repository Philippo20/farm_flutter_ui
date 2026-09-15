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
  String _shortSerial(String serial) => serial.length <= 3 ? serial : serial.substring(serial.length - 3);
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
        for (final pair in (type == 'water_temperature'
            ? sensors.where((s) => registeredSensorType(s) == type).map((sensor) => [sensor]).toList()
            : registeredSensorPairs(sensors.where((s) => registeredSensorType(s) == type).toList()))) ...[
          const SizedBox(height: 16),
          pair.length == 2 && type != 'water_temperature'
            ? _pairedCard(pair, type)
            : Column(children: [for (final sensor in pair) _registeredCard(sensor, type)]),
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

  Widget _pairedCard(List<Map<String, dynamic>> sensors, String type) {
    final isDark = widget.isDark;
    final colors = [type == 'humidity' ? Colors.blue : Colors.orange, Colors.teal];
    final histories = sensors.map((sensor) => readingsForRegisteredSensor(sensor, widget.readings)).toList();
    final charts = histories.map((rows) => latestSensorActivity(rows).map((row) => FlSpot(registeredReadingTime(row)!.millisecondsSinceEpoch / 1000, registeredReadingValue(row)!)).toList()).toList();
    final serials = sensors.map((sensor) => sensorText(sensor, ['serial_number', r'$id', 'sensor_id', 'id'])).toList();
    final units = sensors.map((sensor) => sensorText(sensor, ['unit', 'measurement_unit'])).toList();
    Widget reading(int index) => Expanded(child: Column(crossAxisAlignment: index == 0 ? CrossAxisAlignment.start : CrossAxisAlignment.end, children: [
      Text(histories[index].isEmpty ? 'No reading' : '${registeredReadingValue(histories[index].last)!.toStringAsFixed(1)} ${units[index]}',
        textAlign: index == 0 ? TextAlign.left : TextAlign.right,
        style: AppTypography.font(fontSize: AppTypography.metricSize, fontWeight: AppTypography.headingWeight, color: isDark ? Colors.white : Colors.black87)),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(top: 4), child: Icon(Icons.circle, size: 8, color: colors[index])),
        const SizedBox(width: 6),
        Flexible(child: Text('Serial: ${_shortSerial(serials[index])}', style: AppTypography.bodySmall.copyWith(color: isDark ? Colors.white60 : Colors.black54))),
      ]),
    ]));
    return Container(
      key: ValueKey(serials.join('|')),
      width: double.infinity,
      decoration: BoxDecoration(color: isDark ? Colors.grey[850] : Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .08), blurRadius: 6, offset: const Offset(0, 3))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(padding: const EdgeInsets.fromLTRB(16,16,16,0), child: Row(children: [
          Expanded(child: Text(type == 'humidity' ? 'Humidity' : 'Temperature', style: AppTypography.font(fontSize: AppTypography.cardTitleSize, fontWeight: AppTypography.headingWeight, color: isDark ? Colors.white : Colors.black87))),
          Icon(type == 'humidity' ? Icons.water_drop : Icons.thermostat_rounded, color: colors.first),
        ])),
        Padding(padding: const EdgeInsets.fromLTRB(16,8,16,12), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [reading(0), const SizedBox(width: 12), reading(1)])),
        Padding(padding: const EdgeInsets.only(bottom: 6), child: Text('Each sensor scaled independently', textAlign: TextAlign.center, style: AppTypography.caption.copyWith(color: isDark ? Colors.white54 : Colors.black45))),
        // Different units must never share a numerical axis.
        if (units[0] == units[1])
          Padding(padding: const EdgeInsets.fromLTRB(10,0,12,0), child: _areaChart(charts[0], colors[0], isDark, secondary: charts[1], secondaryColor: colors[1], labels: serials))
        else
          for (var i = 0; i < 2; i++) Padding(padding: const EdgeInsets.fromLTRB(10,0,12,0), child: _areaChart(charts[i], colors[i], isDark, labels: [serials[i]])),
      ]),
    );
  }

  Widget _areaChart(List<FlSpot> source, Color color, bool isDark, {List<FlSpot> secondary = const [], Color secondaryColor = Colors.teal, List<String> labels = const []}) {
    if (source.isEmpty && secondary.isEmpty) return const SizedBox(height: 150, child: Center(child: Text('No reading history')));
    List<FlSpot> ordered(List<FlSpot> input) => (<double, FlSpot>{for (final point in input) point.x: point}).values.toList()..sort((a,b) => a.x.compareTo(b.x));
    final rawSeries = [ordered(source), if (secondary.isNotEmpty) ordered(secondary)];
    final allRaw = rawSeries.expand((s) => s).toList()..sort((a,b) => a.x.compareTo(b.x));
    final origin = allRaw.first.x;
    final independent = secondary.isNotEmpty;
    final series = rawSeries.map((items) {
      if (items.isEmpty) return <FlSpot>[];
      final minimum = items.map((p) => p.y).reduce(math.min);
      final maximum = items.map((p) => p.y).reduce(math.max);
      return items.map((point) => FlSpot(point.x - origin,
        !independent ? point.y : maximum == minimum ? .5 : .14 + .72 * (point.y - minimum) / (maximum - minimum))).toList();
    }).toList();
    final points = series.expand((s) => s).toList()..sort((a,b) => a.x.compareTo(b.x));
    final seriesColors = [color, secondaryColor];
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
        minY: independent ? 0 : low - padding, maxY: independent ? 1 : high + padding,
        clipData: const FlClipData.all(),
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(touchTooltipData: LineTouchTooltipData(
          fitInsideHorizontally: true, fitInsideVertically: true,
          maxContentWidth: 130,
          getTooltipColor: (_) => Colors.grey.shade900,
          getTooltipItems: (spots) => spots.map((spot) => LineTooltipItem(
            '${spot.barIndex < labels.length ? _shortSerial(labels[spot.barIndex]) + '\n' : ''}${rawSeries[spot.barIndex][spot.spotIndex].y.toStringAsFixed(2)}\n${time(spot.x)}',
            AppTypography.bodySmall.copyWith(color: Colors.white),
          )).toList(),
        )),
        lineBarsData: [for (var index = 0; index < series.length; index++) LineChartBarData(
          spots: series[index], isCurved: true, curveSmoothness: .4,
          preventCurveOverShooting: true,
          preventCurveOvershootingThreshold: 1,
          color: seriesColors[index], barWidth: 2.5, isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            checkToShowDot: (spot, _) => series[index].isNotEmpty && spot.x == series[index].last.x,
            getDotPainter: (spot, percent, bar, spotIndex) => FlDotCirclePainter(
              radius: 3, color: seriesColors[index], strokeWidth: 1.5,
              strokeColor: isDark ? Colors.grey[850]! : Colors.white,
            ),
          ),
          belowBarData: BarAreaData(show: true, gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [
              seriesColors[index].withValues(alpha: isDark ? .30 : .24),
              seriesColors[index].withValues(alpha: isDark ? .04 : .02),
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
    child: Text('Serial: ${serial.isEmpty ? 'Not provided' : _shortSerial(serial)}', style: AppTypography.bodySmall.copyWith(color: widget.isDark ? Colors.white60 : Colors.black54)),
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
