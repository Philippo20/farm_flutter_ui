import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class TechnicianMobileBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const TechnicianMobileBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  static const List<Map<String, dynamic>> _navItems = [
    {
      'icon': Icons.dashboard_outlined,
      'label': 'Dashboard',
      'route': '/technician_dashboard',
    },
    {
      'icon': Icons.sensors_outlined,
      'label': 'Sensors',
      'route': '/sensor-management',
    },
    {
      'icon': Icons.build_outlined,
      'label': 'Maintain',
      'route': '/maintenance-schedule',
    },
    {
      'icon': Icons.history_outlined,
      'label': 'History',
      'route': '/repair-history',
    },
    {
      'icon': Icons.settings_outlined,
      'label': 'Settings',
      'route': '/technician-settings',
    },
  ];

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
            children: _navItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = selectedIndex == index;
              final color =
                  isSelected ? AppColors.primary : _inactiveColor(isDark);

              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _handleTap(context, index),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                      .withOpacity(isDark ? 0.16 : 0.10)
                                  : Colors.transparent,
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusFull),
                            ),
                            child: Icon(
                              item['icon'] as IconData,
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
