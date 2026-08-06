import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/modern_admin_header.dart';
import '../../core/widgets/modern_admin_sidebar.dart';
import '../../providers/auth_provider.dart';
import '../inventory/overall_inventory_module.dart';

class AdminInventoryOverviewScreen extends ConsumerStatefulWidget {
  const AdminInventoryOverviewScreen({super.key});

  @override
  ConsumerState<AdminInventoryOverviewScreen> createState() =>
      _AdminInventoryOverviewScreenState();
}

class _AdminInventoryOverviewScreenState
    extends ConsumerState<AdminInventoryOverviewScreen> {
  int _selectedNavIndex = 6;

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
      drawer: isMobile
          ? AdminDrawer(
              selectedIndex: 6,
              onItemSelected: (_) {},
              userName: userName,
              userEmail: userEmail,
              userRole: 'Administrator',
            )
          : null,
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: isMobile
          ? _buildMobileLayout(isDark, firstName)
          : _buildDesktopLayout(
              isDark: isDark,
              userName: userName,
              userEmail: userEmail,
              firstName: firstName,
            ),
      bottomNavigationBar: isMobile
          ? AdminMobileBottomNav(selectedIndex: 6, onItemSelected: (_) {})
          : null,
    );
  }

  Widget _buildDesktopLayout({
    required bool isDark,
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
                onProfileTap: () => Navigator.of(context).pushNamed('/profile'),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: const OverallInventoryModule(
                    title: 'Inventory Overview',
                    subtitle:
                        'Monitor inventory across all farms, filter by farm, and review stock movement history.',
                    isMobile: false,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(bool isDark, String firstName) {
    return Column(
      children: [
        ModernAdminHeader(
          userName: firstName,
          onNotificationTap: () {},
          onProfileTap: () => Navigator.of(context).pushNamed('/profile'),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: const OverallInventoryModule(
              title: 'Inventory Overview',
              subtitle:
                  'Monitor inventory across all farms, filter by farm, and review stock movement history.',
              isMobile: true,
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
        'icon': Icons.people_outline,
        'label': 'Users',
        'index': 1,
        'route': '/users'
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
