import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/colors.dart';

class AdminSidebar extends StatefulWidget {
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
  State<AdminSidebar> createState() => _AdminSidebarState();
}

class _AdminSidebarState extends State<AdminSidebar> with SingleTickerProviderStateMixin {
  bool _isCollapsed = false;
  late AnimationController _animationController;
  late Animation<double> _widthAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _widthAnimation = Tween<double>(begin: 240, end: 72).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleCollapse() {
    setState(() {
      _isCollapsed = !_isCollapsed;
      if (_isCollapsed) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final navItems = [
      _NavItem(
          icon: Icons.dashboard_outlined,
          label: 'Home',
          activeIcon: Icons.dashboard,
          route: '/dashboard'),
      _NavItem(
          icon: Icons.people_outline, label: 'Users', activeIcon: Icons.people, route: '/users'),
      _NavItem(
          icon: Icons.agriculture_outlined,
          label: 'Farms',
          activeIcon: Icons.agriculture,
          route: '/farms'),
      _NavItem(
          icon: Icons.sensors_outlined,
          label: 'Sensors',
          activeIcon: Icons.sensors,
          route: '/sensors'),
      _NavItem(
          icon: Icons.settings_outlined,
          label: 'Settings',
          activeIcon: Icons.settings,
          route: '/settings'),
    ];

    if (widget.isMobile) {
      return _buildMobileBottomBar(navItems, context);
    } else {
      return _buildDesktopSidebar(navItems);
    }
  }

  Widget _buildDesktopSidebar(List<_NavItem> navItems) {
    final textColor = widget.isDark ? Colors.white : const Color(0xFF232535);
    final selectedColor = widget.isDark ? AppColors.primary : AppColors.primary;
    final bgColor = widget.isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return AnimatedBuilder(
      animation: _widthAnimation,
      builder: (context, child) {
        return Container(
          width: _widthAnimation.value,
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(
              right: BorderSide(
                color: widget.isDark ? Colors.white12 : Colors.black12,
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(2, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              // Toggle button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Row(
                  mainAxisAlignment:
                      _isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
                  children: [
                    if (!_isCollapsed)
                      Text(
                        'MENU',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textColor.withOpacity(0.5),
                          letterSpacing: 1.2,
                        ),
                      ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _toggleCollapse,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            _isCollapsed ? Icons.chevron_right : Icons.chevron_left,
                            size: 20,
                            color: textColor.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Navigation items
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: _isCollapsed ? 8 : 16),
                  itemCount: navItems.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final item = navItems[idx];
                    final bool selected = idx == widget.selectedIndex;

                    return Material(
                      color: selected ? selectedColor.withOpacity(0.12) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () {
                          widget.onItemSelected(idx);
                          Navigator.of(context).pushReplacementNamed(item.route,
                              arguments: {'isDark': widget.isDark});
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: _isCollapsed ? 0 : 16,
                            vertical: 14,
                          ),
                          child: _isCollapsed
                              ? Center(
                                  child: Icon(
                                    selected ? item.activeIcon : item.icon,
                                    size: 24,
                                    color: selected ? selectedColor : textColor.withOpacity(0.7),
                                  ),
                                )
                              : Row(
                                  children: [
                                    Icon(
                                      selected ? item.activeIcon : item.icon,
                                      size: 22,
                                      color: selected ? selectedColor : textColor.withOpacity(0.7),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        item.label,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: selected ? selectedColor : textColor,
                                          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Logout button
              const Divider(height: 1),
              Container(
                padding: EdgeInsets.all(_isCollapsed ? 8 : 16),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      // Handle logout
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: _isCollapsed ? 0 : 16,
                        vertical: 14,
                      ),
                      child: _isCollapsed
                          ? const Center(
                              child: Icon(
                                Icons.logout,
                                color: AppColors.danger,
                                size: 22,
                              ),
                            )
                          : Row(
                              children: [
                                const Icon(
                                  Icons.logout,
                                  color: AppColors.danger,
                                  size: 22,
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  'Logout',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: AppColors.danger,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMobileBottomBar(List<_NavItem> navItems, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.isDark ? Colors.grey[900] : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: widget.isDark ? Colors.grey[800]! : Colors.grey[200]!,
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
              final selected = index == widget.selectedIndex;
              final color = selected
                  ? AppColors.primary
                  : (widget.isDark ? Colors.grey[400] : Colors.grey[600]);

              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      widget.onItemSelected(index);
                      Navigator.of(context)
                          .pushReplacementNamed(item.route, arguments: {'isDark': widget.isDark});
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
