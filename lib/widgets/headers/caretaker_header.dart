import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/colors.dart';
import '../dialogs/user_profile_popup.dart'; // Import the new popup
import '../../screens/caretaker/care_taker_settings.dart';

class CaretakerHeader extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onMenuPressed;
  final bool isDark;
  final VoidCallback? onToggleDarkMode;
  final String adminName;
  final String subtitle;
  final String avatarImage;

  const CaretakerHeader({
    super.key,
    this.onMenuPressed,
    required this.isDark,
    this.onToggleDarkMode,
    this.adminName = "Acquaye",
    this.subtitle = "Welcome back to your",
    this.avatarImage = "https://png.pngtree.com/png-vector/20220817/ourmid/pngtree-women-cartoon-avatar-in-flat-style-png-image_6110776.png",
  });

  @override
  Size get preferredSize => const Size.fromHeight(100);

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good morning";
    if (hour < 18) return "Good afternoon";
    return "Good evening";
  }

  // Add these methods to your CaretakerHeader class

void _showUserProfilePopup(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => UserProfilePopup(
      isDark: isDark,
      userName: adminName,
      userEmail: "acquaye@farmcare.com",
      userRole: "Senior Caretaker",
      avatarImage: avatarImage,
      onEditProfile: () => _handleEditProfile(context),
      onSettings: () => _handleSettings(context, isDark),
      onHelpSupport: () => _handleHelpSupport(context),
      onAbout: () => _handleAbout(context),
      onLogout: () => _handleLogout(context),
    ),
  );
}

void _handleEditProfile(BuildContext context) {
  Navigator.pop(context); // Close the profile popup
  _showEditProfileDialog(context);
}

void _handleSettings(BuildContext context, bool isDark) {
  Navigator.pop(context);
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => CareTakerSettingsScreen(),
      settings: RouteSettings(arguments: {'isDark': isDark}),
    ),
  );
}

void _handleHelpSupport(BuildContext context) {
  Navigator.pop(context); // Close the profile popup
  _showHelpSupportDialog(context);
}

void _handleAbout(BuildContext context) {
  Navigator.pop(context); // Close the profile popup
  _showAboutDialog(context);
}

void _handleLogout(BuildContext context) {
  Navigator.pop(context); // Close the profile popup
  _showLogoutConfirmation(context);
}

// Edit Profile Dialog
void _showEditProfileDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      title: Text(
        "Edit Profile",
        style: GoogleFonts.poppins(
          color: isDark ? Colors.white : Colors.black,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            decoration: InputDecoration(
              labelText: "Full Name",
              labelStyle: GoogleFonts.poppins(
                color: isDark ? Colors.white70 : Colors.grey[600],
              ),
            ),
            style: GoogleFonts.poppins(
              color: isDark ? Colors.white : Colors.black,
            ),
            initialValue: adminName,
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: InputDecoration(
              labelText: "Email",
              labelStyle: GoogleFonts.poppins(
                color: isDark ? Colors.white70 : Colors.grey[600],
              ),
            ),
            style: GoogleFonts.poppins(
              color: isDark ? Colors.white : Colors.black,
            ),
            initialValue: "acquaye@farmcare.com",
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: InputDecoration(
              labelText: "Phone Number",
              labelStyle: GoogleFonts.poppins(
                color: isDark ? Colors.white70 : Colors.grey[600],
              ),
            ),
            style: GoogleFonts.poppins(
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            "Cancel",
            style: GoogleFonts.poppins(
              color: isDark ? Colors.white70 : Colors.grey[600],
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Profile updated successfully",
                  style: GoogleFonts.poppins(),
                ),
                backgroundColor: Colors.green,
              ),
            );
          },
          child: const Text("Save Changes"),
        ),
      ],
    ),
  );
}

