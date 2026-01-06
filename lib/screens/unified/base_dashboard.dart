import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/mock_farm_data.dart';
import 'widgets/greeting_widget.dart';
import 'widgets/weather_widget.dart';
// TODO: Create these widgets
// import 'widgets/unified_sidebar.dart';
// import 'widgets/unified_header.dart';
// import 'widgets/sensor_grid.dart';
// import 'widgets/activity_feed.dart';
// import 'widgets/notification_panel.dart';

/// Base dashboard layout used by all roles
/// Provides consistent structure with role-specific content
abstract class BaseDashboard extends ConsumerStatefulWidget {
  final String userRole;
  
  const BaseDashboard({
    super.key,
    required this.userRole,
  });
}

abstract class BaseDashboardState<T extends BaseDashboard> 
    extends ConsumerState<T> with TickerProviderStateMixin {
  
  late AnimationController _sidebarController;
  late AnimationController _fadeController;
  late Map<String, dynamic> userData;
  late Map<String, dynamic> weatherData;
  late Map<String, dynamic> sensorData;
  late List<Map<String, dynamic>> activities;
  late List<Map<String, dynamic>> notifications;
  
  int selectedNavIndex = 0;
  bool isSidebarExpanded = true;
  bool showNotifications = false;
  String selectedFarm = 'All Farms';
  
  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadData();
  }
  
  void _initializeControllers() {
    _sidebarController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _fadeController.forward();
  }
  
  void _loadData() {
    userData = MockFarmData.getCurrentUser(widget.userRole);
    weatherData = MockFarmData.getWeatherData();
    sensorData = MockFarmData.getSensorData();
    activities = MockFarmData.getRecentActivities();
    notifications = MockFarmData.getNotifications();
    
    // Load role-specific data
    loadRoleSpecificData();
  }
  
  // Abstract method to be implemented by role-specific dashboards
  void loadRoleSpecificData();
  
  // Abstract method to get navigation items for each role
  List<NavigationItem> getNavigationItems();
  
  // Abstract method to build main content for each role
  Widget buildMainContent(BuildContext context);
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth < 1024;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Stack(
        children: [
          // Background gradient
          _buildBackgroundGradient(isDark),
          
          // Main layout
          Row(
            children: [
              // Sidebar (hidden on mobile)
              if (!isMobile)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: isSidebarExpanded ? 280 : 80,
                  // TODO: Implement UnifiedSidebar widget
                  child: Container(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    child: Center(
                      child: Text('Sidebar Placeholder'),
                    ),
                  ),
                ),
              
              // Main content area
              Expanded(
                child: Column(
                  children: [
                    // Header
                    // TODO: Implement UnifiedHeader widget
                    Container(
                      height: 60,
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      child: Center(
                        child: Text('Header Placeholder'),
                      ),
                    ),
                    
                    // Content area with animations
                    Expanded(
                      child: FadeTransition(
                        opacity: _fadeController,
                        child: Row(
                          children: [
                            // Main content
                            Expanded(
                              child: SingleChildScrollView(
                                padding: EdgeInsets.all(
                                  isMobile ? AppSpacing.md : AppSpacing.xl,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Greeting and weather row
                                    _buildTopSection(isMobile),
                                    
                                    const SizedBox(height: AppSpacing.xl),
                                    
                                    // Role-specific main content
                                    buildMainContent(context),
                                  ],
                                ),
                              ),
                            ),
                            
                            // Notification panel (desktop only)
                            if (!isTablet && showNotifications)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: 350,
                                // TODO: Implement NotificationPanel widget
                                child: Container(
                                  color: isDark ? AppColors.surfaceDark : Colors.white,
                                  child: Center(
                                    child: Text('Notifications Placeholder'),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Mobile bottom navigation
          if (isMobile)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildMobileBottomNav(isDark),
            ),
        ],
      ),
    );
  }
  
  Widget _buildBackgroundGradient(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.backgroundDark,
                  AppColors.backgroundDark.withBlue(30),
                ]
              : [
                  AppColors.backgroundLight,
                  AppColors.backgroundLight.withGreen(245),
                ],
        ),
      ),
    );
  }
  
  Widget _buildTopSection(bool isMobile) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GreetingWidget(
            userName: userData['name'],
            role: userData['role'],
          ),
          const SizedBox(height: AppSpacing.md),
          WeatherWidget(
            weatherData: weatherData,
            compact: true,
          ),
        ],
      );
    }
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: GreetingWidget(
            userName: userData['name'],
            role: userData['role'],
          ),
        ),
        const SizedBox(width: AppSpacing.xl),
        WeatherWidget(
          weatherData: weatherData,
          compact: false,
        ),
      ],
    );
  }
  
  Widget _buildMobileBottomNav(bool isDark) {
    final items = getNavigationItems();
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.take(5).map((item) {
              final index = items.indexOf(item);
              final isSelected = index == selectedNavIndex;
              
              return Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      selectedNavIndex = index;
                    });
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isSelected ? item.activeIcon : item.icon,
                        color: isSelected
                            ? AppColors.primary
                            : (isDark
                                ? Colors.white.withOpacity(0.5)
                                : AppColors.textSecondary),
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: AppTypography.caption.copyWith(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark
                                  ? Colors.white.withOpacity(0.5)
                                  : AppColors.textSecondary),
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
  
  List<String> _getFarmsForRole() {
    switch (widget.userRole) {
      case 'admin':
        return ['All Farms', 'Northern Estate', 'Southern Estate', 
                'Eastern Farm', 'Western Farm'];
      case 'owner':
        return ['All Farms', 'Northern Estate', 'Southern Estate'];
      case 'caretaker':
        return ['Northern Estate'];
      default:
        return ['All Farms'];
    }
  }
  
  void _showProfileMenu() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Profile - ${userData['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Role: ${userData['role']}'),
            Text('Email: ${userData['email']}'),
            const SizedBox(height: AppSpacing.md),
            const Text('Assigned Farms:'),
            ...List<String>.from(userData['farms']).map((farm) => 
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.md),
                child: Text('• $farm'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _sidebarController.dispose();
    _fadeController.dispose();
    super.dispose();
  }
}

/// Navigation item model
class NavigationItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;
  
  const NavigationItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
  });
}
