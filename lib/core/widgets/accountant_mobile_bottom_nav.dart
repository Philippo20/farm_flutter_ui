import 'mobile_navigation_bar.dart';
import 'package:flutter/material.dart';

class AccountantMobileBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const AccountantMobileBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  static const _navItems = [
    {
      'icon': Icons.dashboard_outlined,
      'activeIcon': Icons.dashboard_rounded,
      'label': 'Home',
      'route': '/accountant-dashboard',
    },
    {
      'icon': Icons.receipt_long_outlined,
      'activeIcon': Icons.receipt_long_rounded,
      'label': 'Ledger',
      'route': '/accountant-transactions',
    },
    {
      'icon': Icons.account_balance_outlined,
      'activeIcon': Icons.account_balance_rounded,
      'label': 'Bank',
      'route': '/accountant-reconciliation',
    },
    {
      'icon': Icons.approval_outlined,
      'activeIcon': Icons.approval_rounded,
      'label': 'Approvals',
      'route': '/accountant-approvals',
    },
    {
      'icon': Icons.assessment_outlined,
      'activeIcon': Icons.assessment_rounded,
      'label': 'Reports',
      'route': '/accountant-reports',
    },
  ];

  Future<void> _handleTap(BuildContext context, int index) async {
    if (selectedIndex == index) return;
    onItemSelected(index);
    final route = _navItems[index]['route'] as String;

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
