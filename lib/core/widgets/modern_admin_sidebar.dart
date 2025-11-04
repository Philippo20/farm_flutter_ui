import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';

/// Modern collapsible sidebar for admin dashboard
/// Expanded width: 240px, Collapsed width: 72px
class ModernAdminSidebar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final String userName;
  final String userEmail;
  final String userRole;

  const ModernAdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.userName = "Admin User",
    this.userEmail = "admin@farmestates.com",
    this.userRole = "Administrator",
  });

  @override
  State<ModernAdminSidebar> createState() => _ModernAdminSidebarState();
}

class _ModernAdminSidebarState extends State<ModernAdminSidebar>
    with SingleTickerProviderStateMixin {
  bool _isCollapsed = false;
  late AnimationController _animationController;
  late Animation<double> _widthAnimation;
  late Animation<double> _logoSizeAnimation;

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
    _logoSizeAnimation = Tween<double>(begin: 48, end: 32).animate(
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _widthAnimation,
      builder: (context, child) {
        return Container(
          width: _widthAnimation.value,
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            border: Border(
              right: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.08),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                blurRadius: 10,
                offset: const Offset(2, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              // Logo Section
              _buildLogoSection(isDark),

              // Toggle Button
              _buildToggleButton(isDark),

              const SizedBox(height: AppSpacing.md),

              // Navigation Items
              Expanded(
                child: _buildNavigationItems(isDark),
              ),

              // User Profile Section
              if (!_isCollapsed) _buildUserProfile(isDark),

              // Logout Button
              _buildLogoutButton(isDark),

              const SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogoSection(bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _isCollapsed ? AppSpacing.sm : AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      child: Center(
        child: AnimatedBuilder(
          animation: _logoSizeAnimation,
          builder: (context, child) {
            return Image.asset(
              isDark
                  ? 'assets/logos/logo_white.png'
                  : 'assets/logos/logo_black.png',
              height: _logoSizeAnimation.value,
              width: _logoSizeAnimation.value,
              fit: BoxFit.contain,
            );
          },
        ),
      ),
    );
  }

  Widget _buildToggleButton(bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _isCollapsed ? AppSpacing.sm : AppSpacing.md,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _toggleCollapse,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : AppColors.primary)
                  .withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              mainAxisAlignment: _isCollapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.spaceBetween,
              children: [
                if (!_isCollapsed)
                  Text(
                    'MENU',
                    style: AppTypography.labelSmall.copyWith(
                      color: isDark
                          ? Colors.white.withOpacity(0.6)
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                Icon(
                  _isCollapsed ? Icons.menu : Icons.close,
                  size: 20,
                  color: isDark
                      ? Colors.white.withOpacity(0.8)
                      : AppColors.textPrimary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationItems(bool isDark) {
    final navItems = [
      _NavItem(
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard,
        label: 'Dashboard',
        route: '/dashboard',
      ),
      _NavItem(
        icon: Icons.people_outline,
        activeIcon: Icons.people,
        label: 'Users',
        route: '/users',
      ),
      _NavItem(
        icon: Icons.agriculture_outlined,
        activeIcon: Icons.agriculture,
        label: 'Farms',
        route: '/farms',
      ),
      _NavItem(
        icon: Icons.sensors_outlined,
        activeIcon: Icons.sensors,
        label: 'Sensors',
        route: '/sensors',
      ),
      _NavItem(
        icon: Icons.analytics_outlined,
        activeIcon: Icons.analytics,
        label: 'Analytics',
        route: '/analytics',
      ),
      _NavItem(
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings,
        label: 'Settings',
        route: '/settings',
      ),
    ];

    return ListView.separated(
      padding: EdgeInsets.symmetric(
        horizontal: _isCollapsed ? AppSpacing.xs : AppSpacing.md,
      ),
      itemCount: navItems.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.xs),
      itemBuilder: (context, idx) {
        final item = navItems[idx];
        final isSelected = idx == widget.selectedIndex;

        return _buildNavItem(item, isSelected, isDark);
      },
    );
  }

  Widget _buildNavItem(_NavItem item, bool isSelected, bool isDark) {
    return Material(
      color: isSelected
          ? AppColors.primary.withOpacity(isDark ? 0.15 : 0.1)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: () {
          // Navigate to the route
          Navigator.pushNamed(context, item.route);
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: _isCollapsed ? 0 : AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: _isCollapsed
              ? Center(
                  child: Icon(
                    isSelected ? item.activeIcon : item.icon,
                    size: 24,
                    color: isSelected
                        ? AppColors.primary
                        : (isDark
                            ? Colors.white.withOpacity(0.7)
                            : AppColors.textSecondary),
                  ),
                )
              : Row(
                  children: [
                    Icon(
                      isSelected ? item.activeIcon : item.icon,
                      size: 22,
                      color: isSelected
                          ? AppColors.primary
                          : (isDark
                              ? Colors.white.withOpacity(0.7)
                              : AppColors.textSecondary),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        item.label,
                        style: AppTypography.bodyMedium.copyWith(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark
                                  ? Colors.white
                                  : AppColors.textPrimary),
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildUserProfile(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.primary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withOpacity(0.2),
            child: Text(
              widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : 'A',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.userName,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.userRole,
                  style: AppTypography.caption.copyWith(
                    color: isDark
                        ? Colors.white.withOpacity(0.6)
                        : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _isCollapsed ? AppSpacing.xs : AppSpacing.md,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Handle logout
            _showLogoutDialog();
          },
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: _isCollapsed ? 0 : AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: _isCollapsed
                ? const Center(
                    child: Icon(
                      Icons.logout_rounded,
                      color: AppColors.error,
                      size: 22,
                    ),
                  )
                : Row(
                    children: [
                      const Icon(
                        Icons.logout_rounded,
                        color: AppColors.error,
                        size: 22,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        'Logout',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Add logout logic here
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Logout'),
          ),
        ],
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
