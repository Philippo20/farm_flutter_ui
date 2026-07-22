import 'package:flutter/material.dart';
import '../../widgets/sidebars/admin_sidebar.dart';
import 'adaptive_navigation.dart';
import 'modern_header.dart';
import 'weather_info_chip.dart';
import '../models/dashboard_app_bar_models.dart';

class ModernScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<NavigationItem> navigationItems;
  final int selectedNavigationIndex;
  final bool showNavigation;
  final FloatingActionButton? floatingActionButton;
  final String userName;
  final WeatherInfo? weatherInfo;
  final VoidCallback? onLogoTap;
  final List<String> tenants;
  final String? selectedTenant;
  final TenantChangedCallback? onTenantChanged;
  final List<GlobalSearchItem> searchItems;
  final String searchPlaceholder;
  final List<QuickActionItem> quickActions;
  final List<SystemStatusIndicator> systemStatuses;
  final VoidCallback? onSupportTap;

  const ModernScaffold({
    super.key,
    required this.title,
    required this.body,
    this.navigationItems = const [],
    this.selectedNavigationIndex = 0,
    this.showNavigation = true,
    this.floatingActionButton,
    this.userName = 'Admin',
    this.weatherInfo,
    this.onLogoTap,
    this.tenants = const [],
    this.selectedTenant,
    this.onTenantChanged,
    this.searchItems = const [],
    this.searchPlaceholder = 'Search farms, users, sensors…',
    this.quickActions = const [],
    this.systemStatuses = const [],
    this.onSupportTap,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isMobile = mediaQuery.size.width < 768;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    void handleNavigation(int index) {
      if (index >= 0 && index < navigationItems.length) {
        navigationItems[index].onTap();
      }
    }

    final sidebar = showNavigation && navigationItems.isNotEmpty && !isMobile
        ? AdminSidebar(
            selectedIndex: selectedNavigationIndex,
            onItemSelected: handleNavigation,
            isDark: isDark,
            isMobile: false,
          )
        : null;

    final bottomNavigation =
        showNavigation && navigationItems.isNotEmpty && isMobile
            ? AdminSidebar(
                selectedIndex: selectedNavigationIndex,
                onItemSelected: handleNavigation,
                isDark: isDark,
                isMobile: true,
              )
            : null;

    return Scaffold(
      appBar: ModernHeader(
        title: title,
        userName: userName,
        weatherInfo: weatherInfo,
        onLogoTap: onLogoTap,
        tenants: tenants,
        selectedTenant: selectedTenant,
        onTenantChanged: onTenantChanged,
        searchItems: searchItems,
        searchPlaceholder: searchPlaceholder,
        quickActions: quickActions,
        systemStatuses: systemStatuses,
        onSupportTap: onSupportTap,
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (sidebar != null) sidebar,
          Expanded(child: body),
        ],
      ),
      bottomNavigationBar: bottomNavigation,
      floatingActionButton: floatingActionButton,
    );
  }
}
