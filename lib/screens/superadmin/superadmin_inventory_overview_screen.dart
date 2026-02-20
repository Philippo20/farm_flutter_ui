import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/modern_admin_header.dart';
import '../../core/widgets/superadmin_sidebar.dart';
import '../../providers/auth_provider.dart';
import '../inventory/overall_inventory_module.dart';

class SuperAdminInventoryOverviewScreen extends ConsumerStatefulWidget {
  const SuperAdminInventoryOverviewScreen({super.key});

  @override
  ConsumerState<SuperAdminInventoryOverviewScreen> createState() =>
      _SuperAdminInventoryOverviewScreenState();
}

class _SuperAdminInventoryOverviewScreenState
    extends ConsumerState<SuperAdminInventoryOverviewScreen> {
  int _selectedNavIndex = 9;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final user = ref.watch(currentUserProvider);
    final userName = user?.name ?? 'Super Admin';
    final userEmail = user?.email ?? 'superadmin@farmestates.com';
    final firstName = userName.split(' ').first;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      drawer: isMobile
          ? SuperAdminDrawer(
              selectedIndex: _selectedNavIndex,
              onItemSelected: (index) => setState(() => _selectedNavIndex = index),
              userName: userName,
              userEmail: userEmail,
              userRole: 'Super Administrator',
            )
          : null,
      body: isMobile
          ? _buildMobileLayout(isDark, firstName)
          : _buildDesktopLayout(
              isDark: isDark,
              userName: userName,
              userEmail: userEmail,
              firstName: firstName,
            ),
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
        SuperAdminSidebar(
          selectedIndex: _selectedNavIndex,
          onItemSelected: (index) => setState(() => _selectedNavIndex = index),
          userName: userName,
          userEmail: userEmail,
          userRole: 'Super Administrator',
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
                  child: const OverallInventoryModule(
                    title: 'Global Inventory Oversight',
                    subtitle:
                        'Track stock across all farms, drill down by farm, and audit stock in/out movement logs by user and time.',
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
          onProfileTap: () {},
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: const OverallInventoryModule(
              title: 'Global Inventory Oversight',
              subtitle:
                  'Track stock across all farms, drill down by farm, and audit stock in/out movement logs by user and time.',
              isMobile: true,
            ),
          ),
        ),
      ],
    );
  }
}
