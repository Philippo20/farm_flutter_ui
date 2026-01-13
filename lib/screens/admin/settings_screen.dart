// [FULLY UPDATED] FarmSettingsScreen.dart with advanced design, dynamic farm selection, and updated sensor UI
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/headers/admin_header.dart';
import '../../widgets/sidebars/admin_sidebar.dart';

class FarmSettingsScreen extends StatefulWidget {
  const FarmSettingsScreen({super.key});

  @override
  State<FarmSettingsScreen> createState() => _FarmSettingsScreenState();
}

class _FarmSettingsScreenState extends State<FarmSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int selectedIndex = 4;
  bool isDark = false;

  // Dynamic list of available farms
  List<String> availableFarms = ['All Farms', 'Greenhouse A', 'Field B', 'Hydroponic C'];
  late String selectedFarm; // Initialize later in initState

  final Map<String, bool> _automationSettings = {
    'Smart Irrigation': true,
    'Climate Control': false,
    'Hydroponic Monitoring': true,
    'Livestock Tracking': false,
  };

  // Updated sensor thresholds with new entries
  final Map<String, double> _sensorThresholds = {
    'Soil Moisture': 65.0,
    'Temperature': 28.0,
    'Humidity': 70.0,
    'Water pH': 6.5,
    'Nutrient EC': 1.8, // New: Electrical Conductivity
    'Dissolved Oxygen': 7.0, // New
    'Water Temperature': 22.0, // New
  };

  final Map<String, bool> _alertSettings = {
    'Equipment Failure': true,
    'Environmental Changes': true,
    'Pest Detection': false,
    'Water Leaks': true,
  };

  final Map<String, bool> _notificationChannels = {
    'Email': true,
    'SMS': false,
    'Mobile Push': true,
    'Web Dashboard': true,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    selectedFarm = availableFarms.first; // Set initial selected farm to the first in the list
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      setState(() => isDark = args?['isDark'] ?? false);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final activeColor = isDark ? Colors.tealAccent : Colors.green;
    final cardColor = isDark ? const Color(0xFF2D2D2D) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: _buildBackgroundGradient(),
        child: Column(
          children: [
            // AdminHeader is assumed to be an existing widget
            AdminHeader(
              isDark: isDark,
              onToggleDarkMode: () => setState(() => isDark = !isDark),
              onMenuPressed: null, // This can be wired up to a drawer for mobile if needed
            ),
            Expanded(
              child: Row(
                children: [
                  // AdminSidebar for desktop
                  if (!isMobile) _buildSidebar(selectedIndex, isDark),
                  Expanded(
                    child: Column(
                      children: [
                        _buildFarmSelector(isMobile, textColor, cardColor, activeColor),
                        _buildTabBar(activeColor, textColor),
                        Expanded(
                          child: _buildTabViews(cardColor, textColor, activeColor, subtitleColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // AdminSidebar for mobile (bottom navigation bar)
      bottomNavigationBar: isMobile ? _buildMobileSidebar(selectedIndex, isDark) : null,
    );
  }

  // Builds the desktop sidebar
  Widget _buildSidebar(int selectedIndex, bool isDark) => AdminSidebar(
        selectedIndex: selectedIndex,
        onItemSelected: (idx) => setState(() => this.selectedIndex = idx),
        isDark: isDark,
        isMobile: false,
      );

  // Builds the mobile bottom navigation bar (acting as sidebar)
  Widget _buildMobileSidebar(int selectedIndex, bool isDark) => AdminSidebar(
        selectedIndex: selectedIndex,
        onItemSelected: (idx) => setState(() => this.selectedIndex = idx),
        isDark: isDark,
        isMobile: true,
      );

  // Builds the background gradient based on dark mode
  BoxDecoration _buildBackgroundGradient() {
    return BoxDecoration(
      gradient: isDark
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.grey.shade900, Colors.grey.shade800],
            )
          : LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blueGrey.shade50, Colors.blueGrey.shade100],
            ),
    );
  }

  // Builds the farm selection dropdown and new farm button
  Widget _buildFarmSelector(bool isMobile, Color textColor, Color cardColor, Color activeColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: selectedFarm,
              dropdownColor: cardColor, // Background color of the dropdown menu
              style: GoogleFonts.inter(color: textColor), // Text color of dropdown items
              // Use the dynamic availableFarms list
              items: availableFarms
                  .map((farm) => DropdownMenuItem(
                        value: farm,
                        child: Text(farm),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => selectedFarm = value);
                }
              },
              decoration: InputDecoration(
                labelText: 'Select Farm',
                labelStyle: GoogleFonts.inter(color: textColor.withOpacity(0.8)),
                prefixIcon: Icon(Icons.agriculture, color: activeColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none, // No border for cleaner look
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: textColor.withOpacity(0.2), width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: activeColor, width: 2),
                ),
                filled: true,
                fillColor: cardColor, // Background color of the input field
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // New Farm button
          SizedBox(
            width: isMobile ? null : 200, // Adjust width for mobile
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 20),
              label: Text(
                'New Farm',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              onPressed: () =>
                  _addNewFarm(context, textColor, cardColor, activeColor), // Call the new method
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: activeColor, // Use active color for primary action
                foregroundColor: isDark ? Colors.black : Colors.white, // Text color for button
                elevation: 5,
                shadowColor: activeColor.withOpacity(0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Dialog to add a new farm
  void _addNewFarm(BuildContext context, Color textColor, Color cardColor, Color activeColor) {
    TextEditingController newFarmController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: Text(
            'Add New Farm',
            style: GoogleFonts.inter(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: newFarmController,
            style: GoogleFonts.inter(color: textColor),
            decoration: InputDecoration(
              labelText: 'Farm Name',
              labelStyle: GoogleFonts.inter(color: textColor.withOpacity(0.7)),
              hintText: 'e.g., North Field',
              hintStyle: GoogleFonts.inter(color: textColor.withOpacity(0.5)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: textColor.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: activeColor, width: 2),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: activeColor.withOpacity(0.7)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: activeColor,
                foregroundColor: isDark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'Add',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                if (newFarmController.text.isNotEmpty) {
                  setState(() {
                    availableFarms.add(newFarmController.text);
                    selectedFarm = newFarmController.text; // Automatically select the new farm
                  });
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Farm "${newFarmController.text}" added!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Farm name cannot be empty!')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Builds the tab bar for navigation between settings categories
  Widget _buildTabBar(Color activeColor, Color textColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.grey[100], // Background of the tab container
          borderRadius: BorderRadius.circular(12),
          // Removed boxShadow for a flatter, more professional look
        ),
        child: TabBar(
          controller: _tabController,
          labelColor: activeColor,
          unselectedLabelColor: textColor.withOpacity(0.7),
          // Changed indicator to a more subtle underline with rounded corners
          indicator: UnderlineTabIndicator(
            borderSide: BorderSide(
              width: 4.0, // Thicker underline
              color: activeColor,
            ),
            borderRadius: BorderRadius.circular(4), // Rounded corners for the underline
            insets: const EdgeInsets.symmetric(horizontal: 16.0), // Adjust width
          ),
          indicatorPadding: const EdgeInsets.symmetric(vertical: 8), // Padding around the indicator
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
          unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
          tabs: const [
            Tab(
                icon: Icon(Icons.settings_remote, size: 20),
                text: 'Automation',
                iconMargin: EdgeInsets.zero),
            Tab(icon: Icon(Icons.sensors, size: 20), text: 'Sensors', iconMargin: EdgeInsets.zero),
            Tab(
                icon: Icon(Icons.notifications, size: 20),
                text: 'Alerts',
                iconMargin: EdgeInsets.zero),
            Tab(icon: Icon(Icons.analytics, size: 20), text: 'Data', iconMargin: EdgeInsets.zero),
          ],
        ),
      ),
    );
  }

  // Builds the main tab views content
  Widget _buildTabViews(Color cardColor, Color textColor, Color activeColor, Color subtitleColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildAutomationTab(cardColor, textColor, activeColor),
          _buildSensorsTab(cardColor, textColor, activeColor, subtitleColor),
          _buildAlertsTab(cardColor, textColor, activeColor, subtitleColor),
          _buildDataTab(cardColor, textColor, subtitleColor),
        ],
      ),
    );
  }

  // Content for the Automation tab
  Widget _buildAutomationTab(Color cardColor, Color textColor, Color activeColor) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Automated Farm Operations',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 20),
          // Responsive Grid for Automation settings
          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = 1;
              if (constraints.maxWidth > 1200) {
                crossAxisCount = 3;
              } else if (constraints.maxWidth > 700) {
                crossAxisCount = 2;
              }
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(), // Disable scrolling within grid
                crossAxisCount: crossAxisCount,
                childAspectRatio: 3.0, // Adjusted aspect ratio for better card height
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                children: _automationSettings.entries.map((entry) {
                  return Card(
                    color: cardColor,
                    elevation: 5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Container(
                            width: 55,
                            height: 55,
                            decoration: BoxDecoration(
                              color: activeColor.withOpacity(0.18),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getAutomationIcon(entry.key),
                              color: activeColor,
                              size: 30, // Larger icon
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Text(
                              entry.key,
                              style: GoogleFonts.inter(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                          ),
                          Switch(
                            value: entry.value,
                            onChanged: (val) =>
                                setState(() => _automationSettings[entry.key] = val),
                            inactiveTrackColor: isDark ? Colors.grey[600] : Colors.grey[300],
                            inactiveThumbColor: isDark ? Colors.grey[400] : Colors.grey[500],
                            activeColor: activeColor, // Use the correct parameter for active color
                            activeTrackColor: activeColor.withOpacity(0.5),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // Content for the Sensors tab
  Widget _buildSensorsTab(
      Color cardColor, Color textColor, Color activeColor, Color subtitleColor) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sensor Thresholds & Monitoring',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 20),
          // Responsive Grid for Sensor settings
          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = 1;
              if (constraints.maxWidth > 1200) {
                crossAxisCount = 3;
              } else if (constraints.maxWidth > 700) {
                crossAxisCount = 2;
              }
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                childAspectRatio: 1.5, // Adjust aspect ratio for sensor cards
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                children: _sensorThresholds.entries.map((entry) {
                  return Card(
                    color: cardColor,
                    elevation: 5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(_getSensorIcon(entry.key), color: activeColor, size: 30),
                              const SizedBox(width: 15),
                              Expanded(
                                // Use Expanded to prevent overflow
                                child: Text(
                                  entry.key,
                                  style: GoogleFonts.inter(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                  overflow: TextOverflow.ellipsis, // Handle long text
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${entry.value.toStringAsFixed(entry.key == 'Nutrient EC' || entry.key == 'Water pH' ? 1 : 0)}${_getSensorUnit(entry.key)}', // Adjust precision for EC/pH
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: activeColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          Expanded(
                            // Allow slider to take available height
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 8.0,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10.0),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 20.0),
                                valueIndicatorShape: PaddleSliderValueIndicatorShape(),
                                valueIndicatorTextStyle: GoogleFonts.inter(
                                  color: isDark ? Colors.black : Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              child: Slider(
                                value: entry.value,
                                min: _getSensorMin(entry.key),
                                max: _getSensorMax(entry.key),
                                divisions: _getSensorDivisions(entry.key),
                                activeColor: activeColor,
                                inactiveColor: activeColor.withOpacity(0.3),
                                label:
                                    '${entry.value.toStringAsFixed(entry.key == 'Nutrient EC' || entry.key == 'Water pH' ? 1 : 0)}${_getSensorUnit(entry.key)}',
                                onChanged: (val) =>
                                    setState(() => _sensorThresholds[entry.key] = val),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Adjust Threshold',
                              style: GoogleFonts.inter(color: subtitleColor, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // Content for the Alerts tab
  Widget _buildAlertsTab(Color cardColor, Color textColor, Color activeColor, Color subtitleColor) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Alert Settings & Notification Channels',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 20),
          Card(
            color: cardColor,
            elevation: 5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Alert Triggers',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const Divider(height: 25, thickness: 1),
                  ..._alertSettings.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: SwitchListTile(
                        title: Text(
                          entry.key,
                          style: GoogleFonts.inter(color: textColor, fontSize: 16),
                        ),
                        secondary: Icon(_getAlertIcon(entry.key), color: activeColor, size: 28),
                        value: entry.value,
                        onChanged: (val) => setState(() => _alertSettings[entry.key] = val),
                        activeColor: activeColor,
                        inactiveTrackColor: isDark ? Colors.grey[600] : Colors.grey[300],
                        inactiveThumbColor: isDark ? Colors.grey[400] : Colors.grey[500],
                        activeTrackColor: activeColor.withOpacity(0.5),
                        contentPadding: EdgeInsets.zero, // Remove default padding
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 25),
          Card(
            color: cardColor,
            elevation: 5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notification Channels',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const Divider(height: 25, thickness: 1),
                  ..._notificationChannels.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: SwitchListTile(
                        title: Text(
                          entry.key,
                          style: GoogleFonts.inter(color: textColor, fontSize: 16),
                        ),
                        secondary: Icon(_getChannelIcon(entry.key), color: activeColor, size: 28),
                        value: entry.value,
                        onChanged: (val) => setState(() => _notificationChannels[entry.key] = val),
                        activeColor: activeColor,
                        inactiveTrackColor: isDark ? Colors.grey[600] : Colors.grey[300],
                        inactiveThumbColor: isDark ? Colors.grey[400] : Colors.grey[500],
                        activeTrackColor: activeColor.withOpacity(0.5),
                        contentPadding: EdgeInsets.zero, // Remove default padding
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Content for the Data tab
  Widget _buildDataTab(Color cardColor, Color textColor, Color subtitleColor) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Data Analytics & Reporting',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 20),
          Card(
            color: cardColor,
            elevation: 5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Data Trends',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 15),
                  // Placeholder for a chart or data visualization
                  Container(
                    height: 250, // Increased height for visual impact
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[750] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: subtitleColor.withOpacity(0.2), width: 1),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bar_chart, size: 60, color: subtitleColor.withOpacity(0.6)),
                        const SizedBox(height: 10),
                        Text(
                          'Interactive Chart / Data Visualization Placeholder',
                          style: GoogleFonts.inter(color: subtitleColor, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          'Connect to data sources for live insights.',
                          style: GoogleFonts.inter(
                              color: subtitleColor.withOpacity(0.7), fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'Download Reports',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const Divider(height: 25, thickness: 1),
                  ListTile(
                    leading: Icon(Icons.download_for_offline,
                        color: Theme.of(context).primaryColor, size: 30),
                    title: Text(
                      'Export Sensor Data (CSV)',
                      style: GoogleFonts.inter(color: textColor, fontSize: 16),
                    ),
                    trailing:
                        Icon(Icons.arrow_forward_ios, color: textColor.withOpacity(0.7), size: 18),
                    onTap: () {
                      // TODO: Implement CSV export logic
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Exporting Sensor Data...')),
                      );
                    },
                  ),
                  ListTile(
                    leading:
                        Icon(Icons.picture_as_pdf, color: Theme.of(context).primaryColor, size: 30),
                    title: Text(
                      'Generate Performance Report (PDF)',
                      style: GoogleFonts.inter(color: textColor, fontSize: 16),
                    ),
                    trailing:
                        Icon(Icons.arrow_forward_ios, color: textColor.withOpacity(0.7), size: 18),
                    onTap: () {
                      // TODO: Implement PDF report generation logic
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Generating Performance Report...')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper methods for icons and sensor values ---

  // Returns the appropriate icon for automation settings
  IconData _getAutomationIcon(String title) {
    switch (title) {
      case 'Smart Irrigation':
        return Icons.water_drop;
      case 'Climate Control':
        return Icons.thermostat;
      case 'Hydroponic Monitoring':
        return Icons.waves;
      case 'Livestock Tracking':
        return Icons.pets;
      default:
        return Icons.settings;
    }
  }

  // Returns the appropriate icon for sensor types
  IconData _getSensorIcon(String title) {
    switch (title) {
      case 'Soil Moisture':
        return Icons.water_outlined;
      case 'Temperature':
        return Icons.device_thermostat;
      case 'Humidity':
        return Icons.cloud_outlined;
      case 'Water pH':
        return Icons.science_outlined;
      case 'Nutrient EC':
        return Icons.scatter_plot; // or Icons.electric_bolt
      case 'Dissolved Oxygen':
        return Icons.bubble_chart;
      case 'Water Temperature':
        return Icons.ac_unit; // or Icons.thermostat_outlined
      default:
        return Icons.sensors;
    }
  }

  // Returns the unit for sensor values
  String _getSensorUnit(String title) {
    switch (title) {
      case 'Soil Moisture':
        return '%';
      case 'Temperature':
        return '°C';
      case 'Humidity':
        return '%';
      case 'Water pH':
        return ''; // pH is unitless
      case 'Nutrient EC':
        return ' mS/cm'; // millisiemens per centimeter
      case 'Dissolved Oxygen':
        return ' mg/L'; // milligrams per liter
      case 'Water Temperature':
        return '°C';
      default:
        return '';
    }
  }

  // Returns the minimum value for sensor sliders
  double _getSensorMin(String title) {
    switch (title) {
      case 'Soil Moisture':
        return 0.0;
      case 'Temperature':
        return 0.0;
      case 'Humidity':
        return 0.0;
      case 'Water pH':
        return 0.0;
      case 'Nutrient EC':
        return 0.0;
      case 'Dissolved Oxygen':
        return 0.0;
      case 'Water Temperature':
        return 0.0;
      default:
        return 0.0;
    }
  }

  // Returns the maximum value for sensor sliders
  double _getSensorMax(String title) {
    switch (title) {
      case 'Soil Moisture':
        return 100.0;
      case 'Temperature':
        return 50.0;
      case 'Humidity':
        return 100.0;
      case 'Water pH':
        return 14.0;
      case 'Nutrient EC':
        return 5.0; // Typical range for hydroponics
      case 'Dissolved Oxygen':
        return 15.0; // Typical saturation
      case 'Water Temperature':
        return 40.0;
      default:
        return 100.0;
    }
  }

  // Returns the number of divisions for sensor sliders (for precise steps)
  int _getSensorDivisions(String title) {
    switch (title) {
      case 'Soil Moisture':
        return 100;
      case 'Temperature':
        return 50;
      case 'Humidity':
        return 100;
      case 'Water pH':
        return 140; // 0.1 increments for pH
      case 'Nutrient EC':
        return 50; // 0.1 increments
      case 'Dissolved Oxygen':
        return 150; // 0.1 increments
      case 'Water Temperature':
        return 40; // 1 degree increments
      default:
        return 100;
    }
  }

  // Returns the appropriate icon for alert types
  IconData _getAlertIcon(String title) {
    switch (title) {
      case 'Equipment Failure':
        return Icons.build;
      case 'Environmental Changes':
        return Icons.cloud;
      case 'Pest Detection':
        return Icons.bug_report;
      case 'Water Leaks':
        return Icons.water_damage;
      default:
        return Icons.warning;
    }
  }

  // Returns the appropriate icon for notification channels
  IconData _getChannelIcon(String title) {
    switch (title) {
      case 'Email':
        return Icons.email;
      case 'SMS':
        return Icons.sms;
      case 'Mobile Push':
        return Icons.phone_android;
      case 'Web Dashboard':
        return Icons.web;
      default:
        return Icons.notifications_active;
    }
  }
}
