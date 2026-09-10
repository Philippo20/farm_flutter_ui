import 'mobile_navigation_bar.dart';
import 'package:flutter/material.dart';

class SalesPersonnelMobileBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const SalesPersonnelMobileBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  static const List<Map<String, dynamic>> _navItems = [
    {
      'icon': Icons.dashboard_outlined,
      'activeIcon': Icons.dashboard_rounded,
      'label': 'Home',
      'index': 0,
      'route': '/sales-personnel-dashboard',
    },
    {
      'icon': Icons.local_shipping_outlined,
      'activeIcon': Icons.local_shipping_rounded,
      'label': 'Deliver',
      'index': 1,
      'route': '/sales-personnel-record-delivery',
    },
    {
      'icon': Icons.timeline_outlined,
      'activeIcon': Icons.timeline_rounded,
      'label': 'Pipeline',
      'index': 2,
      'route': '/sales-personnel-pipeline',
    },
    {
      'icon': Icons.payments_outlined,
      'activeIcon': Icons.payments_rounded,
      'label': 'Sales',
      'index': 3,
      'route': '/sales-personnel-sales',
    },
    {
      'icon': Icons.assessment_outlined,
      'activeIcon': Icons.assessment_rounded,
      'label': 'Reports',
      'index': 5,
      'route': '/sales-personnel-reports',
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
