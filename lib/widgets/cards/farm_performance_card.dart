import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/colors.dart';

class FarmPerformanceCard extends StatefulWidget {
  final bool isDark;
  const FarmPerformanceCard({required this.isDark, super.key});

  @override
  State<FarmPerformanceCard> createState() => _FarmPerformanceCardState();
}

class _FarmPerformanceCardState extends State<FarmPerformanceCard> {

  int? selectedRow;
  
  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 768;
    final textColor = widget.isDark ? Colors.white : AppColors.text;

  

    final secondaryTextColor = widget.isDark
        ? Colors.white.withOpacity(0.7)
        : AppColors.text.withOpacity(0.7);
    final dividerColor = widget.isDark
        ? Colors.white.withOpacity(0.15)
        : Colors.black.withOpacity(0.1);
    final cardColor = widget.isDark ? AppColors.darkCard : AppColors.card;
    final headerColor = widget.isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.black.withOpacity(0.03);

    Widget metricsDescription = isSmall
    ? ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 200),
        child: Text(
          "Current metrics across all agricultural sites",
          style: GoogleFonts.inter(
            fontSize: 14,
            color: secondaryTextColor,
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
      )
    : Text(
        "Current metrics across all agricultural sites",
        style: GoogleFonts.inter(
          fontSize: 14,
          color: secondaryTextColor,
          fontWeight: FontWeight.w500,
        ),
      );    

    final farms = [
      FarmData('Farm A', 'John Smith', 'Nairobi, Kenya', 85, 72, 18, 3, 92),
      FarmData('Farm B', 'Sarah Johnson', 'Kampala, Uganda', 78, 65, 22, 5, 87),
      FarmData('Farm C', 'David Kimani', 'Arusha, Tanzania', 92, 88, 15, 1, 95),
      FarmData('Farm D', 'Grace Omondi', 'Mombasa, Kenya', 81, 75, 19, 2, 89),
      FarmData('Farm E', 'Robert Mugabe', 'Harare, Zimbabwe', 76, 68, 24, 6, 84),
    ];

    Widget table = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: headerColor,
            border: Border(
              bottom: BorderSide(
                color: dividerColor,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  "FARM DETAILS",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: secondaryTextColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              ...["HEALTH", "YIELD", "SENSORS", "ISSUES", "EFFICIENCY"]
                  .map((title) => Expanded(
                        child: Center(
                          child: Text(
                            title,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: secondaryTextColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ))
                  ,
            ],
          ),
        ),
        // Table Rows
        ...farms.asMap().entries.map((entry) {
          final i = entry.key;
          final farm = entry.value;
          final isSelected = isSmall && selectedRow == i;
          return GestureDetector(
            onTap: isSmall
                ? () => setState(() => selectedRow = (selectedRow == i ? null : i))
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border(         
                  top: BorderSide(
                    color: isSelected ? AppColors.primary.withOpacity(0.33) : dividerColor,
                    width: isSelected ? 2 : 1,
                  ),
                  bottom: BorderSide(
                    color: isSelected ? AppColors.primary.withOpacity(0.33) : dividerColor,
                    width: isSelected ? 2 : 1,
                  ),
                 
                ),
                borderRadius: isSelected
                    ? BorderRadius.circular(8)
                    : BorderRadius.zero,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Farm Details Column
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          farm.name,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          farm.owner,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: secondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: secondaryTextColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              farm.location,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Health
                  Expanded(
                    child: Center(
                      child: _CircularProgress(
                        value: farm.health / 100,
                        color: _getHealthColor(farm.health),
                        label: '${farm.health}%',
                        isDark: widget.isDark,
                      ),
                    ),
                  ),
                  // Yield
                  Expanded(
                    child: Center(
                      child: _CircularProgress(
                        value: farm.yield / 100,
                        color: _getYieldColor(farm.yield),
                        label: '${farm.yield}%',
                        isDark: widget.isDark,
                      ),
                    ),
                  ),
                  // Sensors
                  Expanded(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: widget.isDark
                              ? Colors.blue.withOpacity(0.1)
                              : Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          farm.sensors.toString(),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[400],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Issues
                  Expanded(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: farm.issues > 3
                              ? Colors.red.withOpacity(widget.isDark ? 0.1 : 0.05)
                              : Colors.green.withOpacity(widget.isDark ? 0.1 : 0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              farm.issues > 3
                                  ? Icons.warning_amber_rounded
                                  : Icons.check_circle_outline,
                              size: 14,
                              color: farm.issues > 3
                                  ? Colors.red[400]
                                  : Colors.green[400],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              farm.issues.toString(),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: farm.issues > 3
                                    ? Colors.red[400]
                                    : Colors.green[400],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Efficiency
                  Expanded(
                    child: Center(
                      child: _CircularProgress(
                        value: farm.efficiency / 100,
                        color: _getEfficiencyColor(farm.efficiency),
                        label: '${farm.efficiency}%',
                        isDark: widget.isDark,
                        showPercentageSymbol: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(widget.isDark ? 0.15 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Card Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Farm Performance",
                      style: GoogleFonts.poppins(
                        
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    metricsDescription,
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.refresh,
                      size: 20, color: AppColors.primary),
                  onPressed: () {
                    // Handle refresh
                  },
                ),
              ],
            ),
          ),
          if (isSmall)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 780, // Ensures horizontal scroll on small screens
                child: table,
              ),
            )
          else
            table,
        ],
      ),
    );
  }

}

// Helpers (as before)

class _CircularProgress extends StatelessWidget {
  final double value;
  final Color color;
  final String label;
  final bool isDark;
  final bool showPercentageSymbol;

  const _CircularProgress({
    required this.value,
    required this.color,
    required this.label,
    required this.isDark,
    this.showPercentageSymbol = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 36,
          height: 36,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: value,
                backgroundColor: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.1),
                color: color,
                strokeWidth: 6,
              ),
              Text(
                '${(value * 100).toInt()}${showPercentageSymbol ? '%' : ''}',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDark
                ? Colors.white.withOpacity(0.8)
                : Colors.black.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

class FarmData {
  final String name;
  final String owner;
  final String location;
  final int health;
  final int yield;
  final int sensors;
  final int issues;
  final int efficiency;

  FarmData(
    this.name,
    this.owner,
    this.location,
    this.health,
    this.yield,
    this.sensors,
    this.issues,
    this.efficiency,
  );
}

Color _getHealthColor(int value) {
  if (value >= 80) return Colors.green[400]!;
  if (value >= 60) return Colors.orange[400]!;
  return Colors.red[400]!;
}

Color _getYieldColor(int value) {
  if (value >= 75) return Colors.green[400]!;
  if (value >= 50) return Colors.orange[400]!;
  return Colors.red[400]!;
}

Color _getEfficiencyColor(int value) {
  if (value >= 85) return Colors.teal[400]!;
  if (value >= 70) return Colors.blue[400]!;
  return Colors.purple[400]!;
}

