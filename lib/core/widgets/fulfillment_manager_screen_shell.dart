import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'fulfillment_manager_header.dart';
import 'fulfillment_manager_sidebar.dart';
import 'role_mobile_navigation.dart';

class FulfillmentManagerScreenShell extends ConsumerWidget {
  final int selectedIndex;
  final Widget child;

  const FulfillmentManagerScreenShell({
    super.key,
    required this.selectedIndex,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'Fulfillment Manager';
    final userEmail = authState.user?.email ?? 'fulfillment@farmestates.com';
    final scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: scaffoldKey,
      drawer: isMobile
          ? RoleMobileDrawer(
              userName: userName,
              userEmail: userEmail,
              userRole: 'Fulfillment Manager',
              selectedIndex: selectedIndex,
              onItemSelected: (_) {},
              items: fulfillmentNavigationItems,
            )
          : null,
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: isMobile
          ? Column(
              children: [
                FulfillmentManagerHeader(
                  userName: userName,
                  onNotificationTap: () {},
                  onMenuTap: () => scaffoldKey.currentState?.openDrawer(),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      96,
                    ),
                    child: child,
                  ),
                ),
              ],
            )
          : Row(
              children: [
                FulfillmentManagerSidebar(
                  selectedIndex: selectedIndex,
                  onItemSelected: (_) {},
                  userName: userName,
                  userEmail: userEmail,
                  userRole: 'Fulfillment Manager',
                ),
                Expanded(
                  child: Column(
                    children: [
                      FulfillmentManagerHeader(
                        userName: userName,
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
              items: fulfillmentNavigationItems,
              defaultDynamicItem: fulfillmentNavigationItems[4],
            )
          : null,
    );
  }
}
