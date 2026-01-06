import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/colors.dart';
import '../../providers/dashboard_provider.dart';
import 'dart:math' as math;

class ModernAdminDashboardScreen extends ConsumerStatefulWidget {
  const ModernAdminDashboardScreen({super.key});

  @override
  ConsumerState<ModernAdminDashboardScreen> createState() =>
      _ModernAdminDashboardScreenState();
}

class _ModernAdminDashboardScreenState
    extends ConsumerState<ModernAdminDashboardScreen> {
  int _selectedNavIndex = 0;
  String _selectedPeriod = 'Today';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {},
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: AppColors.primary,
              ),
              child: Text(
                'Farm Estates',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text('Dashboard'),
              onTap: () {
                setState(() => _selectedNavIndex = 0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.people_outline),
              title: const Text('Users'),
              onTap: () {
                setState(() => _selectedNavIndex = 1);
                Navigator.pushReplacementNamed(context, '/users');
              },
            ),
            ListTile(
              leading: const Icon(Icons.agriculture_outlined),
              title: const Text('Farms'),
              onTap: () {
                setState(() => _selectedNavIndex = 2);
                Navigator.pushReplacementNamed(context, '/farms');
              },
            ),
            ListTile(
              leading: const Icon(Icons.sensors_outlined),
              title: const Text('Sensors'),
              onTap: () {
                setState(() => _selectedNavIndex = 3);
                Navigator.pushReplacementNamed(context, '/sensors');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () {
                setState(() => _selectedNavIndex = 4);
                Navigator.pushReplacementNamed(context, '/settings');
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            _buildWelcomeSection(colorScheme),

            const SizedBox(height: 24.0),

            // Period Filter
            _buildPeriodFilter(),

            const SizedBox(height: 24.0),

            // Stats Cards
            _buildStatsGrid(),

            const SizedBox(height: 24.0),

            // Charts Section
            _buildChartsSection(colorScheme),

            const SizedBox(height: 24.0),

            // Data Tables Section
            _buildDataTablesSection(colorScheme),

            const SizedBox(height: 24.0),

            // Recent Activities & Quick Actions
            _buildBottomSection(colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(ColorScheme colorScheme) {
    final hour = DateTime.now().hour;
    String greeting = 'Good Morning';
    if (hour >= 12 && hour < 17) {
      greeting = 'Good Afternoon';
    } else if (hour >= 17) {
      greeting = 'Good Evening';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4.0),
        Text(
          'Here\'s what\'s happening with your farms today',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withAlpha(153),
              ),
        ),
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
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(period),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedPeriod = period);
              },
              backgroundColor: Colors.transparent,
              selectedColor: AppColors.primary.withAlpha(25),
              checkmarkColor: AppColors.primary,
              labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isSelected ? AppColors.primary : null,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = ref.watch(dashboardStatsProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1200
            ? 4
            : constraints.maxWidth > 800
                ? 3
                : constraints.maxWidth > 500
                    ? 2
                    : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12.0,
            crossAxisSpacing: 12.0,
            childAspectRatio: 1.5,
          ),
          itemCount: stats.length,
          itemBuilder: (context, index) {
            final stat = stats[index];
            return _buildStatCard(
              title: stat.title,
              value: stat.value,
              change: stat.change,
              isPositive: stat.isPositive,
              icon: stat.icon,
              color: stat.color,
            );
          },
        );
      },
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
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withAlpha(128),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          // Add navigation or action here
        },
        borderRadius: BorderRadius.circular(16.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withAlpha(8),
                color.withAlpha(2),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Icon with gradient background
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            color.withAlpha(51),
                            color.withAlpha(25),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12.0),
                        boxShadow: [
                          BoxShadow(
                            color: color.withAlpha(51),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    // Trend indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      decoration: BoxDecoration(
                        color: (isPositive ? AppColors.secondary : AppColors.danger)
                            .withAlpha(38),
                        borderRadius: BorderRadius.circular(24.0),
                        border: Border.all(
                          color: (isPositive ? AppColors.secondary : AppColors.danger)
                              .withAlpha(77),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPositive
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded,
                            size: 14,
                            color: isPositive ? AppColors.secondary : AppColors.danger,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            change,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: isPositive
                                      ? AppColors.secondary
                                      : AppColors.danger,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Value with gradient text effect
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      color,
                      color.withAlpha(178),
                    ],
                  ).createShader(bounds),
                  child: Text(
                    value,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                  ),
                ),
                const SizedBox(height: 4.0),
                // Title with better contrast
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(178),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                ),
                const SizedBox(height: 4.0),
                // Progress indicator
                ClipRRect(
                  borderRadius: BorderRadius.circular(24.0),
                  child: LinearProgressIndicator(
                    value: isPositive ? 0.75 : 0.45,
                    backgroundColor: color.withAlpha(25),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChartsSection(ColorScheme colorScheme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _buildRevenueChart(colorScheme),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: _buildFarmDistributionChart(colorScheme),
              ),
            ],
          );
        } else {
          return Column(
            children: [
              _buildRevenueChart(colorScheme),
              const SizedBox(height: 12.0),
              _buildFarmDistributionChart(colorScheme),
            ],
          );
        }
      },
    );
  }

  Widget _buildRevenueChart(ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Revenue Overview',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12.0),
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
                        color: colorScheme.outline.withAlpha(25),
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
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface.withAlpha(128),
                                ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const months = [
                            'Jan',
                            'Feb',
                            'Mar',
                            'Apr',
                            'May',
                            'Jun'
                          ];
                          if (value.toInt() >= 0 &&
                              value.toInt() < months.length) {
                            return Text(
                              months[value.toInt()],
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurface.withAlpha(128),
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
                        color: AppColors.primary.withAlpha(25),
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

  Widget _buildFarmDistributionChart(ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Farm Distribution',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12.0),
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
                      color: AppColors.primary,
                      radius: 50,
                      titleStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    PieChartSectionData(
                      value: 30,
                      title: '30%',
                      color: AppColors.secondary,
                      radius: 50,
                      titleStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    PieChartSectionData(
                      value: 20,
                      title: '20%',
                      color: AppColors.warning,
                      radius: 50,
                      titleStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    PieChartSectionData(
                      value: 10,
                      title: '10%',
                      color: AppColors.danger,
                      radius: 50,
                      titleStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12.0),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    final items = [
      ('Vegetables', AppColors.primary),
      ('Fruits', AppColors.secondary),
      ('Grains', AppColors.warning),
      ('Others', AppColors.danger),
    ];

    return Wrap(
      spacing: 12.0,
      runSpacing: 8.0,
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
            const SizedBox(width: 4.0),
            Text(
              item.$1,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildBottomSection(ColorScheme colorScheme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _buildRecentActivities(colorScheme),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: _buildQuickActions(colorScheme),
              ),
            ],
          );
        } else {
          return Column(
            children: [
              _buildRecentActivities(colorScheme),
              const SizedBox(height: 12.0),
              _buildQuickActions(colorScheme),
            ],
          );
        }
      },
    );
  }

  Widget _buildRecentActivities(ColorScheme colorScheme) {
    final activities = [
      {
        'title': 'New batch started',
        'subtitle': 'Farm A - Batch #FA-20251026',
        'time': '2 hours ago',
        'icon': Icons.add_circle_outline,
        'color': AppColors.secondary,
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
        'color': AppColors.primary,
      },
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activities',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            ...activities.map((activity) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: (activity['color'] as Color).withAlpha(25),
                        borderRadius:
                            BorderRadius.circular(12.0),
                      ),
                      child: Icon(
                        activity['icon'] as IconData,
                        color: activity['color'] as Color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity['title'] as String,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          Text(
                            activity['subtitle'] as String,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface.withAlpha(153),
                                ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      activity['time'] as String,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withAlpha(128),
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

  Widget _buildDataTablesSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Farm Performance',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12.0),
        _buildFarmsTable(colorScheme),
        const SizedBox(height: 24.0),
        Text(
          'Active Users',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12.0),
        _buildUsersTable(colorScheme),
      ],
    );
  }

  Widget _buildFarmsTable(ColorScheme colorScheme) {
    final farms = [
      {
        'name': 'Greenhouse A',
        'manager': 'John Smith',
        'location': 'Nairobi, Kenya',
        'health': 85,
        'yield': 72,
        'sensors': 18,
        'issues': 3,
        'status': 'Active',
      },
      {
        'name': 'Field B',
        'manager': 'Sarah Johnson',
        'location': 'Kampala, Uganda',
        'health': 78,
        'yield': 65,
        'sensors': 22,
        'issues': 5,
        'status': 'Active',
      },
      {
        'name': 'Hydroponic C',
        'manager': 'David Kimani',
        'location': 'Arusha, Tanzania',
        'health': 92,
        'yield': 88,
        'sensors': 15,
        'issues': 1,
        'status': 'Active',
      },
      {
        'name': 'Greenhouse D',
        'manager': 'Grace Omondi',
        'location': 'Mombasa, Kenya',
        'health': 81,
        'yield': 75,
        'sensors': 19,
        'issues': 2,
        'status': 'Active',
      },
      {
        'name': 'Field E',
        'manager': 'Robert Mugabe',
        'location': 'Harare, Zimbabwe',
        'health': 76,
        'yield': 68,
        'sensors': 24,
        'issues': 6,
        'status': 'Warning',
      },
    ];

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            colorScheme.surfaceContainerHighest.withAlpha(77),
          ),
          columns: [
            DataColumn(
              label: Text(
                'Farm Name',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            DataColumn(
              label: Text(
                'Manager',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            DataColumn(
              label: Text(
                'Location',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            DataColumn(
              label: Text(
                'Health %',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              numeric: true,
            ),
            DataColumn(
              label: Text(
                'Yield %',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              numeric: true,
            ),
            DataColumn(
              label: Text(
                'Sensors',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              numeric: true,
            ),
            DataColumn(
              label: Text(
                'Issues',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              numeric: true,
            ),
            DataColumn(
              label: Text(
                'Status',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            DataColumn(
              label: Text(
                'Actions',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ],
          rows: farms.map((farm) {
            final health = farm['health'] as int;
            final healthColor = health >= 80
                ? AppColors.secondary
                : health >= 60
                    ? AppColors.warning
                    : AppColors.danger;

            return DataRow(
              cells: [
                DataCell(
                  Row(
                    children: [
                      const Icon(
                        Icons.agriculture_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4.0),
                      Text(
                        farm['name'] as String,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
                DataCell(Text(
                  farm['manager'] as String,
                  style: Theme.of(context).textTheme.bodyMedium,
                )),
                DataCell(Text(
                  farm['location'] as String,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withAlpha(153),
                      ),
                )),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: healthColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      '${farm['health']}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: healthColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ),
                DataCell(Text(
                  '${farm['yield']}%',
                  style: Theme.of(context).textTheme.bodyMedium,
                )),
                DataCell(Text(
                  '${farm['sensors']}',
                  style: Theme.of(context).textTheme.bodyMedium,
                )),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: (farm['issues'] as int) > 3
                          ? AppColors.danger.withAlpha(25)
                          : AppColors.secondary.withAlpha(25),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      '${farm['issues']}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: (farm['issues'] as int) > 3
                                ? AppColors.danger
                                : AppColors.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ),
                DataCell(
                  Chip(
                    label: Text(
                      farm['status'] as String,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: farm['status'] == 'Active'
                                ? AppColors.secondary
                                : AppColors.warning,
                          ),
                    ),
                    backgroundColor: (farm['status'] == 'Active'
                            ? AppColors.secondary
                            : AppColors.warning)
                        .withAlpha(25),
                    side: BorderSide.none,
                    padding: EdgeInsets.zero,
                  ),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility_outlined, size: 18),
                        onPressed: () {},
                        tooltip: 'View Details',
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: () {},
                        tooltip: 'Edit',
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildUsersTable(ColorScheme colorScheme) {
    final users = [
      {
        'name': 'John Smith',
        'email': 'john@farmestates.com',
        'role': 'Admin',
        'status': 'Active',
        'lastActive': '2 hours ago',
      },
      {
        'name': 'Sarah Johnson',
        'email': 'sarah@farmestates.com',
        'role': 'Manager',
        'status': 'Active',
        'lastActive': '5 hours ago',
      },
      {
        'name': 'David Kimani',
        'email': 'david@farmestates.com',
        'role': 'Caretaker',
        'status': 'Active',
        'lastActive': '1 hour ago',
      },
      {
        'name': 'Grace Omondi',
        'email': 'grace@farmestates.com',
        'role': 'Viewer',
        'status': 'Active',
        'lastActive': '30 mins ago',
      },
      {
        'name': 'Michael Brown',
        'email': 'michael@farmestates.com',
        'role': 'Technician',
        'status': 'Inactive',
        'lastActive': '2 days ago',
      },
    ];

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            colorScheme.surfaceContainerHighest.withAlpha(77),
          ),
          columns: [
            DataColumn(
              label: Text(
                'Name',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            DataColumn(
              label: Text(
                'Email',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            DataColumn(
              label: Text(
                'Role',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            DataColumn(
              label: Text(
                'Status',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            DataColumn(
              label: Text(
                'Last Active',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            DataColumn(
              label: Text(
                'Actions',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ],
          rows: users.map((user) {
            final roleColor = user['role'] == 'Admin'
                ? AppColors.danger
                : user['role'] == 'Manager'
                    ? AppColors.primary
                    : AppColors.primary;

            return DataRow(
              cells: [
                DataCell(
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: roleColor.withAlpha(25),
                        child: Text(
                          (user['name'] as String)[0],
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: roleColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        user['name'] as String,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
                DataCell(Text(
                  user['email'] as String,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withAlpha(153),
                      ),
                )),
                DataCell(
                  Chip(
                    label: Text(
                      user['role'] as String,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: roleColor,
                          ),
                    ),
                    backgroundColor: roleColor.withAlpha(25),
                    side: BorderSide.none,
                    padding: EdgeInsets.zero,
                  ),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: user['status'] == 'Active'
                              ? AppColors.secondary
                              : AppColors.darkText,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4.0),
                      Text(
                        user['status'] as String,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: user['status'] == 'Active'
                                  ? AppColors.secondary
                                  : colorScheme.onSurface.withAlpha(128),
                            ),
                      ),
                    ],
                  ),
                ),
                DataCell(Text(
                  user['lastActive'] as String,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withAlpha(128),
                      ),
                )),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: () {},
                        tooltip: 'Edit User',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        onPressed: () {},
                        tooltip: 'Delete User',
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildQuickActions(ColorScheme colorScheme) {
    final actions = [
      {
        'title': 'Add New Farm',
        'icon': Icons.add_business_rounded,
        'color': AppColors.primary,
      },
      {
        'title': 'Create Batch',
        'icon': Icons.inventory_2_rounded,
        'color': AppColors.secondary,
      },
      {
        'title': 'Add User',
        'icon': Icons.person_add_rounded,
        'color': AppColors.primary,
      },
      {
        'title': 'View Reports',
        'icon': Icons.assessment_rounded,
        'color': AppColors.warning,
      },
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12.0),
            ...actions.map((action) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: (action['color'] as Color).withAlpha(25),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Icon(
                      action['icon'] as IconData,
                      color: action['color'] as Color,
                    ),
                  ),
                  title: Text(
                    action['title'] as String,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${action['title']} clicked'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
