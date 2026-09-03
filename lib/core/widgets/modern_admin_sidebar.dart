import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import 'sidebar_collapse_state.dart';
import 'adaptive_logout_confirmation.dart';

/// Modern collapsible sidebar for admin dashboard
/// Expanded width: 260px, Collapsed width: 80px
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

/// Mobile drawer using the same navigation pattern as the desktop Admin sidebar.
class AdminDrawer extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final String userName;
  final String userEmail;
  final String userRole;

  const AdminDrawer({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.userName,
    required this.userEmail,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const items = [
      _NavItem(
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard_rounded,
        label: 'Dashboard',
        route: '/dashboard',
      ),
      _NavItem(
        icon: Icons.people_outline,
        activeIcon: Icons.people_alt_rounded,
        label: 'Users',
        route: '/users',
      ),
      _NavItem(
        icon: Icons.agriculture_outlined,
        activeIcon: Icons.agriculture_rounded,
        label: 'Farms',
        route: '/farms',
      ),
      _NavItem(
        icon: Icons.grass_outlined,
        activeIcon: Icons.grass_rounded,
        label: 'Crop Varieties',
        route: '/crop-varieties',
      ),
      _NavItem(
        icon: Icons.inventory_2_outlined,
        activeIcon: Icons.inventory_2_rounded,
        label: 'Inventory',
        route: '/inventory-admin',
      ),
      _NavItem(
        icon: Icons.local_shipping_outlined,
        activeIcon: Icons.local_shipping_rounded,
        label: 'Deliveries',
        route: '/deliveries-admin',
      ),
      _NavItem(
        icon: Icons.sensors_outlined,
        activeIcon: Icons.sensors_rounded,
        label: 'Sensors',
        route: '/sensors',
      ),
      _NavItem(
        icon: Icons.analytics_outlined,
        activeIcon: Icons.analytics_rounded,
        label: 'Analytics',
        route: '/analytics',
      ),
      _NavItem(
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings_rounded,
        label: 'Settings',
        route: '/settings',
      ),
      _NavItem(
        icon: Icons.grid_view_outlined,
        activeIcon: Icons.grid_view_rounded,
        label: 'Batch Management',
        route: '/batches-admin',
      ),
      _NavItem(
        icon: Icons.qr_code_2_outlined,
        activeIcon: Icons.qr_code_2_rounded,
        label: 'Traceability',
        route: '/traceability-admin',
      ),
      _NavItem(
        icon: Icons.inventory_2_outlined,
        activeIcon: Icons.inventory_2_rounded,
        label: 'Packaging',
        route: '/admin/packaging',
      ),
    ];
    int indexFor(_NavItem item) => const [
          '/dashboard',
          '/users',
          '/farms',
          '/sensors',
          '/analytics',
          '/settings',
          '/inventory-admin',
          '/deliveries-admin',
          '/crop-varieties',
          '/batches-admin',
          '/traceability-admin',
          '/admin/packaging',
        ].indexOf(item.route);

    return Drawer(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.neutral100,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white24,
                    child: Text(
                      userName.isEmpty ? 'A' : userName[0].toUpperCase(),
                      style: AppTypography.h4.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.h6.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userRole,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: items.map((item) {
                  final index = indexFor(item);
                  final selected = index == selectedIndex;
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary.withOpacity(0.2)
                            : (isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.black.withOpacity(0.04)),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Icon(
                        selected ? item.activeIcon : item.icon,
                        color: selected
                            ? AppColors.primary
                            : (isDark
                                ? Colors.white70
                                : AppColors.textSecondary),
                      ),
                    ),
                    title: Text(
                      item.label,
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: 15,
                        color: selected
                            ? AppColors.primary
                            : (isDark ? Colors.white : AppColors.textPrimary),
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    selected: selected,
                    selectedTileColor: isDark
                        ? Colors.white.withOpacity(0.1)
                        : AppColors.primary.withOpacity(0.1),
                    onTap: () {
                      onItemSelected(index);
                      Navigator.pushReplacementNamed(context, item.route);
                    },
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 1),
            Container(
              margin: const EdgeInsets.all(AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                gradient: LinearGradient(
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
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        userName.isEmpty ? 'A' : userName[0].toUpperCase(),
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
                      children: [
                        Text(
                          userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMedium.copyWith(
                            fontSize: 15,
                            color:
                                isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userEmail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            fontSize: 12,
                            color: isDark
                                ? Colors.white.withOpacity(0.7)
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: InkWell(
                  onTap: () async {
                    final confirmed =
                        await showAdaptiveLogoutConfirmation(context);
                    if (confirmed && context.mounted) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  },
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: AppColors.error.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.logout_rounded,
                          color: AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Logout',
                          style: AppTypography.bodyMedium.copyWith(
                            fontSize: 15,
                            color: AppColors.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

/// Compact mobile navigation for Admin screens.
class AdminMobileBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const AdminMobileBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  static const _primaryItems = [
    _NavItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
      label: 'Home',
      route: '/dashboard',
    ),
    _NavItem(
      icon: Icons.people_outline,
      activeIcon: Icons.people_alt_rounded,
      label: 'Users',
      route: '/users',
    ),
    _NavItem(
      icon: Icons.agriculture_outlined,
      activeIcon: Icons.agriculture_rounded,
      label: 'Farms',
      route: '/farms',
    ),
    _NavItem(
      icon: Icons.sensors_outlined,
      activeIcon: Icons.sensors_rounded,
      label: 'Sensors',
      route: '/sensors',
    ),
  ];

  static const _allItems = [
    ..._primaryItems,
    _NavItem(
      icon: Icons.analytics_outlined,
      activeIcon: Icons.analytics_rounded,
      label: 'Analytics',
      route: '/analytics',
    ),
    _NavItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
      label: 'Settings',
      route: '/settings',
    ),
    _NavItem(
      icon: Icons.inventory_2_outlined,
      activeIcon: Icons.inventory_2_rounded,
      label: 'Inventory',
      route: '/inventory-admin',
    ),
    _NavItem(
      icon: Icons.local_shipping_outlined,
      activeIcon: Icons.local_shipping_rounded,
      label: 'Deliveries',
      route: '/deliveries-admin',
    ),
    _NavItem(
      icon: Icons.grass_outlined,
      activeIcon: Icons.grass_rounded,
      label: 'Crop Varieties',
      route: '/crop-varieties',
    ),
    _NavItem(
      icon: Icons.grid_view_outlined,
      activeIcon: Icons.grid_view_rounded,
      label: 'Batches',
      route: '/batches-admin',
    ),
    _NavItem(
      icon: Icons.qr_code_2_outlined,
      activeIcon: Icons.qr_code_2_rounded,
      label: 'Traceability',
      route: '/traceability-admin',
    ),
    _NavItem(
      icon: Icons.inventory_2_outlined,
      activeIcon: Icons.inventory_2_rounded,
      label: 'Packaging',
      route: '/admin/packaging',
    ),
  ];

  static const _defaultDynamicItem = _NavItem(
    icon: Icons.analytics_outlined,
    activeIcon: Icons.analytics_rounded,
    label: 'Analytics',
    route: '/analytics',
  );

  int _routeIndex(String route) => _allItems.indexWhere(
        (item) => item.route == route,
      );

  void _navigate(BuildContext context, _NavItem item) {
    final index = _routeIndex(item.route);
    onItemSelected(index);
    if (index != selectedIndex) {
      Navigator.pushReplacementNamed(context, item.route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final current = _allItems.where(
      (item) =>
          _routeIndex(item.route) == selectedIndex &&
          !_primaryItems.contains(item),
    );
    final dynamicItem =
        current.isNotEmpty ? current.first : _defaultDynamicItem;
    final visible = [
      ..._primaryItems,
      dynamicItem,
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.08),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.24 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 76,
          child: Row(
            children: visible
                .map((item) => _buildBottomItem(context, item, isDark))
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomItem(
    BuildContext context,
    _NavItem item,
    bool isDark,
  ) {
    final selected = _routeIndex(item.route) == selectedIndex;
    final color = selected
        ? AppColors.primary
        : (isDark
            ? AppColors.textOnDark.withOpacity(0.74)
            : AppColors.textSecondary);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigate(context, item),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary.withOpacity(isDark ? 0.16 : 0.10)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Icon(
                    selected ? item.activeIcon : item.icon,
                    size: 22,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: color,
                    fontSize: 11,
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
}

class _ModernAdminSidebarState extends State<ModernAdminSidebar>
    with SingleTickerProviderStateMixin {
  bool _isCollapsed = SidebarCollapseState.isCollapsed;
  late AnimationController _animationController;
  late Animation<double> _widthAnimation;
  late Animation<double> _logoSizeAnimation;
  late Animation<double> _opacityAnimation;

  // Define navItems at class level so it's accessible in both methods
  final List<_NavItem> _navItems = [
    _NavItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
      label: 'Dashboard',
      route: '/dashboard',
    ),
    _NavItem(
      icon: Icons.people_outline,
      activeIcon: Icons.people_alt_rounded,
      label: 'Users',
      route: '/users',
    ),
    _NavItem(
      icon: Icons.agriculture_outlined,
      activeIcon: Icons.agriculture_rounded,
      label: 'Farms',
      route: '/farms',
    ),
    _NavItem(
      icon: Icons.sensors_outlined,
      activeIcon: Icons.sensors_rounded,
      label: 'Sensors',
      route: '/sensors',
    ),
    _NavItem(
      icon: Icons.analytics_outlined,
      activeIcon: Icons.analytics_rounded,
      label: 'Analytics',
      route: '/analytics',
    ),
    _NavItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
      label: 'Settings',
      route: '/settings',
    ),
    _NavItem(
      icon: Icons.inventory_2_outlined,
      activeIcon: Icons.inventory_2_rounded,
      label: 'Inventory',
      route: '/inventory-admin',
    ),
    _NavItem(
      icon: Icons.local_shipping_outlined,
      activeIcon: Icons.local_shipping_rounded,
      label: 'Deliveries',
      route: '/deliveries-admin',
    ),
    _NavItem(
      icon: Icons.grass_outlined,
      activeIcon: Icons.grass_rounded,
      label: 'Crop Varieties',
      route: '/crop-varieties',
    ),
    _NavItem(
      icon: Icons.grid_view_outlined,
      activeIcon: Icons.grid_view_rounded,
      label: 'Batch Management',
      route: '/batches-admin',
    ),
    _NavItem(
      icon: Icons.qr_code_2_outlined,
      activeIcon: Icons.qr_code_2_rounded,
      label: 'Traceability',
      route: '/traceability-admin',
    ),
    _NavItem(
      icon: Icons.inventory_2_outlined,
      activeIcon: Icons.inventory_2_rounded,
      label: 'Packaging',
      route: '/admin/packaging',
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
            final index = _navItems.indexOf(item);
            widget.onItemSelected(index);
            SidebarCollapseState.isCollapsed = _isCollapsed;
            // Navigate to the route - use pushReplacementNamed to replace current route
            // instead of stacking routes
            try {
              Navigator.pushReplacementNamed(context, item.route);
            } catch (e) {
              // If route doesn't exist, try pushNamed as fallback
              try {
                Navigator.pushNamed(context, item.route);
              } catch (e2) {
                // If both fail, just update the selected index
                // The parent widget should handle the navigation
                debugPrint('Navigation error: $e2');
              }
            }
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
                                  ? FontWeight.w500
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
                      : 'A',
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

  Future<void> _showLogoutDialog() async {
    final confirmed = await showAdaptiveLogoutConfirmation(context);
    if (!confirmed) return;

    // Existing sidebar logout flow only dismissed the confirmation.
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.activeIcon,
    required this.route,
  });
}
