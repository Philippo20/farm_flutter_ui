import 'mobile_navigation_bar.dart';
import 'package:flutter/material.dart';

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
      'activeIcon': Icons.dashboard_rounded,
      'label': 'Dashboard',
      'route': '/technician_dashboard',
    },
    {
      'icon': Icons.sensors_outlined,
      'activeIcon': Icons.sensors_rounded,
      'label': 'Sensors',
      'route': '/sensor-management',
    },
    {
      'icon': Icons.build_outlined,
      'activeIcon': Icons.build_rounded,
      'label': 'Maintain',
      'route': '/maintenance-schedule',
    },
    {
      'icon': Icons.history_outlined,
      'activeIcon': Icons.history_rounded,
      'label': 'History',
      'route': '/repair-history',
    },
    {
      'icon': Icons.settings_outlined,
      'activeIcon': Icons.settings_rounded,
      'label': 'Settings',
      'route': '/technician-settings',
    },
  ];

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
    return MobileNavigationBar(
        children: _navItems.asMap().entries.map((entry) {
      final item = entry.value;
      final index = entry.key;
      return MobileNavigationDestination(
          icon: item['icon'] as IconData,
          activeIcon: item['activeIcon'] as IconData,
          label: item['label'] as String,
          selected: index == selectedIndex,
          onTap: () => _handleTap(context, index));
    }).toList());
  }
}
