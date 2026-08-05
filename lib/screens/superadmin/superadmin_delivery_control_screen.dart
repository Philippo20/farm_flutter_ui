import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/modern_admin_header.dart';
import '../../core/widgets/superadmin_sidebar.dart';
import '../../providers/auth_provider.dart';
import '../deliveries/overall_delivery_control_module.dart';

class SuperAdminDeliveryControlScreen extends ConsumerStatefulWidget {
  const SuperAdminDeliveryControlScreen({super.key});

  @override
  ConsumerState<SuperAdminDeliveryControlScreen> createState() =>
      _SuperAdminDeliveryControlScreenState();
}

class _SuperAdminDeliveryControlScreenState
    extends ConsumerState<SuperAdminDeliveryControlScreen> {
  int _selectedNavIndex = 11;
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
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      drawer: isMobile
          ? SuperAdminDrawer(
              selectedIndex: _selectedNavIndex,
              onItemSelected: (index) =>
                  setState(() => _selectedNavIndex = index),
              userName: userName,
              userEmail: userEmail,
              userRole: 'Super Administrator',
            )
          : null,
      body: isMobile
          ? _buildMobileLayout(firstName)
          : _buildDesktopLayout(
              userName: userName,
              userEmail: userEmail,
              firstName: firstName,
            ),
      bottomNavigationBar: isMobile
          ? SuperAdminMobileBottomNav(
              selectedIndex: 11,
              onItemSelected: (_) {},
            )
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
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
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
}
