import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants/colors.dart';
import 'package:intl/intl.dart';

class FirstRow extends StatefulWidget {
  final bool isDark;

  const FirstRow({super.key, required this.isDark});

  @override
  State<FirstRow> createState() => _FirstRowState();
}

class _FirstRowState extends State<FirstRow> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildGreetingContainer(),
        SizedBox(height: 16),
        _buildDateTime(),
        SizedBox(height: 16),
        _buildOutsideTemp(),
        SizedBox(height: 20),
        _buildTitle("Grow Stage Tracker", 30),
        SizedBox(height: 16),
        _buildStageCard(
          icon: Icons.eco,
          stage: "Vegetation",
          day: 23,
          isDark: widget.isDark,
        ),
        SizedBox(height: 16),
        _buildTrackerProgressbarCard(
          isDark: widget.isDark,
          progress: 0.65, // 65% progress
          icon: Icons.eco,
        ),
        SizedBox(height: 16),
        _buildTitle("Farm Equipment Status", 25),
        SizedBox(height: 16),
        _buildTabCard(isDark: widget.isDark),
      ],
    );
  }

  Widget _buildGreetingContainer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDark ? Colors.grey[800] : Colors.white,
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
          // Home icon with rounded background
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.isDark ? Colors.blueGrey[800] : Colors.green[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.home,
              color: widget.isDark ? Colors.white : AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // Greeting text column
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, Abacca Philip (CTO)',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: widget.isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Good Afternoon',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: widget.isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateTime() {
    final now = DateTime.now();
    final time = DateFormat('hh:mm a').format(now); // e.g., 02:07 PM
    final date = DateFormat('MMM d, yyyy').format(now); // e.g., Jul 2, 2025

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: widget.isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Clock icon
          Container(
            padding: const EdgeInsets.all(15),
            child: Icon(
              Icons.date_range,
              color: widget.isDark ? Colors.white : AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),

          // Time and date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Date & Time",
                    style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: widget.isDark ? Colors.white : Colors.black)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 12,
                  runSpacing: 2,
                  children: [
                    Text(
                      time,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color:
                            widget.isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    Text(
                      date,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color:
                            widget.isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutsideTemp() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          // Weather icon
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: widget.isDark
                  ? Colors.blueGrey[700]
                  : Colors.orange.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.wb_sunny_rounded,
              color: widget.isDark ? Colors.yellow[200] : Colors.orange,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // Two columns inside Expanded
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Column 1: Weather Type + Outside Temp label
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Partly Cloudy",
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: widget.isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Outside Temperature",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color:
                            widget.isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),

                // Column 2: Temperature + Humidity
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "28°C",
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: widget.isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.thermostat,
                          color: widget.isDark
                              ? Colors.yellow[200]
                              : Colors.orange,
                          size: 15,
                        ),
                        Text(
                          " 60%",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: widget.isDark
                                ? Colors.grey[400]
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(String title, double fontSize) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
          color: widget.isDark ? Colors.white : AppColors.darkCard,
        ),
      ),
    );
  }

  Widget _buildStageCard({
    required IconData icon,
    required String stage,
    required int day,
    required bool isDark,
  }) {
    return Align(
      alignment: Alignment.centerLeft, // Push card to the left
      child: Container(
        width: 230,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          //border: Border.all(color: Colors.grey[600]!, width: 1)  ,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon with circular background
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? Colors.green[900] : Colors.green[100],
              ),
              child: Icon(
                icon,
                size: 30,
                color: isDark ? Colors.green[300] : Colors.green[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              stage,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              "Day: $day",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackerProgressbarCard({
    required bool isDark,
    required double progress, // 0.0 to 1.0
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // Title
          Text(
            "Product Grow Stage",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // Icon + progress bar + percentage
          Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? Colors.green[900] : Colors.green[100],
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isDark ? Colors.green[300] : Colors.green[800],
                ),
              ),
              const SizedBox(width: 12),

              // Wider Progress bar using flex
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 40, // Slightly taller too if you want
                    backgroundColor:
                        isDark ? Colors.grey[700] : Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? Colors.greenAccent : Colors.green,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Percentage
              Text(
                "${(progress * 100).toStringAsFixed(0)}%",
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabCard({required bool isDark}) {
    return DefaultTabController(
      length: 3,
      child: SizedBox(
        width: double.infinity,
        // padding: const EdgeInsets.all(0),
        /*
        decoration: BoxDecoration(
         // color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        */
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(builder: (context, constraints) {
              final compactTabs = constraints.maxWidth < 330;
              return TabBar(
                labelColor: isDark ? Colors.greenAccent : Colors.green[800],
                unselectedLabelColor: isDark ? Colors.white70 : Colors.black54,
                indicatorColor: isDark ? Colors.greenAccent : Colors.green[800],
                indicatorWeight: 5,
                labelPadding: EdgeInsets.symmetric(
                  horizontal: compactTabs ? 4 : 8,
                ),
                tabs: [
                  _equipmentTab(
                    icon: Icons.lightbulb_outline,
                    label: 'Lights',
                    compact: compactTabs,
                  ),
                  _equipmentTab(
                    icon: Icons.water,
                    label: 'Pumps',
                    compact: compactTabs,
                  ),
                  _equipmentTab(
                    icon: Icons.science_outlined,
                    label: 'pH / Air',
                    compact: compactTabs,
                  ),
                ],
              );
            }),

            const SizedBox(height: 12),

            // Tab Content
            LayoutBuilder(builder: (context, constraints) {
              final compactContent = constraints.maxWidth < 340;
              return SizedBox(
                height: compactContent ? 280 : 210,
                child: TabBarView(
                  children: [
                    SingleChildScrollView(child: _tabCardContentLights(isDark)),
                    SingleChildScrollView(child: _tabCardContentPumps(isDark)),
                    SingleChildScrollView(child: _tabCardContentPhAir(isDark)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _equipmentTab({
    required IconData icon,
    required String label,
    required bool compact,
  }) {
    if (compact) {
      return Tab(
        icon: Tooltip(
          message: label,
          child: Icon(icon, size: 20),
        ),
      );
    }

    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabCardContentLights(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
          child: Text(
            "Rack Lights",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        _equipmentCardRow([
          _lightStatusCard("E RACK", true, isDark),
          _lightStatusCard("F RACK", false, isDark),
          _lightStatusCard("P RACK", true, isDark),
        ]),
      ],
    );
  }

  Widget _tabCardContentPumps(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
          child: Text(
            "Pump Controls",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        _equipmentCardRow([
          _pumpStatusCard("Water Pump", true, isDark),
          _pumpStatusCard("Air Pump", false, isDark),
          _pumpStatusCard("Nut Pump", true, isDark),
        ]),
      ],
    );
  }

  Widget _tabCardContentPhAir(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
          child: Text(
            "pH & Air Monitoring",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        _equipmentCardRow([
          _phAirStatusCard("pH Up", true, Icons.arrow_upward, isDark),
          _phAirStatusCard("pH Down", false, Icons.arrow_downward, isDark),
          _phAirStatusCard("Air Condition", true, Icons.air, isDark),
        ]),
      ],
    );
  }

  Widget _equipmentCardRow(List<Widget> children) {
    return LayoutBuilder(builder: (context, constraints) {
      final gap = constraints.maxWidth < 340 ? 8.0 : 10.0;
      final columns = constraints.maxWidth >= 340 ? 3 : 2;
      final cardWidth =
          (constraints.maxWidth - ((columns - 1) * gap)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: children
            .map((child) => SizedBox(width: cardWidth, child: child))
            .toList(),
      );
    });
  }

  /// TAB MORE FEATURES
  /// LIGHTS, PUMPS, PH/AIR
  Widget _lightStatusCard(String name, bool isActive, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
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
          Icon(
            Icons.lightbulb,
            color: isActive
                ? (isDark ? Colors.greenAccent : Colors.green)
                : Colors.grey,
            size: 30,
          ),
          const SizedBox(height: 8),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isActive ? "ACTIVE" : "NOT ACTIVE",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isActive
                  ? (isDark ? Colors.greenAccent : Colors.green)
                  : Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }

//pump
  Widget _pumpStatusCard(String name, bool isActive, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(5, 10, 5, 5),
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
          Icon(
            Icons.water, // You can customize per pump if needed
            color: isActive
                ? (isDark ? Colors.greenAccent : Colors.green)
                : Colors.grey,
            size: 30,
          ),
          const SizedBox(height: 8),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isActive ? "ACTIVE" : "NOT ACTIVE",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isActive
                  ? (isDark ? Colors.greenAccent : Colors.green)
                  : Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }

//
  Widget _phAirStatusCard(
      String name, bool isActive, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(5, 10, 5, 5),
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
          Icon(
            icon,
            color: isActive
                ? (isDark ? Colors.greenAccent : Colors.green)
                : Colors.grey,
            size: 30,
          ),
          const SizedBox(height: 8),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isActive ? "ACTIVE" : "NOT ACTIVE",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isActive
                  ? (isDark ? Colors.greenAccent : Colors.green)
                  : Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }
}
