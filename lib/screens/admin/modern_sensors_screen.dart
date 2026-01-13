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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Sensors Dashboard', style: AppTypography.h4.copyWith(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)),
                                Text('Monitor all sensor readings in real-time', style: AppTypography.bodyMedium.copyWith(color: isDark ? Colors.white70 : AppColors.textSecondary)),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: () {},
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
                        ),
                        
                        const SizedBox(height: AppSpacing.xl),
                        
                        // Live Sensor Readings Grid
                        _buildSensorReadingsGrid(isDark),
                        
                        const SizedBox(height: AppSpacing.xl),
                        
                        // Filters
                        Row(
                          children: [
                            _buildDropdown('Farm', _selectedFarm, ['All Farms', 'Northern Estate', 'Southern Estate', 'Eastern Farm', 'Western Farm'], 
                              (v) => setState(() => _selectedFarm = v!), isDark),
                            const SizedBox(width: AppSpacing.md),
                            _buildDropdown('Status', _selectedStatus, ['All', 'Normal', 'Warning', 'Alert'], 
                              (v) => setState(() => _selectedStatus = v!), isDark),
                          ],
                        ),
                        
                        const SizedBox(height: AppSpacing.lg),
                        
                        // Sensors Table
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDark : Colors.white,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                            border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
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
                                  children: const [
                                    Expanded(flex: 2, child: Text('Sensor', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                                    Expanded(flex: 2, child: Text('Location', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                                    Expanded(child: Text('Value', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                                    Expanded(child: Text('Status', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                                    Expanded(child: Text('Battery', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                                    Expanded(child: Text('Last Update', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                                    SizedBox(width: 100, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12), textAlign: TextAlign.center)),
                                  ],
                                ),
                              ),
                              // Rows
                              ..._sensors.where((sensor) {
                                if (_selectedStatus != 'All' && sensor['status'] != _selectedStatus) return false;
                                if (_selectedFarm != 'All Farms' && !sensor['location'].contains(_selectedFarm)) return false;
                                return true;
                              }).map((sensor) => _buildSensorRow(sensor, isDark)),
                            ],
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
      );
  }

  Widget _buildMobileLayout(bool isDark) {
    return Column(
      children: [
        ModernAdminHeader(userName: 'Admin', onNotificationTap: () {}, onProfileTap: () {}),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sensors Dashboard', style: AppTypography.h5.copyWith(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)),
                const SizedBox(height: AppSpacing.lg),
                // Filters (mobile optimized)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: _buildDropdown('Farm', _selectedFarm, ['All Farms', 'Northern Estate', 'Southern Estate'], (v) => setState(() => _selectedFarm = v!), isDark)),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: _buildDropdown('Status', _selectedStatus, ['All', 'Normal', 'Warning', 'Alert'], (v) => setState(() => _selectedStatus = v!), isDark)),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                // Sensors List (mobile optimized)
                ..._sensors.where((sensor) {
                  if (_selectedStatus != 'All' && sensor['status'] != _selectedStatus) return false;
                  if (_selectedFarm != 'All Farms' && !sensor['location'].contains(_selectedFarm)) return false;
                  return true;
                }).map((sensor) => _buildMobileSensorCard(sensor, isDark)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileSensorCard(Map<String, dynamic> sensor, bool isDark) {
    Color statusColor = sensor['status'] == 'Normal' ? AppColors.success : sensor['status'] == 'Warning' ? AppColors.warning : AppColors.error;
    Color batteryColor = sensor['battery'] > 50 ? AppColors.success : sensor['battery'] > 20 ? AppColors.warning : AppColors.error;
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
      ),
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
                child: Icon(sensor['icon'] as IconData, color: sensor['color'] as Color, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sensor['name'], style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isDark ? Colors.white : AppColors.textPrimary)),
                    Text(sensor['type'], style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : AppColors.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(sensor['status'], style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
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
                    Text('Value', style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : AppColors.textSecondary)),
                    Text(sensor['value'], style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: sensor['color'] as Color)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Battery', style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : AppColors.textSecondary)),
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
                        Text('${sensor['battery']}%', style: TextStyle(fontSize: 11, color: batteryColor)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(sensor['location'], style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : AppColors.textSecondary)),
          Text('Last update: ${sensor['lastUpdate']}', style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(bool isDark) {
    final navItems = [
      {'icon': Icons.dashboard_outlined, 'label': 'Dashboard', 'index': 0, 'route': '/dashboard'},
      {'icon': Icons.people_outline, 'label': 'Users', 'index': 1, 'route': '/users'},
      {'icon': Icons.agriculture_outlined, 'label': 'Farms', 'index': 2, 'route': '/farms'},
      {'icon': Icons.sensors_outlined, 'label': 'Sensors', 'index': 3, 'route': '/sensors'},
      {'icon': Icons.analytics_outlined, 'label': 'Analytics', 'index': 4, 'route': '/analytics'},
      {'icon': Icons.settings_outlined, 'label': 'Settings', 'index': 5, 'route': '/settings'},
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
              final isSelected = index == 3; // Sensors screen is index 3

              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (index != 3) {
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
                                : (isDark ? Colors.white.withOpacity(0.5) : AppColors.textSecondary),
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
  
  Widget _buildSensorReadingsGrid(bool isDark) {
    final readings = [
      {'label': 'Temperature', 'value': '22°C', 'trend': '+2°', 'icon': Icons.thermostat, 'color': Colors.orange},
      {'label': 'Humidity', 'value': '65%', 'trend': '-3%', 'icon': Icons.water_drop, 'color': Colors.blue},
      {'label': 'pH Level', 'value': '6.2', 'trend': '+0.1', 'icon': Icons.science, 'color': Colors.purple},
      {'label': 'CO2', 'value': '800ppm', 'trend': '+50', 'icon': Icons.air, 'color': Colors.grey},
      {'label': 'Soil Moisture', 'value': '42%', 'trend': '-5%', 'icon': Icons.grass, 'color': Colors.brown},
      {'label': 'Water Level', 'value': '75cm', 'trend': '-2cm', 'icon': Icons.water, 'color': Colors.cyan},
    ];
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 2.5,
      ),
      itemCount: readings.length,
      itemBuilder: (context, index) {
        final reading = readings[index];
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: (reading['color'] as Color).withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: (reading['color'] as Color).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (reading['color'] as Color).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(reading['icon'] as IconData, color: reading['color'] as Color, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(reading['label'] as String, style: TextStyle(fontSize: 11, color: (reading['color'] as Color).withOpacity(0.8))),
                    Row(
                      children: [
                        Text(reading['value'] as String, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: reading['color'] as Color)),
                        const SizedBox(width: 8),
                        Text(reading['trend'] as String, style: TextStyle(fontSize: 10, color: reading['trend'].toString().startsWith('+') ? AppColors.success : AppColors.error)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildSensorRow(Map<String, dynamic> sensor, bool isDark) {
    Color statusColor = sensor['status'] == 'Normal' ? AppColors.success : sensor['status'] == 'Warning' ? AppColors.warning : AppColors.error;
    Color batteryColor = sensor['battery'] > 50 ? AppColors.success : sensor['battery'] > 20 ? AppColors.warning : AppColors.error;
    
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05))),
      ),
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              // Sensor Info
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (sensor['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Icon(sensor['icon'] as IconData, color: sensor['color'] as Color, size: 16),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(sensor['name'], style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isDark ? Colors.white : AppColors.textPrimary)),
                          Text(sensor['type'], style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Location
              Expanded(flex: 2, child: Text(sensor['location'], style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : AppColors.textSecondary))),
              // Value
              Expanded(child: Text(sensor['value'], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sensor['color'] as Color))),
              // Status
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(sensor['status'], style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
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
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${sensor['battery']}%', style: TextStyle(fontSize: 11, color: batteryColor)),
                  ],
                ),
              ),
              // Last Update
              Expanded(child: Text(sensor['lastUpdate'], style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : AppColors.textSecondary))),
              // Actions
              SizedBox(
                width: 100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(onPressed: () {}, icon: const Icon(Icons.settings_outlined), iconSize: 18, color: AppColors.primary),
                    IconButton(onPressed: () {}, icon: const Icon(Icons.delete_outline), iconSize: 18, color: AppColors.error),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : AppColors.neutral100,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: DropdownButton<String>(
        value: value,
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item, style: const TextStyle(fontSize: 13)))).toList(),
        onChanged: onChanged,
        underline: const SizedBox(),
        icon: const Icon(Icons.arrow_drop_down, size: 20),
      ),
    );
  }
}
