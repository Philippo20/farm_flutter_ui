// Farm settings
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/headers/owner_header.dart';
import '../../widgets/sidebars/owner_sidebar.dart';

class OwnerFarmsSettingsScreen extends StatefulWidget {
  const OwnerFarmsSettingsScreen({super.key});

  @override
  State<OwnerFarmsSettingsScreen> createState() =>
      _OwnerFarmsSettingsScreenState();
}

class _OwnerFarmsSettingsScreenState extends State<OwnerFarmsSettingsScreen> {
  int selectedIndex = 2;
  bool isDark = false;

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
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Container(
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
                        child: Column(
                          children: [
                            FarmInfoCard(isDark: isDark),
                            SizedBox(height: 16),
                            _TabCard(isDark: isDark),
                             SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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

class FarmInfoCard extends StatelessWidget {
  final bool isDark;

  const FarmInfoCard({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;
    final double imageHeight = isMobile ? 200 : 300;

    return Container(
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black12,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: Image + Name Overlay
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.asset(
                  'images/farm.jpg',
                  height: imageHeight,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Container(
                height: imageHeight,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.6),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 20,
                child: Text(
                  "Green Valley Farm",
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          // Row 2: Farm Details
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Location
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 18, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      "Central Region, Ghana",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Crop
                Row(
                  children: [
                    const Icon(Icons.eco, size: 18, color: Colors.teal),
                    const SizedBox(width: 8),
                    Text(
                      "Lettuce (Batavia)",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Progress
                Text(
                  "Growth Progress: 65%",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: 0.65,
                    minHeight: 8,
                    backgroundColor: isDark ? Colors.white10 : Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? Colors.greenAccent : Colors.green,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Status Tags
                Row(
                  children: [
                    _buildStatusTag(
                      icon: Icons.check_circle,
                      label: "Farm: Active",
                      color: Colors.green,
                    ),
                    const SizedBox(width: 12),
                    _buildStatusTag(
                      icon: Icons.spa,
                      label: "Stage: Germination",
                      color: Colors.orange,
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

  Widget _buildStatusTag({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabCard extends StatefulWidget {
  final bool isDark;
  const _TabCard({required this.isDark});

  @override
  State<_TabCard> createState() => _TabCardState();
}

class _TabCardState extends State<_TabCard> {
  int selectedIndex = 0;

  final List<String> _tabs = [
    "Farm Setting",
    "User Setting",
    "Data Setting",
    "Notifications", // New tab added
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final screenWidth = MediaQuery.of(context).size.width;
    final Color activeBg = isDark ? Colors.white : Colors.black;
    final Color activeText = isDark ? Colors.black : Colors.white;
    final Color borderColor = isDark ? Colors.white60 : Colors.black87;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black12,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Original tab style preserved
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: List.generate(_tabs.length, (index) {
                final isSelected = selectedIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => selectedIndex = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? activeBg : Colors.transparent,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: borderColor, width: 1),
                    ),
                    child: Text(
                      _tabs[index],
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? activeText : borderColor,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Content area
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildTabContent(selectedIndex),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(int index) {
    switch (index) {
      case 0:
        return _buildFarmSettingsContent();
      case 1:
        return _buildUserSettingsContent();
      case 2:
        return _buildDataSettingsContent();
      case 3:
        return _buildNotificationsContent(); // New content
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildFarmSettingsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSettingCard(
          icon: Icons.agriculture,
          title: "Farm Information",
          children: [
            _buildInfoRow("Farm Name", "Green Valley Farm"),
            _buildInfoRow("Location", "Central Region, Ghana"),
            _buildInfoRow("Size", "5.2 hectares"),
            _buildInfoRow("Established", "January 2018"),
          ],
        ),
        const SizedBox(height: 16),
        _buildSettingCard(
          icon: Icons.grass,
          title: "Crop Details",
          children: [
            _buildInfoRow("Current Crop", "Lettuce (Batavia)"),
            _buildInfoRow("Planting Date", "March 15, 2023"),
            _buildInfoRow("Growth Stage", "Vegetative (65%)"),
            LinearProgressIndicator(
              value: 0.65,
              minHeight: 8,
              backgroundColor: widget.isDark ? Colors.white10 : Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.isDark ? Colors.greenAccent : Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserSettingsContent() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // User Profile Card - Enhanced
      Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: widget.isDark ? Colors.grey[800] : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header with Avatar
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.isDark ? Colors.greenAccent : Colors.green,
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundImage: AssetImage("owner/owner.png"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "John Doe",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: widget.isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: widget.isDark ? Colors.green[900] : Colors.green[100],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            "Farm Owner",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: widget.isDark ? Colors.greenAccent : Colors.green[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.edit,
                      color: widget.isDark ? Colors.greenAccent : Colors.green,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Profile Details
              _buildProfileDetailItem(Icons.email, "Email", "john@greenvalley.com"),
              const SizedBox(height: 12),
              _buildProfileDetailItem(Icons.phone, "Phone", "+233 24 765 4321"),
              const SizedBox(height: 12),
              _buildProfileDetailItem(Icons.calendar_today, "Member Since", "Jan 2020"),
              const SizedBox(height: 12),
              _buildProfileDetailItem(Icons.login, "Last Login", "Today, 10:30 AM"),
            ],
          ),
        ),
      ),
      const SizedBox(height: 20),

      // Permissions Card - Enhanced
      Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: widget.isDark ? Colors.grey[800] : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.security,
                    size: 24,
                    color: widget.isDark ? Colors.greenAccent : Colors.green,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Access Permissions",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: widget.isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildPermissionItem("Access Level", "Administrator", Icons.admin_panel_settings),
              const SizedBox(height: 12),
              _buildPermissionItem("Farm Access", "Full Control", Icons.agriculture),
              const SizedBox(height: 12),
              _buildPermissionItem("Data Access", "Read/Write", Icons.data_usage),
              const SizedBox(height: 12),
              _buildPermissionItem("User Management", "Add/Remove Users", Icons.people_alt),
            ],
          ),
        ),
      ),
      const SizedBox(height: 20),

      // Caretakers Card - Enhanced
      Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: widget.isDark ? Colors.grey[800] : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.people,
                    size: 24,
                    color: widget.isDark ? Colors.greenAccent : Colors.green,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Assigned Caretakers",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: widget.isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.add_circle,
                      color: widget.isDark ? Colors.greenAccent : Colors.green,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildCaretakerCard(
                name: "Kwame Mensah",
                role: "Senior Caretaker",
                phone: "+233 24 123 4567",
                email: "kwame@greenvalley.com",
                image: "caretakers/kwame.jpg",
                status: "Active",
                lastActive: "2 hours ago",
              ),
             
            ],
          ),
        ),
      ),
    ],
  );
}

// Helper Widgets for the Enhanced Design
Widget _buildProfileDetailItem(IconData icon, String label, String value) {
  return Row(
    children: [
      Icon(
        icon,
        size: 20,
        color: widget.isDark ? Colors.white70 : Colors.grey[600],
      ),
      const SizedBox(width: 12),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: widget.isDark ? Colors.white60 : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: widget.isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    ],
  );
}

Widget _buildPermissionItem(String title, String value, IconData icon) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: widget.isDark ? Colors.grey[700] : Colors.grey[100],
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: widget.isDark ? Colors.greenAccent : Colors.green,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: widget.isDark ? Colors.white70 : Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: widget.isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.chevron_right,
          color: widget.isDark ? Colors.white60 : Colors.grey[500],
        ),
      ],
    ),
  );
}

Widget _buildCaretakerCard({
  required String name,
  required String role,
  required String phone,
  required String email,
  required String image,
  required String status,
  required String lastActive,
}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: widget.isDark ? Colors.grey[700] : Colors.grey[50],
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: widget.isDark ? Colors.white60 : Colors.grey[300]!,
      ),
    ),
    child: Column(
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: AssetImage(image),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: widget.isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    role,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: widget.isDark ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: status == "Active"
                    ? (widget.isDark ? Colors.green[900] : Colors.green[50])
                    : (widget.isDark ? Colors.orange[900] : Colors.orange[50]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: status == "Active"
                      ? (widget.isDark ? Colors.greenAccent : Colors.green)
                      : (widget.isDark ? Colors.orangeAccent : Colors.orange),
                ),
              ),
              child: Text(
                status,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: status == "Active"
                      ? (widget.isDark ? Colors.greenAccent : Colors.green[800])
                      : (widget.isDark ? Colors.orangeAccent : Colors.orange[800]),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildContactInfoItem(Icons.phone, phone),
            ),
            Expanded(
              child: _buildContactInfoItem(Icons.email, email),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Divider(
          color: widget.isDark ? Colors.grey[600] : Colors.grey[200],
          height: 1,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Last active: $lastActive",
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: widget.isDark ? Colors.white60 : Colors.grey[600],
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.message,
                    size: 20,
                    color: widget.isDark ? Colors.greenAccent : Colors.green,
                  ),
                  onPressed: () {},
                ),
                IconButton(
                  icon: Icon(
                    Icons.call,
                    size: 20,
                    color: widget.isDark ? Colors.blueAccent : Colors.blue,
                  ),
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _buildContactInfoItem(IconData icon, String text) {
  return Row(
    children: [
      Icon(
        icon,
        size: 16,
        color: widget.isDark ? Colors.white70 : Colors.grey[600],
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: widget.isDark ? Colors.white70 : Colors.grey[600],
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

  Widget _buildDataSettingsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSettingCard(
          icon: Icons.settings,
          title: "System Settings",
          children: [
            _buildInfoRow("Data Sync", "Every 15 minutes"),
            _buildInfoRow("Backup Schedule", "Daily at 2:00 AM"),
            _buildInfoRow("Storage Used", "1.2GB of 5GB"),
          ],
        ),
        const SizedBox(height: 16),
        _buildSettingCard(
          icon: Icons.analytics,
          title: "Monitoring",
          children: [
            _buildInfoRow("Temperature Range", "15°C - 22°C"),
            _buildInfoRow("Humidity Range", "50% - 70%"),
            _buildInfoRow("Light Intensity", "800-1200 lux"),
          ],
        ),
      ],
    );
  }

  Widget _buildNotificationsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSettingCard(
          icon: Icons.notifications,
          title: "Notification Settings",
          children: [
            SwitchListTile(
              title: Text(
                "Enable Push Notifications",
                style: GoogleFonts.poppins(
                  color: widget.isDark ? Colors.white : Colors.black,
                ),
              ),
              value: true,
              onChanged: (value) {},
            ),
            const Divider(height: 1),
            SwitchListTile(
              title: Text(
                "Email Alerts",
                style: GoogleFonts.poppins(
                  color: widget.isDark ? Colors.white : Colors.black,
                ),
              ),
              value: true,
              onChanged: (value) {},
            ),
            const Divider(height: 1),
            SwitchListTile(
              title: Text(
                "SMS Notifications",
                style: GoogleFonts.poppins(
                  color: widget.isDark ? Colors.white : Colors.black,
                ),
              ),
              value: false,
              onChanged: (value) {},
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSettingCard(
          icon: Icons.warning,
          title: "Alert Preferences",
          children: [
            _buildInfoRow("Temperature Alerts", "When outside 15°C-22°C"),
            _buildInfoRow("Humidity Alerts", "When outside 50%-70%"),
            _buildInfoRow("Irrigation Alerts", "System failures only"),
          ],
        ),
        const SizedBox(height: 16),
        _buildSettingCard(
          icon: Icons.history,
          title: "Recent Notifications",
          children: [
            _buildNotificationItem(
              "Irrigation System Activated",
              "Today, 06:00 AM",
              Icons.opacity,
            ),
            const Divider(height: 16),
            _buildNotificationItem(
              "Temperature Alert: 24°C Detected",
              "Yesterday, 02:30 PM",
              Icons.thermostat,
            ),
            const Divider(height: 16),
            _buildNotificationItem(
              "Caretaker Kwame checked in",
              "Yesterday, 10:15 AM",
              Icons.person,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCaretakerInfo({
    required String name,
    required String role,
    required String contact,
    required String image,
  }) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundImage: AssetImage(image),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: widget.isDark ? Colors.white : Colors.black,
                ),
              ),
              Text(
                role,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: widget.isDark ? Colors.white70 : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.phone,
                    size: 16,
                    color: widget.isDark ? Colors.greenAccent : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    contact,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: widget.isDark ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.message,
            color: widget.isDark ? Colors.greenAccent : Colors.green,
          ),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildNotificationItem(String title, String time, IconData icon) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: widget.isDark ? Colors.grey[800] : Colors.grey[200],
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 20,
          color: widget.isDark ? Colors.greenAccent : Colors.green,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: widget.isDark ? Colors.white : Colors.black,
        ),
      ),
      subtitle: Text(
        time,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: widget.isDark ? Colors.white60 : Colors.grey[600],
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: widget.isDark ? Colors.white60 : Colors.grey[600],
      ),
      onTap: () {},
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      color: widget.isDark ? Colors.grey[800] : Colors.grey[100],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: widget.isDark ? Colors.greenAccent : Colors.green[700],
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: widget.isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: widget.isDark ? Colors.white70 : Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: widget.isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

  

