import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/modern_admin_sidebar.dart';
import '../../core/widgets/modern_admin_header.dart';
import '../../core/widgets/weather_info_chip.dart';
import '../../utils/weather_utils.dart';
import '../../utils/location_utils.dart';
import '../../data/mock_farm_data.dart';
import '../../widgets/alert_summary_card.dart';

/// Redesigned Admin Dashboard with full dark mode support
/// Features: Collapsible sidebar, modern header, weather info, greeting
class RedesignedAdminDashboard extends ConsumerStatefulWidget {
  const RedesignedAdminDashboard({super.key});

  @override
  ConsumerState<RedesignedAdminDashboard> createState() =>
      _RedesignedAdminDashboardState();
}

class _RedesignedAdminDashboardState
    extends ConsumerState<RedesignedAdminDashboard> {
  int _selectedNavIndex = 0;
  String _selectedPeriod = 'Today';
  final String _adminName = 'Acquaye';
  WeatherInfo? _weatherInfo;
  final List<String> _farms = ['All Farms', 'Northern Estate', 'Southern Estate', 'Eastern Farm', 'Western Farm'];
  String _selectedFarm = 'All Farms';

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    try {
      // Use working API key
      const apiKey = 'bd5e378503939ddaee76f12ad7a97608';

      final position = await getCurrentLocation();
      final latitude = position?.latitude ?? 5.6037; // Accra, Ghana
      final longitude = position?.longitude ?? -0.1870;

      final data = await fetchWeatherData(
        latitude: latitude,
        longitude: longitude,
        apiKey: apiKey,
      );

      if (!mounted) return;

      setState(() {
        if (data != null) {
          _weatherInfo = WeatherInfo(
            condition: data['condition'] as String? ?? 'Clear',
            temperature: (data['temperature'] as num?)?.toDouble() ?? 28.0,
          );
        } else {
          _weatherInfo = const WeatherInfo(condition: 'Clear', temperature: 28.0);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _weatherInfo = const WeatherInfo(condition: 'Clear', temperature: 28.0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: isMobile ? _buildMobileLayout(isDark) : _buildDesktopLayout(isDark),
    );
  }

  Widget _buildDesktopLayout(bool isDark) {
    return Row(
      children: [
        // Sidebar
        ModernAdminSidebar(
          selectedIndex: _selectedNavIndex,
          onItemSelected: (index) {
            setState(() => _selectedNavIndex = index);
          },
          userName: _adminName,
          userEmail: 'admin@farmestates.com',
          userRole: 'Administrator',
        ),

        // Main Content
        Expanded(
          child: Column(
            children: [
              // Header
              ModernAdminHeader(
                userName: _adminName,
                weatherInfo: _weatherInfo,
                onNotificationTap: _showNotifications,
                onProfileTap: _showProfileMenu,
                farms: _farms,
                selectedFarm: _selectedFarm,
                onFarmChanged: (farm) {
                  if (farm != null) {
                    setState(() => _selectedFarm = farm);
                  }
                },
              ),

              // Content Area
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Period Filter
                      _buildPeriodFilter(),

                      const SizedBox(height: AppSpacing.xl),

                      // Stats Cards
                      _buildStatsGrid(),

                      const SizedBox(height: AppSpacing.xl),

                      // Alert Summary
                      const AlertSummaryCard(
                        showRecentAlerts: true,
                        maxRecentAlerts: 3,
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // Charts Section
                      _buildChartsSection(isDark),

                      const SizedBox(height: AppSpacing.xl),

                      // Recent Activities
                      _buildRecentActivities(isDark),
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

  Widget _buildMobileLayout(bool isDark) {
    return Column(
      children: [
        // Header
        ModernAdminHeader(
          userName: _adminName,
          weatherInfo: _weatherInfo,
          onNotificationTap: _showNotifications,
          onProfileTap: _showProfileMenu,
        ),

        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPeriodFilter(),
                const SizedBox(height: AppSpacing.lg),
                _buildStatsGrid(),
                const SizedBox(height: AppSpacing.lg),
                _buildChartsSection(isDark),
                const SizedBox(height: AppSpacing.lg),
                _buildRecentActivities(isDark),
              ],
            ),
          ),
        ),

        // Bottom Navigation
        _buildBottomNavigation(isDark),
      ],
    );
  }

  Widget _buildPeriodFilter() {
    final periods = ['Today', 'Week', 'Month', 'Year'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: periods.map((period) {
          final isSelected = _selectedPeriod == period;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: FilterChip(
              label: Text(
                period,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.primary
                      : Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedPeriod = period);
              },
              backgroundColor: Colors.transparent,
              selectedColor: AppColors.primary.withOpacity(0.15),
              checkmarkColor: AppColors.primary,
              labelStyle: AppTypography.bodyMedium.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatsGrid() {
    // Get real-time sensor and system data
    final sensorData = MockFarmData.getSensorData();
    final powerData = MockFarmData.getPowerData();
    final systemControls = MockFarmData.getSystemControls();
    
    // Calculate average temperature from all sensors
    final avgTemp = 17.5; // Average of 15-20°C range
    
    // Calculate active systems count
    int activeSystems = 0;
    systemControls['pumps'].forEach((key, value) {
      if (value['state'] == 'ON') activeSystems++;
    });
    systemControls['lights'].forEach((key, value) {
      if (value['state'] == 'ON') activeSystems++;
    });
    if (systemControls['climate']['airCondition']['state'] == 'ON') activeSystems++;
    if (systemControls['phControl']['phUp']['state'] == 'ON') activeSystems++;
    if (systemControls['phControl']['phDown']['state'] == 'ON') activeSystems++;
    
    final totalSystems = 9; // 3 pumps + 3 lights + 1 AC + 2 pH relays
    
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 3.5,
      children: [
        _buildStatCard(
          title: 'Avg Temperature',
          value: '${avgTemp.toStringAsFixed(1)}°C',
          change: '+0.5°C',
          isPositive: true,
          icon: Icons.thermostat_rounded,
          color: AppColors.warning,
        ),
        _buildStatCard(
          title: 'Humidity',
          value: '${sensorData['humidity']['value']}%',
          change: '+${sensorData['humidity']['change']}%',
          isPositive: sensorData['humidity']['trend'] == 'up',
          icon: Icons.water_drop_rounded,
          color: AppColors.info,
        ),
        _buildStatCard(
          title: 'Power',
          value: '${(powerData['grid']['power'] / 1000).toStringAsFixed(1)}kW',
          change: '+15%',
          isPositive: false, // Higher power is not always good
          icon: Icons.bolt_rounded,
          color: AppColors.error,
        ),
        _buildStatCard(
          title: 'Active Systems',
          value: '$activeSystems/$totalSystems',
          change: '+2',
          isPositive: true,
          icon: Icons.settings_rounded,
          color: AppColors.success,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String change,
    required bool isPositive,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      color: color.withOpacity(0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: () {
          // Handle stat card tap
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon with colored background
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(isDark ? 0.15 : 0.9),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 18,
                ),
              ),
              
              const SizedBox(width: AppSpacing.sm),
              
              // Title and Value
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: AppTypography.bodySmall.copyWith(
                          color: color.withOpacity(0.8),
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value,
                          style: AppTypography.h6.copyWith(
                            fontWeight: FontWeight.bold,
                            color: color,
                            letterSpacing: -0.5,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: AppSpacing.xs),
              
              // Trend Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(isDark ? 0.15 : 0.9),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 9,
                      color: isPositive ? AppColors.success : AppColors.error,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      change,
                      style: AppTypography.caption.copyWith(
                        color: isPositive ? AppColors.success : AppColors.error,
                        fontWeight: FontWeight.w700,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartsSection(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _buildRevenueChart(isDark),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildFarmDistributionChart(isDark),
              ),
            ],
          );
        } else {
          return Column(
            children: [
              _buildRevenueChart(isDark),
              const SizedBox(height: AppSpacing.md),
              _buildFarmDistributionChart(isDark),
            ],
          );
        }
      },
    );
  }

  Widget _buildRevenueChart(bool isDark) {
    return Card(
      elevation: 0,
      color: isDark ? AppColors.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Revenue Overview',
              style: AppTypography.h6.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 10,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.08),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '\$${value.toInt()}K',
                            style: AppTypography.caption.copyWith(
                              color: isDark
                                  ? Colors.white.withOpacity(0.5)
                                  : AppColors.textSecondary,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                          if (value.toInt() >= 0 && value.toInt() < months.length) {
                            return Text(
                              months[value.toInt()],
                              style: AppTypography.caption.copyWith(
                                color: isDark
                                    ? Colors.white.withOpacity(0.5)
                                    : AppColors.textSecondary,
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 30),
                        FlSpot(1, 35),
                        FlSpot(2, 32),
                        FlSpot(3, 42),
                        FlSpot(4, 38),
                        FlSpot(5, 48),
                      ],
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primary.withOpacity(0.1),
                      ),
                    ),
                  ],
                  minY: 0,
                  maxY: 60,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFarmDistributionChart(bool isDark) {
    return Card(
      elevation: 0,
      color: isDark ? AppColors.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Farm Distribution',
              style: AppTypography.h6.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 60,
                  sections: [
                    PieChartSectionData(
                      value: 40,
                      title: '40%',
                      color: AppColors.chartBlue,
                      radius: 50,
                      titleStyle: AppTypography.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    PieChartSectionData(
                      value: 30,
                      title: '30%',
                      color: AppColors.chartGreen,
                      radius: 50,
                      titleStyle: AppTypography.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    PieChartSectionData(
                      value: 20,
                      title: '20%',
                      color: AppColors.chartOrange,
                      radius: 50,
                      titleStyle: AppTypography.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    PieChartSectionData(
                      value: 10,
                      title: '10%',
                      color: AppColors.chartPurple,
                      radius: 50,
                      titleStyle: AppTypography.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildLegend(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(bool isDark) {
    final items = [
      ('Vegetables', AppColors.chartBlue),
      ('Fruits', AppColors.chartGreen),
      ('Grains', AppColors.chartOrange),
      ('Others', AppColors.chartPurple),
    ];

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: items.map((item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: item.$2,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              item.$1,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildRecentActivities(bool isDark) {
    final activities = [
      {
        'title': 'New batch started',
        'subtitle': 'Farm A - Batch #FA-20251026',
        'time': '2 hours ago',
        'icon': Icons.add_circle_outline,
        'color': AppColors.success,
      },
      {
        'title': 'Harvest completed',
        'subtitle': 'Farm B - 2,500 kg harvested',
        'time': '5 hours ago',
        'icon': Icons.check_circle_outline,
        'color': AppColors.primary,
      },
      {
        'title': 'Sensor alert',
        'subtitle': 'Temperature spike detected',
        'time': '1 day ago',
        'icon': Icons.warning_amber_rounded,
        'color': AppColors.warning,
      },
      {
        'title': 'New user added',
        'subtitle': 'John Doe - Caretaker',
        'time': '2 days ago',
        'icon': Icons.person_add_outlined,
        'color': AppColors.info,
      },
    ];

    return Card(
      elevation: 0,
      color: isDark ? AppColors.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activities',
                  style: AppTypography.h6.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ...activities.map((activity) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: (activity['color'] as Color).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Icon(
                        activity['icon'] as IconData,
                        color: activity['color'] as Color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity['title'] as String,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            activity['subtitle'] as String,
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark
                                  ? Colors.white.withOpacity(0.6)
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      activity['time'] as String,
                      style: AppTypography.caption.copyWith(
                        color: isDark
                            ? Colors.white.withOpacity(0.5)
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(bool isDark) {
    final navItems = [
      {'icon': Icons.dashboard_outlined, 'label': 'Dashboard', 'index': 0},
      {'icon': Icons.people_outline, 'label': 'Users', 'index': 1},
      {'icon': Icons.agriculture_outlined, 'label': 'Farms', 'index': 2},
      {'icon': Icons.sensors_outlined, 'label': 'Sensors', 'index': 3},
      {'icon': Icons.settings_outlined, 'label': 'Settings', 'index': 4},
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
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.08),
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
              final isSelected = index == _selectedNavIndex;

              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() => _selectedNavIndex = index);
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item['icon'] as IconData,
                          size: 24,
                          color: isSelected
                              ? AppColors.primary
                              : (isDark
                                  ? Colors.white.withOpacity(0.5)
                                  : AppColors.textSecondary),
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
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
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

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications'),
        content: const Text('You have 3 new notifications.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showProfileMenu() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Profile - $_adminName'),
        content: const Text('Profile settings and preferences.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
