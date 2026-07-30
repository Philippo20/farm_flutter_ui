import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'accountant_header.dart';
import 'accountant_mobile_bottom_nav.dart';
import 'accountant_sidebar.dart';
import 'weather_info_chip.dart';

class AccountantScreenShell extends ConsumerWidget {
  final int selectedIndex;
  final Widget child;

  const AccountantScreenShell({
    super.key,
    required this.selectedIndex,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'Accountant';
    final userEmail = authState.user?.email ?? 'accountant@farmestates.com';
    const weatherInfo = WeatherInfo(condition: 'Sunny', temperature: 28.5);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: isMobile
          ? Column(
              children: [
                AccountantHeader(
                  userName: userName,
                  weatherInfo: weatherInfo,
                  onNotificationTap: () {},
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
                AccountantSidebar(
                  selectedIndex: selectedIndex,
                  onItemSelected: (_) {},
                  userName: userName,
                  userEmail: userEmail,
                  userRole: 'Accountant',
                ),
                Expanded(
                  child: Column(
                    children: [
                      AccountantHeader(
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
          ? SafeArea(
              top: false,
              child: AccountantMobileBottomNav(
                selectedIndex: selectedIndex,
                onItemSelected: (_) {},
              ))
          : null,
    );
  }
}
