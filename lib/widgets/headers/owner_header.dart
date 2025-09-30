import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/colors.dart';

class OwnerHeader extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onMenuPressed;
  final bool isDark;
  final VoidCallback? onToggleDarkMode;
  final String adminName;
  final String subtitle;
  final String avatarImage;

  const OwnerHeader({
    super.key,
    this.onMenuPressed,
    required this.isDark,
    this.onToggleDarkMode,
    this.adminName = "Acquaye",
    this.subtitle = "Welcome back to your",
    this.avatarImage =
        "https://png.pngtree.com/png-vector/20220817/ourmid/pngtree-women-cartoon-avatar-in-flat-style-png-image_6110776.png",
  });

  @override
  Size get preferredSize => const Size.fromHeight(100);

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good morning";
    if (hour < 18) return "Good afternoon";
    return "Good evening";
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
                      "Owner Panel",
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
                              "Owner Panel",
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
      onTap: () => _showUserMenu(context),
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

  void _showUserMenu(BuildContext context) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width - 200,
        100,
        20,
        0,
      ),
      items: [
        PopupMenuItem(
          child: const Text("Profile"),
          onTap: () {},
        ),
        PopupMenuItem(
          child: const Text("Settings"),
          onTap: () {},
        ),
        PopupMenuItem(
          child: const Text("Logout"),
          onTap: () {},
        ),
      ],
    );
  }
}

class _HeaderDropdown extends StatelessWidget {
  final bool isDark;
  final VoidCallback? onToggleDarkMode;

  const _HeaderDropdown({
    super.key,
    required this.isDark,
    this.onToggleDarkMode,
  });

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
