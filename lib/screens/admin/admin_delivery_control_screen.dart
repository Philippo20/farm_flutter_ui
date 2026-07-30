import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/modern_admin_header.dart';
import '../../core/widgets/modern_admin_sidebar.dart';
import '../../providers/auth_provider.dart';
import '../deliveries/overall_delivery_control_module.dart';

class AdminDeliveryControlScreen extends ConsumerStatefulWidget {
  const AdminDeliveryControlScreen({super.key});

  @override
  ConsumerState<AdminDeliveryControlScreen> createState() =>
      _AdminDeliveryControlScreenState();
}

class _AdminDeliveryControlScreenState
    extends ConsumerState<AdminDeliveryControlScreen> {
  int _selectedNavIndex = 7;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final user = ref.watch(currentUserProvider);
    final userName = user?.name ?? 'Admin';
    final userEmail = user?.email ?? 'admin@farmestates.com';
    final firstName = userName.split(' ').first;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: isMobile
          ? _buildMobileLayout(firstName)
          : _buildDesktopLayout(
              userName: userName,
              userEmail: userEmail,
              firstName: firstName,
            ),
      bottomNavigationBar: isMobile
          ? SafeArea(top: false, child: _buildBottomNavigation(isDark))
          : null,
    );
  }

  Widget _buildDesktopLayout({
    required String userName,
    required String userEmail,
    required String firstName,
  }) {
    return Row(
      children: [
        ModernAdminSidebar(
          selectedIndex: _selectedNavIndex,
          onItemSelected: (index) => setState(() => _selectedNavIndex = index),
          userName: userName,
          userEmail: userEmail,
          userRole: 'Administrator',
        ),
        Expanded(
          child: Column(
            children: [
              ModernAdminHeader(
                userName: firstName,
                onNotificationTap: () {},
                onProfileTap: () {},
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: const OverallDeliveryControlModule(
                    title: 'Global Delivery Command',
                    subtitle:
                        'Control delivery operations across all farms with approval, assignment, hold, cancellation, and traceable activity logs.',
                    isMobile: false,
                    allowCreateDelivery: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(String firstName) {
    return Column(
      children: [
        ModernAdminHeader(
          userName: firstName,
          onNotificationTap: () {},
          onProfileTap: () {},
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: const OverallDeliveryControlModule(
              title: 'Global Delivery Command',
              subtitle:
                  'Control delivery operations across all farms with approval, assignment, hold, cancellation, and traceable activity logs.',
              isMobile: true,
              allowCreateDelivery: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation(bool isDark) {
    final navItems = [
      {
        'icon': Icons.dashboard_outlined,
        'label': 'Dashboard',
        'index': 0,
        'route': '/dashboard'
      },
      {
        'icon': Icons.agriculture_outlined,
        'label': 'Farms',
        'index': 2,
        'route': '/farms'
      },
      {
        'icon': Icons.inventory_2_outlined,
        'label': 'Inventory',
        'index': 6,
        'route': '/inventory-admin'
      },
      {
        'icon': Icons.local_shipping_outlined,
        'label': 'Deliveries',
        'index': 7,
        'route': '/deliveries-admin'
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 70,
          child: Row(
            children: navItems.map((item) {
              final index = item['index'] as int;
              final isSelected = index == _selectedNavIndex;
              return Expanded(
                child: InkWell(
                  onTap: () {
                    if (_selectedNavIndex != index) {
                      setState(() => _selectedNavIndex = index);
                      Navigator.pushReplacementNamed(
                          context, item['route'] as String);
                    }
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item['icon'] as IconData,
                        size: 22,
                        color: isSelected
                            ? AppColors.primary
                            : (isDark
                                ? Colors.white.withOpacity(0.5)
                                : AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['label'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected
                              ? AppColors.primary
                              : (isDark
                                  ? Colors.white.withOpacity(0.5)
                                  : AppColors.textSecondary),
                        ),
                      ),
                    ],
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
