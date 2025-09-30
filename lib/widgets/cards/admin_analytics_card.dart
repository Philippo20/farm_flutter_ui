import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../constants/colors.dart';

class AnalyticsDashboard extends StatelessWidget {
  final bool isDark;

  
  const AnalyticsDashboard({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
   final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 1025; // Adjust breakpoint as needed 627.00

     return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: isSmallScreen
            ? Column(
                children: [
                  _BarChartCard(isDark: isDark),
                  const SizedBox(height: 20),
                  _PieChartCard(isDark: isDark),
                ],
              )
            : IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: _BarChartCard(isDark: isDark),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 4,
                      child: _PieChartCard(isDark: isDark),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
  


class _BarChartCard extends StatelessWidget {
  final bool isDark;

  const _BarChartCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600; // Adjust breakpoint as needed

    final cardColor = isDark ? AppColors.darkCard : AppColors.card;
    final textColor = isDark ? AppColors.darkText : AppColors.text;
    final secondaryTextColor =
        isDark ? AppColors.darkText.withOpacity(0.7) : AppColors.text.withOpacity(0.7);
    final gridColor =
        isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1);

    // Bar chart data
    final barData = [
      BarData('Mon', 12.5, AppColors.primary),
      BarData('Tue', 14.2, const Color(0xFF4CAF50)),
      BarData('Wed', 8.7, const Color(0xFF2196F3)),
      BarData('Thu', 11.3, const Color(0xFFFFC107)),
      BarData('Fri', 15.8, const Color.fromARGB(255, 167, 2, 2)),
      BarData('Sat', 9.4, const Color(0xFF9C27B0)),
      BarData('Sun', 13.1, const Color(0xFFFF9800)),
    ];

    // All content in a column
    Widget content = Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Energy Consumption",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Last 7 Days",
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Average: 12.1 kWh/day",
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: secondaryTextColor,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 320,
            width: isSmallScreen ? 420 : null, // Ensures chart fits on small screens
            child: BarChart(
              BarChartData(
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipPadding: const EdgeInsets.all(12),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY} kWh',
                        GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color:  Colors.white,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < barData.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              barData[index].day,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: secondaryTextColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                      reservedSize: 28,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: secondaryTextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                      reservedSize: 32,
                      interval: 5,
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(color: gridColor, width: 1),
                    left: BorderSide(color: gridColor, width: 1),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 5,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: gridColor,
                    strokeWidth: 1,
                  ),
                ),
                barGroups: barData
                    .asMap()
                    .entries
                    .map((entry) {
                      final index = entry.key;
                      final data = entry.value;
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: data.value,
                            color: data.color,
                            width: 16,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                        showingTooltipIndicators: isSmallScreen ? [1] :  [0],
                      );
                    })
                    .toList(),
                maxY: 20,
                alignment: BarChartAlignment.spaceAround,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              _StatIndicator(
                label: "Peak Usage",
                value: "15.8 kWh",
                color: const Color(0xFFE91E63),
                isDark: isDark,
              ),
              _StatIndicator(
                label: "Lowest Usage",
                value: "8.7 kWh",
                color: const Color(0xFF2196F3),
                isDark: isDark,
              ),
              _StatIndicator(
                label: "Total Weekly",
                value: "84.8 kWh",
                color: AppColors.primary,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: isSmallScreen
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 470, // or tweak as needed for your content
                child: content,
              ),
            )
          : content,
    );
  }
}


class _PieChartCard extends StatefulWidget {
  final bool isDark;
  const _PieChartCard({required this.isDark});

  @override
  State<_PieChartCard> createState() => _PieChartCardState();
}

class _PieChartCardState extends State<_PieChartCard> {
  int? _hoveredIndex;
  
  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final isSmallScreen = MediaQuery.of(context).size.width < 600; // Adjust breakpoint as needed
  
    final cardColor = isDark
        ? const Color(0xFF20232C)
        : Colors.white;
    final textColor = isDark
        ? Colors.white
        : const Color(0xFF232535);
    final secondaryTextColor = isDark
        ? Colors.white70
        : Colors.black.withOpacity(0.65);

