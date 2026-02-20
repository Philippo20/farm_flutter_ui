import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/modern_admin_sidebar.dart';
import '../../core/widgets/modern_admin_header.dart';

/// Modern Sensors Dashboard with real-time monitoring
class ModernSensorsScreen extends ConsumerStatefulWidget {
  const ModernSensorsScreen({super.key});

  @override
  ConsumerState<ModernSensorsScreen> createState() => _ModernSensorsScreenState();
}

class _ModernSensorsScreenState extends ConsumerState<ModernSensorsScreen> {
  String _selectedFarm = 'All Farms';
  String _selectedStatus = 'All';
  String _selectedType = 'All Types';
  
  final List<Map<String, dynamic>> _sensors = [
    {'id': 'S001', 'name': 'Temperature Sensor A', 'type': 'Temperature', 'location': 'Northern Estate - Greenhouse 1', 'value': '22°C', 'status': 'Normal', 'battery': 85, 'lastUpdate': '2 mins ago', 'icon': Icons.thermostat, 'color': Colors.orange},
    {'id': 'S002', 'name': 'Humidity Sensor B', 'type': 'Humidity', 'location': 'Northern Estate - Field 2', 'value': '65%', 'status': 'Normal', 'battery': 92, 'lastUpdate': '5 mins ago', 'icon': Icons.water_drop, 'color': Colors.blue},
    {'id': 'S003', 'name': 'pH Sensor C', 'type': 'pH Level', 'location': 'Southern Estate - Hydroponic', 'value': '6.2 pH', 'status': 'Warning', 'battery': 45, 'lastUpdate': '1 min ago', 'icon': Icons.science, 'color': Colors.purple},
    {'id': 'S004', 'name': 'CO2 Sensor D', 'type': 'CO2', 'location': 'Eastern Farm - Storage', 'value': '800 ppm', 'status': 'Normal', 'battery': 78, 'lastUpdate': '8 mins ago', 'icon': Icons.air, 'color': Colors.grey},
    {'id': 'S005', 'name': 'Soil Moisture E', 'type': 'Moisture', 'location': 'Western Farm - Field 5', 'value': '42%', 'status': 'Alert', 'battery': 15, 'lastUpdate': '30 secs ago', 'icon': Icons.grass, 'color': Colors.brown},
    {'id': 'S006', 'name': 'Water Level F', 'type': 'Water Level', 'location': 'Northern Estate - Tank A', 'value': '75 cm', 'status': 'Normal', 'battery': 68, 'lastUpdate': '3 mins ago', 'icon': Icons.water, 'color': Colors.cyan},
  ];
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: isMobile ? _buildMobileLayout(isDark) : _buildDesktopLayout(isDark),
      bottomNavigationBar: isMobile ? _buildBottomNavigation(isDark) : null,
    );
  }
  
  Widget _buildBottomNavigation(bool isDark) {
    final navItems = [
      {'icon': Icons.dashboard_outlined, 'activeIcon': Icons.dashboard_rounded, 'label': 'Dashboard', 'index': 0, 'route': '/dashboard'},
      {'icon': Icons.people_outline, 'activeIcon': Icons.people_rounded, 'label': 'Users', 'index': 1, 'route': '/users'},
      {'icon': Icons.agriculture_outlined, 'activeIcon': Icons.agriculture_rounded, 'label': 'Farms', 'index': 2, 'route': '/farms'},
      {'icon': Icons.sensors_outlined, 'activeIcon': Icons.sensors, 'label': 'Sensors', 'index': 3, 'route': '/sensors'},
      {'icon': Icons.analytics_outlined, 'activeIcon': Icons.analytics_rounded, 'label': 'Analytics', 'index': 4, 'route': '/analytics'},
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
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: navItems.map((item) {
              final index = item['index'] as int;
              final route = item['route'] as String;
              final isSelected = index == 3; // Sensors screen is index 3

              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (index != 3) {
                        Navigator.pushReplacementNamed(context, route);
                      }
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isSelected ? item['activeIcon'] as IconData : item['icon'] as IconData,
                          size: 22,
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
                                : (isDark ? Colors.white.withOpacity(0.5) : AppColors.textSecondary),
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 10,
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
  
  Widget _buildDesktopLayout(bool isDark) {
    return Row(
      children: [
        ModernAdminSidebar(selectedIndex: 3, onItemSelected: (_) {}),
        Expanded(
          child: Column(
            children: [
              ModernAdminHeader(userName: 'Admin', onNotificationTap: () {}, onProfileTap: () {}),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                        Builder(
                          builder: (context) {
                            final screenWidth = MediaQuery.of(context).size.width;
                            final isTablet = screenWidth < 1200;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Sensors Dashboard',
                                            style: AppTypography.h4.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? Colors.white : AppColors.textPrimary,
                                              fontSize: isTablet ? 22 : 28,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            'Monitor all sensor readings in real-time',
                                            style: AppTypography.bodyMedium.copyWith(
                                              color: isDark ? Colors.white70 : AppColors.textSecondary,
                                              fontSize: isTablet ? 13 : 14,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!isTablet) ...[
                                      const SizedBox(width: AppSpacing.md),
                                      ElevatedButton.icon(
                                        onPressed: () => _showAddSensorDialog(context, isDark),
                                        icon: const Icon(Icons.add_circle_outline, size: 20),
                                        label: const Text('Add Sensor'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (isTablet) ...[
                                  const SizedBox(height: AppSpacing.md),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () => _showAddSensorDialog(context, isDark),
                                      icon: const Icon(Icons.add_circle_outline, size: 18),
                                      label: const Text('Add Sensor'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                        
                        const SizedBox(height: AppSpacing.xl),
                        
                        // Live Sensor Readings Grid
                        _buildSensorReadingsGrid(isDark),
                        
                        const SizedBox(height: AppSpacing.xl),
                        
                        // Filters
                        _buildDesktopFilterSection(isDark),
                        
                        const SizedBox(height: AppSpacing.lg),
                        
                        // Sensors Table
                        Builder(
                          builder: (context) {
                            final screenWidth = MediaQuery.of(context).size.width;
                            final isTablet = screenWidth < 1200 && screenWidth >= 600;
                            
                            final filteredSensors = _sensors.where((sensor) {
                              if (_selectedStatus != 'All' && sensor['status'] != _selectedStatus) return false;
                              if (_selectedFarm != 'All Farms' && !sensor['location'].contains(_selectedFarm)) return false;
                              if (_selectedType != 'All Types' && sensor['type'] != _selectedType) return false;
                              return true;
                            }).toList();
                            
                            if (filteredSensors.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(AppSpacing.xxl),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.surfaceDark : Colors.white,
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                                  border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.sensors_off,
                                      size: 48,
                                      color: isDark ? Colors.white30 : AppColors.textSecondary.withOpacity(0.5),
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    Text(
                                      'No sensors match the current filters',
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: isDark ? Colors.white60 : AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    TextButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          _selectedFarm = 'All Farms';
                                          _selectedStatus = 'All';
                                          _selectedType = 'All Types';
                                        });
                                      },
                                      icon: const Icon(Icons.refresh, size: 16),
                                      label: const Text('Reset Filters'),
                                    ),
                                  ],
                                ),
                              );
                            }
                            
                            if (isTablet) {
                              // Use card layout for tablet
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                                    child: Text(
                                      '${filteredSensors.length} sensor${filteredSensors.length == 1 ? '' : 's'} found',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: isDark ? Colors.white60 : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  ...filteredSensors.map((sensor) {
                                    Color statusColor = sensor['status'] == 'Normal' ? AppColors.success : sensor['status'] == 'Warning' ? AppColors.warning : AppColors.error;
                                    Color batteryColor = sensor['battery'] > 50 ? AppColors.success : sensor['battery'] > 20 ? AppColors.warning : AppColors.error;
                                    return _buildTabletSensorCard(sensor, isDark, statusColor, batteryColor);
                                  }),
                                ],
                              );
                            }
                            
                            // Use table layout for desktop
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${filteredSensors.length} sensor${filteredSensors.length == 1 ? '' : 's'} found',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: isDark ? Colors.white60 : AppColors.textSecondary,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.sort,
                                            size: 16,
                                            color: isDark ? Colors.white60 : AppColors.textSecondary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Sort by: Name',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark ? Colors.white60 : AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.surfaceDark : Colors.white,
                                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                                    border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
                                    boxShadow: isDark ? null : [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      // Header
                                      Container(
                                        padding: const EdgeInsets.all(AppSpacing.lg),
                                        decoration: BoxDecoration(
                                          color: isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50,
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                'Sensor',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                'Location',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                'Value',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                'Status',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                'Battery',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                'Last Update',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 100,
                                              child: Text(
                                                'Actions',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Rows
                                      ...filteredSensors.map((sensor) => _buildSensorRow(sensor, isDark)),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
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
    final filteredSensors = _sensors.where((sensor) {
      if (_selectedStatus != 'All' && sensor['status'] != _selectedStatus) return false;
      if (_selectedFarm != 'All Farms' && !sensor['location'].contains(_selectedFarm)) return false;
      if (_selectedType != 'All Types' && sensor['type'] != _selectedType) return false;
      return true;
    }).toList();
    
    return Column(
      children: [
        ModernAdminHeader(
          userName: 'Admin',
          onNotificationTap: () {},
          onProfileTap: () {},
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title & Add Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sensors',
                            style: AppTypography.h5.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${filteredSensors.length} devices active',
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark ? Colors.white60 : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: IconButton(
                        onPressed: () => _showAddSensorDialog(context, isDark),
                        icon: const Icon(Icons.add, color: Colors.white, size: 20),
                        tooltip: 'Add Sensor',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                
                // Quick Stats
                _buildMobileQuickStats(isDark),
                const SizedBox(height: AppSpacing.md),
                
                // Filter Chips
                _buildMobileFilterChips(isDark),
                const SizedBox(height: AppSpacing.md),
                
                // Sensors List
                ...filteredSensors.map((sensor) => _buildMobileSensorCard(sensor, isDark)),
                
                if (filteredSensors.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(
                          Icons.sensors_off,
                          size: 48,
                          color: isDark ? Colors.white30 : AppColors.textSecondary.withOpacity(0.5),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'No sensors found',
                          style: AppTypography.bodyMedium.copyWith(
                            color: isDark ? Colors.white60 : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildMobileQuickStats(bool isDark) {
    final normalCount = _sensors.where((s) => s['status'] == 'Normal').length;
    final warningCount = _sensors.where((s) => s['status'] == 'Warning').length;
    final alertCount = _sensors.where((s) => s['status'] == 'Alert').length;
    
    return Row(
      children: [
        Expanded(child: _buildMiniStatCard('Total', '${_sensors.length}', Icons.sensors, AppColors.primary, isDark)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: _buildMiniStatCard('Normal', '$normalCount', Icons.check_circle, AppColors.success, isDark)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: _buildMiniStatCard('Warning', '$warningCount', Icons.warning, AppColors.warning, isDark)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: _buildMiniStatCard('Alert', '$alertCount', Icons.error, AppColors.error, isDark)),
      ],
    );
  }
  
  Widget _buildMiniStatCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: color.withOpacity(0.8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
  
  Widget _buildMobileFilterChips(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('All', _selectedStatus == 'All', () => setState(() => _selectedStatus = 'All'), isDark),
          const SizedBox(width: AppSpacing.xs),
          _buildFilterChip('Normal', _selectedStatus == 'Normal', () => setState(() => _selectedStatus = 'Normal'), isDark, color: AppColors.success),
          const SizedBox(width: AppSpacing.xs),
          _buildFilterChip('Warning', _selectedStatus == 'Warning', () => setState(() => _selectedStatus = 'Warning'), isDark, color: AppColors.warning),
          const SizedBox(width: AppSpacing.xs),
          _buildFilterChip('Alert', _selectedStatus == 'Alert', () => setState(() => _selectedStatus = 'Alert'), isDark, color: AppColors.error),
        ],
      ),
    );
  }
  
  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap, bool isDark, {Color? color}) {
    final chipColor = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
            color: isSelected ? chipColor : (isDark ? Colors.white12 : Colors.grey.withOpacity(0.2)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppColors.textSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileSensorCard(Map<String, dynamic> sensor, bool isDark) {
    Color statusColor = sensor['status'] == 'Normal' ? AppColors.success : sensor['status'] == 'Warning' ? AppColors.warning : AppColors.error;
    Color batteryColor = sensor['battery'] > 50 ? AppColors.success : sensor['battery'] > 20 ? AppColors.warning : AppColors.error;
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            (sensor['color'] as Color).withOpacity(0.2),
                            (sensor['color'] as Color).withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Icon(
                        sensor['icon'] as IconData,
                        color: sensor['color'] as Color,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            sensor['name'],
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.category_outlined,
                                size: 12,
                                color: isDark ? Colors.white.withOpacity(0.4) : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                sensor['type'],
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.white60 : AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            sensor['status'],
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppSpacing.md),
                
                // Value & Battery Row
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Current Value',
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark ? Colors.white.withOpacity(0.4) : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              sensor['value'],
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: sensor['color'] as Color,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 36,
                        color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Battery',
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark ? Colors.white.withOpacity(0.4) : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: sensor['battery'] / 100,
                                      backgroundColor: isDark ? Colors.white12 : Colors.grey.withOpacity(0.2),
                                      valueColor: AlwaysStoppedAnimation(batteryColor),
                                      minHeight: 6,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${sensor['battery']}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: batteryColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppSpacing.sm),
                
                // Footer Row
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 12,
                      color: isDark ? Colors.white.withOpacity(0.4) : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        sensor['location'],
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: isDark ? Colors.white.withOpacity(0.4) : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      sensor['lastUpdate'],
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSensorReadingsGrid(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth < 1200 && screenWidth >= 600;
    final readings = [
      {'label': 'Temperature', 'value': '22°C', 'trend': '+2°', 'icon': Icons.thermostat, 'color': Colors.orange},
      {'label': 'Humidity', 'value': '65%', 'trend': '-3%', 'icon': Icons.water_drop, 'color': Colors.blue},
      {'label': 'pH Level', 'value': '6.2', 'trend': '+0.1', 'icon': Icons.science, 'color': Colors.purple},
      {'label': 'CO2', 'value': '800ppm', 'trend': '+50', 'icon': Icons.air, 'color': Colors.grey},
      {'label': 'Moisture', 'value': '42%', 'trend': '-5%', 'icon': Icons.grass, 'color': Colors.brown},
      {'label': 'Water', 'value': '75cm', 'trend': '-2cm', 'icon': Icons.water, 'color': Colors.cyan},
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Live Readings',
              style: AppTypography.h6.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Live',
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isTablet ? 2 : 3,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: isTablet ? 2.5 : 2.2,
          ),
          itemCount: readings.length,
          itemBuilder: (context, index) {
            final reading = readings[index];
            final trendIsPositive = reading['trend'].toString().startsWith('+');
            return Container(
              padding: EdgeInsets.all(isTablet ? AppSpacing.sm : AppSpacing.md),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    (reading['color'] as Color).withOpacity(0.15),
                    (reading['color'] as Color).withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: (reading['color'] as Color).withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isTablet ? 8 : 10),
                    decoration: BoxDecoration(
                      color: (reading['color'] as Color).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Icon(
                      reading['icon'] as IconData,
                      color: reading['color'] as Color,
                      size: isTablet ? 18 : 22,
                    ),
                  ),
                  SizedBox(width: isTablet ? AppSpacing.sm : AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          reading['label'] as String,
                          style: TextStyle(
                            fontSize: isTablet ? 10 : 11,
                            color: (reading['color'] as Color).withOpacity(0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              reading['value'] as String,
                              style: TextStyle(
                                fontSize: isTablet ? 15 : 17,
                                fontWeight: FontWeight.bold,
                                color: reading['color'] as Color,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              trendIsPositive ? Icons.trending_up : Icons.trending_down,
                              size: isTablet ? 12 : 14,
                              color: trendIsPositive ? AppColors.success : AppColors.error,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              reading['trend'] as String,
                              style: TextStyle(
                                fontSize: isTablet ? 9 : 10,
                                fontWeight: FontWeight.w500,
                                color: trendIsPositive ? AppColors.success : AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
  
  Widget _buildSensorRow(Map<String, dynamic> sensor, bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth < 1200 && screenWidth >= 600;
    Color statusColor = sensor['status'] == 'Normal' ? AppColors.success : sensor['status'] == 'Warning' ? AppColors.warning : AppColors.error;
    Color batteryColor = sensor['battery'] > 50 ? AppColors.success : sensor['battery'] > 20 ? AppColors.warning : AppColors.error;
    
    if (isTablet) {
      return _buildTabletSensorCard(sensor, isDark, statusColor, batteryColor);
    }
    
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05))),
      ),
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: EdgeInsets.all(isTablet ? AppSpacing.md : AppSpacing.lg),
          child: Row(
            children: [
              // Sensor Info
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isTablet ? 6 : 8),
                      decoration: BoxDecoration(
                        color: (sensor['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Icon(
                        sensor['icon'] as IconData,
                        color: sensor['color'] as Color,
                        size: isTablet ? 14 : 16,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            sensor['name'],
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: isTablet ? 12 : 13,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            sensor['type'],
                            style: TextStyle(
                              fontSize: isTablet ? 10 : 11,
                              color: isDark ? Colors.white60 : AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Location
              Expanded(
                flex: 2,
                child: Text(
                  sensor['location'],
                  style: TextStyle(
                    fontSize: isTablet ? 11 : 12,
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Value
              Expanded(
                child: Text(
                  sensor['value'],
                  style: TextStyle(
                    fontSize: isTablet ? 11 : 12,
                    fontWeight: FontWeight.w600,
                    color: sensor['color'] as Color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Status
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    sensor['status'],
                    style: TextStyle(
                      color: statusColor,
                      fontSize: isTablet ? 10 : 11,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              // Battery
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: sensor['battery'] / 100,
                        backgroundColor: Colors.grey.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation(batteryColor),
                        minHeight: isTablet ? 4 : 6,
                      ),
                    ),
                    SizedBox(width: isTablet ? 4 : 8),
                    Flexible(
                      child: Text(
                        '${sensor['battery']}%',
                        style: TextStyle(
                          fontSize: isTablet ? 10 : 11,
                          color: batteryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // Last Update
              Expanded(
                child: Text(
                  sensor['lastUpdate'],
                  style: TextStyle(
                    fontSize: isTablet ? 10 : 11,
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Actions
              SizedBox(
                width: isTablet ? 80 : 100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () => _showSensorSettingsDialog(context, sensor, isDark),
                      icon: const Icon(Icons.settings_outlined),
                      iconSize: isTablet ? 16 : 18,
                      color: AppColors.primary,
                    ),
                    IconButton(
                      onPressed: () => _showDeleteSensorDialog(context, sensor, isDark),
                      icon: const Icon(Icons.delete_outline),
                      iconSize: isTablet ? 16 : 18,
                      color: AppColors.error,
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

  Widget _buildTabletSensorCard(Map<String, dynamic> sensor, bool isDark, Color statusColor, Color batteryColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
      ),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
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
                      color: (sensor['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Icon(
                      sensor['icon'] as IconData,
                      color: sensor['color'] as Color,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sensor['name'],
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          sensor['type'],
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white60 : AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    child: Text(
                      sensor['status'],
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Value',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.white60 : AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          sensor['value'],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: sensor['color'] as Color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Battery',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.white60 : AppColors.textSecondary,
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: LinearProgressIndicator(
                                value: sensor['battery'] / 100,
                                backgroundColor: Colors.grey.withOpacity(0.2),
                                valueColor: AlwaysStoppedAnimation(batteryColor),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${sensor['battery']}%',
                              style: TextStyle(
                                fontSize: 11,
                                color: batteryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                sensor['location'],
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white60 : AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Last update: ${sensor['lastUpdate']}',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white60 : AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _showSensorSettingsDialog(context, sensor, isDark),
                        icon: const Icon(Icons.settings_outlined),
                        iconSize: 16,
                        color: AppColors.primary,
                      ),
                      IconButton(
                        onPressed: () => _showDeleteSensorDialog(context, sensor, isDark),
                        icon: const Icon(Icons.delete_outline),
                        iconSize: 16,
                        color: AppColors.error,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged, bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth < 1200 && screenWidth >= 600;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isTablet)
          Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 4),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white60 : AppColors.textSecondary,
              ),
            ),
          ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? AppSpacing.sm : AppSpacing.md,
            vertical: isTablet ? 2 : 4,
          ),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.black.withOpacity(0.1),
            ),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontSize: isTablet ? 12 : 13,
            ),
            items: items.map((item) => DropdownMenuItem(
              value: item,
              child: Text(
                item,
                style: TextStyle(
                  fontSize: isTablet ? 12 : 13,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            )).toList(),
            onChanged: onChanged,
            underline: const SizedBox(),
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              size: isTablet ? 18 : 20,
              color: isDark ? Colors.white60 : AppColors.textSecondary,
            ),
            dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
          ),
        ),
      ],
    );
  }
  
  Widget _buildDesktopFilterSection(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth < 1200 && screenWidth >= 600;
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.filter_list,
                    size: 18,
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Filters',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              if (_selectedFarm != 'All Farms' || _selectedStatus != 'All' || _selectedType != 'All Types')
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedFarm = 'All Farms';
                      _selectedStatus = 'All';
                      _selectedType = 'All Types';
                    });
                  },
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('Clear All'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (isTablet)
            Column(
              children: [
                _buildDropdown('Farm', _selectedFarm, ['All Farms', 'Northern Estate', 'Southern Estate', 'Eastern Farm', 'Western Farm'], 
                  (v) => setState(() => _selectedFarm = v!), isDark),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown('Status', _selectedStatus, ['All', 'Normal', 'Warning', 'Alert'], 
                        (v) => setState(() => _selectedStatus = v!), isDark),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _buildDropdown('Type', _selectedType, ['All Types', 'Temperature', 'Humidity', 'pH Level', 'CO2', 'Moisture', 'Water Level'], 
                        (v) => setState(() => _selectedType = v!), isDark),
                    ),
                  ],
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: _buildDropdown('Farm', _selectedFarm, ['All Farms', 'Northern Estate', 'Southern Estate', 'Eastern Farm', 'Western Farm'], 
                    (v) => setState(() => _selectedFarm = v!), isDark),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildDropdown('Status', _selectedStatus, ['All', 'Normal', 'Warning', 'Alert'], 
                    (v) => setState(() => _selectedStatus = v!), isDark),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildDropdown('Type', _selectedType, ['All Types', 'Temperature', 'Humidity', 'pH Level', 'CO2', 'Moisture', 'Water Level'], 
                    (v) => setState(() => _selectedType = v!), isDark),
                ),
              ],
            ),
        ],
      ),
    );
  }
  
  // ============ MODAL DIALOGS ============
  
  void _showAddSensorDialog(BuildContext context, bool isDark) {
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    String selectedType = 'Temperature';
    String selectedFarm = 'Northern Estate';
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusXl)),
          insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? AppSpacing.md : AppSpacing.xxl, vertical: AppSpacing.xl),
          child: Container(
            width: isMobile ? double.infinity : 500,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.info, AppColors.info.withOpacity(0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
                  ),
                  child: Row(
                    children: [
                      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(AppSpacing.radiusMd)), child: const Icon(Icons.sensors, color: Colors.white, size: 24)),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Add New Sensor', style: AppTypography.h6.copyWith(color: Colors.white, fontWeight: FontWeight.bold)), Text('Register a new sensor device', style: AppTypography.bodySmall.copyWith(color: Colors.white70))])),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white70)),
                    ],
                  ),
                ),
                // Form
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFormLabel('Sensor Name', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildFormTextField(controller: nameController, hint: 'e.g., Temperature Sensor A', icon: Icons.sensors, isDark: isDark),
                        const SizedBox(height: AppSpacing.lg),
                        _buildFormLabel('Location/Zone', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildFormTextField(controller: locationController, hint: 'e.g., Greenhouse 1', icon: Icons.location_on, isDark: isDark),
                        const SizedBox(height: AppSpacing.lg),
                        if (!isMobile) Row(children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildFormLabel('Sensor Type', isDark), const SizedBox(height: AppSpacing.sm), _buildFormDropdown(value: selectedType, items: ['Temperature', 'Humidity', 'pH Level', 'CO2', 'Moisture', 'Water Level'], icon: Icons.category, isDark: isDark, onChanged: (v) => setDialogState(() => selectedType = v!))])),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildFormLabel('Farm', isDark), const SizedBox(height: AppSpacing.sm), _buildFormDropdown(value: selectedFarm, items: ['Northern Estate', 'Southern Estate', 'Eastern Farm', 'Western Farm'], icon: Icons.agriculture, isDark: isDark, onChanged: (v) => setDialogState(() => selectedFarm = v!))])),
                        ]) else ...[
                          _buildFormLabel('Sensor Type', isDark), const SizedBox(height: AppSpacing.sm), _buildFormDropdown(value: selectedType, items: ['Temperature', 'Humidity', 'pH Level', 'CO2', 'Moisture', 'Water Level'], icon: Icons.category, isDark: isDark, onChanged: (v) => setDialogState(() => selectedType = v!)),
                          const SizedBox(height: AppSpacing.lg),
                          _buildFormLabel('Farm', isDark), const SizedBox(height: AppSpacing.sm), _buildFormDropdown(value: selectedFarm, items: ['Northern Estate', 'Southern Estate', 'Eastern Farm', 'Western Farm'], icon: Icons.agriculture, isDark: isDark, onChanged: (v) => setDialogState(() => selectedFarm = v!)),
                        ],
                      ],
                    ),
                  ),
                ),
                // Actions
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppSpacing.radiusXl))),
                  child: Row(
                    children: [
                      Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: AppSpacing.md), side: BorderSide(color: isDark ? Colors.white24 : AppColors.neutral300), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd))), child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondary)))),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(flex: 2, child: ElevatedButton.icon(onPressed: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: [const Icon(Icons.check_circle, color: Colors.white), const SizedBox(width: 8), Text('${nameController.text.isEmpty ? "Sensor" : nameController.text} added!')]), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)))); }, icon: const Icon(Icons.add, size: 18), label: const Text('Add Sensor'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.info, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: AppSpacing.md), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd))))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _showSensorSettingsDialog(BuildContext context, Map<String, dynamic> sensor, bool isDark) {
    String selectedThreshold = 'Medium';
    bool alertsEnabled = true;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusXl)),
          insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? AppSpacing.md : AppSpacing.xxl, vertical: AppSpacing.xl),
          child: Container(
            width: isMobile ? double.infinity : 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [sensor['color'] as Color, (sensor['color'] as Color).withOpacity(0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
                  ),
                  child: Row(
                    children: [
                      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(AppSpacing.radiusMd)), child: Icon(sensor['icon'] as IconData, color: Colors.white, size: 24)),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Sensor Settings', style: AppTypography.h6.copyWith(color: Colors.white, fontWeight: FontWeight.bold)), Text(sensor['name'], style: AppTypography.bodySmall.copyWith(color: Colors.white70))])),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white70)),
                    ],
                  ),
                ),
                // Sensor Preview Card
                Container(
                  margin: const EdgeInsets.all(AppSpacing.lg),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : (sensor['color'] as Color).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: (sensor['color'] as Color).withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: (sensor['color'] as Color).withOpacity(0.1), borderRadius: BorderRadius.circular(AppSpacing.radiusSm)), child: Icon(sensor['icon'] as IconData, color: sensor['color'] as Color, size: 24)),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(sensor['type'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : AppColors.textPrimary)),
                        Text(sensor['location'], style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : AppColors.textSecondary)),
                      ])),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text(sensor['value'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: sensor['color'] as Color)),
                        Row(children: [
                          Icon(Icons.battery_charging_full, size: 14, color: sensor['battery'] > 50 ? AppColors.success : AppColors.warning),
                          const SizedBox(width: 2),
                          Text('${sensor['battery']}%', style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : AppColors.textSecondary)),
                        ]),
                      ]),
                    ],
                  ),
                ),
                // Settings
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFormLabel('Alert Threshold', isDark),
                      const SizedBox(height: AppSpacing.sm),
                      _buildFormDropdown(value: selectedThreshold, items: ['Low', 'Medium', 'High', 'Critical'], icon: Icons.warning, isDark: isDark, onChanged: (v) => setDialogState(() => selectedThreshold = v!)),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Enable Alerts', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textPrimary)),
                          Switch(value: alertsEnabled, onChanged: (v) => setDialogState(() => alertsEnabled = v), activeColor: AppColors.success),
                        ],
                      ),
                    ],
                  ),
                ),
                // Actions
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppSpacing.radiusXl))),
                  child: Row(
                    children: [
                      OutlinedButton(onPressed: () { Navigator.pop(context); _showDeleteSensorDialog(context, sensor, isDark); }, style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.md), side: const BorderSide(color: AppColors.error), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd))), child: const Icon(Icons.delete_outline, color: AppColors.error, size: 20)),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: AppSpacing.md), side: BorderSide(color: isDark ? Colors.white24 : AppColors.neutral300), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd))), child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondary)))),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(flex: 2, child: ElevatedButton.icon(onPressed: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: [const Icon(Icons.check_circle, color: Colors.white), const SizedBox(width: 8), const Text('Settings saved!')]), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)))); }, icon: const Icon(Icons.save, size: 18), label: const Text('Save'), style: ElevatedButton.styleFrom(backgroundColor: sensor['color'] as Color, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: AppSpacing.md), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd))))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _showDeleteSensorDialog(BuildContext context, Map<String, dynamic> sensor, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusXl)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.sensors_off, color: AppColors.error, size: 40)),
              const SizedBox(height: AppSpacing.lg),
              Text('Delete Sensor?', style: AppTypography.h5.copyWith(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)),
              const SizedBox(height: AppSpacing.sm),
              Text('Are you sure you want to delete "${sensor['name']}"?', style: AppTypography.bodyMedium.copyWith(color: isDark ? Colors.white70 : AppColors.textSecondary), textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.md),
              // Sensor Preview
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : AppColors.error.withOpacity(0.05), borderRadius: BorderRadius.circular(AppSpacing.radiusMd), border: Border.all(color: AppColors.error.withOpacity(0.2))),
                child: Row(
                  children: [
                    Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: (sensor['color'] as Color).withOpacity(0.1), borderRadius: BorderRadius.circular(AppSpacing.radiusSm)), child: Icon(sensor['icon'] as IconData, color: sensor['color'] as Color, size: 20)),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(sensor['name'], style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isDark ? Colors.white : AppColors.textPrimary)),
                      Text(sensor['location'], style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : AppColors.textSecondary)),
                    ])),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(AppSpacing.radiusMd), border: Border.all(color: AppColors.warning.withOpacity(0.3))),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: AppColors.warning, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text('All sensor data and history will be permanently deleted.', style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : AppColors.textSecondary))),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: AppSpacing.md), side: BorderSide(color: isDark ? Colors.white24 : AppColors.neutral300), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd))), child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondary)))),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: ElevatedButton.icon(onPressed: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: [const Icon(Icons.delete, color: Colors.white), const SizedBox(width: 8), Text('${sensor['name']} deleted')]), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)))); }, icon: const Icon(Icons.delete, size: 18), label: const Text('Delete'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: AppSpacing.md), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd))))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Helper Widgets
  Widget _buildFormLabel(String label, bool isDark) => Text(label, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textPrimary));
  
  Widget _buildFormTextField({required TextEditingController controller, required String hint, required IconData icon, required bool isDark}) {
    return TextFormField(
      controller: controller,
      style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.white38 : AppColors.textSecondary.withOpacity(0.5)),
        prefixIcon: Icon(icon, color: isDark ? Colors.white54 : AppColors.textSecondary, size: 20),
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.05) : AppColors.neutral50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd), borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.neutral200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd), borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.neutral200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
      ),
    );
  }
  
  Widget _buildFormDropdown({required String value, required List<String> items, required IconData icon, required bool isDark, required Function(String?) onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : AppColors.neutral50, borderRadius: BorderRadius.circular(AppSpacing.radiusMd), border: Border.all(color: isDark ? Colors.white12 : AppColors.neutral200)),
      child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: value, isExpanded: true, icon: Icon(Icons.keyboard_arrow_down, color: isDark ? Colors.white54 : AppColors.textSecondary), dropdownColor: isDark ? AppColors.surfaceDark : Colors.white, style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary, fontSize: 14), items: items.map((item) => DropdownMenuItem(value: item, child: Row(children: [Icon(icon, color: isDark ? Colors.white54 : AppColors.textSecondary, size: 20), const SizedBox(width: AppSpacing.md), Text(item)]))).toList(), onChanged: onChanged)),
    );
  }
}
