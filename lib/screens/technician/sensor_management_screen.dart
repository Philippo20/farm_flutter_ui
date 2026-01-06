import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/mock_farm_data.dart';
import 'package:intl/intl.dart';

/// Sensor Management Screen for Technicians
/// Allows viewing, calibrating, and managing all farm sensors
class SensorManagementScreen extends StatefulWidget {
  const SensorManagementScreen({super.key});

  @override
  State<SensorManagementScreen> createState() => _SensorManagementScreenState();
}

class _SensorManagementScreenState extends State<SensorManagementScreen> {
  String _selectedType = 'All';
  String _selectedStatus = 'All';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sensors = MockFarmData.getAllSensors();

    // Filter sensors
    final filteredSensors = sensors.where((sensor) {
      if (_selectedType != 'All' && sensor['type'] != _selectedType) return false;
      if (_selectedStatus != 'All' && sensor['status'] != _selectedStatus) return false;
      if (_searchQuery.isNotEmpty && 
          !sensor['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Sensor Management', style: AppTypography.h5.copyWith(fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {}); // Refresh sensor data
            },
            tooltip: 'Refresh Sensors',
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showAddSensorDialog(context, isDark),
            tooltip: 'Add Sensor',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08),
                ),
              ),
            ),
            child: Column(
              children: [
                // Search bar
                TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search sensors...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.white10 : AppColors.neutral100,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // Filter chips
                Row(
                  children: [
                    Expanded(
                      child: _buildFilterDropdown(
                        'Type',
                        _selectedType,
                        ['All', 'temperature', 'humidity', 'ph', 'ec', 'tds', 'co2', 'distance'],
                        (value) => setState(() => _selectedType = value!),
                        isDark,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _buildFilterDropdown(
                        'Status',
                        _selectedStatus,
                        ['All', 'normal', 'warning', 'alert', 'offline'],
                        (value) => setState(() => _selectedStatus = value!),
                        isDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Sensor count
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filteredSensors.length} Sensors',
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${sensors.where((s) => s['status'] == 'normal').length} Active',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Sensor grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 3 : 2,
                childAspectRatio: 1.4,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
              ),
              itemCount: filteredSensors.length,
              itemBuilder: (context, index) {
                return _buildSensorCard(filteredSensors[index], isDark);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorCard(Map<String, dynamic> sensor, bool isDark) {
    final color = sensor['color'] as Color;
    final batteryLevel = sensor['batteryLevel'] as int;
    final signalStrength = sensor['signalStrength'] as int;
    final lastCalibrated = sensor['lastCalibrated'] as DateTime;
    final daysSinceCalibration = DateTime.now().difference(lastCalibrated).inDays;

    return Card(
      elevation: 0,
      color: isDark ? AppColors.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08),
        ),
      ),
      child: InkWell(
        onTap: () => _showSensorDetails(sensor, isDark),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon and status
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Icon(
                      sensor['icon'] as IconData,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sensor['name'],
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          sensor['id'],
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark ? Colors.white60 : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(sensor['status'], isDark),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Current value
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${sensor['value']}',
                    style: AppTypography.h4.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      sensor['unit'],
                      style: AppTypography.bodyMedium.copyWith(
                        color: color.withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xs),

              // Location
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      sensor['location'],
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? Colors.white60 : AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Metrics row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMetric(
                    Icons.battery_std,
                    '$batteryLevel%',
                    batteryLevel > 80 ? AppColors.success : 
                    batteryLevel > 50 ? AppColors.warning : AppColors.error,
                    isDark,
                  ),
                  _buildMetric(
                    Icons.signal_cellular_alt,
                    '$signalStrength%',
                    signalStrength > 70 ? AppColors.success : 
                    signalStrength > 40 ? AppColors.warning : AppColors.error,
                    isDark,
                  ),
                  _buildMetric(
                    Icons.schedule,
                    '${daysSinceCalibration}d',
                    daysSinceCalibration < 14 ? AppColors.success : 
                    daysSinceCalibration < 21 ? AppColors.warning : AppColors.error,
                    isDark,
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.sm),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _calibrateSensor(sensor),
                      icon: const Icon(Icons.tune, size: 16),
                      label: const Text('Calibrate'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: color,
                        side: BorderSide(color: color),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton(
                    onPressed: () => _showSensorDetails(sensor, isDark),
                    icon: const Icon(Icons.more_vert),
                    iconSize: 20,
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, bool isDark) {
    Color color;
    switch (status) {
      case 'normal':
        color = AppColors.success;
        break;
      case 'warning':
        color = AppColors.warning;
        break;
      case 'alert':
        color = AppColors.error;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: AppTypography.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildMetric(IconData icon, String value, Color color, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: AppTypography.bodySmall.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : AppColors.neutral100,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: DropdownButton<String>(
        value: value,
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
        onChanged: onChanged,
        underline: const SizedBox(),
        isExpanded: true,
        icon: const Icon(Icons.arrow_drop_down),
      ),
    );
  }

  void _showSensorDetails(Map<String, dynamic> sensor, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(sensor['name']),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Sensor ID', sensor['id']),
              _buildDetailRow('Type', sensor['type']),
              _buildDetailRow('Location', sensor['location']),
              _buildDetailRow('Current Value', '${sensor['value']} ${sensor['unit']}'),
              _buildDetailRow('Status', sensor['status']),
              _buildDetailRow('Battery Level', '${sensor['batteryLevel']}%'),
              _buildDetailRow('Signal Strength', '${sensor['signalStrength']}%'),
              _buildDetailRow(
                'Last Calibrated',
                DateFormat('MMM dd, yyyy').format(sensor['lastCalibrated']),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _calibrateSensor(sensor);
            },
            icon: const Icon(Icons.tune),
            label: const Text('Calibrate'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          Text(
            value,
            style: AppTypography.bodyMedium,
          ),
        ],
      ),
    );
  }

  void _calibrateSensor(Map<String, dynamic> sensor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calibrating ${sensor['name']}...'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {},
        ),
      ),
    );
  }

  void _showAddSensorDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Sensor'),
        content: const Text('Sensor addition feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
