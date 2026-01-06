import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class NavigationItem {
  final String label;
  final IconData icon;
  final IconData? selectedIcon;
  final VoidCallback onTap;

  NavigationItem({
    required this.label,
    required this.icon,
    this.selectedIcon,
    required this.onTap,
  });
}

class AdaptiveNavigation extends StatelessWidget {
  final List<NavigationItem> items;
  final int selectedIndex;
  final bool isExtended;

  const AdaptiveNavigation({
    super.key,
    required this.items,
    required this.selectedIndex,
    this.isExtended = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return NavigationRail(
      extended: isExtended,
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) => items[index].onTap(),
      backgroundColor: isDark ? AppColors.neutral900 : AppColors.neutral800,
      selectedIconTheme: const IconThemeData(
        color: AppColors.primary,
      ),
      unselectedIconTheme: IconThemeData(
        color: isDark ? AppColors.neutral400 : AppColors.neutral300,
      ),
      selectedLabelTextStyle: const TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: isDark ? AppColors.neutral400 : AppColors.neutral300,
      ),
      destinations: items
          .map((item) => NavigationRailDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon ?? item.icon),
                label: Text(item.label),
              ))
          .toList(),
    );
  }
}
