import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'adaptive_logout_confirmation.dart';

class CaretakerMobileBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const CaretakerMobileBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  static const List<Map<String, dynamic>> _navItems = [
    {
      'icon': Icons.dashboard_outlined,
      'activeIcon': Icons.dashboard_rounded,
      'label': 'Dashboard',
      'route': '/caretaker_dashboard',
    },
    {
      'icon': Icons.edit_note_outlined,
      'activeIcon': Icons.edit_note_rounded,
      'label': 'Record',
      'route': '/record-entry',
    },
    {
      'icon': Icons.check_circle_outline,
      'activeIcon': Icons.check_circle_rounded,
      'label': 'Confirm',
      'route': '/input-confirmation',
    },
    {
      'icon': Icons.chat_bubble_outline,
      'activeIcon': Icons.chat_bubble_rounded,
      'label': 'Chat',
      'route': '/chat',
    },
    {
      'icon': Icons.calendar_today_outlined,
      'activeIcon': Icons.calendar_today_rounded,
      'label': 'Calendar',
      'route': '/calendar',
    },
    {
      'icon': Icons.settings_outlined,
      'activeIcon': Icons.settings_rounded,
      'label': 'Settings',
      'route': '/caretaker_settings',
    },
  ];

  static const _primaryIndices = [0, 1, 2, 3];
  static const _defaultDynamicIndex = 4;

  Color _inactiveColor(bool isDark) {
    return isDark
        ? AppColors.textOnDark.withOpacity(0.74)
        : AppColors.textSecondary;
  }

  Future<void> _handleTap(BuildContext context, int index) async {
    if (selectedIndex == index) return;

    final route = _navItems[index]['route'] as String;
    onItemSelected(index);

    try {
      await Navigator.pushReplacementNamed(context, route);
    } catch (_) {
      try {
        await Navigator.pushNamed(context, route);
      } catch (error) {
        debugPrint('Navigation error: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.08);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.24 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(top: BorderSide(color: dividerColor)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 76,
          child: Row(
            children: [
              ..._primaryIndices,
              selectedIndex >= 4 ? selectedIndex : _defaultDynamicIndex,
            ].map((index) {
              final item = _navItems[index];
              final isSelected = index == selectedIndex;
              final color =
                  isSelected ? AppColors.primary : _inactiveColor(isDark);

              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _handleTap(context, index),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withOpacity(
                                      isDark ? 0.16 : 0.10,
                                    )
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusFull,
                              ),
                            ),
                            child: Icon(
                              isSelected
                                  ? (item['activeIcon'] as IconData)
                                  : (item['icon'] as IconData),
                              size: 22,
                              color: color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['label'] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(
                              color: color,
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
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

class CaretakerMobileDrawer extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final String userName;
  final String userEmail;

  const CaretakerMobileDrawer({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.userName,
    required this.userEmail,
  });

  static const _items = [
    (
      'Dashboard',
      '/caretaker_dashboard',
      Icons.dashboard_outlined,
      Icons.dashboard_rounded
    ),
    (
      'Record Entry',
      '/record-entry',
      Icons.edit_note_outlined,
      Icons.edit_note_rounded
    ),
    (
      'Input Confirmation',
      '/input-confirmation',
      Icons.check_circle_outline,
      Icons.check_circle_rounded
    ),
    ('Chat', '/chat', Icons.chat_bubble_outline, Icons.chat_bubble_rounded),
    (
      'Calendar',
      '/calendar',
      Icons.calendar_today_outlined,
      Icons.calendar_today_rounded
    ),
    (
      'Settings',
      '/caretaker_settings',
      Icons.settings_outlined,
      Icons.settings_rounded
    ),
  ];

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
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(
                      userName.isEmpty ? 'C' : userName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(userName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700)),
                        Text('Caretaker',
                            style: AppTypography.bodySmall.copyWith(
                                color: Colors.white.withOpacity(0.9))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  final selected = index == selectedIndex;
                  return ListTile(
                    onTap: () {
                      onItemSelected(index);
                      Navigator.pop(context);
                      if (index != selectedIndex) {
                        Navigator.pushReplacementNamed(context, item.$2);
                      }
                    },
                    selected: selected,
                    selectedTileColor: isDark
                        ? Colors.white.withOpacity(0.1)
                        : AppColors.primary.withOpacity(0.1),
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
                      child: Icon(selected ? item.$4 : item.$3,
                          color: selected
                              ? AppColors.primary
                              : (isDark
                                  ? Colors.white70
                                  : AppColors.textSecondary)),
                    ),
                    title: Text(item.$1,
                        style: AppTypography.bodyMedium.copyWith(
                            fontSize: 15,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected
                                ? AppColors.primary
                                : (isDark
                                    ? Colors.white
                                    : AppColors.textPrimary))),
                  );
                },
              ),
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
                        userName.isEmpty ? 'C' : userName[0].toUpperCase(),
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
                        Text(userName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyMedium.copyWith(
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        Text(userEmail,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white70
                                    : AppColors.textSecondary)),
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
                      border:
                          Border.all(color: AppColors.error.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.logout_rounded,
                            size: 20, color: AppColors.error),
                        const SizedBox(width: AppSpacing.sm),
                        Text('Logout',
                            style: AppTypography.bodyMedium.copyWith(
                                fontSize: 15,
                                color: AppColors.error,
                                fontWeight: FontWeight.w500)),
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
