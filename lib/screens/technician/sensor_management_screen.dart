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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth < 1200 && screenWidth >= 600;
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
        title: Text(
          'Sensor Management',
          style: AppTypography.h5.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontSize: isMobile ? 18 : 20,
          ),
        ),
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
            padding: EdgeInsets.all(isMobile ? AppSpacing.sm : AppSpacing.md),
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
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontSize: isMobile ? 13 : 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search sensors...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white60 : AppColors.textSecondary,
                      fontSize: isMobile ? 13 : 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: isDark ? Colors.white60 : AppColors.textSecondary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.white10 : AppColors.neutral100,
                    contentPadding: EdgeInsets.all(isMobile ? AppSpacing.sm : AppSpacing.md),
                  ),
                ),
                SizedBox(height: isMobile ? AppSpacing.sm : AppSpacing.md),
                // Filter chips
                isMobile
                    ? Column(
                        children: [
                          _buildFilterDropdown(
                            'Type',
                            _selectedType,
                            ['All', 'temperature', 'humidity', 'ph', 'ec', 'tds', 'co2', 'distance'],
                            (value) => setState(() => _selectedType = value!),
                            isDark,
                            isMobile: true,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _buildFilterDropdown(
                            'Status',
                            _selectedStatus,
                            ['All', 'normal', 'warning', 'alert', 'offline'],
                            (value) => setState(() => _selectedStatus = value!),
                            isDark,
                            isMobile: true,
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: _buildFilterDropdown(
                              'Type',
                              _selectedType,
                              ['All', 'temperature', 'humidity', 'ph', 'ec', 'tds', 'co2', 'distance'],
                              (value) => setState(() => _selectedType = value!),
                              isDark,
                              isMobile: false,
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
                              isMobile: false,
                            ),
                          ),
                        ],
                      ),
              ],
            ),
          ),

          // Sensor count
          Container(
            padding: EdgeInsets.all(isMobile ? AppSpacing.sm : AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    '${filteredSensors.length} Sensors',
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      fontSize: isMobile ? 15 : 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Flexible(
                  child: Text(
                    '${sensors.where((s) => s['status'] == 'normal').length} Active',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                      fontSize: isMobile ? 13 : 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Sensor grid
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(isMobile ? AppSpacing.sm : AppSpacing.md),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isMobile ? 1 : (isTablet ? 2 : 3),
                childAspectRatio: isMobile ? 1.6 : (isTablet ? 1.5 : 1.4),
                crossAxisSpacing: isMobile ? AppSpacing.sm : AppSpacing.md,
                mainAxisSpacing: isMobile ? AppSpacing.sm : AppSpacing.md,
              ),
              itemCount: filteredSensors.length,
              itemBuilder: (context, index) {
                return _buildSensorCard(filteredSensors[index], isDark, isMobile: isMobile, isTablet: isTablet);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorCard(Map<String, dynamic> sensor, bool isDark, {bool isMobile = false, bool isTablet = false}) {
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
          padding: EdgeInsets.all(isMobile ? AppSpacing.sm : (isTablet ? AppSpacing.sm : AppSpacing.md)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with icon and status
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isMobile ? 6 : (isTablet ? 7 : AppSpacing.sm)),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Icon(
                      sensor['icon'] as IconData,
                      color: color,
                      size: isMobile ? 20 : (isTablet ? 22 : 24),
                    ),
                  ),
                  SizedBox(width: isMobile ? AppSpacing.xs : AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          sensor['name'],
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                            fontSize: isMobile ? 13 : (isTablet ? 14 : 15),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          sensor['id'],
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark ? Colors.white60 : AppColors.textSecondary,
                            fontSize: isMobile ? 10 : 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(sensor['status'], isDark, isMobile: isMobile, isTablet: isTablet),
                ],
              ),

              SizedBox(height: isMobile ? AppSpacing.sm : AppSpacing.md),

              // Current value
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      '${sensor['value']}',
                      style: AppTypography.h4.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: isMobile ? 24 : (isTablet ? 26 : 28),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      sensor['unit'],
                      style: AppTypography.bodyMedium.copyWith(
                        color: color.withOpacity(0.8),
                        fontSize: isMobile ? 12 : (isTablet ? 13 : 14),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              SizedBox(height: isMobile ? AppSpacing.xs : AppSpacing.xs),

              // Location
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: isMobile ? 12 : 14,
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      sensor['location'],
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? Colors.white60 : AppColors.textSecondary,
                        fontSize: isMobile ? 10 : 11,
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
                  Expanded(
                    child: _buildMetric(
                      Icons.battery_std,
                      '$batteryLevel%',
                      batteryLevel > 80 ? AppColors.success : 
                      batteryLevel > 50 ? AppColors.warning : AppColors.error,
                      isDark,
                      isMobile: isMobile,
                      isTablet: isTablet,
                    ),
                  ),
                  SizedBox(width: isMobile ? 4 : AppSpacing.xs),
                  Expanded(
                    child: _buildMetric(
                      Icons.signal_cellular_alt,
                      '$signalStrength%',
                      signalStrength > 70 ? AppColors.success : 
                      signalStrength > 40 ? AppColors.warning : AppColors.error,
                      isDark,
                      isMobile: isMobile,
                      isTablet: isTablet,
                    ),
                  ),
                  SizedBox(width: isMobile ? 4 : AppSpacing.xs),
                  Expanded(
                    child: _buildMetric(
                      Icons.schedule,
                      '${daysSinceCalibration}d',
                      daysSinceCalibration < 14 ? AppColors.success : 
                      daysSinceCalibration < 21 ? AppColors.warning : AppColors.error,
                      isDark,
                      isMobile: isMobile,
                      isTablet: isTablet,
                    ),
                  ),
                ],
              ),

              SizedBox(height: isMobile ? AppSpacing.xs : AppSpacing.sm),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _calibrateSensor(sensor),
                      icon: Icon(Icons.tune, size: isMobile ? 14 : 16),
                      label: Text(
                        'Calibrate',
                        style: TextStyle(fontSize: isMobile ? 11 : 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: color,
                        side: BorderSide(color: color),
                        padding: EdgeInsets.symmetric(
                          vertical: isMobile ? 6 : 8,
                          horizontal: isMobile ? AppSpacing.xs : AppSpacing.sm,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                  SizedBox(width: isMobile ? AppSpacing.xs : AppSpacing.sm),
                  IconButton(
                    onPressed: () => _showSensorDetails(sensor, isDark),
                    icon: Icon(Icons.more_vert, size: isMobile ? 18 : 20),
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, bool isDark, {bool isMobile = false, bool isTablet = false}) {
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
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 6 : (isTablet ? 7 : 8),
        vertical: isMobile ? 3 : 4,
      ),
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
          fontSize: isMobile ? 9 : 10,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildMetric(IconData icon, String value, Color color, bool isDark, {bool isMobile = false, bool isTablet = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: isMobile ? 12 : (isTablet ? 13 : 14),
          color: color,
        ),
        SizedBox(width: isMobile ? 2 : 4),
        Flexible(
          child: Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: isMobile ? 10 : 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
    bool isDark, {
    bool isMobile = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? AppSpacing.sm : AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : AppColors.neutral100,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08),
        ),
      ),
      child: DropdownButton<String>(
        value: value,
        items: items.map((item) => DropdownMenuItem(
          value: item,
          child: Text(
            item,
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontSize: isMobile ? 12 : 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        )).toList(),
        onChanged: onChanged,
        underline: const SizedBox(),
        isExpanded: true,
        icon: Icon(
          Icons.arrow_drop_down,
          color: isDark ? Colors.white : AppColors.textPrimary,
          size: isMobile ? 20 : 24,
        ),
        style: TextStyle(
          color: isDark ? Colors.white : AppColors.textPrimary,
          fontSize: isMobile ? 12 : 13,
        ),
        dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
      ),
    );
  }

  void _showSensorDetails(Map<String, dynamic> sensor, bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        title: Text(
          sensor['name'],
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontSize: isMobile ? 18 : 20,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Sensor ID', sensor['id'], isDark, isMobile: isMobile),
              _buildDetailRow('Type', sensor['type'], isDark, isMobile: isMobile),
              _buildDetailRow('Location', sensor['location'], isDark, isMobile: isMobile),
              _buildDetailRow('Current Value', '${sensor['value']} ${sensor['unit']}', isDark, isMobile: isMobile),
              _buildDetailRow('Status', sensor['status'], isDark, isMobile: isMobile),
              _buildDetailRow('Battery Level', '${sensor['batteryLevel']}%', isDark, isMobile: isMobile),
              _buildDetailRow('Signal Strength', '${sensor['signalStrength']}%', isDark, isMobile: isMobile),
              _buildDetailRow(
                'Last Calibrated',
                DateFormat('MMM dd, yyyy').format(sensor['lastCalibrated']),
                isDark,
                isMobile: isMobile,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(
                color: isDark ? Colors.white70 : AppColors.textPrimary,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _calibrateSensor(sensor);
            },
            icon: Icon(Icons.tune, size: isMobile ? 16 : 18),
            label: Text(
              'Calibrate',
              style: TextStyle(fontSize: isMobile ? 13 : 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark, {bool isMobile = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 6 : 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 2,
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontSize: isMobile ? 13 : 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            flex: 3,
            child: Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
                fontSize: isMobile ? 13 : 14,
              ),
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        title: Text(
          'Add New Sensor',
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontSize: isMobile ? 18 : 20,
          ),
        ),
        content: Text(
          'Sensor addition feature coming soon!',
          style: TextStyle(
            color: isDark ? Colors.white70 : AppColors.textSecondary,
            fontSize: isMobile ? 13 : 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? Colors.white70 : AppColors.textPrimary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Add',
              style: TextStyle(fontSize: isMobile ? 13 : 14),
            ),
          ),
        ],
      ),
    );
  }
}
