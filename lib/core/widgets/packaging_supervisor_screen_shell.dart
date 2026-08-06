import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'packaging_supervisor_header.dart';
import 'packaging_supervisor_sidebar.dart';
import 'weather_info_chip.dart';
import 'role_mobile_navigation.dart';

class PackagingSupervisorScreenShell extends ConsumerWidget {
  final int selectedIndex;
  final Widget child;

  const PackagingSupervisorScreenShell({
    super.key,
    required this.selectedIndex,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'Packaging Supervisor';
    final userEmail = authState.user?.email ?? 'packaging@farmestates.com';
    const weatherInfo = WeatherInfo(condition: 'Sunny', temperature: 28.5);
    final scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: scaffoldKey,
      drawer: isMobile
          ? RoleMobileDrawer(
              userName: userName,
              userEmail: userEmail,
              userRole: 'Packaging Supervisor',
              selectedIndex: selectedIndex,
              onItemSelected: (_) {},
              items: packagingNavigationItems,
            )
          : null,
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: isMobile
          ? Column(
              children: [
                PackagingSupervisorHeader(
                  userName: userName,
                  weatherInfo: weatherInfo,
                  onNotificationTap: () {},
                  onMenuTap: () => scaffoldKey.currentState?.openDrawer(),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.lg,
                    ),
                    child: child,
                  ),
                ),
              ],
            )
          : Row(
              children: [
                PackagingSupervisorSidebar(
                  selectedIndex: selectedIndex,
                  onItemSelected: (_) {},
                  userName: userName,
                  userEmail: userEmail,
                  userRole: 'Packaging Supervisor',
                ),
                Expanded(
                  child: Column(
                    children: [
                      PackagingSupervisorHeader(
                        userName: userName,
                        weatherInfo: weatherInfo,
                        onNotificationTap: () {},
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: child,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: isMobile
          ? RoleMobileBottomNav(
              selectedIndex: selectedIndex,
              onItemSelected: (_) {},
              items: packagingNavigationItems,
              defaultDynamicItem: packagingNavigationItems[4],
            )
          : null,
    );
  }
}
