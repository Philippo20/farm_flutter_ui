import 'package:farmestates_ai_dashbaord/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SensorTabsContainer extends StatefulWidget {
  final bool isDark;
  const SensorTabsContainer({super.key, required this.isDark});

  @override
  State<SensorTabsContainer> createState() => _SensorTabsContainerState();
}

class _SensorTabsContainerState extends State<SensorTabsContainer>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final tabs = ['Ambient', 'Nutrition', 'Relays'];
  int _selectedIndex = 0;

  get onPressed => null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {
        _selectedIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = widget.isDark;
    final activeColor = isDark ? AppColors.primary : Colors.black;
    final inactiveColor = isDark ? Colors.white.withOpacity(0.6) : Colors.black.withOpacity(0.6);
    final backgroundColor = isDark ? const Color(0xFF232323) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.16) : Colors.black.withOpacity(0.13);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.12 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      height: 615, // Or whatever fixed height fits your layout
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tabs Row
          Container(
            padding: const EdgeInsets.only(top: 16.0, left: 20, right: 20, bottom: 0),
            alignment: Alignment.centerLeft,
            child: Row(
              children: tabs.asMap().entries.map((entry) {
                final index = entry.key;
                final tab = entry.value;
                final isSelected = _selectedIndex == index;
                return GestureDetector(
                  onTap: () => _tabController.animateTo(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: EdgeInsets.only(right: index == tabs.length - 1 ? 0 : 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark
                              ? Colors.white.withOpacity(0.12)
                              : Colors.black.withOpacity(0.06))
                          : Colors.transparent,
                      border: isSelected ? null : Border.all(color: borderColor, width: 1.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      child: Text(
                        tab,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? activeColor : inactiveColor,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          // Tab content area
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAmbientContent(),
                _buildNutritionContent(),
                _buildRelaysContent(),
              ],
            ),
          ),
          SizedBox(height: 15),
        ],
      ),
    );
  }

  Widget _buildAmbientContent() {
    final bool isDark = widget.isDark;
    final containerColor = isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03);
    final textColor = isDark ? Colors.white.withOpacity(0.9) : Colors.black.withOpacity(0.8);
    final secondaryTextColor =
        isDark ? Colors.white.withOpacity(0.6) : Colors.black.withOpacity(0.5);
    final borderColor = isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.15);

    bool isAmbientEnabled = true;
    final currentTemp = 24.5;
    final currentHumidity = 68.0;
    final roomTemp = 22.3;
    final minTemp = 18.0;
    final maxTemp = 28.0;
    final criticalAlerts = 2;
    final onlineSensors = 8;
    final totalSensors = 10;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with toggle
            Padding(
              padding: const EdgeInsets.only(left: 4.0, bottom: 16.0),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.thermostat_outlined, size: 22, color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Text(
                        'ENVIRONMENT MONITORING',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: secondaryTextColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ambient Controls',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.auto_awesome_mosaic_sharp,
                      size: 22,
                      color: widget.isDark ? Colors.white : Colors.black,
                    ),
                    onPressed: () => _handleSystemCommand('view more'),
                  ),
                ],
              ),
            ),

            // Critical Alert Card
            if (criticalAlerts > 0)
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.red.withOpacity(0.15),
                      Colors.red.withOpacity(0.05),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.warning_rounded, color: Colors.red, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'CRITICAL ALERT: TEMPERATURE SPIKE',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.red,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Zone 3 temperature has reached 32.5°C (max safe: 28°C). Cooling system activated.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),

            // Compact 4-Card Row
            SizedBox(
              height: 180,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  const SizedBox(width: 4),
                  _buildCompactSensorCard(
                    icon: Icons.thermostat,
                    title: 'SYSTEM',
                    value: '$currentTemp°C',
                    status: currentTemp > maxTemp ? 'High' : 'Normal',
                    statusColor: currentTemp > maxTemp ? Colors.red : Colors.green,
                    trend: Icons.trending_up,
                    trendColor: Colors.orange,
                    isDark: isDark,
                  ),
                  _buildCompactSensorCard(
                    icon: Icons.water_drop,
                    title: 'HUMIDITY',
                    value: '$currentHumidity%',
                    status: currentHumidity > 70 ? 'High' : 'Optimal',
                    statusColor: currentHumidity > 70 ? Colors.orange : Colors.teal,
                    trend: Icons.trending_flat,
                    trendColor: Colors.green,
                    isDark: isDark,
                  ),
                  _buildCompactSensorCard(
                    icon: Icons.home,
                    title: 'ROOM',
                    value: '$roomTemp°C',
                    status: roomTemp > 25 ? 'Warm' : 'Good',
                    statusColor: roomTemp > 25 ? Colors.orange : Colors.blue,
                    trend: Icons.trending_down,
                    trendColor: Colors.blueAccent,
                    isDark: isDark,
                  ),
                  _buildCompactSensorCard(
                    icon: Icons.settings,
                    title: 'RANGE',
                    value: '${minTemp.toInt()}-${maxTemp.toInt()}°C',
                    status: 'Set',
                    statusColor: Colors.blue,
                    trend: Icons.tune,
                    trendColor: Colors.purple,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Sensor Status Card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
                color: containerColor,
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SENSOR NETWORK STATUS',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: secondaryTextColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSensorStatusIndicator(
                        count: onlineSensors,
                        label: 'Online',
                        color: Colors.green,
                        isDark: isDark,
                      ),
                      _buildSensorStatusIndicator(
                        count: totalSensors - onlineSensors,
                        label: 'Offline',
                        color: Colors.grey,
                        isDark: isDark,
                      ),
                      _buildSensorStatusIndicator(
                        count: criticalAlerts,
                        label: 'Critical',
                        color: Colors.red,
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: onlineSensors / totalSensors,
                    backgroundColor:
                        isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                    color: Colors.green,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactSensorCard({
    required IconData icon,
    required String title,
    required String value,
    required String status,
    required Color statusColor,
    required IconData trend,
    required Color trendColor,
    required bool isDark,
  }) {
    final cardColor = isDark ? Colors.grey[850] : Colors.white;
    final textColor = isDark ? Colors.white : Colors.grey[800];
    final secondaryColor = isDark ? Colors.white60 : Colors.grey[600];

    return Container(
      width: 150,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: cardColor,
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 23, color: statusColor),
                Icon(trend, size: 20, color: trendColor),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: secondaryColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                status,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorStatusIndicator({
    required int count,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    final textColor = isDark ? Colors.white.withOpacity(0.9) : Colors.black.withOpacity(0.8);

    return Column(
      children: [
        Text(
          count.toString(),
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nutrient Monitoring',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: widget.isDark ? Colors.white : Colors.black,
                ),
              ),
              Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  /*
              decoration: BoxDecoration(
                color: widget.isDark ? Colors.grey[800] : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              */
                  child: Row(children: [
                    /*
                  Text(
                    DateFormat('MMM dd, yyyy').format(DateTime.now()),
                    style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: widget.isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              */
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(
                        Icons.auto_awesome_mosaic_sharp,
                        size: 22,
                        color: widget.isDark ? Colors.white : Colors.black,
                      ),
                      onPressed: () => _handleSystemCommand('view system metrics'),
                    ),
                  ])),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Real-time hydroponic system metrics',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: widget.isDark ? Colors.white60 : Colors.black54,
            ),
          ),

          const SizedBox(height: 24),

          // Critical Metrics Cards
          SizedBox(
            height: 160,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: [
                _buildCriticalMetricCard(
                  title: "pH Balance",
                  value: "6.8",
                  status: "Optimal",
                  icon: Icons.linear_scale,
                  isDark: widget.isDark,
                  isCritical: false,
                ),
                const SizedBox(width: 12),
                _buildCriticalMetricCard(
                  title: "EC Level",
                  value: "2.4",
                  status: "Warning",
                  icon: Icons.bolt,
                  isDark: widget.isDark,
                  isCritical: true,
                ),
                const SizedBox(width: 12),
                _buildCriticalMetricCard(
                  title: "Water Temp",
                  value: "22.5°C",
                  status: "Optimal",
                  icon: Icons.thermostat,
                  isDark: widget.isDark,
                  isCritical: false,
                ),
                const SizedBox(width: 12),
                _buildCriticalMetricCard(
                  title: "Dissolved O₂",
                  value: "8.2 mg/L",
                  status: "Optimal",
                  icon: Icons.air,
                  isDark: widget.isDark,
                  isCritical: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Nutrient Levels Section
          Text(
            'Nutrient Concentrations',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: widget.isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          _buildNutrientGauge(
            nutrient: "Nitrogen (N)",
            value: 150,
            unit: "ppm",
            optimalRange: "100-200 ppm",
            currentLevel: 0.75,
            isDark: widget.isDark,
          ),
          _buildNutrientGauge(
            nutrient: "Phosphorus (P)",
            value: 45,
            unit: "ppm",
            optimalRange: "30-50 ppm",
            currentLevel: 0.9,
            isDark: widget.isDark,
          ),
          _buildNutrientGauge(
            nutrient: "Potassium (K)",
            value: 320,
            unit: "ppm",
            optimalRange: "250-400 ppm",
            currentLevel: 0.65,
            isDark: widget.isDark,
          ),
          _buildNutrientGauge(
            nutrient: "Calcium (Ca)",
            value: 180,
            unit: "ppm",
            optimalRange: "150-300 ppm",
            currentLevel: 0.3,
            isDark: widget.isDark,
          ),
          const SizedBox(height: 24),

          // System Status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: widget.isDark ? Colors.grey[900] : Colors.grey[100],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'System Status',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: widget.isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.circle,
                            color: Colors.green[400],
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Active',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.green[400],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildStatusRow(
                  icon: Icons.water,
                  label: "Water Level",
                  value: "85%",
                  isGood: true,
                  isDark: widget.isDark,
                ),
                _buildStatusRow(
                  icon: Icons.power,
                  label: "Pump Status",
                  value: "Running",
                  isGood: true,
                  isDark: widget.isDark,
                ),
                _buildStatusRow(
                  icon: Icons.light_mode,
                  label: "Light Cycle",
                  value: "Day (6h remaining)",
                  isGood: true,
                  isDark: widget.isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCriticalMetricCard({
    required String title,
    required String value,
    required String status,
    required IconData icon,
    required bool isDark,
    required bool isCritical,
  }) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isCritical
            ? (isDark ? Colors.orange[900]!.withOpacity(0.3) : Colors.orange[100])
            : (isDark ? Colors.teal[900]!.withOpacity(0.3) : Colors.teal[100]),
        border: Border.all(
          color: isCritical
              ? (isDark ? Colors.orange[400]! : Colors.orange[600]!)
              : (isDark ? Colors.teal[400]! : Colors.teal[600]!),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icon,
                color: isCritical
                    ? (isDark ? Colors.orange[400] : Colors.orange[600])
                    : (isDark ? Colors.teal[400] : Colors.teal[600]),
              ),
              if (isCritical)
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange[400],
                  size: 20,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            status,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isCritical
                  ? (isDark ? Colors.orange[400] : Colors.orange[600])
                  : (isDark ? Colors.teal[400] : Colors.teal[600]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientGauge({
    required String nutrient,
    required double value,
    required String unit,
    required String optimalRange,
    required double currentLevel,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isDark ? Colors.grey[800] : Colors.white,
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                nutrient,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              Text(
                "$value $unit",
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _getValueColor(value, nutrient, isDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: currentLevel,
            backgroundColor: isDark ? Colors.grey[700] : Colors.grey[200],
            color: _getProgressColor(currentLevel, isDark),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                optimalRange,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              Text(
                _getLevelStatus(currentLevel),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _getProgressColor(currentLevel, isDark),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isGood,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: isGood
                ? (isDark ? Colors.tealAccent[400] : Colors.teal[600])
                : (isDark ? Colors.orange[400] : Colors.orange[600]),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isGood
                  ? (isDark ? Colors.tealAccent[400] : Colors.teal[600])
                  : (isDark ? Colors.orange[400] : Colors.orange[600]),
            ),
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(double value, bool isDark) {
    if (value < 0.3) {
      return Colors.red[400]!;
    } else if (value < 0.7) {
      return isDark ? Colors.orange[300]! : Colors.orange[600]!;
    } else {
      return isDark ? Colors.tealAccent[400]! : Colors.teal[600]!;
    }
  }

  Color _getValueColor(double value, String nutrient, bool isDark) {
    // This would have actual logic based on nutrient type and optimal ranges
    if (value < 50) {
      return Colors.red[400]!;
    } else if (value > 300) {
      return Colors.orange[400]!;
    } else {
      return isDark ? Colors.tealAccent[400]! : Colors.teal[600]!;
    }
  }

  String _getLevelStatus(double level) {
    if (level < 0.3) return "Low";
    if (level < 0.7) return "Normal";
    return "High";
  }

// end of Nutri

// Updated version with correct icons and additional refinements
  Widget _buildRelaysContent() {
    final relays = [
      {'name': 'Water Pump', 'status': true, 'lastActive': '2m', 'icon': Icons.water},
      {'name': 'Grow Lights', 'status': false, 'lastActive': '1h', 'icon': Icons.light_mode},
      {'name': 'Air Pump', 'status': true, 'lastActive': '5m', 'icon': Icons.air},
      {'name': 'Nutrient Mixer', 'status': false, 'lastActive': '30m', 'icon': Icons.blender},
      {'name': 'Heating', 'status': true, 'lastActive': '15m', 'icon': Icons.thermostat},
      {'name': 'Ventilation', 'status': false, 'lastActive': '45m', 'icon': Icons.wind_power},
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Device Controls',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: widget.isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      '${relays.where((r) => r['status'] as bool).length} of ${relays.length} active',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: widget.isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    Icons.settings,
                    size: 22,
                    color: widget.isDark ? Colors.white : Colors.black,
                  ),
                  onPressed: () => _handleSystemCommand('settings'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Horizontal scrollable relay cards
            SizedBox(
              height: 160, // Fixed height for the card row
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  const SizedBox(width: 4),
                  ...relays.map((relay) => _buildCompactRelayCard(
                        name: relay['name'] as String,
                        icon: relay['icon'] as IconData,
                        isActive: relay['status'] as bool,
                        lastActive: relay['lastActive'] as String,
                        isDark: widget.isDark,
                        onToggle: (value) => _handleRelayToggle(relay['name'] as String, value),
                      )),
                  const SizedBox(width: 4),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // System Controls
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildSystemActionButton(
                  icon: Icons.play_arrow,
                  label: 'Start All',
                  color: Colors.green,
                  isDark: widget.isDark,
                  onPressed: () => _handleSystemCommand('start_all'),
                ),
                _buildSystemActionButton(
                  icon: Icons.stop,
                  label: 'Stop All',
                  color: Colors.red,
                  isDark: widget.isDark,
                  onPressed: () => _handleSystemCommand('stop_all'),
                ),
                _buildSystemActionButton(
                  icon: Icons.refresh,
                  label: 'Restart',
                  color: Colors.blue,
                  isDark: widget.isDark,
                  onPressed: () => _handleSystemCommand('restart'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactRelayCard({
    required String name,
    required IconData icon,
    required bool isActive,
    required String lastActive,
    required bool isDark,
    required Function(bool) onToggle,
  }) {
    final activeColor = Colors.teal;
    final inactiveColor = Colors.grey;

    return Container(
      width: 150, // Compact width
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isDark
            ? isActive
                ? activeColor.withOpacity(0.1)
                : Colors.grey[800]!.withOpacity(0.3)
            : isActive
                ? activeColor.withOpacity(0.05)
                : Colors.grey[100],
        border: Border.all(
          color: isActive
              ? activeColor.withOpacity(0.5)
              : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isActive ? activeColor : (isDark ? Colors.grey[500] : Colors.grey[500]),
                ),
                Transform.scale(
                  scale: 0.7,
                  child: Switch(
                    value: isActive,
                    onChanged: onToggle,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    thumbColor: WidgetStateProperty.all(activeColor),
                    trackColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.selected)
                          ? activeColor.withOpacity(0.3)
                          : null,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              name,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: widget.isDark ? Colors.white : Colors.black,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive ? activeColor : inactiveColor,
                    shape: BoxShape.circle,
                  ),
                ),
                Text(
                  lastActive,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: widget.isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleRelayToggle(String deviceName, bool newValue) {
    // Implement your relay toggle logic here
    print('$deviceName toggled to $newValue');
  }

  void _handleSystemCommand(String command) {
    // Implement system-wide command logic
    print('Executing system command: $command');
  }

  Widget _buildSystemActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      icon: Icon(icon, size: 18, color: isDark ? Colors.white : Colors.black),
      label: Text(label, style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black)),
      style: OutlinedButton.styleFrom(
        // foregroundColor: isDark ? color : color[700],
        side: BorderSide(
          color: isDark ? color.withOpacity(0.3) : color.withOpacity(0.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onPressed: onPressed,
    );
  }
}
