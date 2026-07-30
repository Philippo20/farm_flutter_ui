import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart'; // Add to pubspec.yaml

class ThirdRow extends StatefulWidget {
  final bool isDark;
  final Map<String, int> sensorCounts;
  final Map<String, int> activeSensorCounts;

  const ThirdRow({
    super.key,
    required this.isDark,
    this.sensorCounts = const {},
    this.activeSensorCounts = const {},
  });

  @override
  State<ThirdRow> createState() => _ThirdRowState();
}

class _ThirdRowState extends State<ThirdRow> {
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

  @override
  Widget build(BuildContext context) {
    final phData = [
      FlSpot(0, 6.2),
      FlSpot(1, 6.4),
      FlSpot(2, 6.3),
      FlSpot(3, 6.6),
      FlSpot(4, 6.5),
    ];

    final cO2data = [
      FlSpot(0, 40),
      FlSpot(1, 45),
      FlSpot(2, 50),
      FlSpot(3, 48),
      FlSpot(4, 52),
      FlSpot(5, 55),
      FlSpot(6, 53),
    ];

    final timeLabels = ['12:00', '13:00', '14:00', '15:00', '16:00'];

    return Column(
      children: [
        _buildSensorTitleContainer(),
        const SizedBox(height: 16),
        _buildSensorIndicatorsCard(),
        const SizedBox(height: 16),
        _sensorGaugeCards(),
        const SizedBox(height: 16),
        _chartCard(
          title: "pH Level",
          value: 6.35,
          chartData: phData,
          isDark: widget.isDark,
          timeLabels: timeLabels,
        ),
        const SizedBox(height: 16),
        _co2SensorCard(co2: 24.5, isDark: widget.isDark, chartData: cO2data),
      ],
    );
  }

