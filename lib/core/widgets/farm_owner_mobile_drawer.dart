import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class FarmOwnerMobileDrawer extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final String userName;
  final String userRole;

  const FarmOwnerMobileDrawer({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.userName,
    this.userRole = 'Farm Owner',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      width: 248,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.md, AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
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
                            color:
                                isDark ? Colors.white : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          userRole,
                          style: AppTypography.caption.copyWith(
                            color: isDark
                                ? Colors.white60
                                : AppColors.textSecondary,
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
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: AppColors.error.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.logout_rounded,
                          size: 16, color: AppColors.error),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Logout',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 2),
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = index == selectedIndex;
        final icon =
            isSelected ? item['active'] as IconData : item['icon'] as IconData;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: InkWell(
            onTap: () {
              if (selectedIndex != index) {
                onItemSelected(index);
                Navigator.pop(context);
                try {
                  Navigator.pushReplacementNamed(
                      context, item['route'] as String);
                } catch (_) {
                  Navigator.pushNamed(context, item['route'] as String);
                }
              } else {
                Navigator.pop(context);
              }
            },
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  vertical: 10, horizontal: AppSpacing.sm),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark
                        ? Colors.white.withOpacity(0.08)
                        : AppColors.neutral50)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? Colors.white70 : AppColors.textSecondary),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      item['label'] as String,
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? AppColors.primary
                            : (isDark ? Colors.white70 : AppColors.textPrimary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
