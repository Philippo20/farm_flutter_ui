import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/colors.dart';

class AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool isDark;
  final bool isMobile;
  final String userName;
  final String userEmail;
  final String userAvatar;

  const AdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.isDark,
    required this.isMobile,
    this.userName = "Admin User",
    this.userEmail = "admin@farmestates.com",
    this.userAvatar = "",
  });

  @override
  Widget build(BuildContext context) {
    final navItems = [
      _NavItem(icon: Icons.dashboard_outlined, label: 'Home', activeIcon: Icons.dashboard, route: '/dashboard'),
      _NavItem(icon: Icons.people_outline, label: 'Users', activeIcon: Icons.people, route: '/users'),
      _NavItem(icon: Icons.agriculture_outlined, label: 'Farms', activeIcon: Icons.agriculture, route: '/farms'),
      _NavItem(icon: Icons.sensors_outlined, label: 'Sensors', activeIcon: Icons.sensors, route: '/sensors'),
      _NavItem(icon: Icons.settings_outlined, label: 'Settings', activeIcon: Icons.settings, route: '/settings'),
    ];

    if (isMobile) {
      return _buildMobileBottomBar(navItems, context);
    } else {
      return _buildDesktopSidebar(navItems);
    }
  }

  Widget _buildDesktopSidebar(List<_NavItem> navItems) {
    final textColor = isDark ? Colors.white : const Color(0xFF232535);
    final selectedColor = isDark ? AppColors.primary : AppColors.primary;

    return SizedBox(
      width: 115,
      
      child: Column(
        children: [
          const SizedBox(height: 40),
          Expanded(
            child: Center(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: navItems.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, idx) {
                  final item = navItems[idx];
                  final bool selected = idx == selectedIndex;

                  return Material(
                    color: selected ? selectedColor.withOpacity(0.15) : Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                      side: BorderSide(
                        color: selected ? selectedColor.withOpacity(0.3) : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: InkWell(
                      onTap: () {
                        onItemSelected(idx);
                        Navigator.of(context).pushReplacementNamed(item.route, arguments: {'isDark': isDark});
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              selected ? item.activeIcon : item.icon,
                              size: 25,
                              color: selected ? selectedColor : textColor.withOpacity(0.8),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.label,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: selected ? selectedColor : textColor.withOpacity(0.9),
                                fontWeight: selected ? FontWeight.w500 : FontWeight.normal,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white12 : Colors.black12,
                  width: 1,
                ),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  // Handle logout
                },
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(
                    Icons.logout,
                    color: AppColors.danger,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileBottomBar(List<_NavItem> navItems, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: navItems.map((item) {
              final index = navItems.indexOf(item);
              final selected = index == selectedIndex;
              final color = selected 
                  ? AppColors.primary 
                  : (isDark ? Colors.grey[400] : Colors.grey[600]);

              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      onItemSelected(index);
                      Navigator.of(context).pushReplacementNamed(item.route, arguments: {'isDark': isDark});
                    },
                    splashColor: AppColors.primary.withOpacity(0.2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          selected ? item.activeIcon : item.icon,
                          size: 24,
                          color: color,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: color,
                            fontWeight: selected ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  _NavItem({
    required this.icon,
    required this.label,
    required this.activeIcon,
    required this.route,
  });
}