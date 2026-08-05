import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import 'weather_info_chip.dart';
import 'notification_center.dart';
import 'adaptive_logout_confirmation.dart';

/// Modern caretaker header with greeting, weather, notifications, and theme toggle
class CaretakerHeader extends ConsumerWidget {
  final String userName;
  final WeatherInfo? weatherInfo;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;
  final List<String>? farms;
  final String? selectedFarm;
  final ValueChanged<String?>? onFarmChanged;

  const CaretakerHeader({
    super.key,
    required this.userName,
    this.weatherInfo,
    this.onNotificationTap,
    this.onProfileTap,
    this.farms,
    this.selectedFarm,
    this.onFarmChanged,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return SafeArea(
      top: isMobile,
      bottom: false,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? AppSpacing.md : AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDark : AppColors.neutral100,
        ),
        child: isMobile
            ? _buildMobileLayout(context, isDark, ref)
            : _buildDesktopLayout(isDark, ref),
      ),
    );
  }

  Widget _buildDesktopLayout(bool isDark, WidgetRef ref) {
    return Row(
      children: [
        // Left Section: Greeting and Date
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    _getGreeting(),
                    style: AppTypography.h4.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 28,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    ', $userName',
                    style: AppTypography.h4.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 28,
                      color: isDark
                          ? Colors.white.withOpacity(0.9)
                          : AppColors.textPrimary.withOpacity(0.8),
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: isDark
                        ? Colors.white.withOpacity(0.5)
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    _getFormattedDate(),
                    style: AppTypography.bodyLarge.copyWith(
                      fontSize: 14,
                      color: isDark
                          ? Colors.white.withOpacity(0.7)
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Farm Selector
        if (farms != null && farms!.isNotEmpty) ...[
          _buildFarmSelector(isDark),
          const SizedBox(width: AppSpacing.lg),
        ],

        // Right Section: Weather, Actions
        Row(
          children: [
            // Weather Info
            if (weatherInfo != null) ...[
              WeatherInfoChip(
                condition: weatherInfo!.condition,
                temperature: weatherInfo!.temperature,
                isDark: isDark,
              ),
              const SizedBox(width: AppSpacing.md),
            ],

            // Theme Toggle
            _buildActionButton(
              icon:
                  isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              tooltip: isDark ? 'Light Mode' : 'Dark Mode',
              isDark: isDark,
              onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
            ),

            const SizedBox(width: AppSpacing.sm),

            // Notifications
            const NotificationCenter(),

            const SizedBox(width: AppSpacing.sm),

            // Profile
            _buildProfileButton(isDark),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context, bool isDark, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Row: Greeting/User and Actions
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (Scaffold.maybeOf(context) != null) ...[
              _buildMobileActionButton(
                icon: Icons.menu,
                tooltip: 'Menu',
                isDark: isDark,
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            // Left Section: Greeting and User Name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Greeting
                  Row(
                    children: [
                      Text(
                        _getGreeting(),
                        style: AppTypography.h5.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // User Name
                  Text(
                    userName,
                    style: AppTypography.bodyLarge.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? Colors.white.withOpacity(0.85)
                          : AppColors.textPrimary.withOpacity(0.75),
                      letterSpacing: 0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // Role with icon
                  Row(
                    children: [
                      Icon(
                        Icons.agriculture_outlined,
                        size: 12,
                        color: isDark
                            ? Colors.white.withOpacity(0.6)
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Caretaker',
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 11,
                          color: isDark
                              ? Colors.white.withOpacity(0.6)
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            // Action Buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMobileActionButton(
                  icon: isDark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  tooltip: isDark ? 'Light Mode' : 'Dark Mode',
                  isDark: isDark,
                  onPressed: () =>
                      ref.read(themeProvider.notifier).toggleTheme(),
                ),
                const SizedBox(width: AppSpacing.xs),
                const NotificationCenter(),
                const SizedBox(width: AppSpacing.xs),
                _buildMobileProfileButton(isDark, ref),
              ],
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        // Bottom Row: Date and Weather
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.02),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.04),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: isDark
                    ? Colors.white.withOpacity(0.6)
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  _getFormattedDate(),
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 12,
                    color: isDark
                        ? Colors.white.withOpacity(0.7)
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (weatherInfo != null) ...[
                const SizedBox(width: AppSpacing.sm),
                WeatherInfoChip(
                  condition: weatherInfo!.condition,
                  temperature: weatherInfo!.temperature,
                  isDark: isDark,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileActionButton({
    required IconData icon,
    required String tooltip,
    required bool isDark,
    VoidCallback? onPressed,
    int? badge,
  }) {
    return Tooltip(
      message: tooltip,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            elevation: 0,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.12)
                        : Colors.black.withOpacity(0.08),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isDark
                      ? Colors.white.withOpacity(0.95)
                      : AppColors.textPrimary,
                ),
              ),
            ),
          ),
          if (badge != null && badge > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Text(
                  badge > 9 ? '9+' : badge.toString(),
                  style: AppTypography.caption.copyWith(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMobileProfileButton(bool isDark, WidgetRef ref) {
    return Consumer(
      builder: (context, ref, child) {
        final authState = ref.watch(authProvider);
        final user = authState.user;
        final initials = user?.name
                .split(' ')
                .map((n) => n.isNotEmpty ? n[0] : '')
                .take(2)
                .join()
                .toUpperCase() ??
            'CT';

        return PopupMenuButton<String>(
          key: const ValueKey('caretaker-mobile-profile-menu'),
          offset: const Offset(0, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Material(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            elevation: 0,
            child: Container(
              width: 40,
              height: 40,
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
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.12)
                      : Colors.black.withOpacity(0.08),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  initials,
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          itemBuilder: (menuContext) => [
            PopupMenuItem(
              value: 'profile',
              child: Row(
                children: const [
                  Icon(Icons.person_outline, size: 18),
                  SizedBox(width: AppSpacing.sm),
                  Text('Profile'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'settings',
              child: Row(
                children: const [
                  Icon(Icons.settings_outlined, size: 18),
                  SizedBox(width: AppSpacing.sm),
                  Text('Settings'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: const [
                  Icon(Icons.logout, size: 18, color: AppColors.error),
                  SizedBox(width: AppSpacing.sm),
                  Text('Logout', style: TextStyle(color: AppColors.error)),
                ],
              ),
            ),
          ],
          onSelected: (value) async {
            if (value == 'logout') {
              final dialogIsDark =
                  Theme.of(context).brightness == Brightness.dark;
              final confirmed = await showAdaptiveLogoutConfirmation(context);

              if (confirmed == true && context.mounted) {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) {
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/login', (route) => false);
                }
              }
            } else if (value == 'settings') {
              Navigator.of(context).pushNamed('/caretaker_settings');
            } else if (value == 'profile') {
              if (onProfileTap != null) onProfileTap!();
            }
          },
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required bool isDark,
    VoidCallback? onPressed,
    int? badge,
  }) {
    return Tooltip(
      message: tooltip,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            elevation: 0,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.06),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: isDark
                      ? Colors.white.withOpacity(0.95)
                      : AppColors.textPrimary,
                ),
              ),
            ),
          ),
          if (badge != null && badge > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Text(
                  badge > 9 ? '9+' : badge.toString(),
                  style: AppTypography.caption.copyWith(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileButton(bool isDark) {
    return Consumer(
      builder: (context, ref, child) {
        return PopupMenuButton<String>(
          key: const ValueKey('caretaker-desktop-profile-menu'),
          offset: const Offset(0, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          itemBuilder: (menuContext) => [
            PopupMenuItem(
              value: 'profile',
              child: Row(
                children: const [
                  Icon(Icons.person_outline, size: 18),
                  SizedBox(width: AppSpacing.sm),
                  Text('Profile'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'settings',
              child: Row(
                children: const [
                  Icon(Icons.settings_outlined, size: 18),
                  SizedBox(width: AppSpacing.sm),
                  Text('Settings'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: const [
                  Icon(Icons.logout, size: 18, color: AppColors.error),
                  SizedBox(width: AppSpacing.sm),
                  Text('Logout', style: TextStyle(color: AppColors.error)),
                ],
              ),
            ),
          ],
          onSelected: (value) async {
            if (value == 'logout') {
              final dialogIsDark =
                  Theme.of(context).brightness == Brightness.dark;
              final confirmed = await showAdaptiveLogoutConfirmation(context);

              if (confirmed == true && context.mounted) {
                // Perform logout
                await ref.read(authProvider.notifier).logout();
                // Navigate to login
                if (context.mounted) {
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/login', (route) => false);
                }
              }
            } else if (value == 'settings') {
              Navigator.of(context).pushNamed('/caretaker_settings');
            } else if (value == 'profile') {
              if (onProfileTap != null) onProfileTap!();
            }
          },
          child: Material(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            elevation: 0,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.06),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
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
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'C',
                          style: AppTypography.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      userName.split(' ').first,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: isDark
                          ? Colors.white.withOpacity(0.7)
                          : AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFarmSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.15)
              : AppColors.primary.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : AppColors.primary.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(
              Icons.agriculture_outlined,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          DropdownButton<String>(
            value: selectedFarm,
            items: farms!.map((farm) {
              return DropdownMenuItem<String>(
                value: farm,
                child: Text(
                  farm,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              );
            }).toList(),
            onChanged: onFarmChanged,
            underline: const SizedBox(),
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: AppColors.primary,
            ),
            dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ],
      ),
    );
  }
}
