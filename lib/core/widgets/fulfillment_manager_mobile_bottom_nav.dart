import 'mobile_navigation_bar.dart';
import 'package:flutter/material.dart';

class FulfillmentManagerMobileBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const FulfillmentManagerMobileBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  static const List<Map<String, dynamic>> _navItems = [
    {
      'icon': Icons.dashboard_outlined,
      'activeIcon': Icons.dashboard_rounded,
      'label': 'Dashboard',
      'route': '/fulfillment_dashboard',
    },
    {
      'icon': Icons.check_box_outlined,
      'activeIcon': Icons.check_box_rounded,
      'label': 'Confirm',
      'route': '/fulfillment-confirm',
    },
    {
      'icon': Icons.inventory_2_outlined,
      'activeIcon': Icons.inventory_2_rounded,
      'label': 'Packaging',
      'route': '/fulfillment-packaging',
    },
    {
      'icon': Icons.calculate_outlined,
      'activeIcon': Icons.calculate_rounded,
      'label': 'Calculator',
      'route': '/fulfillment-yield',
    },
    {
      'icon': Icons.category_outlined,
      'activeIcon': Icons.category_rounded,
      'label': 'Materials',
      'route': '/fulfillment-materials',
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
