import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class SalesManagerMobileBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const SalesManagerMobileBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  static const List<Map<String, dynamic>> _navItems = [
    {
      'icon': Icons.dashboard_outlined,
      'activeIcon': Icons.dashboard_rounded,
      'label': 'Dashboard',
      'index': 0,
      'route': '/sales_dashboard',
    },
    {
      'icon': Icons.people_outlined,
      'activeIcon': Icons.people_rounded,
      'label': 'Buyers',
      'index': 1,
      'route': '/sales-off-takers',
    },
    {
      'icon': Icons.trending_up_outlined,
      'activeIcon': Icons.trending_up_rounded,
      'label': 'Growth',
      'index': 2,
      'route': '/sales-performance',
    },
    {
      'icon': Icons.local_shipping_outlined,
      'activeIcon': Icons.local_shipping_rounded,
      'label': 'Delivery',
      'index': 3,
      'route': '/sales-deliveries',
    },
    {
      'icon': Icons.assessment_outlined,
      'activeIcon': Icons.assessment_rounded,
      'label': 'Reports',
      'index': 5,
      'route': '/sales-reports',
    },
  ];

  Color _inactiveColor(bool isDark) {
    return isDark
        ? AppColors.textOnDark.withOpacity(0.74)
        : AppColors.textSecondary;
  }

  Future<void> _handleTap(
    BuildContext context,
    Map<String, dynamic> item,
  ) async {
    final index = item['index'] as int;
    if (selectedIndex == index) return;

    onItemSelected(index);
    final route = item['route'] as String;

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
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.08),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 76,
          child: Row(
            children: _navItems.map((item) {
              final index = item['index'] as int;
              final isSelected = selectedIndex == index;
              final color =
                  isSelected ? AppColors.primary : _inactiveColor(isDark);

              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _handleTap(context, item),
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
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusFull),
                            ),
                            child: Icon(
                              isSelected
                                  ? item['activeIcon'] as IconData
                                  : item['icon'] as IconData,
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
                                  ? FontWeight.w500
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