    // Pie chart data
    final pieData = [
      PieData('Lights', 35, const Color(0xFF4CAF50), Icons.lightbulb_outline),
      PieData('HVAC', 25, const Color(0xFF2196F3), Icons.ac_unit),
      PieData('Pumps', 20, const Color(0xFFFFC107), Icons.water_damage),
      PieData('Sensors', 12, const Color(0xFF9C27B0), Icons.sensors),
      PieData('Other', 8, const Color(0xFF607D8B), Icons.devices_other),
    ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.11 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Energy Distribution",
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: 0.2,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.filter_alt_outlined, color: AppColors.primary),
                  onPressed: () {},
                  tooltip: "Filter data",
                ),
              ],
            ),
            Text(
              "by equipment category",
              style: GoogleFonts.inter(
                fontSize: 13.5,
                color: secondaryTextColor,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 18),

            // Responsive content layout
            isSmallScreen 
                ? Column(
                    children: [
                      // Pie chart on top for mobile
                      SizedBox(
                        height: 220,
                        child: MouseRegion(
                          onExit: (_) => setState(() => _hoveredIndex = null),
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 1.2,
                              centerSpaceRadius: 50,
                              sections: List.generate(pieData.length, (i) {
                                final isHovered = _hoveredIndex == i;
                                return PieChartSectionData(
                                  value: pieData[i].percent.toDouble(),
                                  color: pieData[i].color,
                                  radius: isHovered ? 70 : 65,
                                  showTitle: isHovered,
                                  title: isHovered ? pieData[i].category : '',
                                  titleStyle: GoogleFonts.poppins(
                                    fontSize: isHovered ? 14 : 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                  titlePositionPercentageOffset: 0.6,
                                  borderSide: BorderSide(
                                    color: isHovered
                                        ? pieData[i].color.withOpacity(0.25)
                                        : Colors.white.withOpacity(0.08),
                                    width: isHovered ? 3 : 1.5,
                                  ),
                                );
                              }),
                              pieTouchData: PieTouchData(
                                touchCallback: (event, pieTouchResponse) {
                                  final idx = pieTouchResponse?.touchedSection?.touchedSectionIndex;
                                  setState(() {
                                    if (event.isInterestedForInteractions && idx != null) {
                                      _hoveredIndex = idx;
                                    } else if (event is FlTapUpEvent || event is FlLongPressEnd || event is FlPanEndEvent) {
                                      _hoveredIndex = null;
                                    }
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Breakdown list below for mobile
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: pieData
                            .map((item) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 13,
                                        height: 13,
                                        decoration: BoxDecoration(
                                          color: item.color,
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Icon(item.icon, size: 17, color: item.color.withOpacity(0.82)),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          item.category,
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w600,
                                            color: textColor,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        "${item.percent}%",
                                        style: GoogleFonts.poppins(
                                          color: item.color,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Equipment breakdown (left)
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: pieData
                              .map((item) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 13,
                                          height: 13,
                                          decoration: BoxDecoration(
                                            color: item.color,
                                            borderRadius: BorderRadius.circular(5),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Icon(item.icon, size: 17, color: item.color.withOpacity(0.82)),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            item.category,
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w600,
                                              color: textColor,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          "${item.percent}%",
                                          style: GoogleFonts.poppins(
                                            color: item.color,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                      // Pie chart (center)
                      Expanded(
                        flex: 6,
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: MouseRegion(
                            onExit: (_) => setState(() => _hoveredIndex = null),
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 1.2,
                                centerSpaceRadius: 60,
                                sections: List.generate(pieData.length, (i) {
                                  final isHovered = _hoveredIndex == i;
                                  return PieChartSectionData(
                                    value: pieData[i].percent.toDouble(),
                                    color: pieData[i].color,
                                    radius: isHovered ? 80 : 75,
                                    showTitle: isHovered,
                                    title: isHovered ? pieData[i].category: '',
                                    titleStyle: GoogleFonts.poppins(
                                      fontSize: isHovered ? 17 : 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                    titlePositionPercentageOffset: 0.58,
                                    borderSide: BorderSide(
                                      color: isHovered
                                          ? pieData[i].color.withOpacity(0.25)
                                          : Colors.white.withOpacity(0.08),
                                      width: isHovered ? 4 : 2,
                                    ),
                                  );
                                }),
                                pieTouchData: PieTouchData(
                                  touchCallback: (event, pieTouchResponse) {
                                    final idx = pieTouchResponse?.touchedSection?.touchedSectionIndex;
                                    setState(() {
                                      if (event.isInterestedForInteractions && idx != null) {
                                        _hoveredIndex = idx;
                                      } else if (event is FlTapUpEvent || event is FlLongPressEnd || event is FlPanEndEvent) {
                                        _hoveredIndex = null;
                                      }
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
            
            // View Details Button
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF2A2D3A) : const Color(0xFFF8F9FC),
                  foregroundColor: isDark ? AppColors.darkText : AppColors.text,
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isDark ? const Color.fromARGB(255, 152, 152, 153) : const Color.fromARGB(255, 202, 209, 229),
                      width: 2,
                    ),
                  ),
                  textStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    letterSpacing: 0.2,
                  ),
                  elevation: 0,
                  splashFactory: NoSplash.splashFactory,
                ),
                label: const Text("View Full Details"),
                onPressed: () {
                  // TODO: Show more details or navigate
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}



class _StatIndicator extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _StatIndicator({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.darkText : AppColors.text;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: textColor.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ignore: unused_element
class _EnergyRow extends StatelessWidget {
  final String category;
  final int percent;
  final Color color;
  final IconData icon;
  final bool isDark;

  const _EnergyRow({
    required this.category,
    required this.percent,
    required this.color,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.darkText : AppColors.text;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              category,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
          Text(
            "$percent%",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}


class BarData {
  final String day;
  final double value;
  final Color color;

  BarData(this.day, this.value, this.color);
}

class PieData {
  final String category;
  final int percent;
  final Color color;
  final IconData icon;

  PieData(this.category, this.percent, this.color, this.icon);
}