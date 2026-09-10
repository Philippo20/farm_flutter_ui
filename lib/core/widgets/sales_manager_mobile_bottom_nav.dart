import 'mobile_navigation_bar.dart';
import 'package:flutter/material.dart';

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
    return MobileNavigationBar(
        children: _navItems.asMap().entries.map((entry) {
      final item = entry.value;
      final index = item['index'] as int;
      return MobileNavigationDestination(
          icon: item['icon'] as IconData,
          activeIcon: item['activeIcon'] as IconData,
          label: item['label'] as String,
          selected: index == selectedIndex,
          onTap: () => _handleTap(context, item));
    }).toList());
  }
}
