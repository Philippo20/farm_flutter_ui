import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'adaptive_logout_confirmation.dart';

class FarmOwnerMobileDrawer extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final String userName;
  final String userEmail;
  final String userRole;

  const FarmOwnerMobileDrawer({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.userName,
    this.userEmail = 'owner@farmestates.com',
    this.userRole = 'Farm Owner',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'F',
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          userRole,
                          style: AppTypography.caption.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(
                height: 1,
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : AppColors.neutral200),
            Expanded(
              child: _buildNavItems(context, isDark),
            ),
            Divider(
                height: 1,
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : AppColors.neutral200),
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
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
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
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'F',
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
                      color: AppColors.error.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border:
                          Border.all(color: AppColors.error.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const Icon(Icons.logout_rounded,
                            size: 20, color: AppColors.error),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Logout',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.error,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
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

  Widget _buildNavItems(BuildContext context, bool isDark) {
    final items = [
      {
        'icon': Icons.dashboard_outlined,
        'active': Icons.dashboard_rounded,
        'label': 'Dashboard',
        'route': '/farm-owner'
      },
      {
        'icon': Icons.agriculture_outlined,
        'active': Icons.agriculture_rounded,
        'label': 'Farm',
        'route': '/farm-owner/farm'
      },
      {
        'icon': Icons.account_balance_wallet_outlined,
        'active': Icons.account_balance_wallet_rounded,
        'label': 'Digital Wallet',
        'route': '/farm-owner/digital-wallet'
      },
      {
        'icon': Icons.analytics_outlined,
        'active': Icons.analytics_rounded,
        'label': 'Analytics',
        'route': '/farm-owner/analytics'
      },
      {
        'icon': Icons.assessment_outlined,
        'active': Icons.assessment_rounded,
        'label': 'Reports',
        'route': '/farm-owner/reports'
      },
      {
        'icon': Icons.settings_outlined,
        'active': Icons.settings_rounded,
        'label': 'Settings',
        'route': '/farm-owner/settings'
      },
    ];

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = index == selectedIndex;
        final icon =
            isSelected ? item['active'] as IconData : item['icon'] as IconData;

        return ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.2)
                  : (isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.04)),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(
              icon,
              size: 22,
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? Colors.white70 : AppColors.textSecondary),
            ),
          ),
          title: Text(
            item['label'] as String,
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 15,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? Colors.white : AppColors.textPrimary),
            ),
          ),
          selected: isSelected,
          selectedTileColor: isDark
              ? Colors.white.withOpacity(0.1)
              : AppColors.primary.withOpacity(0.1),
          onTap: () {
            onItemSelected(index);
            Navigator.pop(context);
            try {
              Navigator.pushReplacementNamed(context, item['route'] as String);
            } catch (_) {
              Navigator.pushNamed(context, item['route'] as String);
            }
          },
        );
      },
    );
  }
}

class FarmOwnerMobileBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const FarmOwnerMobileBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  static const _primaryItems = [
    _OwnerNavItem(Icons.dashboard_outlined, Icons.dashboard_rounded, 'Home',
        '/farm-owner'),
    _OwnerNavItem(Icons.agriculture_outlined, Icons.agriculture_rounded, 'Farm',
        '/farm-owner/farm'),
    _OwnerNavItem(
        Icons.account_balance_wallet_outlined,
        Icons.account_balance_wallet_rounded,
        'Wallet',
        '/farm-owner/digital-wallet'),
    _OwnerNavItem(Icons.analytics_outlined, Icons.analytics_rounded,
        'Analytics', '/farm-owner/analytics'),
  ];

  static const _allItems = [
    ..._primaryItems,
    _OwnerNavItem(Icons.assessment_outlined, Icons.assessment_rounded,
        'Reports', '/farm-owner/reports'),
    _OwnerNavItem(Icons.settings_outlined, Icons.settings_rounded, 'Settings',
        '/farm-owner/settings'),
  ];

  static const _defaultDynamicItem = _OwnerNavItem(
    Icons.assessment_outlined,
    Icons.assessment_rounded,
    'Reports',
    '/farm-owner/reports',
  );

  int _routeIndex(String route) =>
      _allItems.indexWhere((item) => item.route == route);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final current = _allItems.where((item) =>
        _routeIndex(item.route) == selectedIndex &&
        !_primaryItems.contains(item));
    final dynamicItem = current.isNotEmpty
        ? current.first
        : _defaultDynamicItem;
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
            children: visible.map((item) {
              final index = _routeIndex(item.route);
              final selected = index == selectedIndex;
              final color = selected
                  ? AppColors.primary
                  : (isDark
                      ? AppColors.textOnDark.withOpacity(0.74)
                      : AppColors.textSecondary);
              return Expanded(
                child: InkWell(
                  onTap: () {
                    onItemSelected(index);
                    if (index != selectedIndex) {
                      Navigator.pushReplacementNamed(context, item.route);
                    }
                  },
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primary
                                    .withOpacity(isDark ? 0.16 : 0.10)
                                : Colors.transparent,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusFull),
                          ),
                          child: Icon(selected ? item.activeIcon : item.icon,
                              size: 22, color: color),
                        ),
                        const SizedBox(height: 4),
                        Text(item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.w500)),
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

class _OwnerNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  const _OwnerNavItem(this.icon, this.activeIcon, this.label, this.route);
}