  Widget _buildSensorTitleContainer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDark ? Colors.grey[800] : Colors.green,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isDark ? Colors.grey[700]! : Colors.grey[300]!,
          width: 1,
        ),
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.isDark
                  ? Colors.green.withOpacity(0.2)
                  : Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.thermostat,
              color: widget.isDark ? Colors.green : Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'EC, PH, TDS & CO₂',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: widget.isDark ? Colors.white : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorIndicatorsCard() {
    final tdsCount = widget.sensorCounts['tds'] ?? 0;
    final ecCount = widget.sensorCounts['ec'] ?? 0;
    final phCount = widget.sensorCounts['ph'] ?? 0;
    final co2Count = widget.sensorCounts['co2'] ?? 0;
    final activeTds = (widget.activeSensorCounts['tds'] ?? 0) > 0;
    final activeEc = (widget.activeSensorCounts['ec'] ?? 0) > 0;
    final activePh = (widget.activeSensorCounts['ph'] ?? 0) > 0;
    final activeCo2 = (widget.activeSensorCounts['co2'] ?? 0) > 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSensorCard(
          icon: Icons.science,
          label: 'TDS',
          status:
              tdsCount == 0 ? 'NO SENSOR' : (activeTds ? 'ACTIVE' : 'OFFLINE'),
          count: tdsCount,
          isActive: activeTds,
          color: Colors.blue,
        ),
        _buildSensorCard(
          icon: Icons.bubble_chart,
          label: 'EC',
          status:
              ecCount == 0 ? 'NO SENSOR' : (activeEc ? 'ACTIVE' : 'OFFLINE'),
          count: ecCount,
          isActive: activeEc,
          color: Colors.purple,
        ),
        _buildSensorCard(
          icon: Icons.opacity,
          label: 'PH',
          status:
              phCount == 0 ? 'NO SENSOR' : (activePh ? 'ACTIVE' : 'OFFLINE'),
          count: phCount,
          isActive: activePh,
          color: Colors.orange,
        ),
        _buildSensorCard(
          icon: Icons.cloud_outlined,
          label: 'CO₂',
          status:
              co2Count == 0 ? 'NO SENSOR' : (activeCo2 ? 'ACTIVE' : 'OFFLINE'),
          count: co2Count,
          isActive: activeCo2,
          color: Colors.teal,
        ),
      ],
    );
  }

  Widget _buildSensorCard({
    required IconData icon,
    required String label,
    required String status,
    required int count,
    required bool isActive,
    required Color color,
  }) {
    final isOnline = count > 0 && isActive;
    final effectiveColor = isOnline ? color : Colors.grey;
    final statusColor = count == 0
        ? Colors.grey
        : (isActive
            ? (widget.isDark ? Colors.greenAccent : Colors.green)
            : Colors.red);

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Container(
          padding: const EdgeInsets.fromLTRB(5, 10, 5, 15),
          decoration: BoxDecoration(
            color: widget.isDark ? Colors.grey[850] : Colors.grey[100],
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
                    child: _sensorCountBadge(count, isOnline),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: widget.isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              Text(
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _sensorCountBadge(int count, bool isOnline) {
    return Container(
      constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: isOnline
            ? (widget.isDark ? Colors.greenAccent : Colors.green)
            : Colors.grey,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: widget.isDark ? Colors.grey[850]! : Colors.grey[100]!,
          width: 2,
        ),
      ),
      child: Text(
        count.toString(),
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          height: 1,
        ),
      ),
    );
  }

  Widget _sensorGaugeCards() {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: _sensorGaugeCard(
              icon: Icons.bubble_chart,
              value: "2.1",
              label: "EC Level",
              color: Colors.purple,
              isDark: widget.isDark,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: _sensorGaugeCard(
              icon: Icons.science,
              value: "850",
              label: "TDS Value",
              color: Colors.blue,
              isDark: widget.isDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sensorGaugeCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          // Gauge with Icon in the middle
          SizedBox(
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(double.infinity, 80),
                  painter: _HalfGaugePainter(color: color),
                ),
                Positioned(
                  bottom: 1, // Adjust vertical position as needed
                  child: Container(
                    padding: const EdgeInsets.all(
                        8), // Adjust padding to control icon size relative to background
                    decoration: BoxDecoration(
                      color: color.withOpacity(
                          0.2), // Semi-transparent version of your icon color
                      shape: BoxShape
                          .circle, // Makes the background perfectly round
                    ),
                    child: Icon(
                      icon,
                      size: 30, // Adjust size to fit well with the background
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Value Text
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),

          // Label
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartCard({
    required String title,
    required double value,
    required List<FlSpot> chartData,
    required bool isDark,
    required List<String> timeLabels,
  }) {
    return Container(
      height: 292,
      width: double.infinity,
      // padding: const EdgeInsets.all(16),
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
          // Title and pH Value
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value.toStringAsFixed(2),
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          // Chart (second column, takes full width to bottom)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 15, 1),
            child: SizedBox(
              height: 176,
              width: double.infinity,
              child: LineChart(
                LineChartData(
                  lineTouchData: _boundedTouchData(isDark),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    drawHorizontalLine: true,
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          );
                        },
                        interval: 0.1,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();
                          if (index >= 0 && index < timeLabels.length) {
                            return Text(
                              timeLabels[index],
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            );
                          } else {
                            return const Text('');
                          }
                        },
                      ),
                    ),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: const Border(
                      left: BorderSide(color: Colors.grey),
                      bottom: BorderSide(color: Colors.grey),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: chartData,
                      isCurved: true,
                      color:
                          isDark ? Colors.pinkAccent[100] : Colors.pinkAccent,
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
                                  Colors.pinkAccent.withOpacity(0.3),
                                  Colors.pinkAccent.withOpacity(0.05),
                                ]
                              : [
                                  Colors.pink.withOpacity(0.3),
                                  Colors.pink.withOpacity(0.05),
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

  Widget _co2SensorCard({
    required double co2,
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
                  'Co2 Sensor',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Icon(
                  Icons.cloud_outlined,
                  color: isDark ? Colors.orange[200] : Colors.orange[700],
                ),
              ],
            ),
          ),

          // Temperature Value
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text(
              "${co2.toStringAsFixed(1)}ppm",
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
}

class _HalfGaugePainter extends CustomPainter {
  final Color color;

  _HalfGaugePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height * 2);
    canvas.drawArc(rect, -3.14, 3.14, false, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
