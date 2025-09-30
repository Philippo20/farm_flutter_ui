// Owner dashboard
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
//import '../../constants/colors.dart';
import '../../widgets/headers/owner_header.dart';
import '../../widgets/sidebars/owner_sidebar.dart';
import '../../widgets/cards/owner/owner_stat_card.dart';
import '../../widgets/cards/owner/owner_production_widget.dart';
import '../../widgets/cards/owner/owner_energy_widget.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  bool isDark = false;
  int selectedIndex = 0;
  

  final GlobalKey filterPillKey = GlobalKey();

  

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      setState(() => isDark = args?['isDark'] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 750;
    final isMobile = screenWidth < 600;

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
            OwnerHeader(
              isDark: isDark,
              onToggleDarkMode: () => setState(() => isDark = !isDark),
              onMenuPressed: null,
            ),
            Expanded(
              child: Row(
                children: [
                  if (!isMobile)
                    OwnerSidebar(
                      selectedIndex: selectedIndex,
                      onItemSelected: (idx) =>
                          setState(() => selectedIndex = idx),
                      isDark: isDark,
                      isMobile: false,
                    ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            
                            const SizedBox(height: 12),
                            Text(
                              "Dashboard Overview",
                              style: GoogleFonts.poppins(
                                fontSize: isWide ? 20 : 18,
                                color: isDark ? Colors.white : Colors.black,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Below are today's key performance indicators and insights of your farm",
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                color: isDark
                                    ? Colors.white.withOpacity(0.7)
                                    : Colors.black.withOpacity(0.68),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Builder(
                              builder: (context) {
                                final isWide =
                                    MediaQuery.of(context).size.width > 600;
                                return isWide
                                    ? Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: OwnerStatCard(
                                              title: "Active Sensors",
                                              value: "18",
                                              icon: Icons.sensors,
                                              iconColor: Colors.blue[700],
                                              isDark: isDark,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: OwnerStatCard(
                                              title:
                                                  "Users Assigned to your farm",
                                              value: "9",
                                              icon: Icons.people,
                                              iconColor: Colors.deepPurple,
                                              isDark: isDark,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: OwnerStatCard(
                                              title: "Alerts",
                                              value: "3",
                                              icon: Icons.warning_amber_rounded,
                                              iconColor: Colors.red[700],
                                              isDark: isDark,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        children: [
                                          OwnerStatCard(
                                            title: "Active Sensors",
                                            value: "18",
                                            icon: Icons.sensors,
                                            iconColor: Colors.blue[700],
                                            isDark: isDark,
                                          ),
                                          const SizedBox(height: 16),
                                          OwnerStatCard(
                                            title:
                                                "Users Assigned to your farm",
                                            value: "9",
                                            icon: Icons.people,
                                            iconColor: Colors.deepPurple,
                                            isDark: isDark,
                                          ),
                                          const SizedBox(height: 16),
                                          OwnerStatCard(
                                            title: "Alerts",
                                            value: "3",
                                            icon: Icons.warning_amber_rounded,
                                            iconColor: Colors.red[700],
                                            isDark: isDark,
                                          ),
                                          const SizedBox(height: 16),
                                        ],
                                      );
                              },
                            ),
                            const SizedBox(height: 20),
                            // Production and Energy Row
                            const SizedBox(height: 20),
                            // Production and Energy Row
                            const SizedBox(height: 20),
                            // Production and Energy Row
                            LayoutBuilder(
                              builder: (context, constraints) {
                                if (constraints.maxWidth < 800) {
                                  // Mobile/Tablet layout - Column
                                  return Column(
                                    children: [
                                      OwnerProductionWidget(isDark: isDark),
                                      const SizedBox(height: 20),
                                      OwnerEnergyConsumptionContainer(
                                          isDark: isDark),
                                    ],
                                  );
                                } else {
                                  // Desktop layout - Row
                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child:
                                            OwnerProductionWidget(isDark: isDark),
                                      ),
                                      const SizedBox(width: 20),
                                      Expanded(
                                        flex: 1,
                                        child: OwnerEnergyConsumptionContainer(
                                            isDark: isDark),
                                      ),
                                    ],
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 20),
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
          ? OwnerSidebar(
              selectedIndex: selectedIndex,
              onItemSelected: (idx) => setState(() => selectedIndex = idx),
              isDark: isDark,
              isMobile: true,
            )
          : null,
    );
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
      transform: const GradientRotation(0.1), // Subtle angle
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
