import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import 'sidebar_collapse_state.dart';

/// Modern collapsible sidebar for fulfillment manager dashboard
class FulfillmentManagerSidebar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final String userName;
  final String userEmail;
  final String userRole;

  const FulfillmentManagerSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.userName = "Fulfillment Manager",
    this.userEmail = "fulfillment@farmestates.com",
    this.userRole = "Fulfillment Manager",
  });

  @override
  State<FulfillmentManagerSidebar> createState() =>
      _FulfillmentManagerSidebarState();
}

class _FulfillmentManagerSidebarState extends State<FulfillmentManagerSidebar>
    with SingleTickerProviderStateMixin {
  bool _isCollapsed = SidebarCollapseState.isCollapsed;
  late AnimationController _animationController;
  late Animation<double> _widthAnimation;
  late Animation<double> _logoSizeAnimation;
  late Animation<double> _opacityAnimation;

  // Fulfillment Manager navigation items
  final List<_NavItem> _navItems = [
    _NavItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
      label: 'Dashboard',
      route: '/fulfillment_dashboard',
    ),
    _NavItem(
      icon: Icons.check_box_outlined,
      activeIcon: Icons.check_box_rounded,
      label: 'Confirm Harvest',
      route: '/fulfillment-confirm',
    ),
    _NavItem(
      icon: Icons.inventory_2_outlined,
      activeIcon: Icons.inventory_2_rounded,
      label: 'Packaging',
      route: '/fulfillment-packaging',
    ),
    _NavItem(
      icon: Icons.trending_down_outlined,
      activeIcon: Icons.trending_down_rounded,
      label: 'Yield Calculator',
      route: '/fulfillment-yield',
    ),
    _NavItem(
      icon: Icons.category_outlined,
      activeIcon: Icons.category_rounded,
      label: 'Materials',
      route: '/fulfillment-materials',
    ),
    _NavItem(
      icon: Icons.assessment_outlined,
      activeIcon: Icons.assessment_rounded,
      label: 'Reports',
      route: '/fulfillment-reports',
    ),
    _NavItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
      label: 'Settings',
      route: '/fulfillment-settings',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _widthAnimation = Tween<double>(begin: 220, end: 70).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _logoSizeAnimation = Tween<double>(begin: 82, end: 34).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _opacityAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    if (_isCollapsed) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleCollapse() {
    setState(() {
      _isCollapsed = !_isCollapsed;
      SidebarCollapseState.isCollapsed = _isCollapsed;
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
      animation: _animationController,
      builder: (context, child) {
        return Container(
          width: _widthAnimation.value,
          decoration: BoxDecoration(
            color: isDark ? AppColors.backgroundDark : AppColors.neutral100,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Section
              _buildLogoSection(isDark),

              // Divider
              if (!_isCollapsed)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: AppSpacing.md,
                  endIndent: 0,
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : AppColors.neutral300,
                ),

              // Toggle Button
              _buildToggleButton(isDark),

              const SizedBox(height: AppSpacing.xs),

              // Navigation Items
              Expanded(
                child: _buildNavigationItems(isDark),
              ),

              // Divider
              if (!_isCollapsed)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: AppSpacing.md,
                  endIndent: 0,
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : AppColors.neutral300,
                ),

              // User Profile Section
              if (!_isCollapsed) _buildUserProfile(isDark),

              // Logout Button
              _buildLogoutButton(isDark),

              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogoSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      alignment: Alignment.center,
      child: AnimatedBuilder(
        animation: _logoSizeAnimation,
        builder: (context, child) {
          return SizedBox(
            width: _isCollapsed ? 46 : _logoSizeAnimation.value,
            height: _isCollapsed ? 46 : _logoSizeAnimation.value,
            child: Image.asset(
              isDark
                  ? 'assets/logos/logo_white.png'
                  : 'assets/logos/logo_black.png',
              fit: BoxFit.contain,
            ),
          );
        },
      ),
    );
  }

  Widget _buildToggleButton(bool isDark) {
    return Padding(
      padding: EdgeInsets.only(
        left: _isCollapsed ? 0 : AppSpacing.md,
        right: 0,
        top: AppSpacing.xs,
        bottom: AppSpacing.xs,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: InkWell(
          onTap: _toggleCollapse,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Container(
            width: _isCollapsed ? 50 : null,
            height: _isCollapsed ? 50 : null,
            padding: EdgeInsets.symmetric(
              horizontal: _isCollapsed ? 0 : AppSpacing.xs,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color:
                  (isDark ? Colors.white : AppColors.primary).withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: (isDark ? Colors.white : AppColors.primary)
                    .withOpacity(0.15),
                width: 1,
              ),
            ),
            child: _isCollapsed
                ? Center(
                    child: Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: isDark
                          ? Colors.white.withOpacity(0.8)
                          : AppColors.primary,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: AnimatedOpacity(
                          opacity: _opacityAnimation.value,
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            'Collapse',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  fontSize: 11,
                                  color: isDark
                                      ? Colors.white.withOpacity(0.7)
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.2,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_left,
                        size: 16,
                        color: isDark
                            ? Colors.white.withOpacity(0.8)
                            : AppColors.primary,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationItems(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: _isCollapsed ? 0 : 0,
          ),
          child: _isCollapsed
              ? ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: List.generate(_navItems.length, (idx) {
                      final item = _navItems[idx];
                      final isSelected = idx == widget.selectedIndex;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: _buildNavItem(item, isSelected, isDark),
                      );
                    }),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(_navItems.length, (idx) {
                    final item = _navItems[idx];
                    final isSelected = idx == widget.selectedIndex;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: _buildNavItem(item, isSelected, isDark),
                    );
                  }),
                ),
        );
      },
    );
  }

  Widget _buildNavItem(_NavItem item, bool isSelected, bool isDark) {
    return Padding(
      padding: EdgeInsets.only(
        left: _isCollapsed ? 0 : AppSpacing.md,
        right: 0,
        top: 2,
        bottom: 2,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          onTap: () {
            widget.onItemSelected(_navItems.indexOf(item));
            SidebarCollapseState.isCollapsed = _isCollapsed;
            Navigator.pushReplacementNamed(context, item.route);
          },
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: _isCollapsed ? 0 : AppSpacing.xs,
              vertical: AppSpacing.sm,
            ),
            decoration: isSelected && !_isCollapsed
                ? BoxDecoration(
                    color: Colors.white.withOpacity(isDark ? 0.15 : 0.9),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                        spreadRadius: 0,
                      ),
                    ],
                  )
                : null,
            child: _isCollapsed
                ? Center(
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? Colors.white.withOpacity(isDark ? 0.15 : 0.9)
                            : Colors.transparent,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                  spreadRadius: 0,
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        isSelected ? item.activeIcon : item.icon,
                        size: 22,
                        color: isSelected
                            ? AppColors.primary
                            : (isDark
                                ? Colors.white.withOpacity(0.7)
                                : AppColors.textSecondary),
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? Colors.white.withOpacity(0.2)
                              : (isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.black.withOpacity(0.04)),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          isSelected ? item.activeIcon : item.icon,
                          size: 18,
                          color: isSelected
                              ? AppColors.primary
                              : (isDark
                                  ? Colors.white.withOpacity(0.8)
                                  : AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: AnimatedOpacity(
                          opacity: _opacityAnimation.value,
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            item.label,
                            textAlign: TextAlign.left,
                            style: AppTypography.bodyMedium.copyWith(
                              fontSize: 13,
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark
                                      ? Colors.white
                                      : AppColors.textPrimary),
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfile(bool isDark) {
    return AnimatedOpacity(
      opacity: _opacityAnimation.value,
      duration: const Duration(milliseconds: 200),
      child: Container(
        margin: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.xs,
          top: AppSpacing.sm,
          bottom: AppSpacing.sm,
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    AppColors.primary.withOpacity(0.15),
                    AppColors.primary.withOpacity(0.08),
                  ]
                : [
                    AppColors.primary.withOpacity(0.1),
                    AppColors.primary.withOpacity(0.05),
                  ],
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.primaryDark,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  widget.userName.isNotEmpty
                      ? widget.userName[0].toUpperCase()
                      : 'F',
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.userName,
                    style: AppTypography.bodyMedium.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.userRole,
                    style: AppTypography.caption.copyWith(
                      fontSize: 13,
                      color: isDark
                          ? Colors.white.withOpacity(0.7)
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(bool isDark) {
    return Padding(
      padding: EdgeInsets.only(
        left: _isCollapsed ? 0 : AppSpacing.md,
        right: 0,
        top: AppSpacing.xs,
        bottom: AppSpacing.xs,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: InkWell(
          onTap: _showLogoutDialog,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Container(
            width: _isCollapsed ? 50 : null,
            height: _isCollapsed ? 50 : null,
            padding: EdgeInsets.symmetric(
              horizontal: _isCollapsed ? 0 : AppSpacing.xs,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: AppColors.error.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: _isCollapsed
                ? Center(
                    child: Icon(
                      Icons.logout_rounded,
                      color: AppColors.error,
                      size: 20,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        color: AppColors.error,
                        size: 16,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      AnimatedOpacity(
                        opacity: _opacityAnimation.value,
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          'Logout',
                          style: AppTypography.bodyMedium.copyWith(
                            fontSize: 13,
                            color: AppColors.error,
                            fontWeight: FontWeight.w500,
                          ),
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
        title: Text(
          'Logout',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        backgroundColor: Theme.of(context).cardColor,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Add logout logic here
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
            ),
            child: Text(
              'Logout',
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
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