// Help & Support Dialog
void _showHelpSupportDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      title: Text(
        "Help & Support",
        style: GoogleFonts.poppins(
          color: isDark ? Colors.white : Colors.black,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSupportOption(
            context,
            Icons.email_outlined,
            "Email Support",
            "support@farmcare.com",
            () => _launchEmail(),
          ),
          const SizedBox(height: 16),
          _buildSupportOption(
            context,
            Icons.phone_outlined,
            "Call Support",
            "+1 (555) 123-4567",
            () => _launchPhoneCall(),
          ),
          const SizedBox(height: 16),
          _buildSupportOption(
            context,
            Icons.chat_outlined,
            "Live Chat",
            "Available 24/7",
            () => _startLiveChat(),
          ),
          const SizedBox(height: 16),
          _buildSupportOption(
            context,
            Icons.help_outline,
            "FAQs",
            "Frequently Asked Questions",
            () => _openFAQs(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            "Close",
            style: GoogleFonts.poppins(
              color: isDark ? Colors.white70 : Colors.grey[600],
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildSupportOption(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap) {
  return ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(
      icon,
      color: isDark ? Colors.greenAccent : Colors.green,
      size: 24,
    ),
    title: Text(
      title,
      style: GoogleFonts.poppins(
        color: isDark ? Colors.white : Colors.black,
        fontWeight: FontWeight.w500,
      ),
    ),
    subtitle: Text(
      subtitle,
      style: GoogleFonts.poppins(
        color: isDark ? Colors.white70 : Colors.grey[600],
        fontSize: 12,
      ),
    ),
    onTap: onTap,
  );
}

void _launchEmail() {
  // Implement email launch
  print("Launching email...");
}

void _launchPhoneCall() {
  // Implement phone call
  print("Launching phone call...");
}

void _startLiveChat() {
  // Implement live chat
  print("Starting live chat...");
}

void _openFAQs() {
  // Implement FAQs
  print("Opening FAQs...");
}

// About Dialog
void _showAboutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      title: Text(
        "About FarmCare",
        style: GoogleFonts.poppins(
          color: isDark ? Colors.white : Colors.black,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Image.asset(
              isDark ? 'assets/logos/logo_white.png' : 'assets/logos/logo_black.png',
              height: 60,
              width: 60,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "FarmCare v1.0.0",
            style: GoogleFonts.poppins(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Comprehensive farm management solution for modern agriculture.",
            style: GoogleFonts.poppins(
              color: isDark ? Colors.white70 : Colors.grey[600],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Features:",
            style: GoogleFonts.poppins(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          _buildFeatureItem("Real-time monitoring"),
          _buildFeatureItem("Automated irrigation"),
          _buildFeatureItem("Crop health analysis"),
          _buildFeatureItem("Weather integration"),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            "Close",
            style: GoogleFonts.poppins(
              color: isDark ? Colors.white70 : Colors.grey[600],
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildFeatureItem(String feature) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Icon(
          Icons.check_circle,
          size: 16,
          color: isDark ? Colors.greenAccent : Colors.green,
        ),
        const SizedBox(width: 8),
        Text(
          feature,
          style: GoogleFonts.poppins(
            color: isDark ? Colors.white70 : Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}

// Logout Confirmation (updated)
void _showLogoutConfirmation(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 350,
            minWidth: 280,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.logout_rounded,
                  size: 48,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 16),
                Text(
                  "Logout",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Are you sure you want to logout?",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        "Cancel",
                        style: GoogleFonts.poppins(
                          color: isDark ? Colors.white70 : Colors.grey[600],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        // Perform actual logout logic
                        _performLogout(context);
                      },
                      child: const Text("Logout"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

void _performLogout(BuildContext context) {
  // Implement your actual logout logic here
  print("User logged out");
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        "Logged out successfully",
        style: GoogleFonts.poppins(),
      ),
      backgroundColor: Colors.green,
    ),
  );
  
  // Example: Navigate to login screen
  // Navigator.pushAndRemoveUntil(
  //   context,
  //   MaterialPageRoute(builder: (context) => LoginScreen()),
  //   (route) => false,
  // );
}
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 600;
    final isVerySmall = screenWidth < 400;

    return Container(
      height: isSmall ? 150 : preferredSize.height,
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 16 : 24,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.transparent,
      ),
      child: isSmall
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Logo - Top left on small screens
                    Image.asset(
                      isDark
                          ? 'assets/logos/logo_white.png'
                          : 'assets/logos/logo_black.png',
                      height: isVerySmall ? 60 : 80,
                      width: isVerySmall ? 60 : 80,
                      fit: BoxFit.contain,
                    ),
                    const Spacer(),
                    // Dropdown menu on the right
                    _HeaderDropdown(
                      isDark: isDark,
                      onToggleDarkMode: onToggleDarkMode,
                    ),
                  ],
                ),
                // Greeting text below logo on small screens
                Text(
                  "${_greeting()}, $adminName",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: isVerySmall ? 16 : 18,
                    color: isDark ? Colors.white : AppColors.darkBackground,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w400,
                        fontSize: isVerySmall ? 12 : 13,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                    Icon(
                      Icons.admin_panel_settings,
                      color: isDark ? Colors.white : Colors.black,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Your Panel",
                      style: GoogleFonts.poppins(
                        color: isDark ? Colors.white : AppColors.darkBackground,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                // Logo Section
                Padding(
                  padding: const EdgeInsets.only(right: 40),
                  child: Image.asset(
                    isDark
                        ? 'assets/logos/logo_white.png'
                        : 'assets/logos/logo_black.png',
                    height: isVerySmall ? 60 : 92,
                    width: isVerySmall ? 60 : 92,
                    fit: BoxFit.contain,
                  ),
                ),
                // Greeting Section
                Flexible(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${_greeting()}, $adminName",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: isVerySmall ? 16 : 20,
                          color:
                              isDark ? Colors.white : AppColors.darkBackground,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            subtitle,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w400,
                              fontSize: isVerySmall ? 12 : 14,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                            ),
                          ),
                          if (!isVerySmall) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.admin_panel_settings,
                              color: isDark ? Colors.white : Colors.black,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "Your Panel",
                              style: GoogleFonts.poppins(
                                color: isDark
                                    ? Colors.white
                                    : AppColors.darkBackground,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Right side actions
                _buildActionButton(
                  icon: isDark
                      ? Icons.wb_sunny_outlined
                      : Icons.dark_mode_outlined,
                  tooltip: isDark ? "Light Mode" : "Dark Mode",
                  onPressed: onToggleDarkMode,
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  icon: Icons.notifications_none_outlined,
                  tooltip: "Notifications",
                  onPressed: () {},
                ),
                const SizedBox(width: 8),
                _buildUserAvatar(context),
              ],
            ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    VoidCallback? onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.grey.withOpacity(0.2)
            : Colors.grey.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: isDark ? Colors.white : AppColors.darkBackground,
          size: 22,
        ),
        onPressed: onPressed,
        tooltip: tooltip,
        splashRadius: 20,
      ),
    );
  }

  Widget _buildUserAvatar(BuildContext context) {
    final isVerySmall = MediaQuery.of(context).size.width < 450;
    return GestureDetector(
      onTap: () => _showUserProfilePopup(context), // Updated to show profile popup
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.grey.withOpacity(0.2)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(avatarImage),
              child: avatarImage.isEmpty
                  ? Icon(Icons.person,
                      color: isDark ? Colors.white : Colors.black)
                  : null,
            ),
            if (!isVerySmall) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down,
                color: isDark ? Colors.white : Colors.black,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeaderDropdown extends StatelessWidget {
  final bool isDark;
  final VoidCallback? onToggleDarkMode;

  const _HeaderDropdown({
    Key? key,
    required this.isDark,
    this.onToggleDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      icon: Container(
        decoration: BoxDecoration(
          color: isDark
              ? Colors.grey.withOpacity(0.2)
              : Colors.grey.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(8),
        child: Icon(
          Icons.more_vert,
          color: isDark ? Colors.white : AppColors.primary,
          size: 22,
        ),
      ),
      onSelected: (value) {
        switch (value) {
          case 0:
            onToggleDarkMode?.call();
            break;
          case 1:
            // Notification action
            break;
          case 2:
            // Profile action
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 0,
          child: Row(
            children: [
              Icon(
                isDark ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined,
                color: AppColors.primary,
                size: 21,
              ),
              const SizedBox(width: 10),
              Text(isDark ? "Light Mode" : "Dark Mode"),
            ],
          ),
        ),
        PopupMenuItem(
          value: 1,
          child: Row(
            children: [
              Icon(
                Icons.notifications_none_outlined,
                color: AppColors.primary,
                size: 21,
              ),
              const SizedBox(width: 10),
              Text("Notifications"),
            ],
          ),
        ),
        PopupMenuItem(
          value: 2,
          child: Row(
            children: [
              Icon(
                Icons.person_outline,
                color: AppColors.primary,
                size: 21,
              ),
              const SizedBox(width: 10),
              Text("Account"),
            ],
          ),
        ),
      ],
    );
  }
}