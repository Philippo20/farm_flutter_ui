import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/farm_owner_sidebar.dart';
import '../../core/widgets/farm_owner_header.dart';
import '../../core/widgets/farm_owner_mobile_drawer.dart';
import '../../providers/auth_provider.dart';

/// Farm Overview for Farm Owner
/// Monitoring, issues, assigned team, and batch progress
class FarmOverviewScreen extends ConsumerStatefulWidget {
  const FarmOverviewScreen({super.key});

  @override
  ConsumerState<FarmOverviewScreen> createState() => _FarmOverviewScreenState();
}

class _FarmOverviewScreenState extends ConsumerState<FarmOverviewScreen> {
  int _selectedNavIndex = 1;
  int _selectedTab = 0;
  String _selectedReadingDateFilter = 'Today';
  String _selectedReadingTimeFilter = '24H';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final _issues = [
    {'title': 'Drip line leakage', 'status': 'In Progress', 'area': 'Block B', 'reported': '2 days ago'},
    {'title': 'Pest control delayed', 'status': 'Working on it', 'area': 'Nursery', 'reported': '1 day ago'},
    {'title': 'Cold storage fault', 'status': 'Damaged', 'area': 'Packhouse', 'reported': 'Today'},
    {'title': 'Irrigation sensor fix', 'status': 'Solved', 'area': 'Block A', 'reported': 'Yesterday'},
  ];

