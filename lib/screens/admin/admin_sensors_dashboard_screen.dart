import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/colors.dart';
import '../../widgets/sidebars/admin_sidebar.dart';
import '../../widgets/headers/admin_header.dart';
import '../../widgets/cards/sensor_status_container.dart';
import '../../widgets/cards/sensor_tabs_container.dart';

class Sensor {

  final String id;
  final String name;
  final String type;
  final String status;
  final String location;
  final String lastReading;
  final double batteryLevel;

  Sensor({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.location,
    required this.lastReading,
    required this.batteryLevel,
  });

}

class SensorsScreen extends StatefulWidget {
  const SensorsScreen({super.key});

  @override
  State<SensorsScreen> createState() => _SensorsScreenState();
}

class _SensorsScreenState extends State<SensorsScreen> {
  int selectedIndex = 3;
  bool isDark = false;
  final TextEditingController _searchController = TextEditingController();
  
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      setState(() => isDark = args?['isDark'] ?? false);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  final isMobile = screenWidth < 600;
  final textColor = isDark ? AppColors.darkText : AppColors.text;
  final cardColor = isDark ? AppColors.darkCard : AppColors.card;
  final secondaryTextColor = isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.6);

  return Scaffold(
    backgroundColor: Colors.transparent,
    body: Container(
      decoration: BoxDecoration(
        gradient: isDark 
            ? AppBackgroundGradient.getDarkGradient()
            : AppBackgroundGradient.getLightGradient(),
      ),
      child: Column(
        children: [
          AdminHeader(
            isDark: isDark,
            onToggleDarkMode: () => setState(() => isDark = !isDark),
            onMenuPressed: null,
          ),
          Expanded(
            child: Row(
              children: [
                if (!isMobile)
                  AdminSidebar(
                    selectedIndex: selectedIndex,
                    onItemSelected: (idx) => setState(() => selectedIndex = idx),
                    isDark: isDark,
                    isMobile: false,
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 16 : 32,
                        vertical: 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeaderSection(isMobile, textColor),
                          const SizedBox(height: 24),
                          _buildStatsSection(isMobile),
                          const SizedBox(height: 28),
                          _buildSearchAndFilter(cardColor, secondaryTextColor),
                          const SizedBox(height: 22),
                          
                          // Responsive containers section
                          LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth < 800) {
                                // Mobile/Tablet layout - Column
                                return Column(
                                  children: [
                                    SensorTabsContainer(isDark: isDark),
                                    const SizedBox(height: 20),
                                    EnergyConsumptionContainer(isDark: isDark),
                                  ],
                                );
                              } else {
                                // Desktop layout - Row
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: SensorTabsContainer(isDark: isDark),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      flex: 1,
                                      child: EnergyConsumptionContainer(isDark: isDark),
                                    ),
                                  ],
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    bottomNavigationBar: isMobile
        ? AdminSidebar(
            selectedIndex: selectedIndex,
            onItemSelected: (idx) => setState(() => selectedIndex = idx),
            isDark: isDark,
            isMobile: true,
          )
        : null,
  );
}

  Widget _buildHeaderSection(bool isMobile, Color textColor) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Sensor Management',
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 24 : 28,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: 0.3,
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _showAddSensorDialog,
          icon: const Icon(Icons.add, size: 20),
          label: Text(isMobile ? 'Add' : 'Add Sensor'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 20,
              vertical: 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: isMobile ? 14 : 15,
              letterSpacing: 0.2,
            ),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(bool isMobile) {
    return isMobile
        ? Column(
            children: [
              _buildSensorStatCard('Total Sensors', '42', '+8%', true, Icons.sensors, Colors.blue),
              const SizedBox(height: 12),
              _buildSensorStatCard('Active Sensors', '36', '+5%', true, Icons.check_circle, Colors.green),
              const SizedBox(height: 12),
              _buildSensorStatCard('Needs Attention', '6', '-2%', false, Icons.warning, Colors.orange),
            ],
          )
        : Row(
            children: [
              Expanded(child: _buildSensorStatCard('Total Sensors', '42', '+8%', true, Icons.sensors, Colors.blue)),
              const SizedBox(width: 16),
              Expanded(child: _buildSensorStatCard('Active Sensors', '36', '+5%', true, Icons.check_circle, Colors.green)),
              const SizedBox(width: 16),
              Expanded(child: _buildSensorStatCard('Needs Attention', '6', '-2%', false, Icons.warning, Colors.orange)),
            ],
          );
  }

  Widget _buildSensorStatCard(String title, String value, String change, bool isPositive, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.1 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPositive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPositive ? Icons.trending_up : Icons.trending_down,
                      size: 16,
                      color: isPositive ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      change,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isPositive ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(Color cardColor, Color secondaryTextColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.12 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
        child: Row(
          children: [
            Icon(Icons.search, color: secondaryTextColor),
            const SizedBox(width: 6),
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search Farms...',
                  border: InputBorder.none,
                  hintStyle: GoogleFonts.inter(
                    color: secondaryTextColor,
                  ),
                ),
                style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              height: 28,
              width: 1.5,
              color: secondaryTextColor.withOpacity(0.4),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.filter_list_rounded, color: secondaryTextColor),
              itemBuilder: (context) => [
                'All Sensors',
                'Active',
                'Needs Maintenance',
                'By Type',
                'By Location'
              ].map((choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList(),
              onSelected: (String value) {
                // Filter logic
              },
            ),
          ],
        ),
      ),
    );
  }

  

  void _showAddSensorDialog() {
    // Implement add sensor dialog
  }
}

class AppBackgroundGradient {
  static LinearGradient getDarkGradient() {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.grey.shade900.withOpacity(0.9),
        Colors.grey.shade800.withOpacity(0.95),
        Colors.grey.shade700.withOpacity(0.97),
      ],
      stops: const [0.1, 0.5, 1.0],
      transform: const GradientRotation(0.1),
    );
  }

  static LinearGradient getLightGradient() {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.blueGrey.shade50.withOpacity(0.98),
        Colors.blueGrey.shade100.withOpacity(0.95),
        Colors.blueGrey.shade200.withOpacity(0.93),
      ],
      stops: const [0.0, 0.6, 1.0],
    );
  }
}