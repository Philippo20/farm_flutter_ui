import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import 'adaptive_logout_confirmation.dart';
import 'notification_center.dart';

/// Modern Dashboard Scaffold
/// Consistent layout for all role-specific dashboards
class ModernDashboardScaffold extends ConsumerStatefulWidget {
  final String title;
  final List<Widget> children;
  final Widget? floatingActionButton;
  final List<DashboardMenuItem>? menuItems;

  const ModernDashboardScaffold({
    super.key,
    required this.title,
    required this.children,
    this.floatingActionButton,
    this.menuItems,
  });

  @override
  ConsumerState<ModernDashboardScaffold> createState() =>
      _ModernDashboardScaffoldState();
}

class _ModernDashboardScaffoldState
    extends ConsumerState<ModernDashboardScaffold> {
  bool _isSidebarCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'User';

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Row(
        children: [
          // Sidebar
          _buildSidebar(isDark, userName),

          // Main Content
          Expanded(
            child: Column(
              children: [
                // Top AppBar
                _buildTopBar(isDark, userName),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: widget.children,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: widget.floatingActionButton,
    );
  }

  Widget _buildSidebar(bool isDark, String userName) {
    return Container(
      width: _isSidebarCollapsed ? 72 : 240,
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
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: _isSidebarCollapsed ? AppSpacing.sm : AppSpacing.lg,
              vertical: AppSpacing.lg,
            ),
            child: Center(
              child: Image.asset(
                isDark
                    ? 'assets/logos/logo_white.png'
                    : 'assets/logos/logo_black.png',
                height: _isSidebarCollapsed ? 32 : 48,
                width: _isSidebarCollapsed ? 32 : 48,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: _isSidebarCollapsed ? 32 : 48,
                    height: _isSidebarCollapsed ? 32 : 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.eco,
                      color: Colors.white,
                      size: _isSidebarCollapsed ? 20 : 28,
                    ),
                  );
                },
              ),
            ),
          ),

          // Toggle Button (MENU X style)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: _isSidebarCollapsed ? AppSpacing.sm : AppSpacing.md,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _isSidebarCollapsed = !_isSidebarCollapsed;
                  });
                },
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : AppColors.primary)
                        .withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Row(
                    mainAxisAlignment: _isSidebarCollapsed
                        ? MainAxisAlignment.center
                        : MainAxisAlignment.spaceBetween,
                    children: [
                      if (!_isSidebarCollapsed)
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
                        _isSidebarCollapsed ? Icons.menu : Icons.close,
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
          ),

          const SizedBox(height: AppSpacing.md),

          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: _isSidebarCollapsed ? AppSpacing.xs : AppSpacing.md,
              ),
              children: [
                if (widget.menuItems != null)
                  ...widget.menuItems!
                      .map((item) => _buildMenuItem(item, isDark)),
              ],
            ),
          ),

          const Divider(height: 1),

          // Logout Button at Bottom
          SizedBox(
            height: 56,
            child: InkWell(
              onTap: _handleLogout,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal:
                      _isSidebarCollapsed ? AppSpacing.sm : AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.logout,
                      color: AppColors.error,
                      size: 20,
                    ),
                    if (!_isSidebarCollapsed) ...[
                      const SizedBox(width: AppSpacing.md),
                      Flexible(
                        child: Text(
                          'Logout',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(DashboardMenuItem item, bool isDark) {
    final isSelected = item.isSelected ?? false;

    return InkWell(
      onTap: item.onTap,
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: _isSidebarCollapsed ? AppSpacing.xs : AppSpacing.sm,
          vertical: 2,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: _isSidebarCollapsed ? AppSpacing.sm : AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Row(
          children: [
            Icon(
              item.icon,
              size: 20,
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? Colors.white70 : AppColors.textSecondary),
            ),
            if (!_isSidebarCollapsed) ...[
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  item.title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? Colors.white70 : AppColors.textPrimary),
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              if (item.badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    item.badge!,
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(bool isDark, String userName) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white10 : Colors.black12,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Welcome Message
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  userName,
                  style: AppTypography.h6.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Dark Mode Toggle
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            onPressed: () {
              // Toggle theme using theme provider
              ref.read(themeProvider.notifier).toggleTheme();
            },
          ),

          const SizedBox(width: AppSpacing.sm),

          // Notifications
          const NotificationCenter(),

          const SizedBox(width: AppSpacing.sm),

          // User Menu
          PopupMenuButton<String>(
            offset: const Offset(0, 48),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    _getInitials(userName),
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  Icons.arrow_drop_down,
                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                ),
              ],
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    const Icon(Icons.person_outline, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Profile', style: AppTypography.bodyMedium),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    const Icon(Icons.settings_outlined, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Settings', style: AppTypography.bodyMedium),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(Icons.logout, size: 20, color: AppColors.error),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Logout',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'logout') {
                _handleLogout();
              }
            },
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }

  Future<void> _handleLogout() async {
    final confirmed = await showAdaptiveLogoutConfirmation(context);
    if (!confirmed || !mounted) return;

    await ref.read(authProvider.notifier).logout();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }
}

/// Dashboard Menu Item
class DashboardMenuItem {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  final bool? isSelected;
  final String? badge;

  DashboardMenuItem({
    required this.title,
    required this.icon,
    this.onTap,
    this.isSelected,
    this.badge,
  });
}

/// Compact Stat Card (Admin Style - Colored Background)
class CompactStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? trend;
  final bool? isPositive;
  final VoidCallback? onTap;

  const CompactStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.trend,
    this.isPositive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      color: color.withOpacity(0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon with colored background
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(isDark ? 0.15 : 0.9),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 18,
                ),
              ),

              const SizedBox(width: AppSpacing.sm),

              // Title and Value
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: AppTypography.bodySmall.copyWith(
                          color: color.withOpacity(0.8),
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value,
                          style: AppTypography.h6.copyWith(
                            fontWeight: FontWeight.bold,
                            color: color,
                            letterSpacing: -0.5,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppSpacing.xs),

              // Trend Badge
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(isDark ? 0.15 : 0.9),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(
                      color: isPositive == true
                          ? AppColors.success
                          : AppColors.error,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive == true
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        size: 10,
                        color: isPositive == true
                            ? AppColors.success
                            : AppColors.error,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        trend!,
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isPositive == true
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
