import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/headers/caretaker_header.dart';
import '../../widgets/sidebars/caretaker_sidebar.dart';
import '../../widgets/dialogs/edit_profile_dialog.dart';

class CareTakerSettingsScreen extends StatefulWidget {
  const CareTakerSettingsScreen({super.key });

  @override
  State<CareTakerSettingsScreen> createState() => _CareTakerSettingsScreenState();
}

class _CareTakerSettingsScreenState extends State<CareTakerSettingsScreen> {
  int selectedIndex = 2;
  bool isDark = false;
  // Modal control variables
  bool _showEditProfileModal = false;
  bool _showChangePasswordModal = false;
  bool _showNotificationPrefsModal = false;

  // Form variables
  final _profileFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  final _profileNameController = TextEditingController();
  final _profileEmailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      setState(() => isDark = args?['isDark'] ?? false);
    });
  }

  bool get isLargeScreen {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth > 800;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_showEditProfileModal) {
        _showEditProfileModal = false;
        _showEditProfileDialog();
      }
      if (_showChangePasswordModal) {
        _showChangePasswordModal = false;
        _showChangePasswordDialog(context);
      }
      if (_showNotificationPrefsModal) {
        _showNotificationPrefsModal = false;
        _showNotificationPrefsDialog(context);
      }
    });

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
              CaretakerHeader(
                isDark: isDark,
                onToggleDarkMode: () => setState(() => isDark = !isDark),
                onMenuPressed: isMobile ? () => _openSidebar(context) : null,
              ),
              Expanded(
                child: Row(
                  children: [
                    if (!isMobile)
                      CaretakerSidebar(
                        selectedIndex: selectedIndex,
                        onItemSelected: (idx) =>
                            setState(() => selectedIndex = idx),
                        isDark: isDark,
                        isMobile: false,
                      ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isLargeScreen ? 24 : 16,
                            vertical: 16,
                          ),
                          child: isLargeScreen 
                              ? _buildGridLayout() 
                              : _buildListLayout(),
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
          ? CaretakerSidebar(
              selectedIndex: selectedIndex,
              onItemSelected: (idx) => setState(() => selectedIndex = idx),
              isDark: isDark,
              isMobile: true,
            )
          : null,
      endDrawer: isMobile
          ? Drawer(
              child: CaretakerSidebar(
                selectedIndex: selectedIndex,
                onItemSelected: (idx) {
                  setState(() => selectedIndex = idx);
                  Navigator.pop(context);
                },
                isDark: isDark,
                isMobile: false,
              ),
            )
          : null,
    );
  }

  Widget _buildGridLayout() {
    return Column(
      children: [
        const SizedBox(height: 16),
        _buildSettingsHeader(false),
        const SizedBox(height: 24),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          childAspectRatio: 1.5,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildAccountSettingsCard(),
            _buildNotificationSettingsCard(),
            _buildFarmPreferencesCard(),
            _buildSystemSettingsCard(),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildListLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        _buildSettingsHeader(true),
        const SizedBox(height: 24),
        _buildAccountSettingsCard(),
        const SizedBox(height: 16),
        _buildNotificationSettingsCard(),
        const SizedBox(height: 16),
        _buildFarmPreferencesCard(),
        const SizedBox(height: 16),
        _buildSystemSettingsCard(),
        const SizedBox(height: 32),
      ],
    );
  }

  void _openSidebar(BuildContext context) {
    Scaffold.of(context).openEndDrawer();
  }

  Widget _buildSettingsHeader(bool isMobile) {
    return Row(
      children: [
        Icon(
          Icons.settings,
          size: isMobile ? 28 : 32,
          color: isDark ? Colors.greenAccent : Colors.green[700],
        ),
        const SizedBox(width: 12),
        Text(
          "Farm Settings",
          style: GoogleFonts.poppins(
            fontSize: isMobile ? 22 : 24,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSettingsCard() {
    return _buildSettingsCard(
      icon: Icons.person,
      title: "Account Settings",
      children: [
        _buildSettingsItem(
          icon: Icons.edit,
          title: "Edit Profile",
          onTap: () => setState(() => _showEditProfileModal = true),
        ),
        _buildSettingsItem(
          icon: Icons.lock,
          title: "Change Password",
          onTap: () => setState(() => _showChangePasswordModal = true),
        ),
        _buildSettingsItem(
          icon: Icons.notifications_active,
          title: "Notification Preferences",
          onTap: () => setState(() => _showNotificationPrefsModal = true),
        ),
        _buildSettingsItem(
          icon: Icons.language,
          title: "Language",
          trailing: Text(
            "English",
            style: GoogleFonts.poppins(
              color: isDark ? Colors.white70 : Colors.grey[600],
            ),
          ),
          onTap: () {},
        ),
      ],
    );
  }

  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => EditProfileDialog(
        isDark: isDark,
        initialFirstName: "John",
        initialLastName: "Doe",
        initialUsername: "johndoe",
        initialEmail: "john@example.com",
        onSave: (firstName, lastName, email, username) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Profile updated"),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  final isSmallScreen = screenWidth < 400;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 500,
            minWidth: 300,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _passwordFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Change Password",
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close,
                            color: isDark ? Colors.white70 : Colors.grey[600]),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Current Password Field
                    _buildPasswordField(
                      controller: _currentPasswordController,
                      label: "Current Password",
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your current password';
                        }
                        if (value.length < 6) {
                          return 'Must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // New Password Field
                    _buildPasswordField(
                      controller: _newPasswordController,
                      label: "New Password",
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a new password';
                        }
                        if (value.length < 8) {
                          return 'Must be at least 8 characters';
                        }
                        if (!RegExp(r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9]).{8,}$').hasMatch(value)) {
                          return 'Include uppercase, lowercase & numbers';
                        }
                        return null;
                      },
                      helperText: "Must be 8+ characters with uppercase, lowercase & numbers",
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Confirm Password Field
                    _buildPasswordField(
                      controller: _confirmPasswordController,
                      label: "Confirm New Password",
                      validator: (value) {
                        if (value != _newPasswordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: isDark ? Colors.white70 : Colors.grey[700],
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text("Cancel"),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? Colors.greenAccent : Colors.green,
                            foregroundColor: isDark ? Colors.black : Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            if (_passwordFormKey.currentState!.validate()) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Password updated successfully",
                                    style: GoogleFonts.poppins(),
                                  ),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  margin: const EdgeInsets.all(16),
                                ),
                              );
                            }
                          },
                          child: const Text("Update Password"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

Widget _buildPasswordField({
  required TextEditingController controller,
  required String label,
  required String? Function(String?)? validator,
  String? helperText,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: isDark ? Colors.white70 : Colors.grey[700],
        ),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: controller,
        obscureText: true,
        validator: validator,
        style: GoogleFonts.poppins(
          color: isDark ? Colors.white : Colors.black,
        ),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: isDark ? Colors.grey[700]! : Colors.grey[400]!,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: isDark ? Colors.grey[700]! : Colors.grey[400]!,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: isDark ? Colors.greenAccent : Colors.green,
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: Colors.red,
              width: 1.5,
            ),
          ),
          helperText: helperText,
          helperStyle: GoogleFonts.poppins(
            fontSize: 12,
            color: isDark ? Colors.white60 : Colors.grey[600],
          ),
        ),
      ), 
    ],
  );
}

  void _showNotificationPrefsDialog(BuildContext context) {
    bool pushNotifications = true;
    bool emailNotifications = true;
    bool smsNotifications = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: isDark ? Colors.grey[850] : Colors.white,
              title: Text(
                "Notification Preferences",
                style: GoogleFonts.poppins(
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.notifications,
                        color: isDark ? Colors.greenAccent : Colors.green,
                      ),
                      title: Text(
                        "Push Notifications",
                        style: GoogleFonts.poppins(
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      trailing: Switch(
                        value: pushNotifications,
                        onChanged: (value) =>
                            setState(() => pushNotifications = value),
                        activeThumbColor: isDark ? Colors.greenAccent : Colors.green,
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.email,
                        color: isDark ? Colors.greenAccent : Colors.green,
                      ),
                      title: Text(
                        "Email Notifications",
                        style: GoogleFonts.poppins(
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      trailing: Switch(
                        value: emailNotifications,
                        onChanged: (value) =>
                            setState(() => emailNotifications = value),
                        activeThumbColor: isDark ? Colors.greenAccent : Colors.green,
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.sms,
                        color: isDark ? Colors.greenAccent : Colors.green,
                      ),
                      title: Text(
                        "SMS Notifications",
                        style: GoogleFonts.poppins(
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      trailing: Switch(
                        value: smsNotifications,
                        onChanged: (value) =>
                            setState(() => smsNotifications = value),
                        activeThumbColor: isDark ? Colors.greenAccent : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text(
                    "Cancel",
                    style: GoogleFonts.poppins(
                      color: isDark ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.greenAccent : Colors.green,
                  ),
                  child: Text(
                    "Save Preferences",
                    style: GoogleFonts.poppins(
                      color: isDark ? Colors.black : Colors.white,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Notification preferences updated",
                          style: GoogleFonts.poppins(),
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildNotificationSettingsCard() {
    return _buildSettingsCard(
      icon: Icons.notifications,
      title: "Alerts & Notifications",
      children: [
        _buildSwitchSetting(
          icon: Icons.warning,
          title: "Critical Alerts",
          value: true,
          onChanged: (val) {},
        ),
        _buildSwitchSetting(
          icon: Icons.water_drop,
          title: "Irrigation Notifications",
          value: true,
          onChanged: (val) {},
        ),
        _buildSwitchSetting(
          icon: Icons.thermostat,
          title: "Temperature Warnings",
          value: false,
          onChanged: (val) {},
        ),
        _buildSwitchSetting(
          icon: Icons.bug_report,
          title: "Pest Alerts",
          value: true,
          onChanged: (val) {},
        ),
      ],
    );
  }

  Widget _buildFarmPreferencesCard() {
    return _buildSettingsCard(
      icon: Icons.agriculture,
      title: "Farm Preferences",
      children: [
        _buildSettingsItem(
          icon: Icons.straighten,
          title: "Measurement Units",
          trailing: Text(
            "Metric",
            style: GoogleFonts.poppins(
              color: isDark ? Colors.white70 : Colors.grey[600],
            ),
          ),
          onTap: () {},
        ),
        _buildSettingsItem(
          icon: Icons.schedule,
          title: "Working Hours",
          trailing: Text(
            "6:00 AM - 6:00 PM",
            style: GoogleFonts.poppins(
              color: isDark ? Colors.white70 : Colors.grey[600],
            ),
          ),
          onTap: () {},
        ),
        _buildSettingsItem(
          icon: Icons.calendar_today,
          title: "Schedule Preferences",
          onTap: () {},
        ),
        _buildSettingsItem(
          icon: Icons.help_outline,
          title: "Farm Guidelines",
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildSystemSettingsCard() {
    return _buildSettingsCard(
      icon: Icons.phone_android,
      title: "System Settings",
      children: [
        _buildSwitchSetting(
          icon: Icons.dark_mode,
          title: "Dark Mode",
          value: isDark,
          onChanged: (val) => setState(() => isDark = val),
        ),
        _buildSettingsItem(
          icon: Icons.storage,
          title: "Data Usage",
          onTap: () {},
        ),
        _buildSettingsItem(
          icon: Icons.backup,
          title: "Backup & Sync",
          onTap: () {},
        ),
        _buildSettingsItem(
          icon: Icons.help,
          title: "Help & Support",
          onTap: () {},
        ),
        _buildSettingsItem(
          icon: Icons.info,
          title: "About FarmCare",
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildSettingsCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: isLargeScreen ? 200 : 0,

      ),
      child: Card(
        elevation: 0,
        color: isDark ? Colors.grey[850] : Colors.white,
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
                    size: 24,
                    color: isDark ? Colors.greenAccent : Colors.green[700],
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        size: 24,
        color: isDark ? Colors.greenAccent : Colors.green[700],
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildSwitchSetting({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        size: 24,
        color: isDark ? Colors.greenAccent : Colors.green[700],
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: isDark ? Colors.greenAccent : Colors.green,
      ),
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