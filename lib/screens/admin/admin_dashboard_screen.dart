// Admin dashboard
import 'package:farmestates_ai_dashbaord/utils/location_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/headers/admin_header.dart';
import '../../widgets/sidebars/admin_sidebar.dart';
import '../../widgets/cards/admin_stat_card.dart';
import '../../widgets/cards/admin_analytics_card.dart';
import '../../widgets/cards/admin_dashboard_card.dart';
import '../../utils/date_utils.dart';
import '../../utils/weather_utils.dart';
import '../../widgets/cards/farm_performance_card.dart';
import '../../widgets/cards/admin_activities_andLogscard.dart';



class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool isDark = false;
  int selectedIndex = 0;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  String _segmentValue = "All Segment";
  final List<String> _segmentOptions = ["All Segment", "Energy Consumption", "Energy Distribution", "Farms Performance", "Activities and Logs"];
  double _temperature = 0.0;
  String _weatherState = "Sunny";
  
  final GlobalKey filterPillKey = GlobalKey();

  Future<void> updateWeather() async {
    const apiKey = "692f06e188d6253bd59563ad59e00274";
    final position = await getCurrentLocation();
    if (position == null) return;

    final data = await fetchWeatherData(
      latitude: position.latitude,
      longitude: position.longitude,
      apiKey: apiKey,
    );
    
    if (data != null) {
      setState(() {
        _temperature = data['temperature'];
        _weatherState = data['condition'];
      });
    }
  }

  @override
  void initState() {
    super.initState();
    updateWeather();
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
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AdminDashboardCard(
                            isDark: isDark,
                            adminName: "Admin",
                            rangeStart: _rangeStart,
                            rangeEnd: _rangeEnd,
                            onSelectRange: () async {
                              final box = filterPillKey.currentContext?.findRenderObject() as RenderBox?;
                              Rect? pos;
                              if (box != null) {
                                pos = Rect.fromLTWH(
                                  box.localToGlobal(Offset.zero).dx,
                                  box.localToGlobal(Offset.zero).dy + box.size.height + 8,
                                  box.size.width,
                                  0,
                                );
                              }
                              await showDateRangeDropdown(
                                context: context,
                                initialStart: _rangeStart,
                                initialEnd: _rangeEnd,
                                onSelected: (start, end) {
                                  setState(() {
                                    _rangeStart = start;
                                    _rangeEnd = end;
                                  });
                                },
                                isDark: isDark,
                                position: pos,
                              );
                            },
                            segmentValue: _segmentValue,
                            segmentOptions: _segmentOptions,
                            onSegmentChanged: (val) {
                              setState(() => _segmentValue = val ?? "All Segment");
                            },
                            weatherState: _weatherState,
                            temperature: _temperature,
                          ),
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
                            "Below are today's key performance indicators and insights",
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.68),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Builder(
                            builder: (context) {
                              final isWide = MediaQuery.of(context).size.width > 600;
                              return isWide
                                  ? Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: AdminStatCard(
                                            title: "Farms",
                                            value: "5",
                                            icon: Icons.agriculture,
                                            iconColor: Colors.green[600],
                                            isDark: isDark,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: AdminStatCard(
                                            title: "Sensors",
                                            value: "18",
                                            icon: Icons.sensors,
                                            iconColor: Colors.blue[700],
                                            isDark: isDark,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: AdminStatCard(
                                            title: "Users",
                                            value: "9",
                                            icon: Icons.people,
                                            iconColor: Colors.deepPurple,
                                            isDark: isDark,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: AdminStatCard(
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
                                        AdminStatCard(
                                          title: "Farms",
                                          value: "5",
                                          icon: Icons.agriculture,
                                          iconColor: Colors.green[600],
                                          isDark: isDark,
                                        ),
                                        const SizedBox(height: 16),
                                        AdminStatCard(
                                          title: "Sensors",
                                          value: "18",
                                          icon: Icons.sensors,
                                          iconColor: Colors.blue[700],
                                          isDark: isDark,
                                        ),
                                        const SizedBox(height: 16),
                                        AdminStatCard(
                                          title: "Users",
                                          value: "9",
                                          icon: Icons.people,
                                          iconColor: Colors.deepPurple,
                                          isDark: isDark,
                                        ),
                                        const SizedBox(height: 16),
                                        AdminStatCard(
                                          title: "Alerts",
                                          value: "3",
                                          icon: Icons.warning_amber_rounded,
                                          iconColor: Colors.red[700],
                                          isDark: isDark,
                                        ),
                                      ],
                                    );
                            },
                          ),
                          const SizedBox(height: 38),
                          AnalyticsDashboard(isDark: isDark),
                          const SizedBox(height: 38),
                          SizedBox(
                            width: double.infinity,
                            child: FarmPerformanceCard(isDark: isDark),
                          ),
                          const SizedBox(height: 38),
                          ActivitiesAndLogsCard(isDark: isDark),
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