  final _batches = [
    {'id': 'BCH-204', 'crop': 'Tomatoes', 'progress': 78, 'stage': 'Harvest', 'eta': '3 days', 'status': 'On track'},
    {'id': 'BCH-205', 'crop': 'Onions', 'progress': 42, 'stage': 'Growth', 'eta': '2 weeks', 'status': 'On track'},
    {'id': 'BCH-206', 'crop': 'Peppers', 'progress': 28, 'stage': 'Transplant', 'eta': '3 weeks', 'status': 'At risk'},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'Farm Owner';
    final userEmail = authState.user?.email ?? 'owner@farmestates.com';
    final userRole = 'Farm Owner';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      drawer: isMobile
          ? FarmOwnerMobileDrawer(
              selectedIndex: _selectedNavIndex,
              onItemSelected: (i) => setState(() => _selectedNavIndex = i),
              userName: userName,
            )
          : null,
      body: isMobile
          ? _buildMobileLayout(isDark, userName)
          : _buildDesktopLayout(isDark, userName, userEmail, userRole),
      bottomNavigationBar: isMobile ? _buildBottomNavigation(isDark) : null,
    );
  }

  Widget _buildDesktopLayout(bool isDark, String userName, String userEmail, String userRole) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth < 1200 && screenWidth >= 600;

    return Row(
      children: [
        FarmOwnerSidebar(
          selectedIndex: _selectedNavIndex,
          onItemSelected: (index) => setState(() => _selectedNavIndex = index),
          userName: userName,
          userEmail: userEmail,
          userRole: userRole,
        ),
        Expanded(
          child: Column(
            children: [
              FarmOwnerHeader(
                userName: userName,
                onNotificationTap: () {},
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isTablet ? AppSpacing.md : AppSpacing.lg),
                  child: _buildContent(isDark, isTablet),
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
        FarmOwnerHeader(
          userName: userName,
          onNotificationTap: () {},
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: _buildContent(isDark, true),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(bool isDark, bool isTabletOrMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(isDark),
        SizedBox(height: isTabletOrMobile ? AppSpacing.md : AppSpacing.lg),
        _buildMonitoringCards(isDark),
        SizedBox(height: isTabletOrMobile ? AppSpacing.md : AppSpacing.lg),
        _buildTabBar(isDark),
        SizedBox(height: isTabletOrMobile ? AppSpacing.md : AppSpacing.lg),
        if (_selectedTab == 0) ...[
          _buildAssignments(isDark, isTabletOrMobile),
          SizedBox(height: isTabletOrMobile ? AppSpacing.md : AppSpacing.lg),
          _buildTechnicalIssues(isDark, isTabletOrMobile),
          SizedBox(height: isTabletOrMobile ? AppSpacing.md : AppSpacing.lg),
          _buildBatches(isDark, isTabletOrMobile),
        ] else ...[
          _buildIotDashboard(isDark, isTabletOrMobile),
        ],
      ],
    );
  }

  Widget _buildHeader(bool isDark) {
    return Text(
      'Farm Overview',
      style: AppTypography.h4.copyWith(
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : AppColors.textPrimary,
      ),
    );
  }

  Widget _buildMonitoringCards(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth < 1200 && screenWidth >= 600;

    final metrics = [
      {'title': 'Current Yield', 'value': '850 kg', 'change': '+12%', 'icon': Icons.inventory, 'color': AppColors.success},
      {'title': 'Soil Moisture', 'value': '68%', 'change': 'Stable', 'icon': Icons.water_drop, 'color': AppColors.info},
      {'title': 'Quality Grade', 'value': 'A', 'change': '+1', 'icon': Icons.verified, 'color': AppColors.primary},
      {'title': 'Irrigation', 'value': 'Active', 'change': 'OK', 'icon': Icons.sensors, 'color': AppColors.warning},
    ];

    final crossAxisCount = isMobile ? 2 : (isTablet ? 2 : 4);
    final childAspectRatio = isMobile ? 1.25 : (isTablet ? 1.6 : 1.8);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      childAspectRatio: childAspectRatio,
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      children: metrics.map((metric) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (metric['color'] as Color).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      metric['icon'] as IconData,
                      size: 18,
                      color: metric['color'] as Color,
                    ),
                  ),
                  Text(
                    metric['change'] as String,
                    style: AppTypography.caption.copyWith(
                      color: isDark ? Colors.white60 : AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                metric['value'] as String,
                style: AppTypography.h5.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                metric['title'] as String,
                style: AppTypography.caption.copyWith(
                  color: isDark ? Colors.white60 : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTabBar(bool isDark) {
    final tabs = ['Overview', 'IoT Dashboard'];
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : AppColors.neutral100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _selectedTab == index;
          return Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedTab = index),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? Colors.white.withOpacity(0.12) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    tabs[index],
                    style: AppTypography.bodyMedium.copyWith(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? Colors.white70 : AppColors.textSecondary),
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildIotDashboard(bool isDark, bool isTabletOrMobile) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    final sensors = [
      {
        'category': 'Water & Nutrients',
        'label': 'EC (mS/cm)',
        'value': '2.4 mS/cm',
        'status': 'Stable',
        'icon': Icons.science,
        'color': AppColors.info,
        'percent': 0.62,
        'trend': [2.0, 2.2, 2.3, 2.4, 2.35, 2.4],
        'unit': 'mS/cm',
      },
      {
        'category': 'Water & Nutrients',
        'label': 'pH',
        'value': '6.2',
        'status': 'Optimal',
        'icon': Icons.opacity,
        'color': AppColors.success,
        'percent': 0.7,
        'trend': [6.0, 6.1, 6.2, 6.15, 6.2, 6.2],
        'unit': '',
      },
      {
        'category': 'Room Temp/Humidity',
        'label': 'Temp (°C)',
        'value': '24.6 °C',
        'status': 'OK',
        'icon': Icons.thermostat,
        'color': AppColors.warning,
        'percent': 0.55,
        'trend': [23.8, 24.2, 24.6, 24.1, 24.6, 24.6],
        'unit': 'C',
      },
      {
        'category': 'Room Temp/Humidity',
        'label': 'Humidity (%)',
        'value': '62%',
        'status': 'OK',
        'icon': Icons.water,
        'color': AppColors.primary,
        'percent': 0.62,
        'trend': [58, 60, 61, 62, 63, 62],
        'unit': '%',
      },
      {
        'category': 'Air Quality',
        'label': 'Air Quality',
        'value': 'Good',
        'status': 'Good',
        'icon': Icons.air,
        'color': AppColors.success,
        'percent': 0.8,
        'trend': [72, 78, 80, 82, 79, 80],
        'unit': '',
      },
      {
        'category': 'Air Quality',
        'label': 'CO2 (ppm)',
        'value': '540 ppm',
        'status': 'Normal',
        'icon': Icons.cloud,
        'color': AppColors.info,
        'percent': 0.54,
        'trend': [520, 530, 540, 550, 535, 540],
        'unit': 'ppm',
      },
      {
        'category': 'Water & Nutrients',
        'label': 'Light (lx)',
        'value': '780 lx',
        'status': 'Optimal',
        'icon': Icons.light_mode,
        'color': AppColors.warning,
        'percent': 0.78,
        'trend': [720, 740, 760, 780, 790, 780],
        'unit': 'lx',
      },
      {
        'category': 'Water & Nutrients',
        'label': 'Water Level (%)',
        'value': '78%',
        'status': 'Normal',
        'icon': Icons.water_drop,
        'color': AppColors.primary,
        'percent': 0.78,
        'trend': [70, 74, 76, 78, 80, 78],
        'unit': '%',
      },
      {
        'category': 'Energy',
        'label': 'Energy (kWh)',
        'value': '42.5 kWh',
        'status': 'Normal',
        'icon': Icons.bolt,
        'color': AppColors.warning,
        'percent': 0.64,
        'trend': [36.2, 38.8, 40.1, 41.9, 43.3, 42.5],
        'unit': 'kWh',
      },
      {
        'category': 'Energy',
        'label': 'Voltage (V)',
        'value': '228 V',
        'status': 'Stable',
        'icon': Icons.electric_bolt,
        'color': AppColors.info,
        'percent': 0.76,
        'trend': [221, 223, 226, 228, 229, 228],
        'unit': 'V',
      },
      {
        'category': 'Energy',
        'label': 'Current (A)',
        'value': '12.4 A',
        'status': 'Normal',
        'icon': Icons.bolt,
        'color': AppColors.primary,
        'percent': 0.58,
        'trend': [10.8, 11.3, 11.9, 12.1, 12.6, 12.4],
        'unit': 'A',
      },
    ];

    const categoryOrder = [
      'Air Quality',
      'Room Temp/Humidity',
      'Water & Nutrients',
      'Energy',
    ];
    final categorySensorsCrossAxisCount = isMobile ? 1 : 2;
    final categorySensorsAspectRatio = isMobile ? 1.95 : 1.4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'IoT Dashboard',
              style: AppTypography.h6.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Live',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: isTabletOrMobile ? AppSpacing.md : AppSpacing.lg),
        if (isMobile)
          ...categoryOrder.map((category) {
            final categorySensors = sensors
                .where((sensor) => sensor['category'] == category)
                .toList();
            if (categorySensors.isEmpty) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: _buildIotCategorySection(
                isDark: isDark,
                title: category,
                sensors: categorySensors,
                crossAxisCount: categorySensorsCrossAxisCount,
                childAspectRatio: categorySensorsAspectRatio,
                isMobile: isMobile,
              ),
            );
          })
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final sectionWidth = (constraints.maxWidth - AppSpacing.md) / 2;
              return Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: categoryOrder.map((category) {
                  final categorySensors = sensors
                      .where((sensor) => sensor['category'] == category)
                      .toList();
                  if (categorySensors.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return SizedBox(
                    width: sectionWidth,
                    child: _buildIotCategorySection(
                      isDark: isDark,
                      title: category,
                      sensors: categorySensors,
                      crossAxisCount: categorySensorsCrossAxisCount,
                      childAspectRatio: categorySensorsAspectRatio,
                      isMobile: isMobile,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        SizedBox(height: isTabletOrMobile ? AppSpacing.md : AppSpacing.lg),
        _buildDetailedSensorReadingsSection(
          isDark: isDark,
          sensors: sensors,
          isMobile: isMobile,
        ),
      ],
    );
  }

  Widget _buildDetailedSensorReadingsSection({
    required bool isDark,
    required List<Map<String, dynamic>> sensors,
    required bool isMobile,
  }) {
    final now = DateTime.now();
    final updatedAt = _formatReadingTimestamp(now);
    final crossAxisCount = isMobile ? 1 : 2;
    final chartCardAspectRatio = isMobile ? 1.55 : 1.68;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detailed Sensor Readings',
            style: AppTypography.h6.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Updated $updatedAt',
            style: AppTypography.caption.copyWith(
              color: isDark ? Colors.white60 : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['Today', 'Yesterday', 'Last 7 Days'].map((filter) {
              final isSelected = _selectedReadingDateFilter == filter;
              return _buildReadingFilterChip(
                label: filter,
                isSelected: isSelected,
                isDark: isDark,
                onTap: () => setState(() => _selectedReadingDateFilter = filter),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['1H', '6H', '24H', '7D'].map((filter) {
              final isSelected = _selectedReadingTimeFilter == filter;
              return _buildReadingFilterChip(
                label: filter,
                isSelected: isSelected,
                isDark: isDark,
                onTap: () => setState(() => _selectedReadingTimeFilter = filter),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: crossAxisCount,
            childAspectRatio: chartCardAspectRatio,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            children: sensors.map((sensor) {
              final trend = (sensor['trend'] as List).map((e) => (e as num).toDouble()).toList();
              final filteredTrend = _pointsForTimeFilter(trend, _selectedReadingTimeFilter);
              final statusInfo = _resolveSensorStatus(
                sensor['label'] as String,
                sensor['percent'] as double,
              );

              return Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: sensor['color'] as Color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            sensor['label'] as String,
                            style: AppTypography.bodyMedium.copyWith(
                              color: isDark ? Colors.white : AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          sensor['value'] as String,
                          style: AppTypography.bodyMedium.copyWith(
                            color: isDark ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statusInfo.label,
                      style: AppTypography.caption.copyWith(
                        color: statusInfo.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _buildRealtimeChart(
                        isDark,
                        filteredTrend,
                        sensor['color'] as Color,
                        unit: sensor['unit'] as String,
                        height: null,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingFilterChip({
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.12)
              : (isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withOpacity(0.5)
                : (isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: isSelected
                ? AppColors.primary
                : (isDark ? Colors.white70 : AppColors.textSecondary),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  List<double> _pointsForTimeFilter(List<double> points, String filter) {
    if (points.length <= 2) return points;
    switch (filter) {
      case '1H':
        return points.skip(points.length > 3 ? points.length - 3 : 0).toList();
      case '6H':
        return points.skip(points.length > 4 ? points.length - 4 : 0).toList();
      case '24H':
        return points;
      case '7D':
        return points;
      default:
        return points;
    }
  }

  String _formatReadingTimestamp(DateTime timestamp) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '${months[timestamp.month - 1]} ${timestamp.day}, ${timestamp.year} • $hour:$minute';
  }

  Widget _buildIotCategorySection({
    required bool isDark,
    required String title,
    required List<Map<String, dynamic>> sensors,
    required int crossAxisCount,
    required double childAspectRatio,
    required bool isMobile,
  }) {
    final voltageSensor = sensors.cast<Map<String, dynamic>?>().firstWhere(
          (sensor) => sensor?['label'] == 'Voltage (V)',
          orElse: () => null,
        );
    final currentSensor = sensors.cast<Map<String, dynamic>?>().firstWhere(
          (sensor) => sensor?['label'] == 'Current (A)',
          orElse: () => null,
        );

    final normalSensors = sensors
        .where((sensor) =>
            sensor['label'] != 'Voltage (V)' && sensor['label'] != 'Current (A)')
        .toList();

    final sensorCards = <Widget>[
      ...normalSensors.map((sensor) => _buildIotSensorCard(isDark, sensor, isMobile)),
      if (voltageSensor != null && currentSensor != null)
        _buildDoubleReadingCard(
          isDark: isDark,
          voltageSensor: voltageSensor,
          currentSensor: currentSensor,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${sensors.length}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          children: sensorCards,
        ),
      ],
    );
  }

  Widget _buildIotSensorCard(
    bool isDark,
    Map<String, dynamic> sensor,
    bool isMobile,
  ) {
    final statusInfo = _resolveSensorStatus(
      sensor['label'] as String,
      sensor['percent'] as double,
    );

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (sensor['color'] as Color).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        sensor['icon'] as IconData,
                        size: 18,
                        color: sensor['color'] as Color,
                      ),
                    ),
                    _buildMiniGauge(
                      isDark,
                      sensor['percent'] as double,
                      statusInfo.color,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  sensor['value'] as String,
                  style: AppTypography.h5.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  sensor['label'] as String,
                  style: AppTypography.caption.copyWith(
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusInfo.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        statusInfo.label,
                        style: AppTypography.caption.copyWith(
                          color: isDark ? Colors.white60 : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (statusInfo.isAlert) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusInfo.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Alert',
                          style: AppTypography.caption.copyWith(
                            color: statusInfo.color,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(16),
            ),
                    child: SizedBox(
                      height: isMobile ? 60 : 48,
                      width: double.infinity,
                      child: _buildRealtimeChart(
                isDark,
                (sensor['trend'] as List).map((e) => (e as num).toDouble()).toList(),
                sensor['color'] as Color,
                unit: sensor['unit'] as String,
                height: null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoubleReadingCard({
    required bool isDark,
    required Map<String, dynamic> voltageSensor,
    required Map<String, dynamic> currentSensor,
  }) {
    final voltageStatus = _resolveSensorStatus(
      voltageSensor['label'] as String,
      voltageSensor['percent'] as double,
    );
    final currentStatus = _resolveSensorStatus(
      currentSensor['label'] as String,
      currentSensor['percent'] as double,
    );

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.electric_bolt, size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 8),
                Text(
                  'Electrical Double Reading',
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildDualMetricChip(
                    isDark: isDark,
                    color: voltageSensor['color'] as Color,
                    label: voltageSensor['label'] as String,
                    value: voltageSensor['value'] as String,
                    status: voltageStatus,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDualMetricChip(
                    isDark: isDark,
                    color: currentSensor['color'] as Color,
                    label: currentSensor['label'] as String,
                    value: currentSensor['value'] as String,
                    status: currentStatus,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 52,
              width: double.infinity,
              child: _buildDualRealtimeChart(
                isDark,
                voltageSensor,
                currentSensor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDualMetricChip({
    required bool isDark,
    required Color color,
    required String label,
    required String value,
    required _SensorStatus status,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: AppTypography.caption.copyWith(
                color: isDark ? Colors.white60 : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: status.color, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }

  Widget _buildDualRealtimeChart(
    bool isDark,
    Map<String, dynamic> voltageSensor,
    Map<String, dynamic> currentSensor,
  ) {
    final voltageRaw =
        (voltageSensor['trend'] as List).map((e) => (e as num).toDouble()).toList();
    final currentRaw =
        (currentSensor['trend'] as List).map((e) => (e as num).toDouble()).toList();
    if (voltageRaw.isEmpty || currentRaw.isEmpty) return const SizedBox.shrink();

    final pointCount = voltageRaw.length < currentRaw.length
        ? voltageRaw.length
        : currentRaw.length;
    final voltageValues = voltageRaw.take(pointCount).toList();
    final currentValues = currentRaw.take(pointCount).toList();

    final vMin = voltageValues.reduce((a, b) => a < b ? a : b);
    final vMax = voltageValues.reduce((a, b) => a > b ? a : b);
    final iMin = currentValues.reduce((a, b) => a < b ? a : b);
    final iMax = currentValues.reduce((a, b) => a > b ? a : b);
    final vRange = (vMax - vMin) == 0 ? 1.0 : (vMax - vMin);
    final iRange = (iMax - iMin) == 0 ? 1.0 : (iMax - iMin);

    final voltageNorm = voltageValues
        .asMap()
        .entries
        .map((entry) =>
            FlSpot(entry.key.toDouble(), ((entry.value - vMin) / vRange) * 100))
        .toList();
    final currentNorm = currentValues
        .asMap()
        .entries
        .map((entry) =>
            FlSpot(entry.key.toDouble(), ((entry.value - iMin) / iRange) * 100))
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (pointCount - 1).toDouble(),
          minY: -8,
          maxY: 108,
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              tooltipRoundedRadius: 6,
              tooltipPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              tooltipMargin: 6,
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipColor: (_) => isDark ? const Color(0xFF111827) : Colors.white,
              getTooltipItems: (spots) {
                return spots.map((spot) {
                  final idx = spot.x.toInt();
                  final isVoltage = (spot.barIndex == 0);
                  final value = isVoltage ? voltageValues[idx] : currentValues[idx];
                  final unit = isVoltage ? 'V' : 'A';
                  final label = isVoltage ? 'Voltage' : 'Current';
                  final c = isVoltage
                      ? (voltageSensor['color'] as Color)
                      : (currentSensor['color'] as Color);
                  return LineTooltipItem(
                    '$label: ${value.toStringAsFixed(1)} $unit',
                    AppTypography.caption.copyWith(
                      color: c,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              preventCurveOverShooting: true,
              color: voltageSensor['color'] as Color,
              barWidth: 2,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 2.4,
                  color: voltageSensor['color'] as Color,
                  strokeWidth: 1.3,
                  strokeColor: isDark ? AppColors.surfaceDark : Colors.white,
                ),
              ),
              belowBarData: BarAreaData(show: false),
              spots: voltageNorm,
            ),
            LineChartBarData(
              isCurved: true,
              preventCurveOverShooting: true,
              color: currentSensor['color'] as Color,
              barWidth: 2,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 2.4,
                  color: currentSensor['color'] as Color,
                  strokeWidth: 1.3,
                  strokeColor: isDark ? AppColors.surfaceDark : Colors.white,
                ),
              ),
              belowBarData: BarAreaData(show: false),
              spots: currentNorm,
            ),
          ],
        ),
      ),
    );
  }

  _SensorStatus _resolveSensorStatus(String label, double percent) {
    const thresholds = {
      'EC': {'min': 0.55, 'max': 0.8},
      'pH': {'min': 0.6, 'max': 0.85},
      'Temp': {'min': 0.5, 'max': 0.75},
      'Humidity': {'min': 0.55, 'max': 0.8},
      'Air Quality': {'min': 0.7, 'max': 0.9},
      'CO2': {'min': 0.5, 'max': 0.75},
      'Light': {'min': 0.6, 'max': 0.85},
      'Water Level': {'min': 0.6, 'max': 0.85},
    };

    final t = thresholds[label] ?? const {'min': 0.6, 'max': 0.85};
    final min = ((t['min'] as num?) ?? 0.6).toDouble();
    final max = ((t['max'] as num?) ?? 0.85).toDouble();
    if (percent < min) {
      return const _SensorStatus(label: 'Low', color: AppColors.warning, isAlert: true);
    }
    if (percent > max) {
      return const _SensorStatus(label: 'High', color: AppColors.warning, isAlert: true);
    }
    return const _SensorStatus(label: 'Optimal', color: AppColors.success, isAlert: false);
  }

  Widget _buildMiniGauge(bool isDark, double percent, Color color) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            value: percent.clamp(0.0, 1.0),
            strokeWidth: 4,
            backgroundColor: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        Text(
          '${(percent * 100).toStringAsFixed(0)}%',
          style: AppTypography.caption.copyWith(
            fontSize: 9,
            color: isDark ? Colors.white70 : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildRealtimeChart(
    bool isDark,
    List<double> points,
    Color color, {
    String unit = '',
    double? height = 40,
  }) {
    if (points.isEmpty) return const SizedBox.shrink();
    final min = points.reduce((a, b) => a < b ? a : b);
    final max = points.reduce((a, b) => a > b ? a : b);
    final range = (max - min) == 0 ? 1.0 : (max - min);
    final yPadding = range * 0.18;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: LineChart(
          LineChartData(
          minX: 0,
          maxX: points.length - 1,
          minY: min - yPadding,
          maxY: max + yPadding,
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              tooltipRoundedRadius: 6,
              tooltipPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              tooltipMargin: 6,
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipColor: (spot) =>
                  isDark ? const Color(0xFF111827) : Colors.white,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final value = spot.y.toStringAsFixed(2);
                  final suffix = unit.isNotEmpty ? ' $unit' : '';
                  return LineTooltipItem(
                    '$value$suffix',
                    AppTypography.caption.copyWith(
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              preventCurveOverShooting: true,
              color: color,
              barWidth: 2,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 2.5,
                  color: color,
                  strokeWidth: 1.5,
                  strokeColor: isDark ? AppColors.surfaceDark : Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: color.withOpacity(0.12),
              ),
              spots: points
                  .asMap()
                  .entries
                  .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
                  .toList(),
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssignments(bool isDark, bool isTabletOrMobile) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = isTabletOrMobile ? double.infinity : (constraints.maxWidth - AppSpacing.md) / 2;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            SizedBox(width: cardWidth, child: _buildAssigneeCard(isDark, 'Farm Manager', 'Amos Phiri', 'Since Aug 2023', '4.8')),
            SizedBox(width: cardWidth, child: _buildAssigneeCard(isDark, 'Caretaker', 'Lydia Tembo', 'Since Nov 2023', '4.6')),
          ],
        );
      },
    );
  }

  Widget _buildAssigneeCard(bool isDark, String title, String name, String since, String rating) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'F',
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.caption.copyWith(
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  since,
                  style: AppTypography.caption.copyWith(
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, size: 12, color: AppColors.success),
                const SizedBox(width: 4),
                Text(
                  rating,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicalIssues(bool isDark, bool isTabletOrMobile) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Technical Issues',
            style: AppTypography.h6.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ..._issues.map((issue) => _buildIssueRow(issue, isDark, isTabletOrMobile)),
        ],
      ),
    );
  }

  Widget _buildIssueRow(Map<String, dynamic> issue, bool isDark, bool isTabletOrMobile) {
    final status = issue['status'] as String;
    final statusColor = _statusColor(status);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.02) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issue['title'] as String,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${issue['area']} â€¢ ${issue['reported']}',
                  style: AppTypography.caption.copyWith(
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: AppTypography.caption.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatches(bool isDark, bool isTabletOrMobile) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Batch Progress',
            style: AppTypography.h6.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ..._batches.map((batch) => _buildBatchRow(batch, isDark)),
        ],
      ),
    );
  }

  Widget _buildBatchRow(Map<String, dynamic> batch, bool isDark) {
    final progress = batch['progress'] as int;
    final status = batch['status'] as String;
    final statusColor = status == 'At risk' ? AppColors.warning : AppColors.success;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.02) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${batch['id']} â€¢ ${batch['crop']}',
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                batch['stage'] as String,
                style: AppTypography.caption.copyWith(
                  color: isDark ? Colors.white60 : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress / 100,
              minHeight: 8,
              backgroundColor: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  'ETA: ${batch['eta']}',
                  style: AppTypography.caption.copyWith(
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: AppTypography.caption.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Solved':
        return AppColors.success;
      case 'In Progress':
        return AppColors.info;
      case 'Damaged':
        return AppColors.error;
      case 'Working on it':
      default:
        return AppColors.warning;
    }
  }

  Widget _buildBottomNavigation(bool isDark) {
    final navItems = [
      {'icon': Icons.dashboard_outlined, 'label': 'Dashboard', 'index': 0, 'route': '/farm-owner'},
      {'icon': Icons.agriculture_outlined, 'label': 'Farm', 'index': 1, 'route': '/farm-owner/farm'},
      {'icon': Icons.account_balance_wallet_outlined, 'label': 'Wallet', 'index': 2, 'route': '/farm-owner/digital-wallet'},
      {'icon': Icons.analytics_outlined, 'label': 'Analytics', 'index': 3, 'route': '/farm-owner/analytics'},
      {'icon': Icons.assessment_outlined, 'label': 'Reports', 'index': 4, 'route': '/farm-owner/reports'},
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
            children: navItems.take(5).map((item) {
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
}

class _MiniSparklinePainter extends CustomPainter {
  final List<double> points;
  final Color color;
  final double min;
  final double range;
  final bool isDark;

  _MiniSparklinePainter({
    required this.points,
    required this.color,
    required this.min,
    required this.range,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = isDark ? Colors.white12 : const Color(0xFFE2E8F0)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height - 1),
      Offset(size.width, size.height - 1),
      gridPaint,
    );

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = size.width * (i / (points.length - 1));
      final normalized = (points[i] - min) / range;
      final y = size.height - (normalized * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    final fillPaint = Paint()
      ..color = color.withOpacity(0.12)
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _MiniSparklinePainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.color != color ||
        oldDelegate.min != min ||
        oldDelegate.range != range ||
        oldDelegate.isDark != isDark;
  }
}

class _SensorStatus {
  final String label;
  final Color color;
  final bool isAlert;

  const _SensorStatus({
    required this.label,
    required this.color,
    required this.isAlert,
  });
}

