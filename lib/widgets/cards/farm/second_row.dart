import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart'; // Add to pubspec.yaml

class SecondRow extends StatefulWidget {
  final bool isDark;
  final double? liveTemperature;
  final List<double>? liveTemperatureHistory;
  final Map<String, int> sensorCounts;
  final Map<String, int> activeSensorCounts;

  const SecondRow({
    super.key,
    required this.isDark,
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
    final humidityData = [
      FlSpot(0, 40),
      FlSpot(1, 45),
      FlSpot(2, 50),
      FlSpot(3, 48),
      FlSpot(4, 52),
      FlSpot(5, 55),
      FlSpot(6, 53),
    ];
    final temperature = widget.liveTemperature ?? 24.5;
    final temperatureData =
        _sensorChartData(widget.liveTemperatureHistory, temperature);

    return Column(
      children: [
        _buildTempHumTitleContainer(context),
        SizedBox(height: 16),
        _IndicatorsCard(isDark: widget.isDark),
        SizedBox(height: 16),
        _humidityCard(
            humidity: 53.5, isDark: widget.isDark, chartData: humidityData),
        SizedBox(height: 16),
        _temperatureCard(
            temperature: temperature,
            isDark: widget.isDark,
            chartData: temperatureData),
        SizedBox(height: 16),
        _waterTemperatureCard(
            waterTemp: 24.5, isDark: widget.isDark, chartData: humidityData),
      ],
    );
  }

  List<FlSpot> _sensorChartData(List<double>? values, double fallback) {
    final source = (values == null || values.isEmpty) ? [fallback] : values;
    final limited =
        source.length > 12 ? source.sublist(source.length - 12) : source;
    if (limited.length == 1) {
      return [
        FlSpot(0, limited.first),
        FlSpot(1, limited.first),
      ];
    }
    return List.generate(
      limited.length,
      (index) => FlSpot(index.toDouble(), limited[index]),
    );
  }

  LineTouchData _boundedTouchData(bool isDark) {
    return LineTouchData(
      touchTooltipData: LineTouchTooltipData(
        fitInsideHorizontally: true,
        fitInsideVertically: true,
        tooltipMargin: 8,
        tooltipPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        maxContentWidth: 72,
        getTooltipColor: (_) => isDark ? Colors.grey[900]! : Colors.white,
        getTooltipItems: (spots) => spots
            .map(
              (spot) => LineTooltipItem(
                spot.y.toStringAsFixed(1),
                GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            )
            .toList(),
      ),
    );
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
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
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
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
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
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
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
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: count == 0 ? Colors.white : Colors.white,
          height: 1,
        ),
      ),
    );
  }

  Widget _humidityCard({
    required double humidity,
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
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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

          // Humidity Value
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text(
              "${humidity.toStringAsFixed(1)}%",
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),

          // Line Chart without ClipRRect
          Padding(
            padding:
                const EdgeInsets.fromLTRB(10, 0, 12, 0), // paddings, child: ),
            child: SizedBox(
              height: 80,
              width: double.infinity,
              child: LineChart(
                LineChartData(
                  lineTouchData: _boundedTouchData(isDark),
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: chartData,
                      isCurved: true,
                      color: isDark ? Colors.blue[200] : Colors.blue[700],
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: isDark
                              ? [
                                  Colors.blue.withOpacity(0.3),
                                  Colors.blue.withOpacity(0.05),
                                ]
                              : [
                                  Colors.blueAccent.withOpacity(0.3),
                                  Colors.blueAccent.withOpacity(0.05),
                                ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _temperatureCard({
    required double temperature,
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
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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

          // Temperature Value
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text(
              "${temperature.toStringAsFixed(1)}°C",
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),

          // Line Chart
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 12, 0),
            child: SizedBox(
              height: 80,
              width: double.infinity,
              child: LineChart(
                LineChartData(
                  lineTouchData: _boundedTouchData(isDark),
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: chartData,
                      isCurved: true,
                      color: isDark ? Colors.orange[200] : Colors.orange[700],
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: isDark
                              ? [
                                  Colors.orange.withOpacity(0.3),
                                  Colors.orange.withOpacity(0.05),
                                ]
                              : [
                                  Colors.deepOrange.withOpacity(0.3),
                                  Colors.deepOrange.withOpacity(0.05),
                                ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _waterTemperatureCard({
    required double waterTemp,
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
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
              "${waterTemp.toStringAsFixed(1)}°C",
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),

          // Line Chart
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 12, 0),
            child: SizedBox(
              height: 80,
              width: double.infinity,
              child: LineChart(
                LineChartData(
                  lineTouchData: _boundedTouchData(isDark),
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: chartData,
                      isCurved: true,
                      color: isDark ? Colors.teal[200] : Colors.teal[700],
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: isDark
                              ? [
                                  Colors.teal.withOpacity(0.3),
                                  Colors.teal.withOpacity(0.05),
                                ]
                              : [
                                  Colors.tealAccent.withOpacity(0.3),
                                  Colors.tealAccent.withOpacity(0.05),
                                ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
