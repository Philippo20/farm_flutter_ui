import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/caretaker_sidebar.dart';
import '../../core/widgets/caretaker_header.dart';
import '../../core/widgets/modern_dashboard_scaffold.dart';
import '../../core/widgets/weather_time_widget.dart';
import '../../core/widgets/weather_info_chip.dart';
import '../../data/mock_farm_data.dart';
import '../../widgets/alert_summary_card.dart';
import '../../providers/auth_provider.dart';
import 'widgets/water_quality_card.dart';
import 'widgets/environment_monitoring_card.dart';
import 'widgets/nutrient_system_card.dart';

/// Caretaker Dashboard - Redesigned
/// Daily operations and record keeping
class CaretakerDashboardRedesigned extends ConsumerStatefulWidget {
  const CaretakerDashboardRedesigned({super.key});

  @override
  ConsumerState<CaretakerDashboardRedesigned> createState() => _CaretakerDashboardRedesignedState();
}

class _CaretakerDashboardRedesignedState extends ConsumerState<CaretakerDashboardRedesigned> {
  int _selectedNavIndex = 0;
  WeatherInfo? _weatherInfo;

  @override
  void initState() {
    super.initState();
    // Load weather info if needed
    _weatherInfo = const WeatherInfo(condition: 'Sunny', temperature: 28.5);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'Caretaker';
    final userEmail = authState.user?.email ?? 'caretaker@farmestates.com';
    final userRole = 'Caretaker';

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: isMobile
          ? _buildMobileLayout(isDark, userName)
          : _buildDesktopLayout(isDark, userName, userEmail, userRole),
      floatingActionButton: !isMobile
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.pushNamed(context, '/record-entry'),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add),
              label: const Text('New Record'),
            )
          : null,
      bottomNavigationBar: isMobile ? _buildBottomNavigation(isDark) : null,
    );
  }

  Widget _buildDesktopLayout(bool isDark, String userName, String userEmail, String userRole) {
    return Row(
      children: [
        // Sidebar
        CaretakerSidebar(
          selectedIndex: _selectedNavIndex,
          onItemSelected: (index) {
            setState(() {
              _selectedNavIndex = index;
            });
          },
          userName: userName,
          userEmail: userEmail,
          userRole: userRole,
        ),

        // Main Content
        Expanded(
          child: Column(
            children: [
              // Header
              CaretakerHeader(
                userName: userName,
                weatherInfo: _weatherInfo,
                onNotificationTap: () {
                  // Handle notifications
                },
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Weather & Time Widget
                      const WeatherTimeWidget(),

                      const SizedBox(height: AppSpacing.lg),

                      // Compact Stats Section
                      _buildStatsSection(context),

                      const SizedBox(height: AppSpacing.xl),

                      // Alert Summary
                      const AlertSummaryCard(
                        showRecentAlerts: true,
                        maxRecentAlerts: 2,
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // Section Title - Monitoring
                      Text(
                        'Crop Health Monitoring',
                        style: AppTypography.h5.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Monitoring Cards
                      _buildMonitoringCards(context),

                      const SizedBox(height: AppSpacing.xl),

                      // Section Title - Tasks
                      Text(
                        'Daily Tasks',
                        style: AppTypography.h5.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Features Grid
                      _buildFeaturesGrid(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(bool isDark, String userName) {
    return Column(
      children: [
        CaretakerHeader(
          userName: userName,
          weatherInfo: _weatherInfo,
          onNotificationTap: () {
            // Handle notifications
          },
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Weather & Time Widget
                const WeatherTimeWidget(),

                const SizedBox(height: AppSpacing.md),

                // Compact Stats Section
                _buildStatsSection(context),

                const SizedBox(height: AppSpacing.lg),

                // Alert Summary
                const AlertSummaryCard(
                  showRecentAlerts: true,
                  maxRecentAlerts: 2,
                ),

                const SizedBox(height: AppSpacing.lg),

                // Section Title - Monitoring
                Text(
                  'Crop Health Monitoring',
                  style: AppTypography.h5.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Monitoring Cards
                _buildMonitoringCards(context),

                const SizedBox(height: AppSpacing.lg),

                // Section Title - Tasks
                Text(
                  'Daily Tasks',
                  style: AppTypography.h5.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Features Grid
                _buildFeaturesGrid(context),
              ],
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
        'route': '/caretaker_dashboard'
      },
      {
        'icon': Icons.edit_note_outlined,
        'label': 'Record',
        'index': 1,
        'route': '/record-entry'
      },
      {
        'icon': Icons.check_circle_outline,
        'label': 'Confirm',
        'index': 2,
        'route': '/input-confirmation'
      },
      {
        'icon': Icons.chat_bubble_outline,
        'label': 'Chat',
        'index': 3,
        'route': '/chat'
      },
      {
        'icon': Icons.calendar_today_outlined,
        'label': 'Calendar',
        'index': 4,
        'route': '/calendar'
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
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: navItems.map((item) {
              final index = item['index'] as int;
              final route = item['route'] as String;
              final isSelected = index == _selectedNavIndex;

              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (_selectedNavIndex != index) {
                        setState(() => _selectedNavIndex = index);
                        try {
                          Navigator.pushReplacementNamed(context, route);
                        } catch (e) {
                          try {
                            Navigator.pushNamed(context, route);
                          } catch (e2) {
                            debugPrint('Navigation error: $e2');
                          }
                        }
                      }
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item['icon'] as IconData,
                          size: 24,
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? Colors.white.withOpacity(0.5) : AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['label'] as String,
                          style: AppTypography.caption.copyWith(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark
                                    ? Colors.white.withOpacity(0.5)
                                    : AppColors.textSecondary),
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 800 ? 4 : 2;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 3.2,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            CompactStatCard(
              title: 'Tasks Today',
              value: '8 / 5 Done',
              icon: Icons.task_alt,
              color: AppColors.primary,
              trend: '+3',
              isPositive: true,
            ),
            CompactStatCard(
              title: 'Plants Monitored',
              value: '120 Plants',
              icon: Icons.spa,
              color: AppColors.success,
            ),
            CompactStatCard(
              title: 'Harvest Ready',
              value: '85 kg',
              icon: Icons.agriculture,
              color: AppColors.warning,
            ),
            CompactStatCard(
              title: 'Inputs Used',
              value: '\$450',
              icon: Icons.inventory_2,
              color: AppColors.info,
              trend: '-5%',
              isPositive: false,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMonitoringCards(BuildContext context) {
    // Get sensor data from MockFarmData
    final sensorData = MockFarmData.getSensorData();
    final systemControls = MockFarmData.getSystemControls();

    return Column(
      children: [
        // Water Quality Card
        WaterQualityCard(
          ph: sensorData['ph']['value'],
          ec: sensorData['ec']['value'],
          tds: sensorData['tds']['value'],
          waterTemp: sensorData['temperature']['value'].toDouble(),
          onTap: () {
            // Navigate to detailed water quality screen
          },
        ),

        const SizedBox(height: AppSpacing.md),

        // Environment Monitoring Card
        EnvironmentMonitoringCard(
          temperature: sensorData['temperature']['value'].toDouble(),
          humidity: sensorData['humidity']['value'],
          co2: sensorData['co2']['value'],
          temperatureTrend: sensorData['temperature']['trend'],
          humidityTrend: sensorData['humidity']['trend'],
          co2Trend: sensorData['co2']['trend'],
          onTap: () {
            // Navigate to detailed environment screen
          },
        ),

        const SizedBox(height: AppSpacing.md),

        // Nutrient System Card
        NutrientSystemCard(
          nutrientPumpState: systemControls['pumps']['nutrientPump']['state'],
          phUpState: systemControls['phControl']['phUp']['state'],
          phDownState: systemControls['phControl']['phDown']['state'],
          lastAdjustment: DateTime.now().subtract(Duration(minutes: 45)),
          onTap: () {
            // Navigate to nutrient system control screen
          },
        ),
      ],
    );
  }

  Widget _buildFeaturesGrid(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 800 ? 3 : 2;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 1.2,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildFeatureCard(
              context,
              isDark,
              'Record Entry',
              Icons.edit_note,
              AppColors.primary,
              '8 pending entries',
              () => Navigator.pushNamed(context, '/record-entry'),
            ),
            _buildFeatureCard(
              context,
              isDark,
              'Confirm Inputs',
              Icons.check_circle_outline,
              AppColors.success,
              '3 confirmations',
              () {},
            ),
            _buildFeatureCard(
              context,
              isDark,
              'Task Calendar',
              Icons.calendar_today,
              AppColors.info,
              'View schedule',
              () {},
            ),
            _buildFeatureCard(
              context,
              isDark,
              'Chat Support',
              Icons.chat_bubble_outline,
              AppColors.warning,
              'Get help',
              () {},
            ),
            _buildFeatureCard(
              context,
              isDark,
              'View Records',
              Icons.history,
              AppColors.primary,
              'Past entries',
              () {},
            ),
            _buildFeatureCard(
              context,
              isDark,
              'Settings',
              Icons.settings_outlined,
              AppColors.textSecondary,
              'Preferences',
              () {},
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    bool isDark,
    String title,
    IconData icon,
    Color color,
    String subtitle,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black12,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: color,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white60 : AppColors.textSecondary,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
